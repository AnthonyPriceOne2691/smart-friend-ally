# Durable smoke oracles

Постоянные проверки репозитория; все гоняет `run.sh`. S1–S4 — проверки контура, S5 — тесты пакета ремонта текста
с покрытием (в CI — джоба `swift`, чтобы не собирать пакет дважды), S6 — гейт данных ребёнка на записи чёрного ящика,
S7 — тот же гейт на спутниках базы памяти.

| ID | Command | Expected | Timeout |
|---|---|---|---|
| S1 | `python3 scripts/delivery_check.py` | exit 0 | 30s |
| S2 | `bash scripts/lint/check_gate_coverage.sh` | exit 0 | 30s |
| S3 | `python3 docs/canon/stack_selftest.py docs/canon` | exit 0 | 60s |
| S4 | `bash delivery/evals/smoke/idle_overdue.sh` | exit 0: в простое просрочка наблюдения красная, CI зовёт гейт | 30s |
| S5 | `bash scripts/lint/check_swift_coverage.sh` | exit 0: `swift test` пакета `AllyDiscipline` зелёный, покрытие строк Sources ≥ 70% | 300s |
| S6 | `bash delivery/evals/smoke/child_data_blackbox.sh` | exit 0: во временном репозитории гейт данных ребёнка краснеет на записи чёрного ящика под чужим именем, в `local/` через `add -f`, на переименованном WAV и `.allybox`; заголовок посреди текста — не находка (B11) | 30s |
| S7 | `bash delivery/evals/smoke/child_data_sqlite.sh` | exit 0: во временном репозитории гейт данных ребёнка краснеет на WAL базы с записью (`-wal` через `add -f` и под чужим именем), на `-shm` и `.db-journal`; без `add -f` спутники игнорируются; имя спутника посреди текста — не находка (M25). С `CHILD_DATA_GATE=<гейт main до memory-core>` — красный: отрицательный контроль | 30s |
