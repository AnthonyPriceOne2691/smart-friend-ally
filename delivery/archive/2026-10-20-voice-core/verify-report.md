# Verify report

**Date:** 2026-10-20
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; A1–A6 и A14–A18 подписаны родителем 2026-10-20; A25–A27 — уточнение A17 ведущим по замеру speech-in, их 12 строк дайджеста — на подпись родителю вместе с примерами до мержа)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39478562081
**Commit:** abfb5c7 (код; документы — 194ca20; эта сдача — следующим коммитом, PR #33 без конфликтов с main `e94423e`)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки и в CI: `file-length` — 35 файлов по маске `*.swift *.py`; jscpd — 23 файла, 0 пар (обе половины: `AllyDiscipline/Sources` и `AllyCore/Sources`, формат swift); SwiftLint — 33 файла, 0 находок; секреты; данные ребёнка — 333 файла; `gate-coverage` — 19 скриптов, все подключены или объявлены
- [x] PASS — доктор контура: локально `AUTO 41 · WEAK 13 · ABSENT 4 · TOOL 3 · SKIP 2 · DEAD 0`, в CI `AUTO 41 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 3 · DEAD 0`; новая канарейка `check_digest_report.py` (подложенный отчёт с числом 999) поймана
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений (40 файлов); `okf_sync_gate.py --base origin/main`: 4 концепта с `implementation:` сверены (`safety-below-model` и новый `turn-detector` изменены вместе с путями ядра)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 15 файлов, net 793 из 800, без исключений. Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а реляционные оракулы здесь — A3 (ход из потока = `finish` без потока на порождённых ответах) и A17 (сдвиг сигнала сдвигает события)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27, Swift 6.4): 14 тестов из 14, восемь прогонов подряд — без сбоев; в CI на Linux (Swift 6.4.1) — джоба `swift`: AllyCore 9 файлов, 254 из 263 строк, 96%; AllyDiscipline 1035 из 1078, 96%; отрицательный контроль порогом 101% покраснел
- [x] PASS — свойство A3 (поток = целое): 41 трудный ответ и 200 порождённых (seed 20261019), подача посимвольно; первый прогон нашёл 3 расхождения (ссылка съедала точку, заглушка сливала знаки) — граница исправлена, контракт не тронут; прогон 5000 порождённых ответов (5 seed) с охраной по времени — 0 расхождений, 0 зависаний
- [x] PASS — мутация A5: «catch глотает отмену» (обёртка `do/catch`, возвращающая заготовку) — тест красный «отмена проглочена: ход вернул итог»; без мутации — зелёный
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; свойства, мутация, гейты и CI — механика

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-20 «Подписываю»; примеры A1–A6, A14–A19 дословно из спеки D1)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (A1–A6, A14–A18, A25–A27 — тесты; A19 — проба шага)
- [x] PASS — A19, шаг «Assertion digest = verify-report» (`check_digest_report.py`), пять исходов: отчёта нет — зелёный «сверять не с чем» (так и в CI на коде); честный отчёт (0 = 0) — зелёный; подложенное число (2 против пересчёта 0) — красный с обоими числами; нет строки — красный; `n/a` при пересчёте 2 или `unknown` — ошибка, подпись `human:` при 2 — без ошибки (функция `verdict`)

## Исполнение рисковых путей

- `runtime_paths: none` — ядро — чистые функции и протоколы над текстом, кадрами чисел и байтами профиля: без экрана,
  прав, железа и ввода-вывода. Исполнение — `swift test --package-path Packages/AllyCore` на Mac (Apple M5, macOS
  27.0.1) и в CI на Linux; телефон — D1.2. at=2026-10-20

## Spec coverage gaps
- **Граница первой фразы строже формулировки A3** («знак конца, за которым пробел»): добавлены «буква следом» и
  проверка головы после ремонта — иначе A3 не держался (`decisions.md`); ожидания примера — те же, цена — один токен.
- **A25–A27** — уточнение A17 ведущим 2026-10-20 по замеру speech-in; подпись родителя — до мержа. Хвост счёта 2,5 с —
  оценка, уточнит запись речи дочери (E2).
