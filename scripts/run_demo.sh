#!/usr/bin/env bash
# Демо облика в симуляторе одной командой (поставка design-demo, Y7): xcodegen → сборка AllyDemo под симулятор →
# iPhone 17 Pro Max на iOS 27 (нет такого — создаётся) → оракул границы на собранном демо (Y3) → установка → запуск →
# окно симулятора. В демо нет модели, микрофона, голоса и памяти; на телефон оно не ставится.
#
# То же руками в Xcode — для родителя:
#   1. Один раз: bash scripts/run_demo.sh (или cd App && xcodegen generate) — появится App/Ally.xcodeproj; открой его.
#   2. Вверху окна выбери схему AllyDemo и устройство iPhone 17 Pro Max, нажми Run (▶ или ⌘R).
#   3. Превью: App/Demo/DemoPreviews.swift → Editor → Canvas (⌥⌘↩); цвета — Palette.swift, размеры — Look.swift.
#
# Запуск: bash scripts/run_demo.sh ["имя устройства"]. Окно симулятора в Xcode 27 — DeviceHub (Simulator.app нет).
# Рантайм iOS 27.1 (24A94425) знает только iPhone Duo, поэтому берётся новейший iOS 27, который знает устройство.

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"  # активный dir — CLT
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEVICE=${1:-iPhone 17 Pro Max}
BUNDLE=com.anthonypriceone.ally.demo
# Сборка — вне репозитория и своя у каждого клона: в git не попадает, соседнему ворктри не мешает.
DERIVED="$HOME/Library/Developer/Xcode/DerivedData/AllyDemo-$(printf '%s' "$ROOT" | shasum | cut -c1-8)"
APP="$DERIVED/Build/Products/Debug-iphonesimulator/AllyDemo.app"

die() { printf 'run_demo: %s\n' "$*" >&2; exit 1; }
command -v xcodegen >/dev/null || die "нет xcodegen: brew install xcodegen"

# 1. Рантайм и устройство — до сборки: без рантайма ставить некуда.
read -r RUNTIME VERSION KIND UDID < <(xcrun simctl list -j | python3 -c '
import json, sys
name, data = sys.argv[1], json.load(sys.stdin)
kinds = [t["identifier"] for t in data["devicetypes"] if t["name"] == name]
fits = [r for r in data["runtimes"] if r.get("platform") == "iOS" and r.get("isAvailable")
        and r["version"].startswith("27.") and kinds
        and any(t["identifier"] == kinds[0] for t in r.get("supportedDeviceTypes", []))]
if not fits:
    sys.exit(print("- - - -"))
runtime = max(fits, key=lambda r: tuple(int(x) for x in r["version"].split(".")))
devices = sorted((d for d in data["devices"].get(runtime["identifier"], [])
                  if d["name"] == name and d.get("isAvailable")), key=lambda d: d["state"] != "Booted")
print(runtime["identifier"], runtime["version"], kinds[0], devices[0]["udid"] if devices else "-")
' "$DEVICE")
[[ -n "${RUNTIME:-}" && "$RUNTIME" != "-" ]] || die "нет рантайма iOS 27: xcodebuild -downloadPlatform iOS"
[[ "$UDID" != "-" ]] || UDID=$(xcrun simctl create "$DEVICE" "$KIND" "$RUNTIME")

# 2. Проект и сборка под это устройство, без подписи (симулятору она не нужна).
(cd "$ROOT/App" && xcodegen generate --quiet)
mkdir -p "$DERIVED"
LOG="$DERIVED/run_demo.log"
if ! nice -n 10 xcodebuild -project "$ROOT/App/Ally.xcodeproj" -scheme AllyDemo -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO build >"$LOG" 2>&1; then
  grep -E 'error:' "$LOG" | sort -u | head -20 >&2
  die "сборка не прошла — журнал: $LOG"
fi

# 3. Граница демо на собранном (Y3): ни модели, ни микрофона, ни голоса, ни сети.
if ! verdict=$(bash "$ROOT/scripts/lint/check_demo_boundary.sh" "$APP" 2>&1); then
  printf '%s\n' "$verdict" >&2
  die "граница демо нарушена — демо не ставится"
fi

# 4. Загрузка, окно, установка поверх прежней, запуск.
xcrun simctl bootstatus "$UDID" -b >/dev/null
open -a "$DEVELOPER_DIR/../Applications/DeviceHub.app" 2>/dev/null || open -a Simulator 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" >/dev/null
printf 'демо запущено: %s (iOS %s) · %s\n' "$DEVICE" "$VERSION" "$BUNDLE"
