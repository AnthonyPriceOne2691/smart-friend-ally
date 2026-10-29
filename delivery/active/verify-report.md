# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки P21–P24 — дайджест ниже, asserts_without_example: 0; примеры подписаны родителем 2026-10-29 до кода, спека — 901e5ae)
**CI run:** — (PR и прогон — после пуша; ссылка вписывается в коммите сдачи до мержа, `mergeable` проверяется до ссылки, L35)
**Commit:** документы — 901e5ae (спека, STATUS), f76610b (подпись, план, задачи, решения, eval-smoke) до кода; код — cb23637; заморозка обёртки P18 — caecdc8; знание — 0e76d54

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd, секреты, данные ребёнка, `gate-coverage`.
  SwiftLint — 0 находок (снимок 0). Первый заход дал 2, обе починены до коммита: поток без политики буфера в
  `--said`, `String(decoding:)` в тесте.
- [x] PASS — доктор контура: `AUTO 47 · WEAK 13 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0` (как после Э2), «лжи нет».
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: OK, 18 концептов.
- [x] PASS — `delivery_check --diff-base origin/main`: 0 ошибок. Предохранитель — 8 файлов кода, net +256 из 800
  (план ≈ 290). Предупреждение «нет реляционного оракула» знает только hypothesis и fast-check. Реляционные оракулы
  здесь: инвариант P24 по всей базе (100 карточек, одна и после первой фразы в 22 слова) и дифференциальный по
  поверхности (решения поиска на 300 открытых вопросах — main и ветка байт в байт).

## Behavior oracles
- [x] PASS — `swift test` AllyCore на Mac (Xcode 27): 148 тестов из 148. Новые — `CardFallbackTests` (P21–P23, 9 тестов
  через настоящую `Session`, маршрутизатор и базу из ресурсов) и `EncyclopediaBaseTests` (P24, 2 теста). Покрытие
  AllyCore — в CI на Linux.
- [x] PASS — мутации в ту же сессию, исходник восстанавливался из git после каждой: 10 из 10 убиты.
  - Проводка: отката нет; сессия не передаёт карточку; поиск не отдаёт ключ; без метки в следе.
  - Правило: суть в сыром ответе; откат на заготовке; без первой фразы; без «ё» как «е»; откат только в `why`.
  - Отказ закрытый: без проверки ключа при загрузке.
  - «Суть в сыром ответе» краснит только пример, где фразу с сутью срезал контракт: второй вопрос рвёт лимиты `why`.
- [x] PASS — приложение без подписи: `xcodegen` + `xcodebuild` — BUILD SUCCEEDED (1:30 под нагрузкой). Оракул артефакта
  OK: `Ally.app`, бинарей 6; база `encyclopedia.ru.jsonl` — в бандле AllyCore внутри приложения.
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель. Ожидания — примеры P21–P24, подписанные родителем
  до кода; судья P18 заморожен хэшем с Э2.

## Product oracles
- [x] PASS — P21: ответ без сути → «Ой, какой ты умненький!» и текст `boats-float` слово в слово.
  - В следе `why`, источник `model`, `knowledge.hint` + `knowledge.fallback`; память модели — прозвучавшее.
  - Заготовка («повтори») остаётся без карточки.
  - На последнем ходе — карточка, потом прощание.
  - Ответ из одного предложения — одна карточка.
- [x] PASS — P22: ответ с сутью звучит как есть, правила — только `knowledge.hint`; суть через «ё» («тёплой» при ключе
  `тепл`).
- [x] PASS — P23: «почему бурый медведь спит» — `knowledge.coverage`, вход модели — её фраза байт в байт, ответ как есть.
- [x] PASS — P24: все 100 карточек — ключ собирается и ловит свой текст. `why` пропускает текст слово в слово и без
  правил — один и после первой фразы в 22 слова. Негодный ключ («не собирается», «не ловит свой ответ») —
  `selftest_failed`, подсказок нет. Карточка без ключа (тестовая база Э1) текстом не звучит.
