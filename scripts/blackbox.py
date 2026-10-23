#!/usr/bin/env python3
"""Чёрный ящик Элли: выгрузка с телефона на Mac и стирание выгруженного (D3.2 `app-black-box`, B15–B16).

Зачем: записи детских сессий при родителе лежат только на телефоне (knowledge/ops/black-box.md). Родитель одной
командой, без облака, выгружает их в `local/blackbox/<дата>/<сессия>/` и стирает на телефоне только сессии, сверенные
на Mac: первая строка записи `ALLY-BLACKBOX/1`, JSON разбирается, размер и FNV-1a звука равны записанным.

    python3 scripts/blackbox.py pull|erase --device <UDID>     # erase: сначала pull, затем стирание сверенного

Сторожа git и iCloud — до любого копирования; шаги судятся кодом возврата (L10); пути — списком аргументов, без shell.
Тестовые входы: `--date ГГГГ-ММ-ДД`, `BLACKBOX_XCRUN` (путь к xcrun). Смоук — delivery/evals/smoke/blackbox_pull.sh.
Оговорка — рисковый путь D3.2: формат `devicectl device info files --json-output` для вложенных каталогов и поведение
`copy to --remove-existing-content true` проверяются на телефоне: листинг разбирается защитно, а стёртой считается
только сессия, файлов которой нет в листинге после стирания. На Mac инструмент ничего не удаляет, кроме своего
`.staging` и пустых каталогов, созданных тем же прогоном.
"""
from __future__ import annotations

import argparse
import contextlib
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

XCRUN = os.environ.get("BLACKBOX_XCRUN", "xcrun")
CONTAINER = ("--domain-type", "appDataContainer", "--domain-identifier", "com.anthonypriceone.ally")
BOX = "Library/Application Support/BlackBox"
HEADER = b"ALLY-BLACKBOX/1"
SESSION = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}Z-[0-9A-Za-z]{8}")
BOX_FILE = re.compile(r"\d{4,}(?:\.allybox|-child\.wav|-elly\.m4a)")
DAY = re.compile(r"\d{4}-\d{2}-\d{2}")
LOCKED = re.compile(r"locked|passcode", re.IGNORECASE)
FNV_OFFSET, FNV_PRIME, MASK64 = 0xCBF29CE484222325, 0x100000001B3, (1 << 64) - 1
Files = dict[str, dict[str, int]]  # сессия → {файл: байты на телефоне}


class Stop(Exception):
    """Отказ с объяснением для родителя: печатается как есть, выход 1."""


def devicectl(udid: str, *args: str) -> str | None:
    """`devicectl device <два слова> --device UDID <флаги>`: None — код 0, иначе ошибка; запертый телефон — Stop."""
    done = subprocess.run([XCRUN, "devicectl", "device", *args[:2], "--device", udid, *args[2:]],
                          capture_output=True, encoding="utf-8", errors="replace", check=False)
    if done.returncode == 0:
        return None
    if LOCKED.search(done.stdout + done.stderr):
        raise Stop("телефон заперт — разблокируй телефон и повтори")
    lines = [line.strip() for line in (done.stderr + "\n" + done.stdout).splitlines() if line.strip()]
    return lines[0][:200] if lines else f"код {done.returncode}"


def listed(udid: str, sub: str) -> list[tuple[list[str], object]]:
    """Пути по частям и размеры одного каталога контейнера; незнакомый формат — отказ с объяснением, а не падение."""
    with tempfile.TemporaryDirectory() as work:
        out = Path(work, "files.json")
        why = devicectl(udid, "info", "files", *CONTAINER, "--subdirectory", sub, "--json-output", str(out))
        if why:
            raise Stop(f"листинг «{sub}» не получен: {why}")
        try:
            items = json.loads(out.read_text(encoding="utf-8"))["result"]["files"]
            names = [(item["relativePath"] if "relativePath" in item else item["name"]).split("/") for item in items]
            return [([part for part in parts if part not in ("", ".")], (item.get("metadata") or {}).get("size"))
                    for parts, item in zip(names, items)]
        except (OSError, ValueError, KeyError, TypeError, AttributeError) as err:
            raise Stop(f"листинг devicectl в незнакомом формате ({type(err).__name__}) — ждали result.files[]") from err


def sort_into(files: Files, unknown: dict[str, list[str]], found: list, hint: str | None) -> set[str]:
    """Раскладывает листинг по сессиям, возвращает их каталоги; имя без каталога сессии относится к `hint`."""
    dirs: set[str] = set()
    for raw, size in found:
        parts = raw if any(SESSION.fullmatch(part) for part in raw) or not hint else [hint, *raw]
        at = next((i for i, part in enumerate(parts) if SESSION.fullmatch(part)), None)
        if at is None:
            continue
        session, rest = parts[at], "/".join(parts[at + 1:])
        dirs.add(session)
        if rest and not BOX_FILE.fullmatch(rest):
            unknown.setdefault(session, []).append(rest)
        elif rest and isinstance(size, int):
            files.setdefault(session, {})[rest] = size
        elif rest:
            raise Stop(f"листинг devicectl в незнакомом формате — у {session}/{rest} нет metadata.size")
    return dirs


