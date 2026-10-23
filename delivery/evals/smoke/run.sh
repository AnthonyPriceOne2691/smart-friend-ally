#!/usr/bin/env bash
# Постоянные smoke-оракулы репозитория (Delivery §6.1): гоняет S1–S6 из README
# и падает на первом провале. S1–S4 — проверки контура, S5 — тесты пакетов
# с покрытием, S6 — гейт данных ребёнка на записи чёрного ящика (black-box),
# S7 — выгрузка и стирание чёрного ящика на двойнике devicectl (app-black-box).
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
run S6 bash delivery/evals/smoke/child_data_blackbox.sh
run S7 bash delivery/evals/smoke/blackbox_pull.sh
# S5 в CI гоняет джоба swift (тот же скрипт плюс отрицательный контроль): вторая сборка пакета в джобе delivery
# стоила бы минуту на каждом прогоне и не проверила бы ничего нового. Локально run.sh зовёт его сам.
if [ -n "${CI:-}" ]; then
  echo "S5 — в CI это джоба swift (check_swift_coverage.sh)"
  echo "smoke: 6/6 PASS"
else
  run S5 bash scripts/lint/check_swift_coverage.sh
  echo "smoke: 7/7 PASS"
fi