- [x] PASS — P18, перегон 2026-10-29. Стенд: Mac, llama.cpp b10809, E4B Q4_K_M, персона v2.4, `er` × seed 48, 49, 50,
  `nice -n 10`.
  - Судья заморожен с Э2, хэши сверены до прогона. У персоны в записи Э2 описка в 16-м знаке (`…0474` вместо
    `…0476`): тот же файл стоит в снимке поверхности и в строках прогона seed 45–47.
  - Обёртка `p18_fallback.py` (sha256 9bfa96cc…, заморожена коммитом caecdc8 до прогона) подменяет ответы на сказанное
    через настоящий `TurnRunner`.
  - **Верных 48 из 48** (по одному ключу `er` — 42), **артефактов 0**, заготовок 0.
  - **Карточка прозвучала на 12 ходах из 48** (er01 — 2, er02 — 1, er04 — 3, er08 — 1, er11 — 1, er15 — 1, er16 — 3).
  - Время — под нагрузкой: load 8,7 → 96 из-за параллельного отбора моделей; на качество не влияет.
  - До прогона — проверка проводки без модели на сохранённых ответах seed 45–47: 48 из 48, карточка 16 из 48;
    `prompts.json` стенда байт в байт.

## Изменение поверхности модели
- элемент: `Packages/AllyCore/Sources/AllyCore/Encyclopedia.swift` — движок читает `key` карточки (`EncyclopediaCard`,
  `Lookup.key`) и при загрузке проверяет: ключ собирается и ловит свой ответ, иначе `selftest_failed` (→ 2412495f…).
- снимок `delivery/model_surface.txt`: новый хэш `Encyclopedia.swift`. Строка `LlamaModel.swift` подтянута до текущего
  main: файл менял memory-recall (7b9aa9e), снимок тогда не обновлялся; эта поставка его не трогала.
- почему: откат на текст карточки (card-fallback) решает по ключу карточки, а ключ теперь читает рантайм.
- оракулы:
  - вход модели прежний: без подсказки — её фраза байт в байт (P17, P23);
  - дифференциальный: решения поиска на 300 открытых вопросах справки (v1 + v2) — `encyclopedia-replay` main
    (сборка из `git archive origin/main`) и ветки совпали байт в байт, подсказок 85, хэш данных тот же
    (`fnv1a:a177115da057d124`);
  - P13 и P16 зелёные.
- порча промпта: n/a — промпт и вход модели не меняются; правка — чтение ключа и откат после модели. Сам откат судит
  P18 на настоящих ответах модели.
- провайдер: llama.cpp b10809 (`probe-mac`) на стенде P18.
- цена: прогон P18 — 3 × 16 генераций на Mac, без денег.
- at=2026-10-29

## Spec coverage gaps
- Телефон: откат — код ядра, на телефоне не исполнялся. В сессии теста его видно по `knowledge.fallback` в следе и
  чёрном ящике (observe_signal).
- Ключи карточек, которые не узнают верный пересказ («чувствовать» при `чувству`, «пониже» при `низк`): добор — по
  доле `knowledge.fallback` в чёрном ящике, отдельной поставкой.
- Базы стенда Э1 (`cards54.jsonl`, `cards55.jsonl`) выключены рантаймом (`healthy no`) уже на main — проверено сборкой
  main в стороне. Паритет P11 на них не идёт; эта поставка это не меняла.

## Ревью рисковых мест
- **Безопасность.** Текст карточки проходит контракт того же хода (режим, её фраза, решение маршрутизатора) — нового
  пути мимо контракта нет. Заготовку контракта (отказ, тайм-аут, нарушение) карточка не заменяет. Поиск по-прежнему
  только после «pass» маршрутизатора; в базе нет тем маршрутизатора и деликатного (P13, P14 Э2).
- **Отказ закрытый.** Негодный ключ выключает энциклопедию целиком, консоль пишет `selftest_failed`. Ключ, который не
  собирается, в рантайме ничего не судит, и ответ остаётся как есть.
- **Память и след.** Память модели, слова хода, `MemoryTap`, тип её следующего хода и прощание по лимиту берут
  прозвучавшее: первую фразу и карточку. Источник `model` сохранён, поэтому память и прощание ход не теряют. След —
  без слов: правило `knowledge.fallback`, id карточки латиницей.
- **Данные.** В тестах только «Соня» и тексты карточек — факты о мире. Данных ребёнка в git нет.
- **Транзакция БД.** Риска нет. Слово `commit` в диффе — `LanguageModel.commit(spoken:)` у двойника `SavedReply` в
  `encyclopedia-replay`: память модели (D5), пустое тело. Базы и транзакций поставка не трогает: таблица FTS5 строится
  в памяти при загрузке и только читается.
