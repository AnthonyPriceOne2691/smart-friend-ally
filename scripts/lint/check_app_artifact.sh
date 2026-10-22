#!/usr/bin/env bash
# Оракул артефакта приложения (Delivery §12.6, поставка app-voice-loop, A7–A8): судит СОБРАННЫЙ .app, а не исходники.
#
# Свой гейт проекта. Сборка — не оракул (KNOWLEDGE.md П24): права, ключи Info и сетевые символы роняют процесс на
# телефоне или открывают сеть при зелёной сборке, поэтому проверяется то, что уедет на телефон:
#   1. Info.plist — нет ключей сети (ATS, локальная сеть, Bonjour); ключи микрофона и распознавания непустые, по-русски.
#   2. Бинарь, dylib корня и встроенные фреймворки (macOS, xcrun) — в `nm -u` нет URLSession/NSURLSession, `_nw_*`, `_socket`,
#      `_connect`, `_getaddrinfo`; в `otool -L` нет Network, WebKit, CFNetwork, CloudKit. `NSURL` для файлов допустим.
#   3. Права подписанной сборки — сверх подписи (application-identifier, team-identifier, get-task-allow) ровно
#      `com.apple.developer.kernel.increased-memory-limit = true`. Сборка без подписи — права не проверены, и это печатается.
#
# Запуск: check_app_artifact.sh [путь/к/Ally.app …]; без аргументов — все .app в App/build (сборка концепта voice-loop).
# Нет ни одного .app — честный пропуск с причиной (exit 0): гейт судит артефакт, а Linux-джоба его не собирает.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT" || exit 1

red=$(printf '\033[31m'); yellow=$(printf '\033[33m'); green=$(printf '\033[32m'); reset=$(printf '\033[0m')

apps=()
if [[ $# -gt 0 ]]; then
  apps=("$@")
elif [[ -d App/build ]]; then
  while IFS= read -r app; do apps+=("$app"); done < <(find App/build -type d -name '*.app' -prune 2>/dev/null)
fi
if [[ ${#apps[@]} -eq 0 ]]; then
  printf '%sapp-artifact: собранного .app нет — пропуск (сборка: knowledge/engineering/voice-loop.md)%s\n' \
    "$yellow" "$reset"
  exit 0
fi

fail=0
for app in "${apps[@]}"; do
  [[ -d "$app" ]] || { printf '%sapp-artifact: нет каталога %s%s\n' "$red" "$app" "$reset"; fail=1; continue; }
  # 1. Info.plist: plistlib читает и XML, и бинарный формат — проверка одна и на Mac, и на Linux.
  if ! python3 - "$app/Info.plist" <<'PY'
import plistlib, re, sys
try:
    info = plistlib.load(open(sys.argv[1], "rb"))
except (OSError, ValueError) as exc:
    sys.exit(f"Info.plist не читается: {exc}")
bad = [k for k in ("NSAppTransportSecurity", "NSLocalNetworkUsageDescription", "NSBonjourServices") if k in info]
weak = [k for k in ("NSMicrophoneUsageDescription", "NSSpeechRecognitionUsageDescription")
        if not re.search("[А-Яа-яЁё]", str(info.get(k, "")))]
for k in bad:
    print(f"  ключ сети в Info: {k}")
for k in weak:
    print(f"  ключ использования пуст или не по-русски: {k}")
sys.exit(1 if bad or weak else 0)
PY
  then fail=1; fi

  # 2. Бинари: главный и встроенные фреймворки. Без xcrun (Linux) — только Info, и это печатается.
  bins=0
  if command -v xcrun >/dev/null 2>&1; then
    exe=$(python3 -c 'import plistlib,sys; print(plistlib.load(open(sys.argv[1],"rb")).get("CFBundleExecutable",""))' \
      "$app/Info.plist" 2>/dev/null)
    while IFS= read -r bin; do
      [[ -f "$bin" ]] || continue
      bins=$((bins + 1))
      net=$(xcrun nm -u "$bin" 2>/dev/null | awk '{print $NF}' \
        | grep -E '^_(socket|connect|getaddrinfo)$|^_nw_|URLSession' | sort -u | head -5)
      libs=$(xcrun otool -L "$bin" 2>/dev/null | grep -E '/(Network|WebKit|CFNetwork|CloudKit)\.framework/' | head -3)
      if [[ -n "$net$libs" ]]; then
        printf '  сеть в %s: %s\n' "${bin#"$app"/}" "$(printf '%s %s' "$net" "$libs" | tr '\n' ' ')"
        fail=1
      fi
    # Отладочная сборка кладёт код в Ally.debug.dylib рядом с заглушкой: dylib корня судятся наравне с главным бинарём.
    done < <(printf '%s\n' "$app/$exe"; find "$app" -maxdepth 1 -name '*.dylib' 2>/dev/null
             find "$app/Frameworks" -maxdepth 2 -type f -perm -u+x 2>/dev/null)
  fi

  # 3. Права — только у подписанной сборки.
  ents=$(command -v codesign >/dev/null 2>&1 && codesign -d --entitlements :- "$app" 2>/dev/null)
  if [[ -n "$ents" ]]; then
    if ! printf '%s' "$ents" | python3 -c '
import plistlib, sys
ents = plistlib.loads(sys.stdin.buffer.read())
extra = sorted(set(ents) - {"application-identifier", "com.apple.developer.team-identifier", "get-task-allow",
                            "com.apple.developer.kernel.increased-memory-limit"})
memory = ents.get("com.apple.developer.kernel.increased-memory-limit") is True
for k in extra:
    print(f"  лишнее право: {k}")
if not memory:
    print("  нет права com.apple.developer.kernel.increased-memory-limit = true")
sys.exit(1 if extra or not memory else 0)'; then fail=1; fi
    signed="права сверены"
  else
    signed="без подписи — права не проверены (A8 — на подписанной сборке)"
  fi
  printf 'app-artifact: %s — Info, бинарей %d, %s\n' "$app" "$bins" "$signed"
done

if [[ "$fail" -ne 0 ]]; then
  printf '%sERROR%s: артефакт приложения нарушает границу (сеть, ключи Info или права) — см. строки выше.\n' "$red" "$reset"
  exit 1
fi
printf '%sapp-artifact: OK%s — просмотрено приложений: %d\n' "$green" "$reset" "${#apps[@]}"
exit 0
