# Tasks: `story-mode`

- [x] 1: спека и STATUS отдельным коммитом до кода (ffa26d6) — слова на подпись, примеры T1–T14, правило суда R1–R4
- [x] 2: доклад ведущему — тексты, вопрос родителю, решения 1–4 (одобрены 2026-10-30); план, задачи, решения,
  `eval-smoke.md` — до кода
- [x] 3: Discipline — `TurnMode.story`, лимиты и пробы в `contract.json`, отбор `told`, `more`/`stopped`, `finish` с
  отпущенным, `rescue` только в конец; тесты T5, T6 (корпус фикстур), T11, T14; мутации D1–D12 убиты (12 из 12)
- [x] 4: AllyCore — `story.json`, `StoryIntent` (нормализация, шаблоны, мостики, самопроверка с контрактом), паритет с
  `intent.py` на 100 кейсах (фикстура)
- [x] 5: AllyCore — порт `StoryModel`, `StoryRequest`, `Exchange`, адаптер `StoryTurn`; `SessionParts.story`,
  `Conversation`
- [ ] 6: AllyCore — раннер (мостик, отпуск по предложениям, остаток, этапы), сессия (план, счёт мостиков, обмены, ветка
  сказки), след (`story`, этапы, `said`); тесты T1–T4, T6–T8, T10, T11; мутации
- [ ] 7: подсчёт объёма `delivery_check` после ядра; порог переноса `stream` — по `plan.md`
- [ ] 8: `discipline-replay stream` и сверка на Mac без модели: открытый корпус стендов, `talk`, `why`, `goodbye` до и
  после — байт в байт, «по одному = целое» в `story`
- [x] 9: знание — `engineering/session.md`, `engineering/safety-below-model.md`, `product/persona.md`, `log.md`, индексы
- [x] 10: подпись родителя через ведущего (2026-10-30, «Подписываю: три мостика по кругу (Рекомендую)», 8b99056) — строка `human_ok_spec`, дословный вопрос и ответ в спеке и `decisions.md`;
  правки слов по ответу — до PR
- [ ] 11: слияние свежего main, `swift test` Discipline и AllyCore, строгий
  `delivery_check --require-ci --diff-base origin/main`, verify-report, PR, CI зелёный
- [ ] 12: сдача — архив, INDEX (уроки L177–L180), строка `delivery/OBSERVATIONS.md`, доклад «готово к мержу»
