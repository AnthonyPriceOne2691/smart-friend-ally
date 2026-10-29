#!/usr/bin/env bash
# Граница демо (поставка design-demo, Y1–Y3, Y5): демо облика живёт только на Mac и в симуляторе — в приложение на
# телефоне оно не попадает, а в нём самом нет модели, микрофона, голоса и сети. Свой гейт проекта, как
# check_app_artifact.sh: сборка — не оракул (KNOWLEDGE.md П24), поэтому кроме проекта судится и собранное.
#
# Проект — везде (pre-commit, Linux и Mac):
#   Y2  у цели Ally в App/project.yml нет источника, который содержит App/Demo или лежит в нём;
#   Y1  цель AllyDemo есть, её зависимости — только пакет AllyCore и продукты ShellUI, ShellCore пакета AllyShell;
#   Y5  у каждой фазы SessionState (Packages/AllyCore/.../Session.swift) есть строка #Preview в App/Demo/DemoPreviews.swift.
# Собранное — когда есть (macOS-джоба ios.yml, run_demo.sh); вид .app — по CFBundleIdentifier:
#   Y1  AllyDemo.app — com.anthonypriceone.ally.demo, имя «Ally Demo», MinimumOSVersion 27.0;
#   Y2  Ally.app — в Info и бинарях нет метки демо «ally-demo» и bundle id демо; метка в AllyDemo.app есть, иначе
#       проверка слепа (короткие строки Swift живут в коде, а не в таблице строк — метка нарочно длинная);
#   Y3  AllyDemo.app — нет ключей микрофона, распознавания и сети; в бинарях нет символов llama/ggml, ONNX Runtime,
#       sherpa и сети (`xcrun nm`, на Linux — пропуск с причиной); нет файлов модели и голоса; прав сверх подписи нет.
#
# Запуск: check_demo_boundary.sh [--project] [путь/к/*.app …]; без путей — все .app в App/build и App/build-demo;
# --project — только проект (хук pre-commit, бюджет 5 с). Нет ни одного .app — собранное пропускается с причиной.

set -uo pipefail

# Корень — по месту скрипта (scripts/lint/..), а не по git: run_demo.sh зовут из соседнего клона, а в хуке git задаёт
# GIT_DIR, и `git -C каталог rev-parse --show-toplevel` отвечает самим каталогом.
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$REPO_ROOT" || exit 1

exec python3 -I - "$@" <<'PY'
import plistlib
import re
import shutil
import subprocess
import sys
from pathlib import Path

RED, YELLOW, GREEN, RESET = "\033[31m", "\033[33m", "\033[32m", "\033[0m"
DEMO_ID, APP_ID, MARK = "com.anthonypriceone.ally.demo", "com.anthonypriceone.ally", b"ally-demo"
ALLOWED = {("package", "AllyCore", None), ("package", "AllyShell", "ShellUI"), ("package", "AllyShell", "ShellCore")}
EAR = ("NSMicrophoneUsageDescription", "NSSpeechRecognitionUsageDescription")
NET = ("NSAppTransportSecurity", "NSLocalNetworkUsageDescription", "NSBonjourServices")
FILES = re.compile(r"^(model\.json|voice\.json|hearing\.json|allowed_signers|persona.*\.md)$")
SYMBOLS = re.compile(r"llama_|ggml_|OrtGetApiBase|SherpaOnnx|^_(socket|connect|getaddrinfo)$|^_nw_|URLSession")
SIGNING = {"application-identifier", "com.apple.developer.team-identifier", "get-task-allow"}
problems: list[str] = []


def targets(text: str) -> dict:
    """Targets of the XcodeGen spec: name → sources (paths) and dependencies (kind, name, product)."""
    out: dict = {}
    name = key = None
    inside = False
    for raw in text.splitlines():
        line = raw.split(" #", 1)[0].rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent, item = len(line) - len(line.lstrip()), line.strip()
        if indent == 0:
            inside = item == "targets:"
        elif inside and indent == 2 and item.endswith(":"):
            name, key = item[:-1], None
            out[name] = {"sources": [], "deps": []}
        elif inside and indent == 4:
            key = item[:-1] if item.endswith(":") else None
        elif inside and key == "sources" and item.startswith("- "):
            value = item[2:].strip()
            out[name]["sources"].append(value.split(":", 1)[1].strip() if value.startswith("path:") else value)
        elif inside and key == "dependencies" and item.startswith("- "):
            kind, _, value = item[2:].partition(":")
            out[name]["deps"].append([kind.strip(), value.strip(), None])
        elif inside and key == "dependencies" and item.startswith("product:") and out[name]["deps"]:
            out[name]["deps"][-1][2] = item.split(":", 1)[1].strip()
    return out