- **Следствие для D1.2:** хвост по типу хода. Без режимов хода (D2) приложение выберет один хвост: 0,8 с держит A10
  D1.2 (p95 ≤ 2,5 с), но рвёт паузы; 1,8 с без спекулятивного ответа даёт ≈ 3,2 с до первого звука (speech-in). Решение —
  в D1.2 до кода.
- **Реестр:** разделы `runtime` и `sampling` читает пакет модели (D1.2), ядро — свои поля.

## Ревью рисковых мест

- **Новый модуль** — публичный API: `TurnRunner.run(_:)`, `SentenceStream.first(in:)`, `TurnDetector.process(_:at:)`,
  `TurnLog.jsonLine()`, `ModelCheck.check(registry:in:)`, `ProfileExpiry.daysLeft(_:now:)`, протоколы `LanguageModel`,
  `VoiceOutput`, `TurnClock`; `TurnState` и `Watchdog` — `internal`. Падения нет нигде: битый реестр — `.unreadable`,
  нет профиля — `nil`.
- **Конкурентность** — сторож первой фразы: `Watchdog.move(to:)` под `Locked` — побеждает первый из `.fired` и
  `.disarmed`, поэтому тайм-аут и граница не сработают оба; отмена — `withTaskCancellationHandler` зовёт
  `model.cancel()` и `voice.stop()`, после цикла `Task.checkCancellation()` бросает `CancellationError` (A5 и мутация).
- **Безопасность ребёнка** — мимо контракта не звучит ничего: голова — только результат `TurnContract.first`, остаток —
  `finish` с той же головой; при отказе головы `finish` отдаёт заготовку по ней (A4). Журнал — `TurnLog.wordless`
  пишет `redacted` вместо любого значения с кириллицей (A14).
- **Цепочка гейтов** — `check_swift_coverage.sh` теперь меряет пакет по `$REPO_ROOT/$pkg/Sources/` (зависимость
  локальным путём занижала AllyCore до 66%); `check_digest_report.py` пересчитывает `assert_digest.sh` от `BASE` и
  сверяет с отчётом активной или архивируемой поставки; `LINT_TS_SRC` — вторая половина jscpd.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 21 code (+11 process docs) / +910/-7 (net +903); предохранитель (без механики контура) — 15 файлов, net 793 |
