#!/usr/bin/env bash
# Постоянные smoke-оракулы репозитория (Delivery §6.1): гоняет S1–S10 из README
# и падает на первом провале. S1–S4 — проверки контура, S5 — тесты пакетов
# с покрытием, S6 — гейт данных ребёнка на записи чёрного ящика (black-box),
# S7 — тот же гейт на спутниках базы памяти (memory-core), S8 — сверка команды копирования голоса до первой копии
# (voice-config), S9 — папка файлов для Элли на Mac: сверка до записи и ни шагу в контейнер (sim-app).
# S10 — выгрузка и стирание чёрного ящика на двойнике devicectl (app-black-box).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
PY=python3
[ -x .venv/bin/python ] && PY=.venv/bin/python

passed=0
run() {
  local id="$1"; shift
  if "$@" >/tmp/ally-smoke-$$.log 2>&1; then
    echo "PASS $id — $*"
    passed=$((passed + 1))
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
# S3 — самопроверка payload'а канонов. С варианта D (2026-10-25, AGENT_STACK §7.1a) снимок `docs/canon/` лежит только
# локально: где он есть, S3 гоняет самопроверку; в CI и в чистом checkout его нет по построению, и тогда S3 — названный
# пропуск, если вариант объявлен строкой `stack-selftest: external` в STACK-ACCEPTANCE. Без снимка и без объявления —
# провал: инвариант выглядел бы покрытым, не будучи покрыт ничем. Судит код возврата самопроверки, а не вывод (L10).
s3_skip=""
if [ -f docs/canon/stack_selftest.py ]; then
  run S3 "$PY" docs/canon/stack_selftest.py docs/canon
elif grep -qs '^stack-selftest: external' delivery/STACK-ACCEPTANCE.md; then
  s3_skip="S3 — снимка docs/canon/ нет: вариант D, самопроверка канонов локально (stack-selftest: external)"
  echo "SKIP $s3_skip"
else
  echo "FAIL S3 — снимка docs/canon/ нет, и вариант не объявлен: строки stack-selftest: в delivery/STACK-ACCEPTANCE.md нет"
  exit 1
fi
run S4 bash delivery/evals/smoke/idle_overdue.sh
run S6 bash delivery/evals/smoke/child_data_blackbox.sh
run S7 bash delivery/evals/smoke/child_data_sqlite.sh
run S8 bash delivery/evals/smoke/voice_copy_check.sh
run S9 bash delivery/evals/smoke/mac_files_check.sh
run S10 bash delivery/evals/smoke/blackbox_pull.sh
# S5 в CI гоняет джоба swift (тот же скрипт плюс отрицательный контроль): вторая сборка пакета в джобе delivery
# стоила бы минуту на каждом прогоне и не проверила бы ничего нового. Локально run.sh зовёт его сам.
if [ -n "${CI:-}" ]; then
  echo "S5 — в CI это джоба swift (check_swift_coverage.sh)"
else
  run S5 bash scripts/lint/check_swift_coverage.sh
fi
echo "smoke: $passed PASS${s3_skip:+ · пропуск: $s3_skip}"
