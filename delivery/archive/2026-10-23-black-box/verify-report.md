# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; B1–B12 подписаны родителем 2026-10-22 «Подписываю (Рекомендую)»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39985460735
**Commit:** dc503b5 (код, гейт и знание — 2b93937, 69c8d72, 8593e9c; документы — d45a6cb, подпись — e2e3038, eval-smoke — b9efe37; слияния main — 62347c4 (D1.2) и ad29fdd (D2.2); сдача — следующим коммитом, PR #40)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length` по маске `*.swift *.py`; jscpd — 0 новых пар (свой
  генератор SplitMix снят в пользу `SeededGenerator` D2.2); SwiftLint 0.65.0 — 55 файлов, 0 находок (снимок 0);
  секреты (хэши звука — `fnv1a:` и 16 знаков, L38); данные ребёнка; `gate-coverage` — все скрипты подключены
- [x] PASS — доктор контура после правки гейта: `AUTO 45 · WEAK 13 · ABSENT 4 · TOOL 3 · SKIP 3 · DEAD 0`, «развёрнуто
  56 из 57, 1 объявлены неприменимыми»; канарейка `check_child_data.py` (WAV) на месте
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений; `okf_sync_gate.py --base origin/main`: концепты с
  `implementation:` сверены — новый список у `ops/black-box` (4 файла ядра), `ops/child-data` (`.gitignore` и гейт),
  `engineering/session` (`Session`, `TurnTrace`, `Conversation`), `safety-below-model` (`TurnRunner`, `Session`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 12 файлов,
  net 765 из 800 (+785/−20), рисковых путей 0, порог стопа 780 не задет. Предупреждение «нет реляционного оракула»:
  детектор знает только hypothesis и fast-check, а реляционные оракулы здесь — свойства на Swift (ниже)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27, Swift 6.4): AllyCore 48 тестов из 48 — 13 новых (B1–B10, B12, свойство
  «записей ящика столько же, сколько строк следа» на 20 сессиях со случайными событиями, пример через драйвер
  `Conversation`); тесты D1.1, D2 и D2.2 зелёные без правок ожиданий. CI на Linux (Swift 6.4-RELEASE), джоба `swift`:
  AllyCore — 19 файлов `Sources/`, 853 из 882 строк, 96%; AllyDiscipline — 1277 из 1324, 96%; порог 70%, отрицательный
  контроль порогом 101% покраснел. Доктор в CI — `AUTO 45 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0`
- [x] PASS — реляционные оракулы: WAV туда и обратно на отсчётах генератора с зерном 42 (длины 1, 2, 159, 16 000,
  32 001) — бит в бит; на 20 сессиях со случайной лентой событий (зерно 7) номера записей ящика равны номерам строк
  следа
- [x] PASS — мутации в ту же сессию (П30, названы по механизму — L59), 10 из 10 убиты, файлы восстановлены: сессия не
  передаёт слова (B10); запись хода раньше звука (B1); без отката файлов хода при отказе (B8); без предела (B7); без
  проверки `isPrivate` (B8); разветвитель теряет слова (B1, B10); сессия консоли пишется в ящик (B6); стирание во время
  сессии (B9); драйвер `Conversation` теряет `audience` (B10); `EndWatch` теряет слова (B10)
