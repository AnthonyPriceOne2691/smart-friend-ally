# Tasks

Уроки архива: L6 — накат механический, пока отклонения — в конфигах; L11 — ручной
порт штатен для адаптированного шаблона, который канон меняет. Процедура — CLAUDE.md.

## Slice 1 — канон cqg@2.46 → cqg@2.55, delivery@1.99 → delivery@2.00 (Prepare 0b9ece0)
- [x] T1: план: едет сам 8, порт вручную 2 (`quality.yml`, `.pre-commit-config.yaml`), стоп 0
- [x] T2: порт: `default_stages: [pre-commit]` (cqg@2.47) — применимо; ruff из venv (2.55), маски jscpd и сложности (2.53), комментарий к шагу покрытия (2.47) — к снятым у нас хукам и шагам
- [x] T3: подтверждение порта человеком (by=human:anthony, at=2026-10-17) → `apply_update.py --ported=.github/workflows/quality.yml,.pre-commit-config.yaml`; база секретов (8 записей, без изменений); приёмка: gate-coverage OK, доктор AUTO 39 · DEAD 0, selftest 0 ошибок
