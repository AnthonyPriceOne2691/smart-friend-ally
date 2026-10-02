# Eval smoke — contour-bootstrap

Продуктовые оракулы этой поставки — примеры A1–A7 из `spec.md`. Факт заполняется
по прогону, а не по ожиданию.

| id | Команда | Ожидание | Факт |
|---|---|---|---|
| A1 | `python3 scripts/delivery_check.py` | `0 error(s)` | — |
| A2 | `bash scripts/lint/check_gate_coverage.sh` | exit 0, причины `n/a` напечатаны | — |
| A3 | `git add -f local/rec.wav && git commit` | отклонено гейтом детских данных | — |
| A4 | `python3 scripts/lint/contour_doctor.py` | `DEAD 0` | — |
| A5 | `python3 docs/canon/stack_selftest.py docs/canon` | OK | — |
| A6 | `okf_validate.py`, `okf_sync_gate.py` | оба exit 0 | — |
| A7 | PR → `quality`; мерж `merge_guard.sh` | зелёный прогон на последнем коммите | — |
