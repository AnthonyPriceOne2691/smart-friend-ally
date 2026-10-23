# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки M26–M28 — дайджест ниже, asserts_without_example: 0; M26–M28 подписаны родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40019214593
**Commit:** b22b75e (документы — b3e5465 до кода, код и знание — cc1bf63, слияние main — b22b75e; сдача — следующим прогоном PR #64)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 157 файлов, 0 находок
  (снимок 0); секреты; данные ребёнка; `gate-coverage` — скрипты подключены
- [x] PASS — доктор контура в CI: `AUTO 46 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений (51 файл); `okf_sync_gate.py --base origin/main`: концепты с
  `implementation:` сверены (`engineering/memory` — четыре исходника и три ресурса разбора)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 9 файлов, net 503
  из 800 (план ≈ 520, ожидание по L95 ×1,3 — 680). Предупреждение «нет реляционного оракула»: детектор знает только
  hypothesis и fast-check; свойств сверх примеров не пишем — слово родителя 2026-10-23 «сейчас собираем, оптимизировать
  будем потом»

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): `AllyMemory` 13 тестов из 13 (`ExtractTests` 3 из 3). CI на Linux, джоба
  `swift`: `AllyMemory` — 728 из 804 строк, 90%;
  `AllySQLite` — 91 из 108, 84% (не тронут); отрицательный контроль порогом 101% покраснел
- [x] PASS — мутации в ту же сессию (П30), 4 из 4 убиты, файлы восстановлены: повтора нет (M27, 7 провалов); опора только
  по номеру модели — «лепить» отброшено (M28); согласие не проверяется — «зоопарк», Мила и хомяк записаны (M28); хэш
  без текста запроса (M26)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания M26–M28 —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes`: M26–M28 подписаны в спеке серии (подпись 37bb5a9); документы поставки — коммитом
  `b3e5465` раньше кода `cc1bf63` (L33)
- [x] PASS — M26–M28: факт — `eval-smoke.md`; числа примеров (семь кандидатов с опорой, шесть отброшенных «без опоры»,
  уверенность 0,9 / 0,8 / 0,6, две попытки и «ответ не по шаблону») совпали с первого прогона

## Spec coverage gaps
- **У разбора нет вызывающего** (L50): модель зовут только тесты — двойником; E4B подключат `memory-quality` (Mac,
  M32) и `memory-app` (телефон, M33–M35, журнал сессии и «не разобрана» у родителя).
- **Вымысел, чужие питомцы, отрицание и маркеры любимого** держит пока только промпт разбора — advisory в реестре
  `safety-below-model` до `memory-sense` (M30, M31).
- **Возраст вне 1–20 отбрасывается до записи** без своего примера: иначе CHECK базы уронил бы сессию; случай держит прогон
  E4B в M32.

## Изменение поверхности модели

- `Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md` — новый системный текст разбора (правила справки
  B2 без событий и планов, номер реплики у каждого значения), at=2026-10-23; до модели на телефоне ещё не доходит.
- `Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md` — новый шаблон запроса: шаблон ответа «N: …»,
  пример Милы с ответом, «что уже известно», разговор по номерам ходов, at=2026-10-23.
- `Packages/AllyMemory/Sources/Memory/Resources/extract.json` — параметры сэмплирования разбора (0,2, seed 42,
  грамматика JSON), текст повтора, причины мусора, «да»-слова и служебные слова опоры, at=2026-10-23.
- Персона, `model.json` и `AllyLlama` не тронуты. Дифференциального прогона нет: модель разбора ещё не зовётся; первый
  прогон E4B — M32 по порогам, записанным до прогона (L19, L25).

## Ревью рисковых мест

- **Безопасность:** риска нет, потому что секретов в коде нет: «секреты и пароли» — пункт 9 промпта разбора
  (`extract.system.ru.md`) о том, чего не записывать; `secret` — в строке плана о гейте секретов (L38). `MemoryModel`
  получает только запрос разбора; отброшенное (`Extraction.Drop`) несёт поле и причину без значений.
- **Интеграция:** риска нет, потому что сети нет: `requests.first`, `requests.last`, `requests.count` — запросы двойника
  модели в `ExtractTests` (`ModelDouble.requests`); продукт офлайн, модель — за протоколом.
- **Транзакция:** `MemoryStore.remember` пишет разобранное одним `write` (одна транзакция memory-core); мусор дважды —
  возврат до записи; ошибка базы или модели не глотается — уходит вызывающему.
- **Деньги:** риска нет, потому что трат в диффе нет: «цена» — цена решения о форме ответа в `decisions.md`.
- **Цепочка гейтов:** `merge_guard.sh` упоминается в STATUS как путь мержа; гейты и их скрипты не тронуты.
- **Данные ребёнка:** в тестах — вымышленные реплики и имена (Соня, Тёма, Мурка; из примера — Мила, Хрум); база — во
  временном каталоге (`makeFolder`).

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 9 code (+ process docs) / +506/−3 (net +503) |
| commits | 3 до сдачи (документы, код и знание, слияние main); сдача — четвёртым |
| time_to_accepted_spec | 0.0h — M26–M28 подписаны в спеке серии до начала поставки |
| rework_after_done | 0 |
| harness_hardened | yes — новый оракул `ExtractTests` с двойником модели; 4 мутации |
| implement_retries | 2 — сборка (`await` внутри автозамыкания `XCTAssertEqual`) и SwiftLint (длина строк, кортеж из трёх, `String(decoding:)`) исправлены до коммита; утверждения повтора переписаны без индекса, чтобы мутация роняла тест, а не процесс |
| verify_fails_before_green | 0 — прогон CI 40019214593 зелёный во всех трёх джобах (delivery, swift, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **23**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
M26	XCTAssertEqual(request.map(\.role), [.system, .user])
M26	XCTAssertEqual(request[0].text, try Talk.resource("extract.system.ru.md"))
M26	XCTAssertEqual(request[1].text, try Talk.resource("extract.user.ru.md")
M26	XCTAssertTrue(request[1].text.contains("1. Девочка: привет я мила"))
M26	XCTAssertEqual(parse.requestHash, ExtractPrompt.fnv1a(request[0].text + "\n" + request[1].text))
M26	XCTAssertEqual(parse.params, ExtractParams(temperature: 0.2, seed: 42, grammar: "json"))
M26	XCTAssertEqual(model.params, [parse.params])
M26	XCTAssertEqual(again.requestHash, parse.requestHash)
M26	XCTAssertNotEqual(other.requestHash, parse.requestHash)
M27	XCTAssertEqual([first.status], [.parsed])
M27	XCTAssertEqual([first.attempts, first.written?.added], [1, 1])
M27	XCTAssertEqual([second.attempts, second.written?.added], [2, 1])
M27	XCTAssertEqual(retry.map(\.role), [.system, .user, .assistant, .user])
M27	XCTAssertEqual(again.first, "Сейчас подумаю…")
M27	XCTAssertTrue(again.last?.contains("Ответь ещё раз") == true, again.joined())
M27	XCTAssertTrue(again.last?.contains("в ответе нет объекта JSON") == true, again.joined())
M27	XCTAssertEqual(failed.status, .failed("ответ не по шаблону"))
M27	XCTAssertEqual([failed.attempts, failing.requests.count], [2, 2])
M27	XCTAssertEqual(try store.facts(history: true), [])
M28	XCTAssertEqual(parse.candidates, [
M28	XCTAssertEqual(parse.dropped.map(\.field),
M28	XCTAssertEqual(Set(parse.dropped.map(\.reason)), [.ungrounded])
M28	XCTAssertEqual(try store.facts().map(\.confidence), [0.9, 0.9, 0.8, 0.6, 0.9, 0.9, 0.9])
```

✅ **Каждое утверждение ведёт к примеру спеки** (M26 M27 M28), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
