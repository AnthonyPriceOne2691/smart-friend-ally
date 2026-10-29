# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки M43, M15, M23, M24, M40 — дайджест ниже, asserts_without_example: 0; новая форма подписана родителем 2026-10-29, M15–M40 — спека серии 2026-10-23; включение — решение родителя 2026-10-29 «Включить: имя держит код»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40951806447 (03645d9 — delivery, swift, gates зелёные; PR #92)
**Commit:** 03645d9 (документы — 27fb759 до кода, код формы — 30de671, заморозка стенда M40 — 695821f до прогона, итог M40 со стопом — 5600099, включение по решению родителя — 4039258; сдача — следующим прогоном PR #92)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 0 находок (длинные строки
  фикстуры D1 разбиты до коммита); секреты; данные ребёнка; `gate-coverage`
- [x] PASS — `okf_validate.py`: 0 ошибок (53 файла); `okf_sync_gate.py --base origin/main`: OK (`engineering/memory`)
- [x] PASS — `delivery_check` (pre-push): 0 ошибок; предохранитель — 8 файлов кода, net 158 из 800 (план ≈ 90, ожидание
  ≈ 140: сверх плана — фикстура D1 из 31 ответа в `BlockWindowTests`, ≈ 75 строк по решению родителя); рисковых путей 0.
  Предупреждение «нет реляционного оракула»: дифференциальный оракул поставки — M40 («персона» против «персона + блок» на
  тех же наборах и seed); инвариант — байты блока не зависят от порядка записи и повторного открытия (M24)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): AllyMemory 25 из 25 (M43 — пример родителя ровно; M15, M23, M24 —
  новыми словами; M40 — блок новой формы в системном ходе); AllyCore 157 из 157 (M40 — `BlockWindowTests`: 31 ответ E4B
  на D1 через `Session` с окном — имя в 10 из 31). Ожидания M15, M23, M43 выведены отдельно от кода — оценка по тексту и
  подписанный порядок отсева; ожидание окна — правилом доли по номерам ответов с именем (`eval-smoke.md`)
- [x] PASS — мутации в ту же сессию (П30), 4 из 4 убиты, файлы восстановлены: имя вернулось в строку «Она» (M15, M23,
  M43), прежняя шапка (M15–M17, M23, M43), бюджет 300 по умолчанию (M43), шапка без «верь ей» (M15–M17, M23, M43)
- [x] РЕШЕНИЕМ РОДИТЕЛЯ — M40 на стенде персоны (Mac, вне git; правило — spec.md до прогона, заморозка
  `9ad422a3b1f290db`; 22:24–23:20 под нагрузкой второго отбора моделей): «персона» повторила сохранённые ответы v2.4 (быт
  33, «почему» 26, D1 7 из 7, имя D1–D5); «персона + блок»: быт 34 из 45 при 33 ✓, «почему» 31 из 48 при 26 ✓, с
  подсказкой (формат B) 38 при 36 ✓, детали D1 7 из 7 ✓, имя D1 74% при 16% ✗, вываливание 1 из 221 ✗, живость 38% ✗ —
  правило не выдержано; родитель 2026-10-29: «Включить: имя держит код» (`escalation.md`), waiver в STATUS
- [x] PASS — прогрев при запуске после слияния child-open (88e9920): `VoiceLoop.warmUp` грузит модель с системным ходом
  `MemoryBlock.system(persona:block:)` по умолчанию `in_conversation` — теперь `true`, блок новой формы считается
  токенизатором модели; тот же вызов — в `refreshPrefix` после разбора и стирания (`MemoryRecallTests` `// M40`)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; живость M40 судили
  два слепых агента без ключа (вердикты принял ведущий); слова блока подписал родитель до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes`: слова новой формы подписаны родителем 2026-10-29 через ведущего; документы —
  коммитом `27fb759` раньше кода `30de671`, правило суда M40 — там же, заморозка стенда — `695821f` до прогона (L19, L33)
- [x] PASS (решением родителя) — M40: правило не выдержано, остановка оформлена (`escalation.md`), родитель — «Включить:
  имя держит код»; M36 и M37 на телефоне — сессия теста (waiver в STATUS)

## Изменение поверхности модели

- `Packages/AllyMemory/Sources/Memory/Resources/memory.json` — шапка блока новыми словами (подпись родителя
  2026-10-29), бюджет 200, `in_conversation: true` (решение родителя 2026-10-29 после второго M40); блок новой формы идёт
  в системный ход после персоны. Замер — M40 (выше): быт, «почему» и детали D1 не хуже, имя, вываливание и живость — нет.
  at=2026-10-29
- `Packages/AllyMemory/Sources/Memory/BlockLines.swift` — строка «Она» без её имени. at=2026-10-29
- `Packages/AllyMemory/Sources/Memory/MemoryBlock.swift` — только комментарий (ядро без имени); сборка та же. at=2026-10-29
- Снимок `delivery/model_surface.txt` — добавлены три файла блока (sha256), раз блок теперь доходит до модели.

## Исполнение рисковых путей

- Рисковых путей дифф не трогает (`runtime_paths: none`): пересборка префикса с блоком исполнена на Mac с весами в
  memory-recall (`PrefixTests` `// M36`); на телефоне — чтение префикса с блоком ≤ 0,1 с (M36), «помнит на телефоне»
  (M37) и обращение по имени не чаще трети ответов — сессия теста (`ops/test-session`). at=2026-10-29

