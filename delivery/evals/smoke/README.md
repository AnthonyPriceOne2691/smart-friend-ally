# Durable smoke oracles

Постоянные проверки репозитория; все гоняет `run.sh`. Пока кода продукта нет, это проверки контура;
продуктовые (`swift test`, сборка приложения) добавит первая поставка с кодом.

| ID | Command | Expected | Timeout |
|---|---|---|---|
| S1 | `python3 scripts/delivery_check.py` | exit 0 | 30s |
| S2 | `bash scripts/lint/check_gate_coverage.sh` | exit 0 | 30s |
| S3 | `python3 docs/canon/stack_selftest.py docs/canon` | exit 0 | 60s |
| S4 | `bash delivery/evals/smoke/idle_overdue.sh` | exit 0: в простое просрочка наблюдения красная, CI зовёт гейт | 30s |
