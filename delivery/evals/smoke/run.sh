#!/usr/bin/env bash
# Постоянные smoke-оракулы репозитория (Delivery §6.1): гоняет S1–S5 из README
# и падает на первом провале. S1–S4 — проверки контура, S5 — тесты пакета
# AllyDiscipline с покрытием; сборку приложения добавит поставка приложения.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
PY=python3
[ -x .venv/bin/python ] && PY=.venv/bin/python

run() {
  local id="$1"; shift
  if "$@" >/tmp/ally-smoke-$$.log 2>&1; then
    echo "PASS $id — $*"
  else
    echo "FAIL $id — $*"
    tail -20 /tmp/ally-smoke-$$.log
    rm -f /tmp/ally-smoke-$$.log
    exit 1
  fi
  rm -f /tmp/ally-smoke-$$.log
}

run S1 "$PY" scripts/delivery_check.py
run S2 bash scripts/lint/check_gate_coverage.sh
run S3 "$PY" docs/canon/stack_selftest.py docs/canon
run S4 bash delivery/evals/smoke/idle_overdue.sh
# S5 в CI гоняет джоба swift (тот же скрипт плюс отрицательный контроль): вторая сборка пакета в джобе delivery
# стоила бы минуту на каждом прогоне и не проверила бы ничего нового. Локально run.sh зовёт его сам.
if [ -n "${CI:-}" ]; then
  echo "S5 — в CI это джоба swift (check_swift_coverage.sh)"
  echo "smoke: 4/4 PASS"
else
  run S5 bash scripts/lint/check_swift_coverage.sh
  echo "smoke: 5/5 PASS"
fi
