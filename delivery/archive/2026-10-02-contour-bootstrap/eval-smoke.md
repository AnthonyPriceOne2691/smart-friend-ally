# Eval smoke — contour-bootstrap

Продуктовые оракулы этой поставки — примеры A1–A7 из `spec.md`. Факт заполняется
по прогону, а не по ожиданию.

| id | Команда | Ожидание | Факт |
|---|---|---|---|
| A1 | `python3 scripts/delivery_check.py` | `0 error(s)` | 0 error(s), 3 warning(s): deferred-спека, нет реляционных оракулов (нет кода), ci-oracles до прогона ✓ |
| A2 | `bash scripts/lint/check_gate_coverage.sh` | exit 0, причины `n/a` напечатаны | OK: 16 скриптов, подключено 4, осознанно нет 12 ✓ |
| A3 | `git add -f local/rec.wav && git commit` | отклонено гейтом детских данных | отклонено хуком child-data (`local-dir`), HEAD не сдвинулся ✓ |
| A4 | `python3 scripts/lint/contour_doctor.py` | `DEAD 0` | AUTO 35 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 0 · DEAD 0 ✓ |
| A5 | `python3 docs/canon/stack_selftest.py docs/canon` | OK | 116 блоков, 0 ошибок; версии совпали с VENDORED.json ✓ |
| A6 | `okf_validate.py`, `okf_sync_gate.py` | оба exit 0 | validate: 0 ошибок, 11 файлов; sync: OK, 2 привязанных концепта ✓ |
| A7 | PR → `quality`; мерж `merge_guard.sh` | зелёный прогон на последнем коммите | прогон 36991128518 success на 8e1b2a6; мерж — merge_guard.sh ✓ |
