# Verify report

**Date:** 2026-10-30
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки T1–T14 — дайджест ниже; примеры подписаны родителем 2026-10-30 до кода ядра)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/41110535528 (PR #96, коммит cc64f0b: `delivery`, `gates`, `swift` — зелёные с первого прогона, ветка без конфликтов с main 2a8a39f)
**Commit:** спека и STATUS — ffa26d6, план и журналы — 3142310, подпись родителя — 8b99056 (все до кода); контракт — 89694d7; ядро AllyCore — 093f1b1; сжатие и незакрытая скобка — abe2d23

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd, секреты, данные ребёнка, `gate-coverage`. SwiftLint —
  0 находок (снимок 0). Первые заходы дали находки, все починены до коммита: длина строк, поток без политики буфера в
  `tell`, `for`-`where`.
- [x] PASS — `delivery_check --diff-base origin/main`: 0 ошибок, предохранитель — 21 файл кода, net +798 из 800 (сырой план ≈ 718, первый подсчёт 904: поправка +25% подтвердилась, сжато тестами таблицами, перенос `fresh`, `catch_up_tokens` и строки консоли в `story-model`). Предупреждение «нет
  реляционного оракула» знает только hypothesis и fast-check. Реляционные оракулы здесь: «по одному = целое» (T6) и
  дифференциальный по режимам (T14).
- [x] PASS — `okf_validate.py` и `okf_sync_gate.py --base origin/main`: 0 ошибок (54 файла), 20 концептов, 0 предупреждений.

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): Discipline — 63 теста, 1 пропущен (паритет с локальным корпусом вне git); AllyCore — 180 из 180. Новые: `StoryContractTests` (9), `StoryTests` (17). Покрытие в CI на Linux: Discipline — 1368 из 1415 строк, 96%; AllyCore — 2737 из 2834, 96% (порог 70%).
- [x] PASS — мутации в ту же сессию, файл восстанавливался после каждой:
  - Discipline: D1–D12, 12 из 12 убиты;
  - AllyCore: 31 из 31 убит; C11, C12, C28, C31 краснели зависанием — в тесте остановки модели теперь предел настоящего времени (L72).
- [x] PASS — дифференциал T14: `discipline-replay` main (сборка из `git archive origin/main`) и ветки на открытом корпусе
  стендов: 1667 ответов пяти моделей × 3 режима, 5001 строка — байт в байт (sha256 `eaf723605cbe7db5…`).
- [x] PASS — реляционный T6 на том же корпусе: 1667 из 1667 после правила незакрытой скобки. До правила — 2 расхождения:
  обрывок реплики в скобках звучал бы, хотя ремонт снимает закрытую реплику целиком. На 110 фикстурах таких ответов нет.
  Прогон — временной подменой фикстуры, в git она не попадала.
- [x] PASS — приложение без подписи: `xcodegen` + `xcodebuild` — BUILD SUCCEEDED; оракул артефакта OK, бинарей 6. Приложение
  не менялось, сборка — проверка, что новый публичный API ядра его не ломает.
- [x] PASS — `make_fixtures.check_contract()`: `contract.json` совпадает с эталоном на его режимах; `story` — только здесь.
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель. Ожидания — примеры, подписанные родителем до кода.

## Product oracles
- [x] PASS — T1: вторая сказка сессии — мостик 2, шесть предложений дракона по одному, запись без слов, память
  разговора — реплика, мостик, сказка; через `Conversation` модель сказки доходит (L58).
- [x] PASS — T2: мостик «придумаем», один вопрос.
- [x] PASS — T3: пересказ, вопрос, загадка — `talk`, вход байт в байт; перенос правила совпал с `intent.py` на 100 кейсах
  из 100. Это паритет, а не точность: числа dev (L49).
- [x] PASS — T4: скрипт, страж, `pass` с правилом темы, последний ход — без сказки.
- [x] PASS — T5: пределы в трёх точках, вопросы, деление по запятой, нарушение.
- [x] PASS — T6: фраза 2 звучит до конца ответа; неуместившееся останавливает модель; голос = отбор из целого.
- [x] PASS — T7: возврат в разговор, мостики по кругу, новая сессия — с первого, окно M42 читает сказку.
- [x] PASS — T8: что сессия отдаёт модели сказки.
- [x] PASS — T10: мостик до первого слова модели, этапы, таймер 10 с.
- [x] PASS — T11: мостик вне контракта или сломанный шаблон — режим выключен; пробы `story` при загрузке.
- [x] PASS — T14: без модели сказки ход как сегодня; режимы — выше.
- T9, T12, T13, Mac-часть T8 и T14 — следующая поставка `story-model`.

