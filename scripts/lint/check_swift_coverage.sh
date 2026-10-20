#!/usr/bin/env bash
# Покрытие строк Swift-пакетов (роль check_diff_coverage.sh для стека Swift; свой гейт проекта).
#
# Канонный раннер — pytest --cov (CQG §3.5), к Swift не относится. Механика роли сохранена: порог 70%, отчёт —
# число и что посчитано. Источник — JSON, который пишет `swift test --enable-code-coverage`
# (путь даёт `swift test --show-codecov-path`); считаются только файлы Sources/ самого пакета — тесты, фикстуры и
# пакеты-зависимости (локальный путь) не в счёт.
# Пакет новый, поэтому покрытие всего пакета и есть покрытие диффа; когда появится легаси, роль перейдёт на дифф.
#
# Настройка (env):
#   LINT_SWIFT_PACKAGES — пакеты через пробел, от repo-root (дефолт: Packages/AllyDiscipline)
#   LINT_COVERAGE_MIN   — порог, % строк (дефолт: 70)
#   STRICT=0            — soft (warning, exit 0); в CI ЗАПРЕЩЁН
#
# Режим: check_swift_coverage.sh — гоняет тесты с покрытием и сверяет порог; exit 1 ниже порога или без отчёта.

set -uo pipefail

STRICT=${STRICT:-1}
PACKAGES=${LINT_SWIFT_PACKAGES:-Packages/AllyDiscipline}
MIN=${LINT_COVERAGE_MIN:-70}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT" || exit 1

red=$(printf '\033[31m'); yellow=$(printf '\033[33m'); green=$(printf '\033[32m'); reset=$(printf '\033[0m')

if ! command -v swift >/dev/null 2>&1; then
  printf '%sswift не найден — гейт покрытия пропущен%s\n' "$yellow" "$reset" >&2
  exit 0
fi
# На Mac активный developer dir — Command Line Tools, в нём нет XCTest: тесты гоняются тулчейном Xcode (CLAUDE.md).
if [[ "$(uname)" == Darwin && -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
log=$(mktemp)
trap 'rm -f "$log"' EXIT

fail=0
for pkg in $PACKAGES; do
  if ! swift test --package-path "$pkg" --enable-code-coverage >"$log" 2>&1; then
    # Хвост вывода — причина: без него гейт говорит «упал», не сказав почему (тот же класс, что cqg@2.48).
    printf '%sERROR%s: swift test упал в %s — покрытие не считается на красных тестах:\n' "$red" "$reset" "$pkg" >&2
    tail -25 "$log" >&2
    fail=1; continue
  fi
  report=$(swift test --package-path "$pkg" --show-codecov-path 2>/dev/null | tail -1)
  if [[ ! -f "$report" ]]; then
    printf '%sERROR%s: нет отчёта покрытия для %s (%s)\n' "$red" "$reset" "$pkg" "$report" >&2
    fail=1; continue
  fi
  read -r files covered count <<<"$(python3 - "$report" "$REPO_ROOT/$pkg/Sources/" <<'PY'
import json, os, sys
data = json.load(open(sys.argv[1]))["data"][0]["files"]
# Только Sources/ САМОГО пакета: зависимость локальным путём (AllyCore → AllyDiscipline) попадает в тот же отчёт,
# и её непокрытые строки занижали бы чужой пакет — область измерения шире области гейта (Delivery §4.3b, случай 1).
own = os.path.realpath(sys.argv[2])
src = [f for f in data if os.path.realpath(f["filename"]).startswith(own)]
print(len(src), sum(f["summary"]["lines"]["covered"] for f in src), sum(f["summary"]["lines"]["count"] for f in src))
PY
)"
  if [[ "${files:-0}" -eq 0 || "${count:-0}" -eq 0 ]]; then
    printf '%sERROR%s: %s — в отчёте 0 файлов Sources/: гейт слеп\n' "$red" "$reset" "$pkg" >&2
    fail=1; continue
  fi
  pct=$(( 100 * covered / count ))
  printf 'swift-coverage: %s — %d файл(ов) Sources/, строк %d из %d, %d%% (порог %d%%)\n' \
    "$pkg" "$files" "$covered" "$count" "$pct" "$MIN"
  if (( pct < MIN )); then
    fail=1
  fi
done

if [[ "$fail" == "0" ]]; then
  printf '%sswift-coverage: OK%s\n' "$green" "$reset"
  exit 0
fi
if [[ "$STRICT" == "0" ]]; then
  printf '%sWARNING%s: покрытие ниже порога или отчёта нет (STRICT=0)\n' "$yellow" "$reset" >&2
  exit 0
fi
printf '%sERROR%s: покрытие ниже %d%% или отчёта нет.\n' "$red" "$reset" "$MIN" >&2
exit 1
