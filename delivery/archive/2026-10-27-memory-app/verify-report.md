# Verify report

**Date:** 2026-10-27
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки M33, M34, M35, M38 — дайджест ниже, asserts_without_example: 0; подписаны родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40569769028
**Commit:** 973ee19 (документы — 83055d8 до кода, код — a81e72c, знание — следующий коммит, слияние main — 0f18024; сдача — следующим прогоном PR #81)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 220 файлов, 0 находок (снимок
  0); секреты; данные ребёнка; `gate-coverage` — скрипты подключены
- [x] PASS — доктор контура в CI: `AUTO 42 · WEAK 10 · ABSENT 8 · TOOL 3 · SKIP 6 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: 18 концептов сверены
  (`engineering/memory`, `engineering/voice-loop`, `engineering/safety-below-model`, `ops/child-data`,
  `references/repo-map`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 14 файлов, net
  485 из 800 (план ≈ 500, ожидание +50% ≈ 750); рисковых путей 2 по исключению вопроса 9

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): AllyCore 123 из 123 (`MemoryTapTests` — живым путём `Conversation`),
  AllyMemory 19 из 19, AllySQLite 2 из 2, AllyLlama 4 из 5 с весами E4B (`CompletionTests` M35 — зелёный; паритет
  стенда — видимый пропуск без ответов стенда в `local/` этого дерева, L80). CI на Linux, джоба `swift`: AllyCore 2121
  из 2194 строк (96%), AllySQLite 98 из 118 (83%), AllyMemory 1040 из 1123 (92%); отрицательный контроль порогом 101%
  покраснел
- [x] PASS — мутации в ту же сессию (П30), 5 из 5 убиты, файлы восстановлены: отбор без фильтра `forget` (M33), отбор без
  фильтра `audience` (M33), очередь без стирания (M34), отмена считает попытку (M35), пометка бэкапа не ставится (M38)
- [x] PASS — сборка Ally.app без подписи (`xcodebuild … CODE_SIGNING_ALLOWED=NO`, Xcode 27) и оракул артефакта
  `check_app_artifact.sh` — OK; приложение собрано с пакетом AllyMemory
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes`: M33–M35, M38 подписаны в спеке серии (подпись 37bb5a9); документы поставки — коммитом
  `83055d8` раньше кода `a81e72c` (L33)
- [x] PASS — M33, M34, M35 (без телефона), M38 (без телефона): факт — `eval-smoke.md`; телефонные части M35 и M38 —
  сессия теста по waiver'у в STATUS

## Изменение поверхности модели

- `Packages/AllyLlama/` — новый проход модели `LlamaModel.complete`: последовательность 2 от нуля, шаблон Gemma, цепочка
  «грамматика → температура → dist(seed)», ресурс `json.gbnf` (грамматика JSON llama.cpp); разговор (последовательность
  1), персона и её сэмплирование не тронуты, перенос байтов токена в общий `piece` — без изменения поведения (X1, X6
  зелёные), at=2026-10-27. Исполнено на Mac настоящей E4B: JSON по шаблону, ответ разговору после разбора, отмена.

## Исполнение рисковых путей

- `Packages/AllyLlama/` — исполнено на Mac с весами E4B (`CompletionTests`, M35): разбор в последовательности 2 отдал
  объект JSON, разговор после разбора ответил, отмена посреди длинного ответа остановила модель меньше чем за 2 с
  (abort-callback, `LlamaError.stopped`); X1, X6, X7 зелёные. at=2026-10-27
- `App/Sources/` — исполнено на Mac сборкой приложения без подписи и оракулом артефакта; логика отбора, очереди,
  отмены и каталога — тестами пакетов (M33–M35, M38). На телефоне не исполнено: каталог и защита файлов, разбор после
  10-минутной сессии, тап и фон во время разбора, строка `memory.jsonl`. Проверки на телефоне — в общую сессию теста:
  решение родителя 2026-10-23 «Да, всё в общую сессию (Рекомендую)» и его слово 27.10 (waiver M35, M38 в STATUS;
  `ops/test-session` §3.5). at=2026-10-27

## Spec coverage gaps
- **Телефон** — M35 (p95, экран, тап, фон, убийство) и M38 (класс защиты) — сессия теста.
- **Элли пока не вспоминает** — блок в префиксе, консоль памяти, «помнит на телефоне», поверхность модели —
  `memory-recall` (M36, M39, M37, M40); файл префикса с блоком и его класс защиты — там же (M38 о префиксе).
- **Время и токены разбора** — строкой на прогон очереди (последний ответ модели), не на каждую сессию — по данным.

## Ревью рисковых мест