def list_box(udid: str) -> tuple[Files, dict[str, list[str]]]:
    """Ящик на телефоне и незнакомые имена в сессиях; нет ни одного `<сессия>/<файл>` — листинг каждой сессии."""
    files, unknown = {}, {}
    dirs = sort_into(files, unknown, listed(udid, BOX), None)
    if not files:
        for session in sorted(dirs):
            sort_into(files, unknown, listed(udid, f"{BOX}/{session}"), session)
    return files, unknown


def destination(root: Path, day: str) -> Path:
    """Каталог выгрузки после сторожей: игнорируется git и не синхронизируется с iCloud; на диск — ничего."""
    dest = root / "local" / "blackbox" / day
    probe = ["git", "check-ignore", "-q", str(dest / "check-ignore-probe")]
    if subprocess.run(probe, cwd=root, check=False).returncode != 0:
        raise Stop(f"путь {dest.relative_to(root)} не игнорируется git — выгрузка отменена")
    synced = "/Library/Mobile Documents/" in f"{dest}/"
    mdls = shutil.which("mdls")  # нет (не macOS) — проверяется только путь
    if not synced and mdls:
        near = next(path for path in (dest, *dest.parents) if path.exists())
        done = subprocess.run([mdls, "-raw", "-name", "kMDItemIsUbiquitous", str(near)],
                              capture_output=True, text=True, check=False)
        if done.returncode != 0:
            raise Stop(f"признак iCloud не читается (mdls, код {done.returncode}) — выгрузка отменена")
        synced = done.stdout.strip() == "1"
    if synced:
        raise Stop(f"каталог {dest.relative_to(root)} синхронизируется с iCloud — выгрузка отменена")
    return dest


def fnv1a(data: bytes) -> str:
    """FNV-1a 64 в формате записи: `fnv1a:` и ровно 16 hex-цифр в нижнем регистре."""
    value = FNV_OFFSET
    for byte in data:
        value = ((value ^ byte) * FNV_PRIME) & MASK64
    return f"fnv1a:{value:016x}"


def check_audio(folder: Path, audio: object) -> str | None:
    """Причина, если звук не сходится с записью; `missing` — звука нет, сверять нечего."""
    if not isinstance(audio, dict) or "file" not in audio:
        return None if isinstance(audio, dict) and isinstance(audio.get("missing"), str) else "нет ни file, ни missing"
    name = audio["file"]
    if not isinstance(name, str) or not BOX_FILE.fullmatch(name) or not (folder / name).is_file():
        return f"нет файла {name!r}"
    data = (folder / name).read_bytes()
    if len(data) != audio.get("bytes"):
        return f"{name}: {len(data)} байт, в записи {audio.get('bytes')}"
    return None if fnv1a(data) == audio.get("fnv1a") else f"{name}: FNV-1a не сходится"


def check_session(folder: Path) -> str | None:
    """Причина первой несверенной записи; None — сверены все записи сессии."""
    for path in sorted(folder.glob("*.allybox")):
        head, _, body = path.read_bytes().partition(b"\n")
        if head != HEADER:
            return f"{path.name}: первая строка не {HEADER.decode()}"
        try:
            record = json.loads(body.decode("utf-8"))
            bad = [f"{path.name}, {key}: {why}" for key in ("child_audio", "elly_audio")
                   if (why := check_audio(folder, record.get(key)))]
        except (ValueError, AttributeError):
            return f"{path.name}: JSON не разбирается"
        if bad:
            return bad[0]
    return None


def covered(folder: Path, files: dict[str, int]) -> str | None:
    """Причина, если на Mac нет файла с телефона или его размер другой."""
    for name, size in sorted(files.items()):
        have = (folder / name).stat().st_size if (folder / name).is_file() else None
        if have != size:
            return f"{name}: на Mac {'нет' if have is None else f'{have} байт'}, на телефоне {size} байт"
    return None


def on_mac(root: Path, session: str, files: dict[str, int]) -> Path | None:
    """Сверенная копия сессии в любом `local/blackbox/<дата>/`: все файлы телефона того же размера, записи сходятся."""
    for folder in sorted((root / "local" / "blackbox").glob(f"*/{session}")):
        if DAY.fullmatch(folder.parent.name) and not covered(folder, files) and not check_session(folder):
            return folder
    return None


def settle(staged: Path, final: Path) -> str | None:
    """Переносит сверенную сессию в назначение; к прежней копии только добавляет, ничего не перезаписывая."""
    final.mkdir(exist_ok=True)
    paths = sorted(staged.iterdir())
    clash = [p.name for p in paths if (final / p.name).exists() and p.read_bytes() != (final / p.name).read_bytes()]
    if clash:
        return f"в {final.name} на Mac уже лежит другой {clash[0]} — разбери вручную"
    for path in paths:
        if not (final / path.name).exists():
            path.rename(final / path.name)
    return None


