# Tasks

## Slice 1 — эталон и данные
- [ ] T1: копия П1 `router_core.p1.py`; `router_core.py` — темы-статьи, предикаты, флаг `forget`; решения П1 на 787
  строках × 2 режима флага не меняются (L19, L27)
- [ ] T2: `router.json` — понятия, наборы, 10 тем, пробы самопроверки с темой; `make_router.py exact` — двойники и
  хэш; самопроверка эталона — все пробы

## Slice 2 — пакет
- [ ] T3: `Clause.swift`, правки `RouterData`, `Scene`, `Router` — Swift (R3, R8, R9, R10)
- [ ] T4: `Content.swift`, правки `TurnPass`, `Selection`, `TurnContract`, `Contract`, `contract.json` — правила
  содержания и указатель (R13, R14)
- [ ] T5: тесты: примеры спеки, пробы и абляция статей, fail-closed, журнал, флаг игры и указатель, правила
  содержания по фикстуре проб эталона, паритет контракта (R1, R3, R8–R14; E6–E39)
- [ ] T6: `make_router.py parity` (по темам), `make_fixtures.py` (паритет контракта с новыми правилами, фикстура проб
  эталона)

## Slice 3 — замер и сдача
- [ ] T7: паритет на 787 строках × 2 режима и время release (R10, R12; E36, E38); числа открытых наборов (R1 по семи
  ситуациям быта с `judge_safety`, R3; E29, E37)
- [ ] T8: знания: `safety-below-model` (реестр, раздел маршрутизатора), `knowledge/log.md`; `eval-smoke.md`
- [ ] T9: verify-report, PR, CI зелёный; handoff: архив, INDEX, `router-people` в список наблюдений CLAUDE.md; мерж —
  ведущий через merge_guard
