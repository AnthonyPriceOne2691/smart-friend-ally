# Tasks

Уроки по путям диффа (§2.2a): как применены и почему нет — в `plan.md`.

- [x] T1: документы `memory-block-form` первым коммитом, до кода и прогона (L33, L19): STATUS (подпись родителя
  2026-10-29), spec (M43, M15, M23, M24, M40 — правило суда и устройство стенда), plan, tasks, decisions, eval-smoke
- [x] T2: новая форма — шапка и бюджет в `memory.json`, строка «Она» без имени; тесты M43, M15, M23, M24; мутации
- [x] T3: стенд M40 — инструмент блока (`local/spike/m40v2`), драйвер `memory_m40v2.py`, наборы формата B; заморозка
  хэшами до прогона
- [x] T4: прогон M40 на Mac (под нагрузкой), слепые судьи живости, вердикт по правилу спеки — числа в eval-smoke
- [x] T5: по итогу — `escalation.md`, решение родителя «Включить: имя держит код»: `in_conversation: true`, тест `// M40`, окно на D1 (`BlockWindowTests`); знание (`engineering/memory`,
  `engineering/voice-loop`, `engineering/safety-below-model`, `ops/test-session`, лог)
- [ ] T6: PR, CI, verify-report, строгий `delivery_check`; сдача: архив, строка INDEX с уроками L151–L153,
  `memory-block-form` в `delivery/OBSERVATIONS.md`