## Ревью рисковых мест

- **Поведение модели:** включение блока меняет каждый разговор: судьи выбрали ответы без памяти в 14 парах из 24, одно
  вываливание из 221 — принято решением родителя; что держит код: имя — окно сессии (D1 — 10 из 31), опасное —
  маршрутизатор до модели и контракт после неё.
- **Производительность:** после каждого разбора с изменившимся блоком префикс пересобирается (≈ 4 с на телефоне, тап
  ждёт) — цена названа родителю в вопросе.
- **Данные ребёнка:** блок без её имени; файл префикса с блоком — полной защиты, вне бэкапа, уходит со стиранием; в тестах
  и на стенде — вымышленные Соня, Тёма, Мурка; ответы E4B в фикстуре `BlockWindowTests` — на вымышленном диалоге стенда.
- **Цепочка гейтов:** гейты и их скрипты не тронуты; путь мержа — `merge_guard.sh`.
- **Интеграция:** риска нет, потому что сети нет: стенд M40 — `probe-mac` без сервера и портов.
- **Деньги:** риска нет, потому что трат в диффе нет.

## Spec coverage gaps
- **Телефон** — M36, M37 и обращение по имени на слух — сессия теста.
- **Подсказка одного факта к месту кодом** (вариант 1 вопроса) — отложено, по данным чёрного ящика.
- **Окно на D1 — оценка на тех же ответах:** после среза модель помнит уже срезанное (D5), следующие ответы в жизни могли бы
  отличаться.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 8 code (+16 process docs) / +190/−32 (net +158) |
| commits | 12 до PR (с тремя слияниями main) |
| time_to_accepted_spec | 0.4h — вопрос родителю о словах формы и подпись 2026-10-29 |
| rework_after_done | 0 |
| harness_hardened | yes — `BlockWindowTests` (окно на ответах M40), M43; стенд M40 v2 (формат B, блок кодом продукта) |
| implement_retries | 2 — M24 при новом умолчании (бюджет 300 подписанного примера), длины строк фикстуры |
| verify_fails_before_green | 0 — прогон CI 40951806447 зелёный во всех трёх джобах (delivery, swift, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **25**, из них без ссылки на пример спеки: **0**.

```
M40	XCTAssertEqual(said.count, 31)
M40	XCTAssertEqual(BlockD1.turns.filter { $0.elly.contains("Сон") }.count, 23)
M40	XCTAssertEqual(named.map { $0 + 1 }, [6, 7, 9, 13, 15, 18, 21, 24, 27, 30])  // 10 of 31: a third
M23	XCTAssertEqual(at120.trimmed, ["был фиолетовый", "единорог Звёздочка", "считать до десяти",  // M23
M23	XCTAssertEqual(at120.text, Fixture.lines("Она: пять лет.",  // M23
M23	XCTAssertEqual(at120.tokens, 118)  // M23
M23	XCTAssertEqual(at100.text, core)  // M23
M23	XCTAssertEqual(at100.tokens, 108)  // M23
M23	XCTAssertEqual(try store.block(budget: 10).text, core)  // M23
M43	XCTAssertEqual(MemoryBlock.budget, 200)
M43	XCTAssertEqual(block.text, Fixture.lines(
M43	XCTAssertEqual(block.trimmed, ["был фиолетовый", "единорог Звёздочка", "печёт пирожки"])
M43	XCTAssertEqual(block.tokens, 197)
M43	XCTAssertFalse(block.text.contains("Соня"))
M24	XCTAssertEqual(try reversed.block(budget: 300).text, text)  // M24
M24	XCTAssertEqual(try forward.block(budget: 300).text, text)  // M24
M24	XCTAssertEqual(try MemoryStore(directory: folder).block(budget: 300).text, text)  // M24
M40	XCTAssertTrue(MemoryBlock.inConversation)
M40	XCTAssertTrue(block.hasPrefix(Fixture.header))
M40	XCTAssertFalse(block.contains("Соня"))
M40	XCTAssertEqual(MemoryBlock.system(persona: Recall.persona, block: block), Recall.persona + "\n\n" + block)
M40	XCTAssertNil(MemoryConsole.conversation)
M15	XCTAssertEqual(block.text, Fixture.lines("Она: пять лет.", "Любимое: цвет фиолетовый.",  // M15
M15	XCTAssertEqual(block.text.unicodeScalars.count, 441)  // M15
M15	XCTAssertEqual(block.tokens, 164)  // M15
```

✅ **Каждое утверждение ведёт к примеру спеки** (M15 M23 M24 M40 M43).

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (M40 — решением родителя 2026-10-29 «Включить: имя держит код»)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
