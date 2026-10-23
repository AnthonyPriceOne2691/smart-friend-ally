# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; U7–U13 подписаны родителем 2026-10-23 в спеке серии «слух»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40008490584
**Commit:** b3361c7 (код — 40e23f3; документы — c20ff3d, eval-smoke — 3ce6d07; слияния main — 4b9bb5e и следующее; эта сдача — следующим коммитом, PR #54)

## Shape oracles
- [x] PASS — pre-commit и pre-push на коммитах поставки: `file-length`, jscpd, секреты, данные ребёнка, SwiftLint 0 находок
  (политика буфера у новых потоков, размер кортежа — исправлены до коммита), `gate-coverage`, фазовый гейт
- [x] PASS — `okf_validate.py` 0/0; `okf_sync_gate.py`: 12 концептов с `implementation:` сверены
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 8 файлов, net 504 из
  800 (план 437, +15%), рисковый путь — 1 (`App/Sources/Speech/`). Предупреждение «нет реляционного оракула»: детектор
  знает только hypothesis и fast-check, реляционный оракул здесь — свойство U13 на 200 лентах

## Behavior oracles
- [x] PASS — `swift test` AllyCore на Mac: 79 тестов из 79 (7 новых — U7–U13); прежние примеры без правок утверждений.
  CI, джоба `swift`: AllyCore — 23 файла `Sources/`, 1269 из 1315 строк, 96%
- [x] PASS — мутации (П30): «спекуляция без плана реплики» (U9 — модель 3 раза), «отмена не обрывает поток» (U8 — ответ не
  отменён), «стейл не считается» (U12) — красные; «ход на „возможно, конец“» (U13) — тест не прошёл: завис и был
  остановлен — двойник держит ответ до хвоста, ход раньше хвоста ждёт его вечно (урок L72); файлы восстановлены
- [x] PASS — сборка приложения для устройства без подписи и оракул артефакта `check_app_artifact.sh` — зелёные

## Product oracles
- [x] PASS — `human_ok_spec: yes` (подпись серии 3b68733 раньше кода 40e23f3; документы D7.1 — c20ff3d, eval-smoke —
  3ce6d07 до кода, L33)
- [x] PASS — U7–U13: факты — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — U14, U15 (телефон: задержка и текст диктовки на «возможно, конец») — по ответу 8 родителя в сессии
  теста после D7.1 вместе с U6 D7; waiver в STATUS (`by=human:anthony at=2026-10-23`)

## Исполнение рисковых путей
- `App/Sources/Speech/` — исполнен на Mac тот же API той же конфигурацией: `local/spike/finalize-probe/probe` (DictationTranscriber
  ru-RU, `.shortForm`, пунктуация, промежуточные результаты, частая финализация; буферы по 100 мс в реальном времени) —
  `finalize(through: nil)` за 0,019–0,024 с, итог готов на возврате, ввод открыт (фраза после него распознана), итог на
  конце без продолжения равен итогу на finalize. На телефоне `Phrase.tentative()` не исполнялся — U14–U15 в сессии
  теста (waiver). at=2026-10-23

## Spec coverage gaps
- U14, U15 — телефон в сессии теста (ответ 8 родителя).
- Несказанный ответ, дописанный до броска, остаётся в памяти модели — до D5 `kv-spoken` (ответ 5 родителя; счётчик
  `spec_stale`).

## Ревью рисковых мест
- **Публичный API:** `EarEvent`; `Listener.listen(_:events:)`; `SessionEvent.tentative`, `.resumed`;
  `TurnEnding(pauses:)` — параметр со значением по умолчанию; `Speculation` — внутренний тип ядра.
- **Конкурентность:** события слуха идут в сессию одним потребителем по порядку и допиваются до услышанного; у
  `Speculation` состояние под замком, поздние снимки отменённого ответа отсекает номер ответа.
- **Безопасность ребёнка:** к модели спекулятивно идёт только реплика, которую пустил бы ход (U9): скрипт, прощание и
  `forget` — нет.
- **Данные:** в следе нет слов; этапы `spec_*` — числа.

## Harness metrics (this shipment)

| Metric | Value |
|---|---|
| files_touched / loc_diff | 8 code (+ process docs) / +527/−23 (net +504) из 800 |
| commits | 7 до сдачи (документы, eval-smoke, код, слияния main, факты verify); сдача — следующим |
| time_to_accepted_spec | 0h — примеры подписаны в спеке серии |
| rework_after_done | 0 |
| harness_hardened | yes — `SpeculationTests.swift` (U7–U13, свойство на 200 лентах), двойники `SpecModel`, `WordSink`, паузы слуха |
| implement_retries | 1 — SwiftLint (политика буфера, кортеж) |
| verify_fails_before_green | 0 — прогон CI 40008490584 зелёный во всех трёх джобах |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **37**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
U7	XCTAssertEqual(talk.model.calls.map(\.at), [10.3])
U7	XCTAssertEqual(talk.replies.first?.0, "Какая красивая Мурка!")
U7	XCTAssertEqual(talk.replies.first?.1 ?? -1, 11.8, accuracy: 1e-9)
U7	XCTAssertEqual(talk.phases { $0.first { $0.0 == .thinking }?.1 } ?? -1, 11.8, accuracy: 1e-9)
U7	XCTAssertEqual(talk.modelTurns.count, 1)
U7	XCTAssertEqual(talk.modelTurns.first?.stages["spec_reused"], 1)
U7	XCTAssertEqual(talk.modelTurns.first?.stages["spec_lead"] ?? -1, 1.5, accuracy: 1e-9)
U7	XCTAssertEqual(talk.modelTurns.first?.stages["spec_cancels"], 0)
U8	XCTAssertEqual(talk.model.calls.map(\.utterance), ["Я была", "Я была в зоопарке"])
U8	XCTAssertEqual(talk.model.calls.first?.cancelled, true)
U8	XCTAssertEqual(talk.model.memory, ["Я была в зоопарке"])
U8	XCTAssertEqual(talk.replies.first?.0, "Ответ про зоопарк!")
U8	XCTAssertEqual(talk.replies.first?.1 ?? -1, 13.8, accuracy: 1e-9)
U8	XCTAssertEqual(talk.modelTurns.count, 1)
U8	XCTAssertEqual(talk.modelTurns.first?.stages["spec_cancels"], 1)
U8	XCTAssertEqual(talk.modelTurns.first?.stages["spec_reused"], 1)
U9	XCTAssertEqual(talk.model.calls.count, 0)
U9	XCTAssertEqual(talk.sink.records.map(\.source),
U9	XCTAssertEqual(talk.sink.records[1].route?.forget, true)
U10	XCTAssertEqual(talk.model.calls.map(\.utterance), ["Я видела жирафа", "Я видела жирафов"])
U10	XCTAssertEqual(talk.model.calls.first?.cancelled, true)
U10	XCTAssertEqual(talk.replies.first?.0, "Жирафы высокие!")
U10	XCTAssertEqual(talk.replies.first?.1 ?? -1, 12.8, accuracy: 1e-9)
U10	XCTAssertEqual(talk.modelTurns.first?.stages["spec_reused"], 0)
U10	XCTAssertEqual(talk.modelTurns.first?.stages["spec_cancels"], 1)
U10	XCTAssertEqual(Speculation.letters("я видела жирафа"), Speculation.letters("Я видела жирафа."))
U11	XCTAssertEqual(talk.model.calls.first?.cancelled, true)
U11	XCTAssertEqual(talk.voice.sentences, greeting)
U11	XCTAssertEqual(talk.conversation.state.phase, .asleep)
U11	XCTAssertEqual(talk.sink.records.map(\.source), ["session:greeting", "session:stop"])
U11	XCTAssertEqual(talk.sink.records.last?.end, "parent")
U12	XCTAssertEqual(talk.modelTurns.first?.stages["spec_stale"], 1)
U12	XCTAssertEqual(talk.model.memory, ["Ура", "Ура ура"])
U13	XCTAssertEqual(talk.ear.overlaps, 0, "\(seed)")
U13	XCTAssertEqual(talk.modelTurns.count, tape.count, "\(seed)")
U13	XCTAssertTrue(words.modelText?.hasPrefix(about) == true, "\(seed) \(record.turn)")
U13	XCTAssertEqual(talk.model.most, 1, "\(seed)")
```

✅ **Каждое утверждение ведёт к примеру спеки** (U7 U8 U9 U10 U11 U12 U13), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver родителя на телефонные U14–U15)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
