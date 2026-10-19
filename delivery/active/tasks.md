# Tasks

## Slice 1 — эталон и данные
- [x] T1: заморозить router3 (sha256 в `decisions.md`); `router_core.py` — перенос на `router.json`; эквивалентность с
  router3 по темам поставки — 0 расхождений на 787 строках × 2 режима флага игры
- [ ] T2: `router.json` (22 понятия, наборы, шумовая модель, темы, 20 проб) и `make_router.py exact` — двойники и хэш;
  самопроверка эталона 20 из 20

## Slice 2 — пакет
- [ ] T3: `Router`, `RouterData`, `Lexicon`, `Scene` — Swift (R3, R8, R9)
- [ ] T4: тесты: паритет фикстуры, пробы и абляция, fail-closed, журнал, флаг игры, заготовки через контракт, шум, время
  (R3, R8–R12; E2, E3, E5, E6, E15, E16, E21–E25)
- [ ] T5: режим `router` у `discipline-replay`; фикстура `make_router.py parity`

## Slice 3 — замер и сдача
- [ ] T6: паритет на 787 строках и время release (R10, R12; E26, E28); числа открытых наборов (R1 по sf07, R3; E21, E27)
- [ ] T7: знания: `safety-below-model` (строка реестра про счётчики — решение 7; раздел маршрутизатора;
  `implementation:`), `knowledge/log.md`; `eval-smoke.md`
- [ ] T8: verify-report, PR, CI зелёный; handoff: архив, INDEX, `router-core` в список наблюдений CLAUDE.md; мерж —
  ведущий через merge_guard