def stage(udid: str, folder: Path, session: str, files: dict[str, int]) -> str | None:
    """Копирует файлы сессии во временный каталог и сверяет; причина, если сессия не сверена."""
    folder.mkdir()
    for name in sorted(files):
        why = devicectl(udid, "copy", "from", *CONTAINER, "--source", f"{BOX}/{session}/{name}",
                        "--destination", str(folder / name))
        if why:
            return f"{name} не скопирован: {why}"
    return covered(folder, files) or check_session(folder)


def bring(udid: str, dest: Path, files: Files, fresh: list[str]) -> dict[str, str]:
    """Новые сессии — в `.staging`, сверка, сверенные — в назначение; `.staging` убирается в любом случае."""
    made = [path for path in (dest, *dest.parents) if not path.exists()]
    staging, failed = dest / ".staging", {}
    shutil.rmtree(staging, ignore_errors=True)
    staging.mkdir(parents=True)
    try:
        for session in fresh:
            temp = staging / session
            reason = stage(udid, temp, session, files[session]) or settle(temp, dest / session)
            if reason:
                failed[session] = reason
            print(f"не сверена: {session} — {reason}" if reason else f"сверена: {session}")
    finally:
        shutil.rmtree(staging, ignore_errors=True)
        for path in made:  # от глубокого к мелкому; rmdir снимает только пустые
            with contextlib.suppress(OSError):
                path.rmdir()
    return failed


def mb(files: Files, sessions: list[str]) -> str:
    return f"{sum(sum(files[name].values()) for name in sessions) / 2**20:.1f}".replace(".", ",")


def pull(udid: str, root: Path, day: str) -> tuple[dict[str, Path], dict[str, str]]:
    """Сторожа, телефон, листинг, копирование новых сессий и сверка; копии на Mac и причины несверенных."""
    dest = destination(root, day)
    if devicectl(udid, "info", "details", "--timeout", "30"):
        raise Stop(f"телефон {udid} не найден — подключи его или проверь UDID")
    files, _ = list_box(udid)
    found = {session: on_mac(root, session, sizes) for session, sizes in files.items()}
    fresh = sorted(session for session, copy in found.items() if copy is None)
    failed = bring(udid, dest, files, fresh) if fresh else {}
    print(f"выгружено: {len(fresh)} сессий, {mb(files, fresh)} МБ, сверено {len(fresh) - len(failed)} из {len(fresh)}")
    if len(found) > len(fresh):
        print(f"сессий уже на Mac: {len(found) - len(fresh)}")
    return {s: copy or dest / s for s, copy in found.items() if s not in failed}, failed


def keep_reason(session: str, files: Files, unknown: dict[str, list[str]], verified: dict[str, Path],
                failed: dict[str, str]) -> str | None:
    """Причина не стирать: незнакомые файлы, нет сверенной копии на Mac или на телефоне больше, чем на Mac."""
    if session in unknown:
        return f"на телефоне незнакомые файлы: {', '.join(unknown[session][:3])}"
    if session not in verified:
        return failed.get(session, "нет сверенной копии на Mac — выгрузи ещё раз")
    reason = covered(verified[session], files[session])
    return f"{reason} — выгрузи ещё раз" if reason else None


def erase(udid: str, root: Path, day: str) -> int:
    """Сначала выгрузка; затем каталог каждой сессии со сверенной копией на Mac стирается пустым каталогом."""
    verified, failed = pull(udid, root, day)
    files, unknown = list_box(udid)
    kept = {name: why for name in files if (why := keep_reason(name, files, unknown, verified, failed))}
    with tempfile.TemporaryDirectory() as empty:
        for session in sorted(set(files) - set(kept)):
            try:
                why = devicectl(udid, "copy", "to", *CONTAINER, "--source", empty, "--destination",
                                f"{BOX}/{session}", "--remove-existing-content", "true")
            except Stop as stop:
                why = str(stop)
            if why:
                kept[session] = f"стирание не удалось: {why}"
    left, _ = list_box(udid)  # стёрто то, чего нет в листинге после стирания
    stuck = "файлы остались после стирания — сверь devicectl copy to на телефоне"
    kept.update({name: stuck for name in left if name in files and name not in kept})
    gone = [name for name in files if name not in kept]
    print(f"стёрто: {len(gone)} сессий, {mb(files, gone)} МБ")
    for session, reason in sorted(kept.items()):
        print(f"оставлено: {session} — {reason}")
    return 1 if kept else 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="blackbox.py", description="Чёрный ящик Элли: выгрузка на Mac и стирание.")
    parser.add_argument("command", choices=("pull", "erase"), help="pull — выгрузить; erase — выгрузить и стереть")
    parser.add_argument("--device", required=True, help="UDID телефона (xcrun devicectl list devices)")
    parser.add_argument("--date", default=datetime.date.today().isoformat(), help="дата выгрузки ГГГГ-ММ-ДД",
                        type=lambda value: datetime.date.fromisoformat(value).isoformat())
    args = parser.parse_args(argv)
    try:
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=False)
        if top.returncode != 0:
            raise Stop("не git-репозиторий — запусти из клона Ally")
        root = Path(top.stdout.strip())
        if args.command == "erase":
            return erase(args.device, root, args.date)
        return 1 if pull(args.device, root, args.date)[1] else 0
    except (Stop, OSError) as err:
        print(f"blackbox: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