- **Стенд.** `encyclopedia-replay --said` печатает слова Элли — только открытые наборы; без флага выход прежний (паритет
  P11 и слепые счёты ведущего не задеты).

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 8 code (+12 process docs) / +286/−30 (net +256); предохранитель — 8 файлов, net 256 из 800 |
| commits | 5 до отчёта |
| time_to_accepted_spec | 0.2h (спека 901e5ae → подпись родителя 2026-10-29) |
| rework_after_done | 0 (handoff not declared yet) |
| harness_hardened | yes — `CardFallbackTests.swift` (новый оракул), P24 в `EncyclopediaBaseTests.swift`, обёртка стенда `p18_fallback.py`, `encyclopedia-replay --said` |
| implement_retries | 1 — две находки SwiftLint на первом коммите кода (буфер потока, `String(bytes:encoding:)`) |
| verify_fails_before_green | 0 до PR (CI — после пуша) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **35**, из них без ссылки на пример спеки: **0**.

```
P21	XCTAssertEqual(rig.said, ["Ой, какой ты умненький!"] + boat)
P21	XCTAssertEqual([record.mode, record.source], ["why", "model"])
P21	XCTAssertEqual(record.knowledge?.card, "boats-float")
P21	XCTAssertEqual(record.knowledge?.rules, ["knowledge.hint", "knowledge.fallback"])
P21	XCTAssertEqual(rig.model.memory.turns.last?.said, (["Ой, какой ты умненький!"] + boat).joined(separator: " "))
P21	XCTAssertEqual(rig.said, ["Ой, ты знаешь, почему так?"] + boat)
P21	XCTAssertEqual(rig.said, [misheard])
P21	XCTAssertEqual(rig.sink.records.last?.source, "canned:generic")
P21	XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
P21	XCTAssertEqual(rig.said, ["Ой, какой ты умненький!"] + boat + goodbye)
P21	XCTAssertEqual(records.map(\.mode), ["goodbye", "goodbye"])
P21	XCTAssertEqual(records.first?.knowledge?.rules, ["knowledge.hint", "knowledge.fallback"])
P21	XCTAssertEqual(records.map(\.end), [nil, "limit"])
P21	XCTAssertEqual(voice.sentences, boat)
P21	XCTAssertEqual(outcome.turn.sentences, boat)
P21	XCTAssertTrue(outcome.cardSaid)
P22	XCTAssertEqual(rig.said, reply)
P22	XCTAssertEqual(rig.sink.records.last?.mode, "why")
P22	XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
P22	XCTAssertEqual(rig.said, reply)
P22	XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
P23	XCTAssertEqual(rig.model.inputs, ["почему бурый медведь спит"])
P23	XCTAssertEqual(rig.said, ["Ой, а ты как думаешь, почему?"])
P23	XCTAssertEqual(record.mode, "talk")
P23	XCTAssertEqual(record.knowledge?.rules, ["knowledge.coverage"])
P23	XCTAssertNil(record.knowledge?.card)
P24	XCTAssertEqual(rig.said, ["Ой, какой ты умненький!"])
P24	XCTAssertEqual(rig.sink.records.last?.knowledge?.rules, ["knowledge.hint"])
P24	XCTAssertEqual(CardEssence(card.key)?.found(in: [card.answer]), true, card.id)
P24	XCTAssertEqual(alone.sentences.joined(separator: " "), card.answer, card.id)
P24	XCTAssertEqual(alone.record.rules, [], card.id)
P24	XCTAssertEqual(after.sentences, [first] + alone.sentences, card.id)
P24	XCTAssertFalse(base.healthy, key)
P24	XCTAssertEqual(base.failure, "selftest_failed", key)
P24	XCTAssertNil(base.lookup("почему медведь спит всю зиму").hint, key)
```

✅ **Каждое утверждение ведёт к примеру спеки** (P21 P22 P23 P24), а примеры человек подписал до кода
(`human_ok_spec`). Подпись под дайджестом не требуется: `asserts_reviewed_by: n/a`.

asserts_without_example: 0

## Verdict

Verify сделан на Mac; CI — после пуша, ссылка — в коммите сдачи.

- [ ] READY FOR HANDOFF — после зелёного CI на PR
