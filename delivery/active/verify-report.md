# Verify report

**Date:** 2026-10-28
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки M36, M39 — дайджест ниже, asserts_without_example: 0; подписаны родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии)
**CI run:** первый прогон PR — ссылка дописывается следующим коммитом
**Commit:** коммит отчёта (документы — 5654e56 до кода, код — 8dfcf49, заморозка стенда M40 до прогона — 4dbe06c; сдача — следующим прогоном PR)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 0 находок (снимок 0; класс
  `VoiceLoop` и `LlamaModel` — новые функции в расширениях того же файла, тело класса ≤ 300); секреты; данные ребёнка;
  `gate-coverage` — скрипты подключены
- [x] PASS — `okf_validate.py` и `okf_sync_gate.py --base origin/main`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: 18 концептов сверены
  (`engineering/memory`, `engineering/voice-loop`, `engineering/safety-below-model`, `ops/child-data`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 10 файлов кода,
  net 338 из 800 (план ≈ 275, ожидание +50% ≈ 410); рисковых путей 2 по исключению вопроса 9. Предупреждение «нет
  реляционного оракула»: детектор знает только hypothesis и fast-check; дифференциальный оракул поставки — M40 («персона»
  против «персона + блок» на тех же наборах и seed), инвариант — пустая память даёт тот же префикс и тот же файл (M36)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): AllyMemory 21 из 21 (M36 — системный ход, M39 — строки консоли и
  стирание), AllyLlama `PrefixTests` 3 из 3 с весами E4B (M36: пересборка с блоком, чтение из файла новой загрузкой
  0,007–0,013 с, переполненная пересборка оставляет прежний префикс, пересборка после сессии почти во весь контекст
  находит место); весь AllyLlama 8 из 8 (паритет стенда A23 — 37 из 37 токенов и ответов при n_ctx 4096 и 37 при
  8192 с ответами стенда, скопированными в `local/` дерева: старый файл префикса читается в последовательность 3).
  CI на Linux, джоба `swift`: покрытие пакетов ≥ 70% — в прогоне CI
- [x] PASS — мутации в ту же сессию (П30), 10 из 10 убиты, файлы восстановлены: сборка префикса прямо в
  последовательности 0 (убил `testFailedRebuildKeepsThePrefixTheModelHad`), разговор не очищается перед пересборкой
  (`testRebuildAfterALongConversationFindsRoom`), поднятый флаг не отпускается (`testBlockPrefix…`), старый файл
  префикса не удаляется (`testBlockPrefix…`), блок через пробел (M36), строка стирания без эпохи, подтверждение без
  числа, отметка неудачи не снимается и не ставится, формы «факта/фактов» без 12–14 (M39)
- [x] PASS — сборка Ally.app без подписи (`xcodebuild … CODE_SIGNING_ALLOWED=NO`, Xcode 27) и оракул артефакта
  `check_app_artifact.sh` — OK
- [ ] FAIL — M40 на стенде персоны (Mac, вне git; правило — spec.md до прогона, заморозка `4dbe06c`): «персона» повторила
  сохранённый v2.4 байт в байт (221 из 221); «персона + блок»: быт 30 из 45 при 33 ✗, «почему» без подсказки 31 при 26
  ✓, с подсказкой 37 при 43 ✗, детали D1 5 из 7 ✗ (оба промаха — блок спорит со свежими словами), имя в D1 74% при 16%
  ✗, вываливаний 0 из 221 ✓, живость у слепых судей 56% за блок ✓ — `eval-smoke.md`, `escalation.md`
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода; живость M40 судили два слепых агента без ключа

## Product oracles
- [x] PASS — `human_ok_spec: yes`: M36, M37, M39, M40 подписаны в спеке серии (подпись 37bb5a9); документы поставки —
  коммитом `5654e56` раньше кода `8dfcf49`, правило суда M40 — там же, заморозка стенда — `4dbe06c` до прогона (L19, L33)
- [x] PASS — M36, M39 (без телефона): факт — `eval-smoke.md`; M37 целиком, чтение префикса на телефоне и экран консоли —
  сессия теста по waiver'у в STATUS
- [ ] FAIL — M40: правило не выдержано, остановка оформлена (`blockers` в STATUS, `escalation.md`: три варианта с ценой,
  рекомендован «слить с выключенным блоком»)

## Изменение поверхности модели

- `Packages/AllyMemory/Sources/Memory/MemoryBlock.swift`, `Resources/memory.json` — блок памяти входит в системный ход
  разговора: `MemoryBlock.system` — персона, пустая строка, блок (шапка и слова блока — подписанные memory-core);
  пустая память — персона байт в байт и тот же файл префикса (M36); в `memory.json` — только слова консоли, которые
  модели не идут. Дифференциальный прогон M40 «персона» против «персона + блок» правило не выдержал (быт −3 из 45, «почему» с
  подсказкой −6 из 48, детали D1 5 из 7, имя в D1 74%; вываливаний 0, живость 56%) — включение блока в разговор ждёт
  решения родителя (`escalation.md`). at=2026-10-28
- `Packages/AllyLlama/` — префикс читается и собирается в последовательности 3 и копируется в 0 целым, загрузка
  считает блок токенизатором модели, пересборка очищает разговор: тексты и токены префикса те же, что у прежней сборки
  (пустая память — тот же ключ файла, `PrefixTests`); сэмплирование и шаблон не тронуты. at=2026-10-27

## Исполнение рисковых путей

- `Packages/AllyLlama/` — исполнено на Mac с весами E4B (`PrefixTests`, M36): пересборка с блоком и обратно к персоне,
  чтение файла новой загрузкой, переполненная пересборка (`decode(1)`) — последовательность 0 прежняя, пересборка после
  сессии почти во весь контекст — место нашлось; мутации a–d убиты. at=2026-10-27
