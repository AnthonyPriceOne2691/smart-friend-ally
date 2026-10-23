# Tasks — D5 kv-spoken

- [x] T0: подпись родителя под спекой серии и планом — отдельным коммитом (`human_ok_spec`, `human_ok_plan`) — e5c86ac
- [x] T1: дождаться мержа D7.1 `turn-speculation`, влить main — D7.1 fad20f3, main 824f372 влит (03792bb) без конфликтов
- [x] T2: порт `LanguageModel` — `commit(spoken:)`, `retract()`, `remember(heard:spoken:)`; все обёртки и двойники (L58)
  — без реализаций по умолчанию: обёртка `Speculation` передаёт все три, двойники держат память D5 (`ModelMemory`);
    другого `LanguageModel` в пакетах и `App/` нет (приложение отдаёт сессии `LlamaModel` напрямую)
- [x] T3: `TurnRunner` — прозвучавшие предложения, `commit` в конце хода и при отмене; тесты X2, X3
  — `Sounded`: предложение в счёт, если `speak` вернулся до отмены; `commit` — из `defer` на любом выходе
- [x] T4: сессия — заготовки через `remember`, `forget` — ничего; спекуляция → `retract`, `spec_retracted`; тесты X4, X5
  — U12 D7.1 заменён на X4 (сессия ждёт `begunAnswerFinished`, хук тот же, что в fix/u12-race 8919b77); 7 мутаций
    ядра краснят X2–X5; 30 прогонов под нагрузкой (6 параллельно × 5) зелёные
- [x] T5: `LlamaModel` — память хода, стоп не стирает её реплику, проверка `swa_full`; тесты X1, X6 (Mac с весами), X7
  — сделано до D7.1 (от неё не зависит): `commit(spoken:)`, `retract()`, `remember(heard:spoken:)`, ошибка
    `swaFullOff`; X1, X6, X7 зелёные на Mac с весами, мутация «commit и retract не удаляют хвост» краснит X1 и X6;
    A23 — 37 из 37 токенов и ответов при n_ctx 4096 и 8192
- [x] T6: знания — `on-device-model`, `session`, `safety-below-model`, `knowledge/log.md`
  — `session`, `voice-loop` (KV и строка `swa_full`; `on-device-model` — ADR выбора модели, граница памяти описана
    там, где описан KV, L70), `safety-below-model`, `engineering/index`, `log.md`
- [ ] T7: телефон — X8 в общую сессию теста (постоянное решение родителя); eval-smoke, verify-report (L43), строгий
  `delivery_check`, CI; архив в том же PR с уроками L95, L96, L97; slug `kv-spoken` — строкой в конец
  `delivery/OBSERVATIONS.md`, не в CLAUDE.md (правило ведущего 2026-10-23); мерж — ведущий
