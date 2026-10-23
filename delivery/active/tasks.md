# Tasks — D5 kv-spoken

- [ ] T0: подпись родителя под спекой серии и планом — отдельным коммитом (`human_ok_spec`, `human_ok_plan`)
- [ ] T1: дождаться мержа D7.1 `turn-speculation`, влить main
- [ ] T2: порт `LanguageModel` — `commit(spoken:)`, `retract()`, `remember(heard:spoken:)`; все обёртки и двойники (L58)
- [ ] T3: `TurnRunner` — прозвучавшие предложения, `commit` в конце хода и при отмене; тесты X2, X3
- [ ] T4: сессия — заготовки через `remember`, `forget` — ничего; спекуляция → `retract`, `spec_retracted`; тесты X4, X5
- [ ] T5: `LlamaModel` — память хода, стоп не стирает её реплику, проверка `swa_full`; тесты X1, X6 (Mac с весами), X7
- [ ] T6: знания — `on-device-model`, `session`, `safety-below-model`, `knowledge/log.md`
- [ ] T7: телефон — X8 в сессии с родителем; eval-smoke, verify-report (L43), строгий `delivery_check`, CI; архив в
  том же PR с уроками L95, L96, L97; мерж — ведущий
