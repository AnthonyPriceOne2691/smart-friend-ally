#!/usr/bin/env bash
# Постоянные smoke-оракулы репозитория (Delivery §6.1): гоняет S1–S3 из README
# и падает на первом провале. Пока кода продукта нет, это проверки контура;
# продуктовые (swift test, сборка приложения) добавит первая поставка с кодом.
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
echo "smoke: 3/3 PASS"