- [x] PASS — смоук 6 из 6 (`delivery/evals/smoke/run.sh`), S6 — гейт данных ребёнка на записи ящика: 5 красных
  случаев и 0 ложных; отрицательный контроль — тот же смоук со старым гейтом main `ca2befe` красный на трёх случаях
  ящика (переименованная запись в дереве и в индексе, `.allybox`)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` и `human_ok_plan: yes` (родитель 2026-10-22 «Подписываю (Рекомендую)», вопросы 1–8 по
  рекомендациям); подпись — отдельным коммитом `e2e3038` раньше кода `2b93937` (L33)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (B1–B10, B12 — тесты и мутации, B11 — смоук S6)
- [x] PASS — значения B2 и B3 сверены до кода настоящими контрактом и маршрутизатором (`discipline-replay`, main
  `e83a707`, 2026-10-22): «Моя хорошая, …» → `endearment`; «Солнышко, я буду ждать…» → `canned:attachment`;
  «Дай мне спички» → `script`, правило `matches.ask`
- [x] PASS — форматы и объём выбраны по замеру 2026-10-22 (спека, раздел «Форматы и объём»): формат распознавателя —
  проба `SpeechAnalyzer` на macOS 27.0.1 (16 кГц, моно, Int16); кодеки на 88 клипах суррогата детского голоса;
  высота тона голоса Элли — parselmouth 0.4.7

## Исполнение рисковых путей

- `runtime_paths: none` — ядро чёрного ящика: запись хода, предел, стирание и строка консоли над портами диска и ленты,
  без экрана, прав, звука, железа и файлов платформы. Исполнение — `swift test --package-path Packages/AllyCore` на Mac
  (macOS 27) и в CI на Linux; хранилище на телефоне, выгрузка и стирание — D3.2, голос с выхода — D3.3. at=2026-10-23

## Spec coverage gaps
- **B13–B22** — ожидания D3.2 и D3.3 под ту же подпись; переедут таблицей в их спеки.
- **Причина `write_failed`** в спеке названа, но не появляется никогда: по B8 любой отказ откатывает весь ход, и записи,
  которая несла бы причину, нет. Спека уточнится в D3.2.
- **Строки консоли** заданы ядром (`status`), на экран их выводит D3.2.
- **Формат распознавателя на телефоне** не проверен (L23): на Mac 16 кГц Int16; консоль D3.2 печатает его на старте,
  другой — стоп до кода.

## Ревью рисковых мест

- **Публичный API:** `BlackBox` (`heard(_:)`, `write(_:words:)`, `eraseAll()`, `status`), `BlackBoxDisk`, `VoiceTape`,
  `Utterance`, `RecordedVoice`, `TurnWords`, `TraceFanOut`, `Audience`; `SessionParts.audience` — параметр со значением
  по умолчанию; `TraceSink.write(_:words:)` — требование с реализацией по умолчанию: `TraceFile`, `RecordingSink`,
  сток приложения компилируются без правок.
- **Стык с D2.2 (класс L50):** `Conversation` пересобирал `SessionParts` без `audience`, а `EndWatch` не передавал слова —
  за драйвером приложения ящик не получил бы ни признака, ни слов при зелёных B1–B10 через `Session`. Починено, держит
  пример через драйвер и две мутации. Строка «Стыки» в архивной спеке D2.2 поправлена: ящик — второй приёмник рядом с
  `TraceFile`.
- **Конкурентность:** состояние ящика под `Locked` — пишет актор сессии, приложение даёт реплику, читает строку и стирает;
  стирание отказывает, пока у последней записи нет `end`.
- **Безопасность (`secret`):** слово из комментария `FNV1a` в `Wav.swift` — хэш звука несёт префикс `fnv1a:`, чтобы
  гейт секретов не принял голый hex за секрет (L38). Секретов, ключей и сети в диффе нет; данные ребёнка держат класс
  файлов iOS на телефоне (D3.2) и гейт данных ребёнка (B11).
- **Транзакция БД (`atomic`):** базы нет. `.atomic` — из комментария порта `BlackBoxDisk`: на телефоне файл пишется
  целиком (D3.2). Целость хода держит порядок «звуки, затем запись хода» и откат записанных файлов хода при отказе —
  B1, B8 и мутации «запись хода раньше звука», «без отката».
- **Данные ребёнка:** слова и звук только в записи ящика; след без слов — проверка «в следе нет кириллицы» в B1 и B10;
  записей ящика в git нет даже как фикстур — гейт их не пропустит (B11); в тестах — вымышленные «Соня», «Мурка», адрес
  «улица Морковная» и синтетические отсчёты.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 12 code (+19 process docs) / +785/−20 (net +765); предохранитель — 12 файлов, net 765 из 800 |
| commits | 11 до сдачи (спека, подпись, eval-smoke, ядро, слияние D1.2, гейт и знание, точка остановки, слияние D2.2, T9 и др.); сдача — следующим |
| time_to_accepted_spec | 0.2h |
| rework_after_done | 0 |
| harness_hardened | yes — `BlackBoxTests.swift` (оракулы B1–B10, B12, два свойства), смоук S6 `child_data_blackbox.sh` с отрицательным контролем, правило гейта на запись ящика, 10 мутаций |
| implement_retries | 3 — 14 находок SwiftLint на первом прогоне (длина строки, `optional_data_string_conversion`) исправлены до коммита; предупреждение компилятора о `Sendable` у `Date.init`; на слиянии D2.2 — дефект стыка `Conversation` (починен с примером) |
| verify_fails_before_green | 0 — первый прогон CI 39985460735 на `dc503b5` зелёный во всех трёх джобах (swift, delivery, gates); PR #40 `MERGEABLE`, `CLEAN` (L35) |
| est_token_or_cost | n/a |


## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **83**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
B12	XCTAssertEqual(lines.first, "ALLY-BLACKBOX/1")
B1	XCTAssertEqual(rig.disk.paths, names.map { folder + $0 })
B1	XCTAssertEqual(Array(rig.disk.order.suffix(3)), names.suffix(3).map { folder + $0 })
B1	XCTAssertEqual(turn.heard, "Я сегодня была в зоопарке")
B1	XCTAssertEqual(turn.modelText, "Ух ты, в зоопарке! А кого ты там видела?")
B1	XCTAssertEqual(turn.said, ["Ух ты, в зоопарке!", "А кого ты там видела?"])
B1	XCTAssertEqual([turn.rules, [turn.source, turn.route?.kind ?? "", turn.audience]], [[], ["model", "pass",
B1	XCTAssertEqual([turn.childAudio.bytes, turn.childAudio.rate, turn.ellyAudio.bytes],
B1	XCTAssertEqual([turn.childAudio.seconds, turn.ellyAudio.seconds], [1.5, 3.1])
B1	XCTAssertEqual(turn.childAudio.fnv1a, FNV1a.tag(wav))
B1	XCTAssertEqual([time.pauseBeforeSpeech, time.herSpeech, time.tail, time.recognize, time.speechEndToSound,
B1	XCTAssertEqual(turn.versions["voice_rate"], "0.42")
B1	XCTAssertEqual(turn.sessionStarted, "2026-10-25T18:03:12Z")
B1	XCTAssertEqual([kept[0].heard, kept[0].childAudio.missing], [nil, "no_utterance"])
B1	XCTAssertEqual(kept[0].said, greeting)
B1	XCTAssertEqual(kept[0].ellyAudio.seconds, 3.0)
B1	XCTAssertEqual(rig.wordlessTrace, 2)
B2	XCTAssertEqual(turn.modelText, line[0])
B2	XCTAssertEqual(turn.source, line[1])
B2	XCTAssertEqual(turn.rules, line[2].split(separator: " ").map(String.init))
B2	XCTAssertEqual(turn.said, Array(line[3...]))
B3	XCTAssertEqual(rig.queue?.calls, 0)
B3	XCTAssertNil(turn.modelText)
B3	XCTAssertEqual(turn.said, matches)
B3	XCTAssertEqual([turn.route?.kind, turn.route?.key, turn.route?.topic], ["script", "matches", "matches"])
B3	XCTAssertEqual([turn.childAudio.file, turn.ellyAudio.file], ["0002-child.wav", "0002-elly.m4a"])
B4	XCTAssertEqual(kept.map(\.source), ["session:greeting", "session:misheard", "session:rest"])
B4	XCTAssertEqual([kept[1].heard, kept[2].heard], ["", nil])
B4	XCTAssertEqual([kept[1].said, kept[2].said], [[misheard], rest])
B4	XCTAssertEqual(kept[1].childAudio.seconds, 1.2)
B4	XCTAssertEqual([kept[2].childAudio.missing, kept[2].end], ["silence", "rest"])
B5	XCTAssertTrue(cut.cancelled && cut.said == nil && cut.modelText == nil)
B5	XCTAssertEqual(cut.end, "parent")
B5	XCTAssertEqual([cut.ellyAudio.seconds, cut.timing.interruptedAt, cut.childAudio.seconds], [0.7, 20, 0.8])
B6	XCTAssertTrue(rig.disk.paths.isEmpty)
B6	XCTAssertEqual(rig.trace.records.map(\.audience), Array(repeating: "parent", count: 4))
B6	XCTAssertEqual(rig.box.status, "запись выключена")
B6	XCTAssertEqual(try next.kept().map { "\($0.turn) \($0.audience)" }, (1...3).map { "\($0) supervised" })
B7	XCTAssertEqual(try near.kept().last?.childAudio.file, "0002-child.wav")
B7	XCTAssertEqual(near.box.status, "● запись: 820 из 1024 МБ — выгрузи на Mac")
B7	XCTAssertEqual([turn.childAudio.missing, turn.ellyAudio.missing, turn.heard], ["full", "full", "Раз"])
B7	XCTAssertEqual(full.box.status, "● ящик полон: выгрузи и сотри")
B7	XCTAssertEqual(try full.box.eraseAll(), .erased(sessions: 2, bytes: held))
B7	XCTAssertEqual(try again.kept().last?.childAudio.file, "0002-child.wav")
B8	XCTAssertEqual(Array(rig.voice.sentences.dropFirst(greeting.count)), ["Ага."])
B8	XCTAssertFalse(rig.disk.paths.contains { $0.contains("/0002") })
B8	XCTAssertTrue(rig.box.status.hasSuffix(" · не записано ходов: 1"), rig.box.status)
B8	XCTAssertEqual(rig.disk.paths.filter { $0.contains("/0003") }.count, 3)
B8	XCTAssertTrue(open.disk.paths.isEmpty)
B8	XCTAssertEqual(open.box.status, "не пишу: каталог в бэкапе")
B9	XCTAssertEqual(try rig.box.eraseAll(), .erased(sessions: 3, bytes: 41 * mib))
B9	XCTAssertTrue(rig.disk.paths.isEmpty)
B9	XCTAssertEqual(rig.box.status, "стёрто: 3 сес., 41 МБ")
B9	XCTAssertEqual(try busy.box.eraseAll(), .busy)
B9	XCTAssertEqual(busy.disk.paths.count, 4)
B10	XCTAssertEqual(kept.map(\.turn), Array(1...7))
B10	XCTAssertEqual(Set(kept.map(\.session)).count, 1)
B10	XCTAssertEqual(kept.map { $0.heard != nil }, [false, true, true, false, true, true, false])
B10	XCTAssertEqual(kept.map { $0.modelText != nil }, [false, true, false, false, true, true, false])
B10	XCTAssertEqual(kept.map { $0.childAudio.file != nil }, [false, true, true, false, true, true, false])
B10	XCTAssertEqual(kept[3].childAudio.missing, "silence")
B10	XCTAssertEqual(kept.map(\.end), [nil, nil, nil, nil, nil, nil, "limit"])
B10	XCTAssertEqual(rig.wordlessTrace, 7)
B10	XCTAssertEqual(trace.records.map(\.audience), audiences)
B10	XCTAssertEqual(kept.map(\.source), ["session:greeting", "model", "session:misheard", "session:rest"])
B10	XCTAssertEqual([kept[1].heard, kept[1].modelText], ["Я сегодня была в зоопарке", "Ух ты, в зоопарке!"])
B10	XCTAssertEqual(Set(kept.map(\.audience)), ["supervised"])
B10	XCTAssertEqual(try rig.kept().map(\.turn), rig.trace.records.map(\.turn))
B12	XCTAssertEqual(wav.count, 48_044)
B12	XCTAssertEqual(String(bytes: wav[0..<4] + wav[8..<16], encoding: .ascii), "RIFFWAVEfmt ")
B12	XCTAssertEqual([wav.le32(4), wav.le32(16), wav.le32(24), wav.le32(28), wav.le32(40)],
B12	XCTAssertEqual([wav.le16(20), wav.le16(22), wav.le16(32), wav.le16(34)], [1, 1, 2, 16])
B12	XCTAssertEqual(String(bytes: wav[36..<40], encoding: .ascii), "data")
B12	XCTAssertEqual(readBack(wav), samples)
B12	XCTAssertEqual(FNV1a.tag(Data()), "fnv1a:cbf29ce484222325")
B12	XCTAssertEqual(FNV1a.tag(Data("a".utf8)), "fnv1a:af63dc4c8601ec8c")
B12	XCTAssertEqual(try rig.kept().last?.childAudio.missing, "no_audio")
B12	XCTAssertFalse(rig.disk.paths.contains { $0.hasSuffix(".wav") })
B12	XCTAssertTrue(text.hasPrefix("ALLY-BLACKBOX/1\n{") && text.hasSuffix("}\n"))
B12	XCTAssertTrue(text.contains("\"heard\":\"Привет\"") && !text.contains("\\u"))
B12	XCTAssertEqual(places, places.sorted())
B12	XCTAssertEqual(places.count, keys.count)
B12	XCTAssertEqual(readBack(Wav.file(samples, rate: 16_000)), samples, "\(length)")
```

✅ **Каждое утверждение ведёт к примеру спеки** (B1 B10 B12 B2 B3 B4 B5 B6 B7 B8 B9), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