- `App/Sources/` — исполнено на Mac сборкой приложения без подписи и оракулом артефакта; блок, строки консоли и
  стирание — тестами пакетов (M36, M39). На телефоне не исполнено: чтение префикса ≤ 0,1 с, экран консоли памяти,
  «помнит на телефоне» и «не знает» после стирания, класс защиты файла префикса. Проверки на телефоне — в общую сессию
  теста: решение родителя 2026-10-23 «Да, всё в общую сессию (Рекомендую)» и его слово 27.10 (waiver M36, M37, M39 в
  STATUS; `ops/test-session` §3.5). at=2026-10-27

## Verdict

**NOT READY** — M40 не выдержан; код, тесты, гейты и CI зелёные; решение родителя — `escalation.md`.

## Spec coverage gaps
- **Телефон** — M36 (чтение ≤ 0,1 с), M37 целиком, экран M39, класс защиты `Caches/persona-*` — сессия теста.
- **Забыть один факт и счётчики брата и имени** — `memory-forget` (M41, M42).
- **Пересборка после разбора ждёт тап** до ≈ 4 с на телефоне (A24: сборка 3,8–4,3 с) — цена «следующая сессия
  помнит» (decisions); замер — сессия теста.

## Ревью рисковых мест

- **Конкурентность:** пересборка префикса идёт на последовательной очереди модели; `VoiceLoop.occupy` держит одно
  место памяти у модели — разбор и стирание, `wake` ждёт его, конец работы освобождает место только своё (`slot`), так
  что разбор, остановленный стиранием, не снимает стирание с места; флаг остановки законченного ответа отпускается
  (`release`) — иначе он прервал бы сборку (мутация c убита).
- **Целостность префикса:** `preparePrefix` наполняет последовательность 3 и только целым копирует её в 0
  (`llama_memory_seq_cp`), `prefixCount` меняется после копии — пересборка, которая не уместилась, оставляет прежнюю
  персону (мутация a убита); разговор (последовательность 1) очищается до сборки, иначе длинная сессия не оставила бы
  места (мутация b убита).
- **Данные ребёнка:** файл префикса `Caches/persona-*` несёт блок — класс полной защиты (`FileProtectionType.complete`),
  Caches в бэкап не идёт, «Стереть память» пересобирает префикс из персоны и удаляет файл с блоком; в тестах и на стенде
  — вымышленные Соня, Тёма, Мурка; блок стенда M40 — в `local/`, в git только числа.
- **Цепочка гейтов:** `scripts/lint/check_app_artifact.sh` — оракул артефакта, назван в STATUS; `merge_guard.sh` —
  путь мержа; гейты и их скрипты не тронуты.
- **Интеграция:** риска нет, потому что сети нет: модель — E4B на телефоне, продукт офлайн; `probe-mac` стенда M40 — без
  сервера и портов.
- **Деньги:** риска нет, потому что трат в диффе нет: «цена» — цена решений в `decisions.md`.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 10 code (+ process docs) / +374/−36 (net +338) |
| commits | 4 до PR (документы, код, заморозка M40, итог M40 со стопом) |
| time_to_accepted_spec | 0.0h — M36, M37, M39, M40 подписаны в спеке серии |
| rework_after_done | 0 |
| harness_hardened | yes — новые оракулы `PrefixTests` (3), `MemoryRecallTests`, `MemoryConsoleTests`; 10 мутаций; стенд M40 с проверкой вываливаний |
| implement_retries | 3 — `@State` с двумя именами, тело класса > 300 строк (`VoiceLoop`, `LlamaModel`), кортеж из трёх в тесте — исправлены до коммита |
| verify_fails_before_green | в прогоне CI |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **26**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
M36	XCTAssertLessThanOrEqual(model.tokenCount(block), 300)
M36	XCTAssertEqual(try prefixes(cache).count, 1)
M36	XCTAssertNotEqual(try prefixes(cache), today)
M36	XCTAssertGreaterThan(withBlock, bare)
M36	XCTAssertEqual(again.prefixInKV, withBlock)
M36	XCTAssertEqual(readPrompt, prompt)
M36	XCTAssertEqual(try prefixes(cache), today)
M36	XCTAssertEqual(again.prefixInKV, bare)
M36	XCTAssertLessThanOrEqual(context, Int(Double(settings.runtime.nCtx) * 0.85))
M36	XCTFail("a system turn longer than the context must not build")
M36	XCTAssertEqual(try prefixes(cache), file)
M36	XCTAssertEqual(model.prefixInKV, prefix)
M36	XCTAssertEqual(after, before)
M36	XCTAssertGreaterThan(model.prefixInKV, bare)
M36	XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: try store.block().text), Recall.persona)
M36	XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: block), Recall.persona + "\n\n" + block)
M36	XCTAssertTrue(block.hasPrefix(Fixture.header))
M39	XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: Элли пока ничего не знает"])
M39	XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: 14 фактов"])
M39	XCTAssertEqual(MemoryConsole.confirmation(facts: 14), "Стереть всё, что помнит Элли? (14 фактов)")
M39	XCTAssertEqual([1, 2, 5, 11, 21, 22].map { MemoryConsole.count("{n} {facts}", $0) },
M39	XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: 14 фактов", "ждёт разбора: 2"])
M39	XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: 14 фактов", "разбор не удался"])
M39	XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone).count, 1)
M39	XCTAssertEqual(try MemoryConsole.lines(store, zone: Recall.zone), ["память: стёрта 20.10 в 12:00"])
M39	XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: try store.block().text), Recall.persona)
```

✅ **Каждое утверждение ведёт к примеру спеки** (M36 M39), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0
