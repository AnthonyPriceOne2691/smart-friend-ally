# Verify report

**Date:** 2026-10-22
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; S1–S12 подписаны родителем 2026-10-22 «Подписываю (Рекомендую)»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39834241073
**Commit:** c8964b6 (код и знание; документы — 4862a9c, подпись — 61fa373, слияние main с cqg@2.74 — 5f1135b; эта сдача — следующим коммитом, PR #37)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length` — 38 файлов по маске `*.swift *.py`, снимок 0; jscpd 4.0.5 —
  29 файлов, 0 пар (обе половины: `AllyDiscipline/Sources` и `AllyCore/Sources`, формат swift); SwiftLint 0.65.0 —
  36 файлов, 0 находок (снимок 0); секреты; данные ребёнка; `gate-coverage` — все скрипты подключены
- [x] PASS — доктор контура после наката cqg@2.74: `AUTO 43 · WEAK 13 · ABSENT 3 · TOOL 3 · SKIP 2 · DEAD 0`,
  «развёрнуто 56 из 57, 1 объявлены неприменимыми»
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений (41 файл); `okf_sync_gate.py --base origin/main`: 6 концептов
  с `implementation:` сверены (`safety-below-model` — `TurnRunner.swift`; новый `engineering/session`; `session-limit`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 11 файлов, net 746
  из 800 (+759/−13), без исключений, порог стопа 780 не задет. Предупреждение «нет реляционного оракула»: детектор
  знает только hypothesis и fast-check, а реляционный оракул здесь — свойство S6 (на ленте ходов при любом лимите 1–60
  минут прощание приходит у первой границы после лимита, ни одного хода `talk` после неё)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27, Swift 6.4): 27 тестов из 27 (13 новых — S1–S12; 14 тестов D1.1 без
  правок). CI на Linux (Swift 6.4-RELEASE), джоба `swift`: AllyCore — 13 файлов `Sources/`, 507 из 528 строк, 96%;
  AllyDiscipline — 1269 из 1319, 96%; отрицательный контроль порогом 101% покраснел. Доктор в CI —
  `AUTO 41 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0`
- [x] PASS — мутации в ту же сессию (П30), 14 из 14 убиты, файлы восстановлены: без реплики в контракте (S9); без
  решения маршрутизатора (S8); широкий `catch` вместо ветки отмены (S10); лимит только в windingDown (S4); заготовка
  прощания повторяется (S4); лимит не проверяется после ответа (S5); тема тоже прощается (S7); список прощаний
  выключен (S3); отдых на третьем промахе (S2); нет верхней границы ключа (S6); лимит позже на 10 с (S6, свойство);
  speaking не отмечается (S1); запись хода дважды (S11); фраза прощания с вопросом (S12)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-22 «Подписываю (Рекомендую)»); подпись — отдельным коммитом
  `61fa373` раньше кода `315666c` (L33)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (S1–S12 — тесты и мутации)
- [x] PASS — тексты сессии проверены до кода эталоном `output_filter.filter_reply` и Swift-контрактом (`discipline-replay`,
  main `bc5447c`) — PASS в своём режиме у всех четырёх; в коде их держит перечень S12

## Исполнение рисковых путей

- `runtime_paths: none` — ядро сессии — актор и чистые функции над протоколами модели, голоса и маршрутизатора: без
  экрана, прав, звука и железа. Исполнение — `swift test --package-path Packages/AllyCore` на Mac (macOS 27) и в CI на
  Linux; телефон — D2.2. at=2026-10-22

## Spec coverage gaps
- **`ReleaseGate` (бывшие S13–S14)** — в R вместе с `release-gate.json`, решение ведущего по правилу переноса (план
  725 > 700). Пороги и состав целей, записанные в первой редакции спеки, едут туда же.
