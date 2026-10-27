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
- [x] T7: телефон — X8 в общую сессию теста (постоянное решение родителя, waiver в STATUS); eval-smoke, verify-report
  (L43 — дайджест совпал с пересчётом), строгий `delivery_check`, CI (Linux 40015897856 зелёный; macOS-джоба по метке
  в очереди без раннера, её шаги прогнаны на Mac); архив в том же PR с уроками L111, L112, L113 (перенумерованы
  ведущим 2026-10-23: L95 занял memory-guard); slug `kv-spoken` — строкой в конец `delivery/OBSERVATIONS.md`, не в
  CLAUDE.md (правило ведущего 2026-10-23); мерж — ведущий

## Точка остановки 23.10

Стоп по слову родителя: кончаются лимиты сессии.

**Сделано.** main 4307a08 (Ш3, V3b) влит в #60 коммитом 11fcbd0. Конфликт в шапке `safety-below-model.md` разрешён по
смыслу: оставлены обе строки исполнителей, child-shell-app и kv-spoken. Уроки путей, пришедшие с main (L77–L79,
L105–L107), сосланы в плане сдачи (b7caa5c); L113 записан как дополнение к L79. Проверено на Mac: AllyCore — 98 тестов из
98, сборка `Ally.app` и `check_app_artifact.sh` — OK, `delivery_check --diff-base origin/main` — 0 ошибок, дайджест
утверждений совпал.

**CI не запустился.** Прогон 40020360197 на b7caa5c: GitHub не стартовал джобы — «recent account payments have failed
or your spending limit needs to be increased». Это решает владелец в настройках оплаты.

**Следующий шаг.** Когда оплату восстановят:
1. перезапустить CI на голове (`gh run rerun` или новый пуш) и дождаться зелёного;
2. прогнать `delivery_check --require-ci --diff-base origin/main`;
3. мерж через `merge_guard.sh` делает ведущий.

Если main за это время уйдёт — влить origin/main; конфликт в общих шапках знаний решается так же, обе строки.
