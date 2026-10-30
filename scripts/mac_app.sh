#!/usr/bin/env bash
# Элли на Mac одной командой (sim-app): свежий проект — и он открыт в Xcode. Приложение для iPhone на Mac запускает
# только Xcode (Gatekeeper убивает любой другой запуск и показывает окно), поэтому дальше — кнопки родителя:
# устройство «My Mac (Designed for iPhone)» и ⌘R. Тот же ⌘R ставит новую версию и обновляет подпись Personal Team
# на 7 дней. Файлы модели, слуха и голоса — `python3 scripts/mac_files.py` и кнопка консоли «Файлы с Mac…».
#
#   bash scripts/mac_app.sh
#
# Шаги судятся кодом возврата (L10). Приложение скрипт не запускает и в его контейнер не заглядывает.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

fail() { printf 'mac-app: %s\n' "$*" >&2; exit 1; }

[ -f "$REPO/App/Local.xcconfig" ] || fail "нет App/Local.xcconfig с DEVELOPMENT_TEAM — подписать нечем (runbook voice-loop)"
command -v xcodegen >/dev/null 2>&1 || fail "нет xcodegen (brew install xcodegen)"
( cd "$REPO/App" && xcodegen generate >/dev/null ) || fail "xcodegen не собрал проект"
[ -f "$HOME/models/ally-mac/manifest.json" ] || printf 'папки файлов нет — сначала: python3 scripts/mac_files.py\n'
open -a Xcode "$REPO/App/Ally.xcodeproj" || fail "Xcode не открыл проект"
printf '%s\n' "В Xcode: схема Ally (не AllyDemo), устройство «My Mac (Designed for iPhone)», затем ⌘R." \
  "Первый раз: в консоли «Файлы с Mac…» → ~/models/ally-mac; на вопрос macOS про микрофон — «Разрешить»."