- **Проводка в App и переустановка одной командой (E4)** — D2.2 после мержа D1.2: сессия ещё не звучит на телефоне.
- **Её прощание списком** ловит только реплику целиком (12 форм); иное идёт в модель в `talk`.
- **Находка для серии контракта:** «Я буду по тебе скучать!» и «Буду по тебе скучать.» проходят правило привязанности
  во всех режимах (Swift и эталон, 2026-10-22). Сессия обходит щель: на её прощание модель не зовётся.

## Ревью рисковых мест

- **Публичный API:** `Session` (актор) с `handle(_:)` и `state`; `SessionParts`, `SessionSettings`, `SessionState`,
  `SessionEvent`; `Route`, `TurnRouting`, `PassThroughRouting`; `TurnTrace`, `TraceStamp`, `TraceSink`;
  `TurnRunner.run(_:decision:)` — параметр со значением по умолчанию, вызов `run(_:)` у D1.2 компилируется без правок;
  `TurnLog` — та же строка JSON через общий `journalLine`.
- **Конкурентность:** ход и фраза — одна дочерняя задача, `stop` отменяет её через сохранённое замыкание; ловятся только
  отмена (запись `cancelled`) и названная ошибка (запись `error`); переход thinking → speaking ставит обёртка голоса
  под `Locked`, пока актор ждёт ход, — порядок состояний держит S1.
- **Безопасность ребёнка:** её реплика и решение теперь доходят до контракта на каждом ходе (S9 — эхо адреса снято);
  фразы сессии звучат только как результат `TurnContract(режим).finish`; прощание — фраза кода; после хода с темой
  сессия не прощается (S7).
