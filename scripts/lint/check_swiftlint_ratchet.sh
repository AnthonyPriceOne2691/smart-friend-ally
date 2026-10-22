#!/usr/bin/env bash
# SwiftLint findings-ратчет (Swift-слой). Глобальный счётчик находок.
#
# Свой гейт проекта: адаптация check_eslint_warnings.sh из CODE_QUALITY_GATES.md Приложение A (образец —
# lash-try-on). Механика сохранена: global-count baseline, только вниз, --generate, STRICT=0; инструмент — swiftlint,
# потому что код продукта — Swift. Держит роли «warnings линтера не растут», сложности (cyclomatic_complexity 8/10)
# и Swift-двойников правил grep/ast (custom_rules в .swiftlint.yml). Плюс роль no-grab-bag-module: файл-помойка
# utils/misc/common/helpers.swift в Sources считается находкой.
#
# Бинаря swiftlint нет — гейт не блокирует, только предупреждает (чистый clone без brew); в CI шаг «инструменты
# гейтов на месте» требует swiftlint, поэтому там пропуск невозможен.
#
# Настройка (env):
#   DEVELOPER_DIR — путь к Xcode на macOS (дефолт: /Applications/Xcode.app/Contents/Developer)
#   STRICT=0      — soft (warning, exit 0); в CI ЗАПРЕЩЁН
#
# Режимы:
#   check_swiftlint_ratchet.sh             # проверка; exit 1 при росте
#   check_swiftlint_ratchet.sh --generate  # пере-снять baseline (текущее число)

set -uo pipefail

STRICT=${STRICT:-1}
GENERATE=0
[[ "${1:-}" == "--generate" ]] && GENERATE=1

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BASELINE="$SCRIPT_DIR/swiftlint_baseline.txt"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT" || exit 1

red=$(printf '\033[31m'); yellow=$(printf '\033[33m'); green=$(printf '\033[32m'); reset=$(printf '\033[0m')

if ! command -v swiftlint >/dev/null 2>&1; then
  printf '%sswiftlint не найден — гейт пропущен (brew install swiftlint)%s\n' "$yellow" "$reset" >&2
  exit 0
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
fi

# Скоуп: сколько Swift-файлов реально просмотрено (CQG §6 — гейт обязан это показать).
scanned=$(git ls-files -- 'Packages/*.swift' 'App/*.swift' | grep -c . || true)
if [[ "$scanned" -eq 0 ]]; then
  printf '%s  !  swiftlint-ratchet: 0 Swift-файлов в скоупе — included в .swiftlint.yml мимо кода%s\n' \
    "$yellow" "$reset" >&2
  exit 1
fi

json=$(swiftlint lint --quiet --reporter json 2>/dev/null)
if [[ -z "$json" ]]; then
  printf '%sswiftlint не вернул результат (sourcekitd? DEVELOPER_DIR=%s)%s\n' \
    "$red" "${DEVELOPER_DIR:-}" "$reset" >&2
  exit 1
fi

read -r lint errors <<<"$(printf '%s' "$json" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print(len(d), sum(1 for x in d if x.get("severity") == "Error"))
')"

# no-grab-bag-module: тема файла — в его имени.
grab=$(git ls-files -- 'Packages/*/Sources/*.swift' 'App/Sources/*.swift' \
  | grep -ciE '/(utils?|misc|common|helpers?)\.swift$' || true)
total=$(( lint + grab ))

if [[ "$GENERATE" == "1" ]]; then
  {
    echo "# swiftlint_baseline.txt — снимок числа находок SwiftLint и файлов-помоек. --generate, НЕ руками."
    echo "# Global-count: гейт падает при РОСТЕ суммы. Снимок только вниз (CQG §7)."
    echo "$total"
  } >"$BASELINE"
  printf '%sbaseline пересобран%s: %s (%s находок, из них errors: %s, помоек: %s)\n' \
    "$green" "$reset" "$(basename "$BASELINE")" "$total" "$errors" "$grab"
  exit 0
fi

snap=$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$BASELINE" 2>/dev/null | head -1 | tr -d '[:space:]')
snap=${snap:-0}

printf 'swiftlint-ratchet: просмотрено %d файл(ов), находок %d (errors %d, помоек %d), снимок %d\n' \
  "$scanned" "$total" "$errors" "$grab" "$snap"

if [[ "$total" -le "$snap" ]]; then
  exit 0
fi

if [[ "$STRICT" == "0" ]]; then
  printf '%sWARNING%s: находки выросли %s -> %s (STRICT=0)\n' "$yellow" "$reset" "$snap" "$total" >&2
  exit 0
fi
printf '%sERROR%s: находки SwiftLint выросли %s -> %s.\n' "$red" "$reset" "$snap" "$total" >&2
echo "Новый код держим чистым. Починил легаси — пере-сними вниз: --generate." >&2
echo "Список: swiftlint lint --quiet" >&2
exit 1
