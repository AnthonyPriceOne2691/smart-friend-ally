# Tasks

Уроки архива: `delivery/archive/INDEX.md` пуст — первая поставка проекта.
Опыт тренера учтён через KNOWLEDGE.md §8 (П24–П37).

## Slice 1 — ① Delivery
- [x] T1: дерево `delivery/` по §2.3, конституция Ally, `.claude/settings.json`
- [x] T2: hook A.5 в `CLAUDE.md`, `.gitignore` с правилами детских данных
- [x] T3: `delivery_check` без ошибок (A1)

## Slice 2 — ② CQG
- [x] T4: скрипты Приложения A, `.pre-commit-config.yaml` дословно, затем адаптация путей и масок
- [x] T5: `not-applicable.json`, `adapted.json`, гейт детских данных с канарейкой (A3)
- [x] T6: манифест инструментов, baseline'ы, `pre-commit install` (+ pre-push)
- [x] T7: `check_gate_coverage` (A2), `pre-commit run --all-files`, `contour_doctor` (A4)

## Slice 3 — ③ OKF
- [x] T8: preflight (сверка upstream SPEC), bundle `knowledge/`, валидатор и sync-гейт (A6)

## Slice 4 — ④ CI и гейт мержа
- [x] T9: `quality.yml`, `main-guard.yml`, `canon-freshness.yml`, `merge_guard.sh`, `check_ci_status.sh`
- [ ] T10: приватный репозиторий, первый прогон, `ci-oracles` по факту (A7)

## Slice 5 — снимок и приёмка
- [x] T11: `docs/canon/` + самопроверка + `VENDORED.json` (A5)
- [ ] T12: приёмка §6 → `STACK-ACCEPTANCE.md`, `verify-report.md`, мерж через `merge_guard.sh`