- **Данные:** в следе нет слов — значения от приложения с кириллицей пишутся `redacted` (S11); в тестах — только
  вымышленные «Соня», «Тёма», «Мурка», адрес «улица Морковная».

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 11 code (+13 process docs) / +759/-13 (net +746); предохранитель — 11 файлов, net 746 из 800 |
| commits | 6 до сдачи (спека, подпись, слияние main, стек, код, знание); сдача — седьмым |
| time_to_accepted_spec | 0.3h |
| rework_after_done | 0 |
| harness_hardened | yes — `SessionTests.swift`, `TraceTests.swift` (новые оракулы S1–S12), свойство S6 и 14 мутаций |
| implement_retries | 2 — вывод типа замыкания в `say` (ошибка компиляции, затем находка SwiftLint `redundant_void_return`); три находки SwiftLint исправлены до коммита |
| verify_fails_before_green | 0 — первый прогон CI 39834241073 зелёный во всех трёх джобах (swift, delivery, gates); PR #37 `MERGEABLE`, `CLEAN` (L35) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **108**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
S1	XCTAssertTrue(rig.voice.sentences.isEmpty && rig.sink.records.isEmpty)
S1	XCTAssertEqual(rig.model.calls, 0)
S1	XCTAssertEqual(rig.sink.records.count, 1)
S1	XCTAssertEqual(rig.voice.sentences, greeting + ["Ух ты, в зоопарке!", "А кого ты там видела?"])
S1	XCTAssertEqual(rig.model.calls, 1)
S1	XCTAssertEqual(rig.states.log, [.greeting, .listening, .thinking, .speaking, .listening])
S1	XCTAssertEqual(rig.states.log.map(\.listens), [false, true, false, false, true])
S2	XCTAssertEqual(rig.said, [misheard])
S2	XCTAssertEqual(rig.session.state, .listening)
S2	XCTAssertEqual(rig.said, [misheard] + rest)
S2	XCTAssertEqual(rig.session.state, .asleep)
S2	XCTAssertEqual(rig.sink.records.last?.end, "rest")
S2	XCTAssertEqual(rig.model.calls, 0)
S2	XCTAssertEqual(reset.said, [misheard, "Жирафы очень высокие.", misheard])
S2	XCTAssertEqual(reset.session.state, .listening)
S3	XCTAssertEqual(rig.said, goodbye, word)
S3	XCTAssertEqual(rig.model.calls, 0, word)
S3	XCTAssertEqual(rig.session.state, .asleep, word)
S3	XCTAssertEqual(rig.sink.records.last?.end, "goodbye_word", word)
S3	XCTAssertEqual(rig.model.calls, 1)
S3	XCTAssertEqual(rig.session.state, .listening)
S4	XCTAssertEqual(rig.clock.now(), 596, accuracy: 1e-9)
S4	XCTAssertEqual(rig.said, ["Какой красивый кот!", "А какого он цвета?"])
S4	XCTAssertEqual(rig.session.state, .listening)
S4	XCTAssertEqual(rig.said, ["Какой красивый кот!", "А какого он цвета?", "Рыжий кот — это здорово!"] + goodbye)
S4	XCTAssertEqual(records.map(\.mode), ["talk", "goodbye", "goodbye"])
S4	XCTAssertEqual(records[1].rules, ["limits"])
S4	XCTAssertEqual(records.map(\.source), ["model", "model", "session:goodbye"])
S4	XCTAssertEqual(records.map(\.end), [nil, nil, "limit"])
S4	XCTAssertEqual(rig.session.state, .asleep)
S4	XCTAssertFalse(rig.session.state.listens)
S4	XCTAssertEqual(rig.model.calls, 2)
S4	XCTAssertEqual(said.said, ["Мне с тобой весело!", "А теперь беги поиграй с мамой или папой."])
S4	XCTAssertEqual(said.sink.records.last?.source, "canned:attachment")
S4	XCTAssertEqual(said.sink.records.last?.end, "limit")
S4	XCTAssertEqual(said.session.state, .asleep)
S5	XCTAssertEqual(rig.clock.now(), 603, accuracy: 1e-9)
S5	XCTAssertEqual(rig.session.state, .windingDown)
S5	XCTAssertTrue(rig.session.state.listens)
S5	XCTAssertEqual(rig.said, ["Пять!", "Правильно."] + goodbye)
S5	XCTAssertEqual(rig.model.calls, 1)
S5	XCTAssertEqual(rig.sink.records.last?.end, "limit")
S5	XCTAssertEqual(rig.session.state, .asleep)
S6	XCTAssertEqual(SessionSettings(limitMinutes: "2").limit, 120)
S6	XCTAssertNil(SessionSettings(limitMinutes: "2").note)
S6	XCTAssertEqual(SessionSettings(limitMinutes: raw).limit, 600, raw)
S6	XCTAssertEqual(SessionSettings(limitMinutes: raw).note, "лимит вне 1–60 мин — взято 10", raw)
S6	XCTAssertEqual(SessionSettings().limit, 600)
S6	XCTAssertNil(SessionSettings().note)
S6	XCTAssertEqual(rig.clock.now(), 121, accuracy: 1e-9)
S6	XCTAssertEqual(rig.session.state, .windingDown)
S6	XCTAssertTrue(turns.dropLast().allSatisfy { $0.mode == "talk" && $0.elapsed < limit }, "\(minutes)")
S6	XCTAssertEqual(turns.last?.mode, "goodbye", "\(minutes)")
S6	XCTAssertEqual(turns.last?.elapsed ?? 0, limit + 7, accuracy: 1e-9, "\(minutes)")
S6	XCTAssertEqual(rig.sink.records.last?.source, "session:goodbye", "\(minutes)")
S7	XCTAssertEqual(rig.said, ["Спички и зажигалку сама не бери: можно обжечься или устроить пожар.",
S7	XCTAssertEqual(rig.model.calls, 0)
S7	XCTAssertEqual(record?.route?.kind, "script")
S7	XCTAssertEqual(record?.route?.key, "matches")
S7	XCTAssertEqual(record?.source, "script:matches")
S7	XCTAssertEqual(Array(rig.said.suffix(2)), lost)
S7	XCTAssertEqual(rig.session.state, .windingDown)
S7	XCTAssertEqual(Array(rig.said.suffix(5)), ["Ура, как хорошо!", "Мама рядом."] + goodbye)
S7	XCTAssertEqual(rig.model.calls, 1)
S7	XCTAssertEqual(rig.session.state, .asleep)
S8	XCTAssertEqual(fear.said, ["Не бойся!", "Я с тобой.", "Если страшно, скажи маме или папе."])
S8	XCTAssertEqual(fear.sink.records.last?.rules.contains("adult_pointer"), true)
S8	XCTAssertEqual(pass.said, ["Не бойся!", "Я с тобой.", "Хочешь, споём песенку?"])
S9	XCTAssertEqual(rig.said, ["Адрес и телефон говорят только маме, папе и знакомым взрослым."])
S9	XCTAssertEqual(rig.sink.records.last?.rules.contains("pii_echo"), true)
S9	XCTAssertEqual(TurnContract(mode: .talk).finish(reply).sentences.joined(separator: " "), reply)
S10	XCTAssertTrue(rig.voice.stopped && rig.model.cancelled)
S10	XCTAssertEqual(rig.said, ["Привет!"])
S10	XCTAssertEqual(rig.session.state, .asleep)
S10	XCTAssertEqual(rig.sink.records.map(\.cancelled), [false, true])
S10	XCTAssertEqual(rig.sink.records.last?.end, "parent")
S10	XCTAssertEqual(idle.sink.records.last?.source, "session:stop")
S10	XCTAssertEqual(idle.sink.records.last?.end, "parent")
S10	XCTAssertEqual(idle.session.state, .asleep)
S10	XCTAssertEqual(failing.said, [])
S10	XCTAssertEqual(failing.sink.records.last?.error, "ReplyFailure")
S10	XCTAssertEqual(failing.sink.records.last?.end, "error")
S10	XCTAssertEqual(failing.session.state, .asleep)
S12	XCTAssertEqual(Set(phrases.keys), ["greeting", "misheard", "rest", "goodbye"])
S12	XCTAssertEqual(turn.source, .canned("generic"), key)
S12	XCTAssertEqual(turn.sentences.joined(separator: " "), phrase.text, key)
S12	XCTAssertEqual(turn.record.rules, [], key)
S12	XCTAssertEqual(turn.source, .model, key)
S12	XCTAssertEqual(SessionData.shared.turn("greeting").turn.sentences, greeting)
S12	XCTAssertEqual(SessionData.shared.turn("misheard").turn.sentences, [misheard])
S12	XCTAssertEqual(SessionData.shared.turn("goodbye").mode, .goodbye)
S12	XCTAssertEqual(SessionData.shared.turn("rest").mode, .goodbye)
S11	XCTAssertEqual(records.map(\.turn), Array(1...7))
S11	XCTAssertEqual(Set(records.map(\.session)).count, 1)
S11	XCTAssertEqual(records.map(\.source), ["session:greeting", "model", "script:matches", "session:misheard",
S11	XCTAssertEqual(records.map(\.mode), ["talk", "talk", "talk", "talk", "talk", "goodbye", "goodbye"])
S11	XCTAssertEqual(records.map(\.end), [nil, nil, nil, nil, nil, nil, "limit"])
S11	XCTAssertEqual(lines.count, 7)
S11	XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
S11	XCTAssertTrue(line.contains(part), part + " in " + line)
S11	XCTAssertEqual([script.kind, script.topic, script.key, script.dataHash], ["script", "matches", "matches",
S11	XCTAssertEqual(script.rules, ["matches.ask"])
S11	XCTAssertFalse(script.forget)
S11	XCTAssertEqual(records[1].route?.kind, "pass")
S11	XCTAssertNotNil(records[1].contractHash)
S11	XCTAssertNotNil(records[1].stages["first_sound"])
S11	XCTAssertEqual(records[5].elapsed, 605, accuracy: 1e-9)
S11	XCTAssertNil(records[0].route)
```

✅ **Каждое утверждение ведёт к примеру спеки** (S1 S10 S11 S12 S2 S3 S4 S5 S6 S7 S8 S9), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
