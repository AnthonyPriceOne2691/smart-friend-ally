# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** human:anthony at=2026-10-25 («Подписываю (Рекомендую)» — изменённое ожидание U8 из D7.1: та же реплика «Я была в зоопарке», прочитанная из новой формы памяти `memory.turns.map(\.heard)`; замена U12 из D7.1 тестом X4: ответ, законченный до того, как она продолжила, уходит из памяти — `spec_retracted` 1, `spec_stale` нет. Остальные утверждения ведут к примерам X1–X8 спеки серии «живой разговор», подписанной 2026-10-23; дайджест ниже, asserts_without_example: 0)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40017841603 (Linux: delivery, gates, swift — зелёные на 5819b16; первая попытка джобы `swift` упала падением самого SwiftPM — `Segmentation fault` процесса `swift-package` в прогоне покрытия AllySQLite, пакета вне диффа, — перезапуск зелёный); https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40018186417 (macOS, джоба `app` по метке `macos` — зелёная на 5819b16; прошлый её прогон 40015972860 на f317b81 упал на AllyOnnx: в main тогда не было фикстуры `add.onnx`, L80, её внёс silero-vad)
**Commit:** 5819b16 (код — 6b96a45 и d74a7da, дайджест — 0bcdd96; документы — b7ef7b0, подпись — e5c86ac; слияния main — 03792bb, 4c05062, 9fbf853, c540aa4; сдача — f2d00cd; этот отчёт — следующим коммитом, PR #60)

## Shape oracles
- [x] PASS — pre-commit и pre-push на коммитах поставки: `file-length`, jscpd, секреты, данные ребёнка, SwiftLint 0 находок
  (одна строка длиннее 120 знаков исправлена до коммита), `gate-coverage`, фазовый гейт
- [x] PASS — `okf_validate.py` 0/0; `okf_sync_gate.py`: 15 концептов с `implementation:` сверены
- [x] PASS — `delivery_check --diff-base origin/main`: 0 ошибок; предохранитель — 14 файлов, net 325 (+384/−59) из 800
  (план 280, +16%), рисковый путь — 1 (`Packages/AllyLlama/`). Предупреждение «нет реляционного оракула»: детектор знает
  только hypothesis и fast-check; отношение здесь — X1 и X6 (ответ после `commit` или `retract` равен ответу чистого
  prefill той же переписки, без ожидаемого текста)

## Behavior oracles
- [x] PASS — `swift test` AllyCore на Mac: 83 теста из 83, после слияния silero-vad — 86 из 86 (5 новых — X2–X5; U12
  D7.1 заменён на X4, утверждение памяти U8 — в терминах D5). CI, джоба `swift`: AllyCore — 24 файла `Sources/`, 1327 из
  1382 строк, 96%
- [x] PASS — AllyLlama на Mac с весами: X1, X6, X7 зелёные; A23 — токены 37, ответы 37 из 37 при n_ctx 4096 и 37 при 8192
- [x] PASS — мутации ядра (П30), каждая краснит свои примеры, файлы восстановлены: «commit выключен» — X2, X3, X4;
  «оборванное в счёт» — X2; «нет retract» — оба X4; «обёртка теряет commit» — X2, X4; «обёртка теряет remember» — X5;
  «forget в память» — X5; «счёт как spec_stale» — X4. В AllyLlama мутация «commit и retract не удаляют хвост» краснит
  X1 и X6 (T5)
- [x] PASS — устойчивость X4: 12 прогонов подряд и 30 прогонов под нагрузкой (6 параллельно × 5) — зелёные; прежний U12
  на коде main падал 3 раза из 12 (7 из 12 под нагрузкой)
- [x] PASS — сборка приложения для устройства без подписи (бандл ресурсов `AllyLlama` внутри `.app`) и оракул артефакта
  `check_app_artifact.sh` — зелёные на Mac и на слитом с silero-vad дереве (бинарей 6); macOS-джоба `app` 40018186417 —
  те же шаги плюс тесты AllyLlama, AllyOnnx, AllyHearing, AllyVoice, AllyShell — зелёная

## Product oracles
- [x] PASS — `human_ok_spec: yes` (спека серии b7ef7b0 и подпись e5c86ac раньше кода 6b96a45 и d74a7da, L33)
- [x] PASS — X1–X7: факты — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — X8 (телефон: первая фраза следующего хода не позже main более чем на 0,1 с p95, отпечаток) — в общей
  сессии теста по постоянному решению родителя; waiver в STATUS (`by=human:anthony at=2026-10-23`)

## Исполнение рисковых путей
- `Packages/AllyLlama/` — прогнал на Mac macOS-срез того же xcframework llama.cpp b10809 с весами Gemma 4 E4B Q4_K_M:
  X1 — сказано «Ой, жираф.» из 193 знаков, следующий ответ после `commit` равен ответу переписки только с этим ходом;
  X6 — хвосты 8, 64, 236, 600 токенов, 4 из 4 ответов после `retract` равны контролю; X7 — `swa_full: false` даёт отказ
  загрузки и строку консоли из `lines.json`; A23 — 37 из 37. Пустой ход модели (`commit(spoken: "")`) — 2 пробы из 2:
  следующий ответ — обычная реплика по-русски. На телефоне не исполнялось — X8 в сессии теста (waiver). at=2026-10-23

## Изменение поверхности модели
- элемент: `Packages/AllyLlama/` — `LlamaModel.swift` (память хода: `commit(spoken:)` срезает ответ с первого
  сгенерированного токена и дописывает прозвучавшее, `retract()` убирает ход, `remember(heard:spoken:)` дописывает ход
  без модели, стоп оставляет её реплику; страж `swa_full`), `LlamaSettings.swift` (`LlamaError.swaFullOff`, строка
  консоли), `Package.swift` (ресурс `lines.json`); снимок `delivery/model_surface.txt` обновлён — 3 хэша
- почему: модель должна помнить ровно то, что прозвучало (решения родителя 1 и 2); персона, реестр `model.json`, вес и
  сэмплинг — прежние (хэши в снимке не изменились)
- оракулы: X1 и X6 (ответ после переписывания памяти равен ответу чистого prefill — дифференциально против той же
  переписки), A23 (ответы модели равны стенду v2.4 — 37 из 37)
- порча промпта: n/a — промпт персоны не тронут
- провайдер: llama.cpp b10809 (macOS-срез xcframework), Gemma 4 E4B Q4_K_M, веса `~/models`
- цена: A23 — 160 с, X1 и X6 — 12 с на Mac
- at=2026-10-23

## Spec coverage gaps
- X8 — телефон в общей сессии теста (постоянное решение родителя).
- Стоп в первые ≈ 0,2 с хода, пока модель ещё читает её реплику, убирает и реплику: `llama_decode` прерван до начала
  ответа, и ход уходит целиком. Сессию такой стоп всё равно кончает; перебивание D6.2 приходит во время голоса, когда
  реплика давно прочитана.
- Фразы сессии (приветствие, «не расслышала», прощание) в памяти модели — позже (вне D5 по спеке).

## Ревью рисковых мест
- **Транзакция БД:** риска нет, потому что `commit(spoken:)` — не транзакция базы, а перезапись последнего хода в KV
  модели на её последовательной очереди; `AllyMemory` и `AllySQLite` дифф не трогает.
- **Публичный API:** у `LanguageModel` три новых требования без реализаций по умолчанию. Все соответствия обновлены:
  `LlamaModel`, `Speculation` (передаёт все три), двойники тестов. Других реализаций в пакетах и `App/` нет. Новое:
  `LlamaError.line`; `Conversation.session`, `Session.begunAnswerFinished` — внутренние, те же строки, что в
  fix/u12-race 8919b77.
- **Конкурентность:** порядок «отмена → чистка → `commit`» держит последовательная очередь `LlamaModel`. `commit`
  ставится из `defer` раннера после обработчика отмены, `retract` брошенной спекуляции — после её `cancel`. Методы
  только ставят работу в очередь и сессию не блокируют. Обе сессии приложения делят одну модель (L71), но идут по
  очереди, поэтому их вызовы не перемешиваются.
- **Безопасность ребёнка:** срезанное контрактом и оборванное стопом модель «сказавшим» не считает. Заготовка, звучавшая
  вместо отказанной фразы, и скрипт («нож сама не бери») в памяти есть. Реплики с `forget` (её адрес) в памяти нет
  никогда (X5, мутация «forget в память» — красный).
- **Данные:** память модели — KV в оперативной памяти. На диск пишется только префикс персоны (последовательность 0),
  разговора там нет. В следе новых слов нет: `spec_retracted` — число.

## Harness metrics (this shipment)

| Metric | Value |
|---|---|
| files_touched / loc_diff | 14 code (+ process docs, knowledge) / +384/−59 (net +325) из 800 |
| commits | 16 (спека, план, подпись, память модели, пять слияний main, ядро, дайджест, eval-smoke, уроки, сдача, урок L80); отчёт — следующим |
| time_to_accepted_spec | 0h — примеры подписаны в спеке серии |
| rework_after_done | 0 |
| harness_hardened | yes — `ModelMemoryTests.swift` (X2–X5), память D5 у двойников (`ModelMemory`, `RemembersTurns`), U12 без гонки |
| implement_retries | 2 — гонка X4 (ожидание `begunAnswerFinished`), длина строки SwiftLint |
| verify_fails_before_green | 1 — первая попытка `swift` в 40017841603: падение SwiftPM вне диффа, перезапуск зелёный; macOS 40015972860 — фикстура main (L80) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **29**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
X2	XCTAssertEqual(voice.sentences, ["Слоны большие.", "Они едят траву."])
X2	XCTAssertEqual(model.memory.turns, [.init(heard: "Расскажи про слонов", said: "Слоны большие.")])
X2	XCTAssertEqual(rig.said, ["Привет!"])
X2	XCTAssertEqual(rig.model.memory.turns, [.init(heard: "Привет", said: "")])
X3	XCTAssertTrue(model.cancelled && outcome.turn.source != .model)
X3	XCTAssertFalse(voice.sentences.isEmpty)
X3	XCTAssertEqual(model.memory.turns, [.init(heard: "Мне скучно", said: voice.sentences.joined(separator: " "))])
X4	XCTAssertEqual(stages["spec_retracted"], 1)
X4	XCTAssertNil(stages["spec_stale"])
X4	XCTAssertEqual(talk.model.calls.map(\.utterance), ["Ура", "Ура ура"])
X4	XCTAssertEqual(said, ["Ответ про Ура два!", "Как здорово."])
X4	XCTAssertEqual(talk.model.memory.turns, [.init(heard: "Ура ура", said: said?.joined(separator: " "))])
X4	XCTAssertEqual(speculation.takeStages(), ["spec_reused": 0, "spec_cancels": 1, "spec_retracted": 1])
X4	XCTAssertEqual(speculation.takeStages(), ["spec_reused": 0, "spec_cancels": 1])
X4	XCTAssertEqual(model.calls.map(\.cancelled), [false, true])
X4	XCTAssertEqual(model.memory.turns, [])
X5	XCTAssertEqual(records.prefix(3).map(\.0.source), ["session:greeting", "script:knife", "script:pii"])
X5	XCTAssertEqual(records[2].0.route?.forget, true)
X5	XCTAssertEqual(talk.model.calls.count, 0)
X5	XCTAssertEqual(knife?.isEmpty, false)
X5	XCTAssertEqual(talk.model.memory.turns, [.init(heard: lines[0], said: knife)])
U8	XCTAssertEqual(talk.model.memory.turns.map(\.heard), ["Я была в зоопарке"])  // U8: память D5 — ходы с репликой
X7	XCTFail("the model loaded with swa_full off")
X7	XCTAssertEqual(error as? LlamaError, .swaFullOff)
X7	XCTAssertEqual(LlamaError.swaFullOff.line, "swa_full выключен — память модели не держит только сказанное")
X7	XCTAssertNil(LlamaError.context.line)
X1	XCTAssertGreaterThan(full.count, spoken.count)
X1	XCTAssertEqual(afterCommit, clean)
X6	XCTAssertEqual(after, control, "tail of \(repeats) sentences")
```

✅ **Каждое утверждение ведёт к примеру спеки** (U8 X1 X2 X3 X4 X5 X6 X7), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver родителя на телефонный X8)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