def check_project() -> None:
    app = Path("App")
    spec = targets((app / "project.yml").read_text(encoding="utf-8"))
    demo = (app / "Demo").resolve()
    for source in spec.get("Ally", {}).get("sources", []):  # Y2
        path = (app / source).resolve()
        if path == demo or demo in path.parents or path in demo.parents:
            problems.append(f"Y2: у цели Ally источник {source} — демо попало бы в приложение на телефоне")
    if "AllyDemo" not in spec:  # Y1
        problems.append("Y1: в App/project.yml нет цели AllyDemo")
    for kind, name, product in spec.get("AllyDemo", {}).get("deps", []):
        if (kind, name, product) not in ALLOWED:
            problems.append(f"Y1/Y3: у AllyDemo зависимость {kind}: {name}" + (f" ({product})" if product else "")
                            + " — в демо только AllyCore, ShellUI, ShellCore: без модели, слуха, голоса и памяти")
    session = Path("Packages/AllyCore/Sources/AllyCore/Session.swift").read_text(encoding="utf-8")
    phases = re.search(r"enum SessionState[^{]*\{\s*case ([^\n]+)", session).group(1).split(",")
    previews = [line for line in (app / "Demo/DemoPreviews.swift").read_text(encoding="utf-8").splitlines()
                if line.startswith("#Preview")]
    missing = [p.strip() for p in phases if not any(re.search(rf"\.{p.strip()}\b", line) for line in previews)]
    for phase in missing:  # Y5
        problems.append(f"Y5: у фазы {phase} нет #Preview в App/Demo/DemoPreviews.swift")
    leak = any(line.startswith("Y2:") for line in problems)
    print(f"demo-boundary: проект — просмотрено {len(spec)} цели: Ally {'с Demo' if leak else 'без Demo'}, AllyDemo: "
          f"{len(spec.get('AllyDemo', {}).get('deps', []))} зависимости, превью фаз {len(phases) - len(missing)} из "
          f"{len(phases)}")


def binaries(app: Path, info: dict) -> list[Path]:
    """The main executable, the dylibs of the root (a debug build keeps its code there) and the frameworks."""
    found = [app / info.get("CFBundleExecutable", "")] + sorted(app.glob("*.dylib"))
    found += sorted(p for p in (app / "Frameworks").rglob("*") if p.is_file() and p.stat().st_mode & 0o111)
    return [p for p in found if p.is_file()]


def check_demo(app: Path, info: dict, bins: list[Path]) -> None:
    if info.get("CFBundleDisplayName") != "Ally Demo" or str(info.get("MinimumOSVersion")) != "27.0":  # Y1
        problems.append(f"Y1: {app.name} — имя {info.get('CFBundleDisplayName')!r}, "
                        f"MinimumOSVersion {info.get('MinimumOSVersion')!r} вместо «Ally Demo» и 27.0")
    for key in [k for k in EAR + NET if k in info]:  # Y3
        problems.append(f"Y3: в Info демо ключ {key} — в демо нет микрофона, распознавания и сети")
    for path in app.rglob("*"):
        if FILES.match(path.name):
            problems.append(f"Y3: в демо файл модели или голоса {path.relative_to(app)}")
    if not any(MARK in p.read_bytes() for p in bins):
        problems.append("Y2: метки ally-demo нет в бинарях AllyDemo.app — проверка Ally.app по метке слепа")
    if shutil.which("xcrun"):
        for path in bins:
            names = subprocess.run(["xcrun", "nm", "-j", str(path)], capture_output=True, text=True).stdout
            hits = sorted({n for n in names.split() if SYMBOLS.search(n)})[:5]
            if hits:
                problems.append(f"Y3: в {path.name} символы модели, ORT, sherpa или сети: {' '.join(hits)}")
    else:
        print(f"{YELLOW}demo-boundary: xcrun нет — символы {app.name} не проверены (macOS-джоба){RESET}")
    if shutil.which("codesign"):
        ents = subprocess.run(["codesign", "-d", "--entitlements", ":-", str(app)], capture_output=True).stdout
        extra = sorted(set(plistlib.loads(ents)) - SIGNING) if ents.strip() else []
        if extra:
            problems.append(f"Y3: права демо сверх подписи: {' '.join(extra)}")


def check_release(app: Path, info: dict, bins: list[Path]) -> None:
    text = repr(info)
    if DEMO_ID in text or MARK.decode() in text:  # Y2
        problems.append(f"Y2: в Info {app.name} метка демо")
    for path in [p for p in bins if MARK in p.read_bytes() or DEMO_ID.encode() in p.read_bytes()]:
        problems.append(f"Y2: в {path.relative_to(app)} метка демо — демо попало в приложение на телефоне")


def check_apps(paths: list[str]) -> None:
    apps = [Path(p) for p in paths] or [p for root in ("App/build", "App/build-demo") if Path(root).is_dir()
                                        for p in sorted(Path(root).rglob("*.app")) if p.is_dir()]
    apps = [a for a in apps if not any(parent.suffix == ".app" for parent in a.parents)]
    if not apps:
        print(f"{YELLOW}demo-boundary: собранного .app нет — пропуск собранного (сборка: scripts/run_demo.sh){RESET}")
    for app in apps:
        try:
            info = plistlib.loads((app / "Info.plist").read_bytes())
        except (OSError, ValueError) as exc:
            problems.append(f"{app}: Info.plist не читается: {exc}")
            continue
        bins, ident = binaries(app, info), info.get("CFBundleIdentifier")
        if ident == DEMO_ID:
            check_demo(app, info, bins)
        elif ident == APP_ID:
            check_release(app, info, bins)
        else:
            print(f"demo-boundary: {app} ({ident}) — не Ally и не демо, пропуск")
            continue
        print(f"demo-boundary: {app} — {ident}, бинарей {len(bins)}")


args = sys.argv[1:]
check_project()
if "--project" not in args:
    check_apps([a for a in args if a != "--project"])
for line in problems:
    print(f"  {line}")
if problems:
    print(f"{RED}ERROR{RESET}: граница демо нарушена — см. строки выше (design-demo, Y1–Y3, Y5).")
    sys.exit(1)
print(f"{GREEN}demo-boundary: OK{RESET}")
PY