## Spec coverage gaps
- E4B в этой поставке не запускался: примеры T1, T2 идут на двойнике с текстами стенда. Настоящие сказки через настоящий
  путь — R1 `story-model`.
- В приложении модели сказки нет: `SessionParts.story` пуст, режим не работает, всё звучит как сегодня (T14).
- Строка консоли «сказки: …», `fresh`, `catch_up_tokens` — со своим исполнителем в `story-model`; в спеке сказано.
- Правило намерения судили только его кейсы и паритет. Свежий набор чужой рукой — до сказки без присмотра (L49).

## Ревью рисковых мест
- **Безопасность.** Каждая фраза сказки проходит ремонт и правила содержания до голоса. Ход сказки — только на чистом
  `pass`, тема опасности идёт разговором. Мостики проверяются контрактом при загрузке; ослабленные пределы `story` ловит
  самопроверка контракта (T11).
- **Отказ закрытый.** Данные намерения или мостик не прошли проверку — режим выключен, ходы как сегодня.
- **Память и след.** Память разговора — прозвучавшее: мостик и сказка (`StoryTurn.commit` → `remember`). Обмены — без
  `forget` и фраз сессии. В следе номер мостика и намерение, слов нет: кодировка мостика — без `text`, мутант C35 убит.
- **Отмена.** Вторая рука — дочерняя задача группы: стоп родителя, её речь и пауза отменяют её вместе с ходом. Модель
  стартует до мостика, ответ ждёт в потоке.
- **Параллельные поставки.** `VoiceLoop.swift` не тронут. `Session.swift`, `TurnRunner.swift`, `TurnTrace.swift` —
  точечные правки, путь разговора прежний.