- **Транзакция БД:** `MemoryStore.enqueue` пишет строку очереди и реплику одной транзакцией; `drain` разбирает вне
  транзакции, а запись фактов — одна транзакция `write` в конце: отмена или убийство посреди разбора не оставляют
  частичных записей (M35). Соединение `SQLiteConnection` держит рекурсивный замок: `transaction` держит его на всё тело,
  поэтому запись очереди из сессии и разбор не перекрываются (L127).
- **Цепочка гейтов:** `scripts/lint/check_app_artifact.sh` — оракул артефакта, назван в STATUS; `merge_guard.sh` —
  путь мержа; гейты и их скрипты не тронуты.
- **Интеграция:** риска нет, потому что сети нет: `requests.count` — запросы двойника модели в `MemoryQueueTests`
  (`ModelDouble.requests`); модель — E4B на телефоне, продукт офлайн.
- **Деньги:** риска нет, потому что трат в диффе нет: «цена» — цена решений в `decisions.md`.
- **Данные ребёнка:** очередь хранит её реплики на телефоне до разбора (вопрос 5): база в `Application Support/Memory`
  вне бэкапа и с полной защитой, расшифровка стирается после разбора или второго сбоя с обрезкой WAL (M34 проверяет
  байты); в тестах — вымышленные реплики (Соня, Мурка).

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 14 code (+ process docs) / +493/−8 (net +485) |
| commits | 5 до сдачи (документы, код, знание, слияние main, уроки плана); сдача — шестым |
| time_to_accepted_spec | 0.0h — M33–M35, M38 подписаны в спеке серии |
| rework_after_done | 0 |
| harness_hardened | yes — новые оракулы `MemoryTapTests`, `MemoryQueueTests`, `CompletionTests`; 5 мутаций |
| implement_retries | 2 — `await` в автозамыкании утверждения и длина строк, исправлены до коммита; конфликт `VoiceLoop.swift` со слиянием main (D6.1) решён сложением |
| verify_fails_before_green | 0 — прогон CI 40569769028 зелёный во всех трёх джобах (delivery, swift, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **33**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
M33	XCTAssertEqual(taken.map(\.her), [Picks.cat])
M33	XCTAssertEqual(taken.map(\.elly), [Picks.reply])
M33	XCTAssertEqual(taken.map(\.turn), [2])
M33	XCTAssertEqual(closed, taken.map(\.session))
M33	XCTAssertEqual(console, [])
M33	XCTAssertEqual(consoleClosed, [])
M33	XCTAssertEqual(argued.map(\.her), [Picks.cat])
M35	XCTAssertNotNil(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any], text)
M35	XCTAssertGreaterThan(model.completionStats.prompt, 0)
M35	XCTAssertFalse(reply.isEmpty)
M35	XCTFail("the parse was not stopped")
M35	XCTAssertEqual(error as? LlamaError, .stopped)
M35	XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - cancelled, 2)
M34	XCTAssertEqual(try store.waiting(), 1)
M34	XCTAssertEqual(first.map(\.status), [.parsed])
M34	XCTAssertEqual(try store.facts().map(\.value), ["кошка", "Мурка", "рыжая"])
M34	XCTAssertEqual(try store.waiting(), 1)
M34	XCTAssertEqual(second.map(\.status), [.failed("в ответе нет объекта JSON")])
M34	XCTAssertEqual(try store.waiting(), 0)
M34	XCTAssertEqual(none.count, 0)
M34	XCTAssertEqual([try store.waiting(), model.requests.count], [0, 0])
M34	XCTAssertEqual(try Fixture.occurrences(["красивое", "Рыжая — красота", "у меня кошка"], in: folder), 0)
M35	XCTFail("the parse was not cancelled")
M35	XCTAssertTrue(error is CancellationError, "\(error)")
M35	XCTAssertEqual(try store.db.rows("SELECT attempts FROM queue"), [[.int(0)]])
M35	XCTAssertEqual(try store.facts(history: true), [])
M35	XCTAssertEqual(again.map(\.status), [.parsed])
M35	XCTAssertEqual(try store.waiting(), 0)
M38	XCTAssertEqual(folder, .ready(root.appendingPathComponent("Memory", isDirectory: true)))
M38	XCTAssertNotEqual(MemoryFiles.flags, 0)
M38	XCTAssertNoThrow(try MemoryStore(directory: url, flags: MemoryFiles.flags))
M38	XCTAssertNotEqual(folder, .ready(root.appendingPathComponent("Memory", isDirectory: true)))
M38	XCTAssertEqual(MemoryFiles.flags, 0)
```

✅ **Каждое утверждение ведёт к примеру спеки** (M33 M34 M35 M38), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
