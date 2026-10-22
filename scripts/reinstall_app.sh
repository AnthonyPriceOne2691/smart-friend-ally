#!/usr/bin/env bash
# Переустановка одной командой (E4, поставка app-session). Бесплатная подпись Personal Team живёт 7 дней, и раз в
# неделю приложение ставится заново — поверх, без удаления: контейнер с весами (≈ 5 ГБ, копирование ≈ 3,5 мин) и
# журналом хода остаётся. Скрипт сверяет это списком контейнера до и после установки, печатает срок новой подписи и
# запускает приложение. Ничего не удаляет. Телефона нет — стоп до сборки.
#
#   bash scripts/reinstall_app.sh <UDID>
#
# Каждый шаг судится кодом возврата, а не выводом (L10). Флаги devicectl сверены `--help` на Xcode 27 (L23); формат
# `--json-output`: result.files[].name и .metadata.size. Ставит на телефон только решение родителя (manual-deploy).
set -uo pipefail

UDID="${1:-}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO/App"
BUNDLE="com.anthonypriceone.ally"
MODELS="Library/Application Support/Models"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'reinstall: %s\n' "$*" >&2; exit 1; }

[ -n "$UDID" ] || fail "нужен UDID телефона: bash scripts/reinstall_app.sh <UDID>"
[ -f "$APP_DIR/Local.xcconfig" ] || fail "нет App/Local.xcconfig с DEVELOPMENT_TEAM — подписать нечем (runbook voice-loop)"
read -r WEIGHTS BYTES < <(python3 -c 'import json, sys; m = json.load(open(sys.argv[1]))["model"]; print(m["file"], m["bytes"])' \
  "$APP_DIR/Resources/model.json") || fail "реестр App/Resources/model.json не читается"

xcrun devicectl device info details --device "$UDID" --timeout 30 >/dev/null 2>&1 \
  || fail "телефон $UDID не найден — подключи его или проверь UDID; ничего не собрано и не установлено"

# Байты файла весов в контейнере приложения; пусто — файла нет.
weights_size() {
  xcrun devicectl device info files --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
    --subdirectory "$MODELS" --json-output "$WORK/files.json" >/dev/null 2>&1 || return 0
  python3 - "$WORK/files.json" "$WEIGHTS" <<'PY'
import json, sys
files = json.load(open(sys.argv[1])).get("result", {}).get("files", [])
print(next((f["metadata"]["size"] for f in files if f.get("name") == sys.argv[2]), ""))
PY
}

before=$(weights_size)
printf 'до установки: %s — %s байт (реестр: %s)\n' "$WEIGHTS" "${before:-нет файла}" "$BYTES"

( cd "$APP_DIR" && xcodegen generate >"$WORK/xcodegen.log" 2>&1 ) || fail "xcodegen не собрал проект: $(tail -3 "$WORK/xcodegen.log")"
xcodebuild -project "$APP_DIR/Ally.xcodeproj" -scheme Ally -destination "id=$UDID" -derivedDataPath "$APP_DIR/build" \
  -packageAuthorizationProvider netrc -allowProvisioningUpdates -allowProvisioningDeviceRegistration build \
  >"$WORK/build.log" 2>&1 || { tail -20 "$WORK/build.log" >&2; fail "сборка с подписью не прошла — ничего не установлено"; }
APP="$APP_DIR/build/Build/Products/Debug-iphoneos/Ally.app"
bash "$REPO/scripts/lint/check_app_artifact.sh" "$APP" || fail "оракул артефакта красный — не ставлю"

xcrun devicectl device install app --device "$UDID" "$APP" >"$WORK/install.log" 2>&1 \
  || { tail -5 "$WORK/install.log" >&2; fail "установка не прошла"; }

after=$(weights_size)
printf 'после установки: %s — %s байт\n' "$WEIGHTS" "${after:-нет файла}"
if [ "$after" != "$BYTES" ]; then
  printf 'веса не те или пропали — скопируй с Mac (runbook voice-loop):\n' >&2
  printf '  xcrun devicectl device copy to --device %s --domain-type appDataContainer --domain-identifier %s \\\n' \
    "$UDID" "$BUNDLE" >&2
  printf '    --source ~/models/%s --destination "%s/%s"\n' "$WEIGHTS" "$MODELS" "$WEIGHTS" >&2
  exit 1
fi

security cms -D -i "$APP/embedded.mobileprovision" 2>/dev/null | python3 -c '
import datetime, plistlib, sys
end = plistlib.loads(sys.stdin.buffer.read())["ExpirationDate"].replace(tzinfo=datetime.timezone.utc)
days = (end - datetime.datetime.now(datetime.timezone.utc)).total_seconds() // 86400
print(f"подпись до {end.astimezone():%d.%m %H:%M}, {int(days)} дн.")' || fail "срок подписи не читается"

xcrun devicectl device process launch --device "$UDID" --terminate-existing "$BUNDLE" >"$WORK/launch.log" 2>&1 \
  || fail "приложение стоит, но не запустилось — если подпись новая, доверь сертификату на телефоне: Настройки → Основные → VPN и управление устройством (L15)"
printf 'reinstall: OK — поставлено поверх, веса на месте, приложение запущено\n'
