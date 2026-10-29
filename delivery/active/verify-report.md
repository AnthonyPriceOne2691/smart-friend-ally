# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки M41, M42 — дайджест ниже, asserts_without_example: 0; ожидания подписаны родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии)
**CI run:** — (после открытия PR)
**Commit:** — (сдача — следующим прогоном PR)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 0 находок (снимок 0; длины
  строк и число параметров исправлены до коммита); секреты; данные ребёнка; `gate-coverage` — скрипты подключены
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: OK, 18 концептов сверены
  (`engineering/memory`, `engineering/session`, `engineering/safety-below-model`, `engineering/voice-loop`,
  `ops/child-data`)
- [x] PASS — `delivery_check` (pre-push): 0 ошибок; предохранитель — 19 файлов кода, net 462 из 800 (план ≈ 440,
  ожидание +50% ≈ 600); рисковых путей 1 (`App/Sources/`). Предупреждение «нет реляционного оракула»: детектор знает только
  hypothesis и fast-check; инварианты поставки — «надгробие не возвращает забытое из сессии старше него при любом
  порядке записи» (повторная запись и разговор из очереди, M41) и «срезанное окном не попадает в память модели» (D5, M42)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): AllyMemory 24 из 24 (M41 — 2), AllyCore 141 из 141 (M42 — 4: D2 с
  двойником, её слово о брате, без имён, через `Conversation`); прежние тесты сессии и разговора — без правок утверждений
- [x] PASS — мутации в ту же сессию (П30), 11 из 11 убиты, файлы восстановлены: (a) `secure_delete` выключен, (b) без
  чекпойнта после забывания, (c) удаляется только активное значение, (d) надгробие не читается, (e) момент надгробия
  наоборот — `MemoryForgetTests`; (f) окно только в `finish`, (g) её ход считается, (h) `Conversation` теряет имена,
  (i) доля имени со сдвигом на единицу, (j) имена брата не читаются, (k) её слово не спасает от среза — `WindowTests`
- [x] PASS — сборка Ally.app без подписи (`xcodebuild … CODE_SIGNING_ALLOWED=NO`, Xcode 27) и оракул артефакта
  `check_app_artifact.sh` — OK (первая сборка поймала `@State` с двумя именами — исправлено до PR)
- [x] PASS — M42 на E4B (стенд вне git, заморозка `7119344e7e3f39ae` до прогона, под нагрузкой второго отбора моделей):
  seed 42 / 7 / 1234 — брат 1, имя 0 в каждом из 14 ответов; 3 из 3 (`eval-smoke.md`)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода; стенд E4B — правило в eval-smoke коммитом до прогона

## Product oracles
- [x] PASS — `human_ok_spec: yes`: M41, M42 подписаны в спеке серии (подпись 37bb5a9); документы поставки — коммитом
  `f5c8350` раньше кода `f418822`, правило стенда M42 — там же (L19, L33)
- [x] PASS — M41 и M42 (без телефона): факт — `eval-smoke.md`; экран «Забыть» на телефоне — сессия теста по waiver'у

## Изменение поверхности модели

- `Packages/AllyMemory/Sources/Memory/Resources/memory.json` — добавлены только слова консоли родителя «Забыть «{what}»?»
  и «Забыть всё про «{what}»? ({n} {facts})»; модели они не идут. Шапка, строки, бюджет и `in_conversation` блока не
  тронуты: M15, M23, M24 (байты блока) зелёные, системный ход — персона байт в байт (`// M40`). at=2026-10-29

## Исполнение рисковых путей

- `App/Sources/` — исполнено на Mac: сборка Ally.app без подписи и оракул артефакта (Info, сеть, права); имена из памяти
  доходят до сессии через `Conversation` (`WindowTests`, тот же `SessionParts`, что строит `VoiceLoop`). На телефоне не
  исполнено: экран «Забыть…» (список по сущностям, подтверждения, исчезновение строки, тап «Разбудить» ждёт конца работы) —
  в общую сессию теста: решение родителя 2026-10-23 «Да, всё в общую сессию (Рекомендую)» (waiver M41 в STATUS;
  `ops/test-session`, шаг M41). at=2026-10-29

## Ревью рисковых мест

- **Транзакция БД:** `forget(fact:)` и `forget(entity:)` — удаление и надгробие одной транзакцией (`db.transaction`), затем
  чекпойнт `TRUNCATE`; однозначный признак удаляется одной инструкцией вместе с историей — ссылки `superseded_by` уходят
  той же инструкцией, внешний ключ не рвётся; сущность — каскадом `fact` → `seen`. Убитое приложение между транзакцией и
  чекпойнтом оставит старые страницы в WAL до следующего чекпойнта (разбор очереди, следующее забывание) — значения нет в
  базе, но есть в WAL; на телефоне файлы — полной защиты.
