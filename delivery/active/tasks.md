# Tasks

Уроки архива: L6 (накат механический, пока отклонения — в конфигах), L9 (накат только из
чистого и отправленного Prepare), L14 (строгий `delivery_check` сразу после наката — ревизия приносит
новые обязанности поставки). Процедура — CLAUDE.md; судья `prepare-ae` советует катить из чистого
клона (`git clone --local`), потому что правит канон в отдельном worktree.

## Slice 1 — канон cqg@2.55 → cqg@2.63, delivery@2.01 → delivery@2.03, okf@1.19 → okf@1.21, stack-map@1.52 → 1.53 (Prepare 2eff5ed)
- [ ] T1: план из клона: едет сам 11, порт вручную 0, стоп 0, новый файл 0, порт не нужен 2
- [ ] T2: `apply_update.py` из клона; записи о версиях — `delivery/STACK-ACCEPTANCE.md`, `delivery/CONSTITUTION.md`, `CLAUDE.md`
- [ ] T3: приёмка: гейты, `check_gate_coverage.sh`, доктор, `stack_selftest`, smoke, перескан базы секретов; строгий `delivery_check` сразу (L14)