| commits | 2 (документы до кода, код); сдача — третьим |
| time_to_accepted_spec | 0.0h (спека подписана до ветки — в спеке D1) |
| rework_after_done | 0 |
| harness_hardened | yes — шаг «Assertion digest = verify-report» (`check_digest_report.py` с канарейкой), покрытие пакета по своим `Sources/`, вторая половина jscpd |
| implement_retries | 3 — граница первой фразы после трёх расхождений A3; двойники, висевшие на новой границе; ужатие под предохранитель (910 → 793) |
| verify_fails_before_green | 0 — первый прогон CI 39478562081 зелёный во всех трёх джобах |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **54**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
A14	XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
A14	XCTAssertTrue(line.contains(part), part)
A15	XCTAssertEqual(ModelCheck.check(registry: registry, in: folder).message, "модели нет: скопируй с Mac")
A15	XCTAssertEqual(ModelCheck.check(registry: registry, in: folder).message, "модель не та: 5 байт вместо 12")
A15	XCTAssertTrue(broken.hasPrefix("реестр не читается"), broken)
A15	XCTAssertEqual(ModelCheck.check(registry: registry, in: folder), .ready(weights))
A15	XCTAssertNil(ModelCheck.check(registry: registry, in: folder).message)
A15	XCTAssertEqual(try ModelRegistry.decode(registry).turn.tail(.counting), 2.5)
A16	XCTAssertEqual(ProfileExpiry.daysLeft(profile, now: now), 7)
A16	XCTAssertEqual(ProfileExpiry.line(daysLeft: 7), "подпись: осталось 7 дн.")
A16	XCTAssertNil(ProfileExpiry.daysLeft(Data("мусор".utf8), now: now))
A16	XCTAssertNil(ProfileExpiry.daysLeft(nil, now: now))
A16	XCTAssertEqual(ProfileExpiry.line(daysLeft: nil), "срок подписи неизвестен")
A18	XCTAssertEqual(collector.add("как дела", isFinal: false), "привет как дела")
A18	XCTAssertEqual(TranscriptCollector().text, "")
A17	XCTAssertTrue(events(.closed, [(10, -80)]).isEmpty)
A17	XCTAssertEqual([heard.filter { $0.name == "started" }.count, endings(.closed, speech).count], [1, 1])
A17	XCTAssertEqual(endings(.closed, speech).first ?? -1, 1.48, accuracy: 1e-6)
A17	XCTAssertEqual(shifted.map(\.name), heard.map(\.name))
A17	for (before, after) in zip(heard, shifted) { XCTAssertEqual(after.time - before.time, 1.0, accuracy: 1e-6) }
A25	XCTAssertEqual(endings(.closed, pause12).first ?? -1, 1.48, accuracy: 1e-6)
A25	for kind in [TurnKind.open, .counting] { XCTAssertEqual(endings(kind, pause12).count, 1) }
A25	XCTAssertEqual(endings(.open, pause12).first ?? -1, 3.68, accuracy: 1e-6)
A25	XCTAssertEqual(endings(.counting, pause12).first ?? -1, 3.68, accuracy: 1e-6)
A25	XCTAssertEqual(endings(.open, pause20).first ?? -1, 1.48, accuracy: 1e-6)
A25	XCTAssertEqual(endings(.counting, pause20).count, 1)
A25	XCTAssertEqual(endings(.counting, pause20).first ?? -1, 4.48, accuracy: 1e-6)
A26	XCTAssertGreaterThanOrEqual(Double(preRoll) * frameSeconds, 1.5)
A26	XCTAssertEqual(long.prefix(2).map(\.name), ["started", "limit"])
A26	XCTAssertEqual(long.count > 1 ? long[1].at - long[0].at : 0, 20, accuracy: frameSeconds)
A27	XCTAssertEqual(heard.map(\.name), ["started", "tentative", "resumed", "tentative", "ended"])
A27	XCTAssertEqual(heard.count == 5 ? heard[1].at - heard[1].time : 0, 0.3, accuracy: frameSeconds)
A27	XCTAssertEqual(heard.count == 5 ? heard[4].at - heard[4].time : 0, 1.8, accuracy: frameSeconds)
A1	XCTAssertEqual(heard, whole(reply), reply)
A1	XCTAssertFalse(heard.contains { raw.contains($0) }, reply)
A2	XCTAssertEqual(voice.sentences, ["Слоны очень большие.", "Они едят траву."])
A2	XCTAssertEqual(outcome.times.firstSound ?? -1, 0.3, accuracy: 1e-9)
A2	XCTAssertEqual(outcome.times.replyEnd ?? -1, 3.0, accuracy: 1e-9)
A3	XCTAssertGreaterThanOrEqual(hardReplies.count, 40)
A3	XCTAssertEqual(heard, whole(reply), reply)
A3	XCTAssertEqual(elephant, ["Слон весит два и пять тонны.", "Это очень много!"])
A4	XCTAssertTrue(model.cancelled && outcome.turn.source != .model, first)
A4	XCTAssertEqual(voice.sentences, canned)
A5	XCTFail("отмена проглочена: ход вернул итог")
A5	XCTAssertTrue(voice.stopped)
A5	XCTAssertTrue(model.cancelled)
A5	XCTAssertEqual(voice.sentences, ["Привет!"])
A6	XCTAssertTrue(voice.sentences.isEmpty)
A6	XCTAssertTrue(outcome.modelTimeout)
A6	XCTAssertTrue(model.cancelled)
A6	XCTAssertEqual(voice.sentences, ["Ой, повтори, пожалуйста, я не расслышала."])
A6	XCTAssertTrue(TurnLog(outcome: outcome).jsonLine()?.contains("\"model_timeout\":true") ?? false)
A6	XCTAssertEqual(heard, reply.isEmpty ? ["Ой, повтори, пожалуйста, я не расслышала."] : whole(reply))
A6	XCTAssertFalse(heard.joined().contains { $0.isASCII && $0.isLetter }, heard.joined())
```

✅ **Каждое утверждение ведёт к примеру спеки** (A1 A14 A15 A16 A17 A18 A2 A25 A26 A27 A3 A4 A5 A6), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