- **Конкурентность:** забывание — та же работа на месте памяти у модели, что разбор и стирание (`VoiceLoop.change` →
  `occupy`): разбор останавливается, тап ждёт; соединение SQLite держит замок (L129); окно сессии живёт в акторе
  `Session`, `TurnRunner` получает его значением на ход.
- **Данные ребёнка:** надгробие хранит вид, отношение, сущность, признак, слот и момент — ни значения, ни хэша; байты
  базы, WAL и SHM после забывания — 0 вхождений (M41); имена окна — из памяти на телефоне, в git только вымышленные.
- **Цепочка гейтов:** гейты и их скрипты не тронуты; путь мержа — `merge_guard.sh`.
- **Интеграция:** риска нет, потому что сети нет: модель на телефоне, стенд M42 — `probe-mac`-подобный исполняемый файл без
  сервера и портов.
- **Деньги:** риска нет, потому что трат в диффе нет.

## Spec coverage gaps
- **Телефон** — экран «Забыть» — сессия теста.
- **Уменьшительные имени** («Сонечка») окно не считает — по данным чёрного ящика (L28: форма, а не список).
- **Весь ответ о брате** после двух — звучит заготовка режима («повтори, я не расслышала»); видно в чёрном ящике.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 19 code (+16 process docs) / +507/−45 (net +462) |
| commits | 7 до PR |
| time_to_accepted_spec | 0.0h — M41, M42 подписаны в спеке серии |
| rework_after_done | 0 |
| harness_hardened | yes — новые оракулы `MemoryForgetTests`, `WindowTests`; 11 мутаций; стенд M42 на E4B |
| implement_retries | 3 — SwiftLint (длины строк, шесть параметров), `@State` с двумя именами — исправлены до PR |
| verify_fails_before_green | — (после CI) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **25**, из них без ссылки на пример спеки: **0**.

```
M42	XCTAssertEqual(said.count, 14)
M42	XCTAssertEqual(said.indices.filter { Window.brother(said[$0]) }, [0, 1])
M42	XCTAssertEqual(said.indices.filter { said[$0].contains("Соня") }, [2, 5, 8, 11])
M42	XCTAssertEqual(Array(said.prefix(4)), ["Как здорово! А что сегодня делал братик Тёма?",
M42	XCTAssertEqual(Window.said(rig.model).map(Window.brother), [true, true, true, true, false])
M42	XCTAssertEqual(Window.said(talk.model).first, "Как здорово! А что сегодня делал братик Тёма?")
M42	XCTAssertEqual(Window.said(rig.model), ["Здорово! А братик дома?", "Здорово! А братик дома?", "Здорово!"])
M41	XCTAssertEqual(MemoryConsole.forgetting(item), "Забыть «серая»?")
M41	XCTAssertEqual(try store.forget(fact: color.id, now: try Fixture.at("2026-10-20 12:00")), 2)
M41	XCTAssertEqual(try Fixture.occurrences(["рыжая", "серая"], in: folder), 0)
M41	XCTAssertEqual(try store.block().text.split(separator: "\n").filter { $0.hasPrefix("Кошка") },
M41	XCTAssertEqual(again.refused, ["forgotten": 1])  // the same session parsed again
M41	XCTAssertEqual(parsed.first?.written?.refused, ["forgotten": 1])
M41	XCTAssertNil(try Forget.color(store))
M41	XCTAssertEqual(try Fixture.occurrences(["рыжая", "серая"], in: folder), 0)
M41	XCTAssertEqual(try Forget.color(store)?.value, "рыжая")  // told after the forgetting: known again
M41	XCTAssertEqual(brother.items.map(\.text), ["Тёма", "восемь лет", "строили замок из подушек"])
M41	XCTAssertEqual(MemoryConsole.forgetting(brother), "Забыть всё про «Брат Тёма»? (3 факта)")
M41	XCTAssertEqual(try store.forget(entity: brother.entity, now: try Fixture.at("2026-10-20 12:00")), 3)
M41	XCTAssertEqual(try Fixture.occurrences(["Тёма", "строили замок из подушек"], in: folder), 0)
M41	XCTAssertEqual(try store.facts().count, 11)
M41	XCTAssertFalse(try store.block().text.contains("Брат"))
M41	XCTAssertEqual(again.refused, ["forgotten": 3])
M41	XCTAssertEqual(try store.facts().count, 11)
M41	XCTAssertEqual(try Fixture.occurrences(["Тёма"], in: folder), 0)
```

✅ **Каждое утверждение ведёт к примеру спеки** (M41 M42), а примеры человек подписал до кода (`human_ok_spec`).

asserts_without_example: 0

## Verdict
- [ ] READY FOR HANDOFF (после зелёного CI)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