- **Транзакция БД.** Риска нет. Слово `commit` в диффе — `LanguageModel.commit(spoken:)` адаптера: память модели (D5).

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 21 code (+13 process docs) / +879/-81 (net +798) |
| commits | 10 |
| time_to_accepted_spec | 0.2h |
| rework_after_done | 0 (handoff not declared yet) |
| harness_hardened | yes — Packages/AllyCore/Tests/AllyCoreTests/StoryTests.swift (новый оракул), Packages/AllyDiscipline/Tests/DisciplineTests/StoryContractTests.swift (новый оракул) |
| implement_retries | 2 — находки SwiftLint на первых коммитах; сжатие под предохранитель (904 → 798) |
| verify_fails_before_green | 0 — первый прогон CI на PR #96 зелёный |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **111**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
T1	XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", "Жил-был ёжик.", "Он нашёл яблоко.",
T1	XCTAssertEqual(record.mode, "story")
T1	XCTAssertEqual(record.jsonLine()?.contains("\"story\":{\"bridge\":2,\"intent\":\"story\"}"), true)
T1	XCTAssertEqual(rig.model.calls, 0)
T1	XCTAssertEqual(teller.asked.map(\.utterance).last, asks)
T1	XCTAssertEqual(rig.model.memory.turns.last,
T1	XCTAssertEqual(rig.states.log.suffix(3), [.thinking, .speaking, .listening])
T2	XCTAssertEqual(rig.said, ["Ух, давай! Сейчас придумаю.", idea])
T2	XCTAssertEqual(record.story?.kind, .invent)
T2	XCTAssertEqual(record.story?.number, 1)
T2	XCTAssertEqual(record.rules, ["emoji", "last_question"])
T1	XCTAssertEqual(rig.model.calls, 0)
T1	XCTAssertEqual(rig.sink.records.last?.mode, "story")
T1	XCTAssertNil(rig.sink.records.last?.knowledge)
T1	XCTAssertEqual(rig.model.calls, 0)
T7	XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", "Жил-был ёжик.", "Ёжик уснул."])
T3	XCTAssertEqual(rig.model.inputs, lines)
T3	XCTAssertTrue(teller.asked.isEmpty)
T3	XCTAssertEqual(rig.sink.records.suffix(3).map(\.mode), ["talk", "talk", "talk"])
T3	XCTAssertEqual(rig.sink.records.last?.jsonLine()?.contains("\"story\""), false)
T3	for text in texts { XCTAssertEqual(StoryIntent.shared.kind(of: text)?.rawValue ?? "none", want, text) }
T3	XCTAssertEqual(StoryIntent.normalized("  Ещё объём,\n5 a-b — можешь? "), "еще обем 5 a b можеш")
T4	XCTAssertEqual(record.route?.kind, kind, line)
T4	XCTAssertEqual(record.mode, "talk", line)
T4	XCTAssertNil(record.story, line)
T4	XCTAssertEqual(rig.model.calls, 2)
T4	XCTAssertTrue(teller.asked.isEmpty)
T4	XCTAssertTrue(teller.asked.isEmpty)
T4	XCTAssertEqual(rig.sink.records[1].mode, "goodbye")
T4	XCTAssertEqual(rig.said, ["Сказку расскажу завтра."] + goodbye)
T4	XCTAssertEqual(rig.session.state, .asleep)
T6	XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", "Жил-был ёжик.", "Он нашёл яблоко."])
T6	XCTAssertEqual(rig.model.memory.turns.last?.said, rig.said.joined(separator: " "))
T6	XCTAssertTrue(teller.cancelled)
T6	XCTAssertEqual(rig.said.count, 9)
T6	XCTAssertTrue(teller.cancelled)
T6	XCTAssertEqual(rig.sink.records.last?.rules, ["digits", "limits"])
T6	XCTAssertEqual(voice.sentences, ["Слушай."] + TurnContract(mode: .story).finish(reply).sentences, reply)
T6	XCTAssertEqual(outcome.said, voice.sentences, reply)
T6	XCTAssertEqual(model.memory.turns.last?.said, voice.sentences.joined(separator: " "), reply)
T7	XCTAssertEqual(rig.model.inputs, ["Дракон полетел к маме!"])
T7	XCTAssertEqual(turns.map(\.heard), [asks, "Дракон полетел к маме!"])
T7	XCTAssertEqual(turns[0].said, (["Ой, сейчас расскажу! Слушай."] + told).joined(separator: " "))
T7	XCTAssertEqual(rig.sink.records.last?.mode, "talk")
T7	XCTAssertNil(rig.sink.records.last?.story)
T7	XCTAssertEqual(teller.asked.map(\.bridge), ["Ой, сейчас расскажу! Слушай.", "Ура, сказка! Слушай.",
T7	XCTAssertEqual(rig.sink.records.suffix(3).compactMap(\.story?.number), [2, 3, 1])
T7	XCTAssertEqual(teller.asked.last?.bridge, "Ой, сейчас расскажу! Слушай.")
T7	XCTAssertEqual(teller.asked.last?.recent, [])
T8	XCTAssertEqual(teller.asked, [StoryRequest(recent: [Exchange(heard: lines[1], said: "Здорово!"),
T10	XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай."])
T10	XCTAssertEqual(rig.states.log.last, .speaking)
T10	XCTAssertEqual(stages["first_sound"], 0)
T10	XCTAssertGreaterThanOrEqual(stages["bridge_end"] ?? 0, 2)  // the voice's tick races the double's sleep
T10	XCTAssertGreaterThanOrEqual(stages["story_first_sound"] ?? 0, 5)
T10	XCTAssertEqual(rig.said, ["Ой, сейчас расскажу! Слушай.", misheard])
T10	XCTAssertEqual(rig.sink.records.last?.modelTimeout, true)
T11	XCTAssertTrue(StoryIntent.shared.healthy)
T11	XCTAssertFalse(StoryIntent(bridge).healthy)
T11	XCTAssertFalse(StoryIntent(rule).healthy)
T11	XCTAssertTrue(teller.asked.isEmpty)
T11	XCTAssertEqual(rig.model.inputs, [asks])
T11	XCTAssertEqual(rig.sink.records.last?.mode, "talk")
T14	XCTAssertEqual(none.model.inputs, [asks])
T1	XCTAssertEqual(teller.asked.map(\.utterance), [asks])
T1	XCTAssertEqual(TurnMode.allCases.map { told(text, mode: $0) },
T5	XCTAssertEqual(say(hedgehog.prefix(7).joined(separator: " "), .story).sentences, Array(hedgehog.prefix(7)))
T5	XCTAssertEqual(say(hedgehog.prefix(8).joined(separator: " "), .story).sentences, Array(hedgehog.prefix(8)))
T5	XCTAssertEqual(ten.sentences, Array(hedgehog.prefix(8)))
T5	XCTAssertEqual(ten.record.rules, ["limits"])
T5	XCTAssertEqual(say(five.joined(separator: " "), .story).sentences.count, 5)
T5	XCTAssertEqual(over.sentences.count, 5)
T5	XCTAssertEqual(over.record.rules, ["limits"])
T5	XCTAssertEqual(say("Жил-был ёжик. " + twenty, .story).sentences, ["Жил-был ёжик.", twenty])
T5	XCTAssertEqual(say("Жил-был ёжик. " + twenty.dropLast() + " ёжик.", .story).sentences, ["Жил-был ёжик."])
T5	XCTAssertEqual(say(split, .story).sentences, halves)
T5	XCTAssertEqual(spoken(turn), "Жил-был ёжик. Что же он нашёл в лесу? Большое яблоко! Конечно, маме!")
T5	XCTAssertEqual(turn.record.rules, ["last_question"])
T5	XCTAssertEqual(say(stories[0], .story).sentences.last, "Как тебе такой конец?")
T5	XCTAssertEqual(spoken(after), "Жил-был ёжик. Что он нашёл? Яблоко! Он пошёл к маме.")
T5	XCTAssertEqual(cut.sentences, ["Жил-был ёжик.", "Он жил в лесу."])
T5	XCTAssertTrue(cut.record.rules.contains("attachment"))
T5	XCTAssertEqual(first.source, .canned("attachment"))
T5	XCTAssertEqual(spoken(first), contractData.canned["attachment"])
T5	XCTAssertEqual(skipped.sentences, ["Жил-был ёжик.", "Что он нашёл?", "Большое яблоко.",
T5	XCTAssertEqual(skipped.record.rules, ["last_question", "action_referral"])
T5	XCTAssertEqual(full.sentences, Array(hedgehog.prefix(8)))
T6	XCTAssertEqual(contract.first("Жил-был ёжик."), "Жил-был ёжик.")
T6	XCTAssertEqual(contract.more("Жил-был ёжик. Он жил в лесу. "), ["Он жил в лесу."])
T6	XCTAssertEqual(contract.more("Жил-был ёжик. Он жил в норке. Конец. "), [])
T6	XCTAssertTrue(contract.stopped)
T6	XCTAssertEqual(contract.finish("Жил-был ёжик. Он жил в норке. Конец.").sentences,
T6	XCTAssertEqual(contract.finish(reply).sentences, whole.sentences, reply)
T6	XCTAssertTrue(final.sentences.starts(with: said), "\(said) — \(final.sentences)")
T6	XCTAssertEqual(final.sentences, whole.sentences, "«\(reply)» said \(said)")
T6	XCTAssertEqual(final.source, whole.source, reply)
T6	XCTAssertGreaterThan(streamed, 20)
T6	XCTAssertEqual(contract.first("Жил-был ёжик."), "Жил-был ёжик.")
T6	XCTAssertEqual(contract.more("Жил-был ёжик. Он жил в лесу. "), [])
T6	XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. "), [])
T6	XCTAssertEqual(story.first("Жил-был ёжик."), "Жил-был ёжик.")
T6	XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. "), ["Он жил в лесу."])
T6	XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. Ёжик сказал: я буду ждать тебя. "), [])
T6	XCTAssertTrue(story.stopped)
T6	XCTAssertEqual(story.more("Жил-был ёжик. Он жил в лесу. Ёжик сказал: я буду ждать тебя. Он уснул. "), [])
T6	XCTAssertEqual(long.first(hedgehog[0]), hedgehog[0])
T6	XCTAssertEqual(told, Array(hedgehog[1..<8]))
T6	XCTAssertTrue(long.stopped)
T11	XCTAssertEqual(Set(probes.map(\.rule)), ["limits", "last_question", "attachment"])
T11	XCTAssertTrue(Contract.shared.healthy)
T11	XCTAssertFalse(Contract(broken, hash: "broken").healthy)
```

✅ **Каждое утверждение ведёт к примеру спеки** (T1 T10 T11 T14 T2 T3 T4 T5 T6 T7 T8), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict

Verify сделан, CI на PR #96 зелёный с первого прогона. Ядро режима сказки готово и в продукте не работает, пока приложение
не передаст модель сказки: это `story-model`, там же настоящие сказки E4B и R1–R4.

- [x] READY FOR HANDOFF
