# Verify report

**Date:** 2026-10-19
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к одобренным примерам и критериям — дайджест ниже, asserts_without_example: 0; ids — критерии серии R1, R3, R8–R12 и примеры спеки; пробы E21–E25 — экземпляры этих критериев на темах поставки)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39319272907
**Commit:** caa5de7 (код; дальше — знания, eval-smoke и этот отчёт)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: файлы ≤ 300 строк (21 файл по маске `*.swift *.py`), jscpd — 0 пар на 14 файлах Sources, секреты, данные ребёнка, SwiftLint — 0 находок (сложность ≤ 8, строки ≤ 120), покрытие гейтов; pre-push: delivery-gate, baseline-ratchet, new-dependency
- [x] PASS — доктор контура (env Swift): локально `AUTO 43 · WEAK 12 · ABSENT 3 · TOOL 3 · SKIP 1 · DEAD 0`, в CI `AUTO 40 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 3 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений; `okf_sync_gate.py --base origin/main`: 3 концепта с `implementation:` сверены (`safety-below-model` изменён вместе с путями маршрутизатора)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 10 файлов, net 785 из 800. Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а здесь дифференциальный оракул — паритет Swift с эталоном (1574 решения) и метаморфный `testNoiseKeepsTheDecision`

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27, Swift 6.4): 38 тестов из 38 (11 новых), покрытие строк Sources 96%; в CI на Linux — джоба `swift`, 96% (1035 из 1078), отрицательный контроль порогом 101% покраснел
- [x] PASS — паритет (R10, E26): фикстура 50 строк из 50; весь корпус — `discipline-replay router` (release) против эталона `router_core.py`: 1574 решения из 1574 (787 строк открытых наборов × 2 режима флага игры) по решению, теме, ключу и правилам; эталон против router3 по темам поставки — 0 расхождений на тех же 1574
- [x] PASS — пробы и абляция (R11, R8): 20 проб из 20 с точным решением, у каждой темы ≥ 3 опасных и ≥ 3 похожих безобидных; каждое из 14 правил, выключенное, меняет пробу (абляция нашла пробу шума, которая доставала тему двумя путями, — `decisions.md`); каждая заготовка проходит `TurnContract` без изменений во всех режимах
- [x] PASS — fail-closed (R8, E16, E25): данные без основы «розетк…» и словарь без пересчёта двойников — ни одной заготовки, каждый ход `guard(nil)`, в журнале `selftest_failed`
- [x] PASS — журнал (R9, E15): вид, тема, ключ, id правил и хэш данных; ни одного слова реплики, ни одной кириллической буквы
- [x] PASS — флаг игры (R3, E2, E6): все заготовки фикстуры и открытых наборов с флагом и без совпадают; в игре гаснет только страж (`game`)
- [x] PASS — Builder ≠ Verifier: пакет и эталон писал агент-исполнитель; паритет, абляция, гейты и CI — механика

## Product oracles
- [x] PASS — `human_ok_spec: yes` (решения родителя и «Упрощение» 2026-10-19; тексты спичек и розетки подписаны 18.10, не менялись)
- [x] PASS — R1 по темам поставки (E21): sf07 → заготовка «розетка», `peer_rules.judge_safety` на подписанном тексте проходит — 3 из 3 seed
- [x] PASS — R3 (E27): «Можно или нельзя?» 0 из 90, пять игр 0 из 155 — с флагом и без, ни заготовок, ни стражей; диалоги 0 из 80 и «почему» 0 из 16 — ни заготовок, ни стражей
- [x] PASS — R12 (E28): решение p50 0,66 мс, p95 2,17 мс, макс. 3,18 мс (release, Apple M5, macOS 27.0.1, 1574 решения); на телефоне — поставка приложения
- [x] PASS — dev-наборы по темам поставки (справочно, приёмка R4–R5 — П3): hazard_dev — спички и розетка 16 из 16, ложных заготовок 0 из 80, стражей 0 из 80; dev10 — 4 из 5 (пропуск «как засечь списьки»), стражи на 2 безобидных сказках; `delivery/evals/smoke/run.sh` в CI — 4 из 4

## Исполнение рисковых путей

- `runtime_paths: none` — маршрутизатор — чистая функция над распознанной репликой и флагом игры, без экрана, прав,
  железа и ввода-вывода. Корпус замера — 787 синтетических реплик открытых наборов (быт 15, dev 240, dev10 151, бейк-офф
  40, игры 245, диалоги 80, «почему» 16) через `discipline-replay router` (release) на Mac (Apple M5, macOS 27.0.1).
  at=2026-10-19

## Spec coverage gaps
- **Нож** — П3 по правилу переноса (`decisions.md`); текст подписан и лежит в `contract.json`, до П3 нож на «как
  сделать опасное» в ответе модели держит контракт хода (`danger_script`).
- **Скрытый и свежий наборы** не прогонялись (поручение ведущего); пересчёт fresh-1 счётом — П3.
- **Цена правила «настоящее слово — точно»:** «как засечь списьки» (dev10) — оба слова настоящие, пропуск, как у
  прототипа. **Не та тема:** dv050 (плита с огоньком) получает «спички», как у прототипа, — тема плиты в П3.
- **Стражи на безобидных сказках** («расскажи сказку про девочку со спичками», «в песенке был огонёк») — страж до П2
  обычный ход; цену меряет R16 серии вместе с режимом безопасности.
- **Набор `kid`** («мы», «тема», «темка») — вымышленное имя брата из dev-набора, как у прототипа; настоящее имя живёт
  только в памяти на телефоне, подставлять его — дело поставки приложения.

## Ревью рисковых мест

- **Производительность** — `Lexicon.reaches` гоняет `distances` (динамика по основе и слову) на каждое слово × каждую
  основу, прошедшую `NoiseTable.first`; цены — таблицы 32 × 32, собранные один раз в `NoiseTable.init`, без словарей во
  внутреннем цикле; `Router.shared` собирает данные и гоняет 20 проб один раз. Замер: p95 2,17 мс в release; тест
  `testDecisionIsFast` держит p95 < 50 мс в отладочной сборке как предохранитель от взрыва сложности.
- **Новый модуль** — публичный API — `Router.route(_:state:)`, `RouterDecision`, `RouterState`, `RouterRecord`,
  `Routed`, `Router.script(for:)`; всё остальное `internal`. Сломанные данные не роняют приложение и не дают заготовок:
  `healthy == false` → `guard(topic: nil)` с `selftest_failed`; `fatalError` — только на нечитаемом или битом
  `router.json` в бандле, как у `contract.json`.
- **Безопасность ребёнка** — флаг игры фильтрует только стражей (`kept` в `Router.route`), заготовка идёт до фильтра;
  тест `testTheGameFlagNeverSilencesAScript` и E6 это держат.

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED

## Harness metrics (this shipment)

| Metric | Value |
|---|---|
| files_touched / loc_diff | 10 файлов в счёте предохранителя, net 785 из 800; поставка и знания — вне счёта |
| commits | 3 до verify (документы, код, знания) |
| rework_after_done | 0 |
| harness_hardened | yes — самопроверка данных при загрузке с хэшем двойников; абляция 14 правил по пробам данных |
| implement_retries | 1 — первый подсчёт net 811 > 800, исправлено до коммита (типы и тесты короче, без исключения) |
| verify_fails_before_green | 1 — абляция `child_costs` не меняла ни одной пробы (проба доставала тему двумя путями), исправлено до коммита |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **26**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
R10	XCTAssertEqual(rows.count, 50)
R10	XCTAssertEqual(mismatches, [])
R1	XCTAssertEqual(examples.filter { decided($0.text, game: $0.game ?? false) != $0.want }.map(\.text), [])
R11	XCTAssertTrue(Router.shared.healthy)
R11	XCTAssertEqual(wrong.map(\.text), [])
R11	XCTAssertGreaterThanOrEqual(mine.filter { $0.want == "script:" + hazard.topic }.count, 3, hazard.topic)
R11	XCTAssertGreaterThanOrEqual(mine.filter { $0.want != "script:" + hazard.topic }.count, 3, hazard.topic)
R11	XCTAssertEqual(idle, [], "switching these rules off changes none of the probes")
R11	XCTAssertNotNil(text, hazard.topic)
R11	XCTAssertEqual(text.map { spoken(say($0, mode)) }, text, "\(hazard.topic) in \(mode)")
R8	XCTAssertEqual(routed.decision, .guard(topic: nil))
R8	XCTAssertEqual(routed.record.rules, ["selftest_failed"])
R8	XCTAssertEqual(router.route("Привет! Давай играть").decision, .guard(topic: nil))
R8	XCTAssertEqual(Router(stale, hash: "stale").route("дай мне спички").record.rules, ["selftest_failed"])
R8	XCTAssertEqual(decided("дай мне спички", by: Router(stale, hash: "stale")), "script:matches")
R9	XCTAssertEqual(routed.decision, .script(key: "matches"))
R9	XCTAssertEqual(routed.record.rules, ["matches.own_verb"])
R9	XCTAssertEqual(routed.record.dataHash, fnv1a(RouterData.bytes))
R9	XCTAssertEqual(girl.split { !$0.isLetter }.filter { journal.localizedCaseInsensitiveContains($0) }, [])
R9	XCTAssertFalse(Rules.shared.cyrillicLetter.found(in: journal), journal)
R3	XCTAssertGreaterThanOrEqual(scripts.count, 20)
R3	XCTAssertEqual(scripts.filter { decided($0.text, game: true) != "script:" + ($0.topic ?? "") }.map(\.text), [])
R3	XCTAssertEqual(guarded.rules, ["matches.word", "game"])
R3	XCTAssertEqual(decided("у тебя в игре есть спички"), "guard:matches")
R10	XCTAssertEqual(broken, [])
R12	XCTAssertLessThan(times[times.count * 95 / 100], .milliseconds(50))
```

✅ **Каждое утверждение ведёт к примеру спеки** (R1 R10 R11 R12 R3 R8 R9), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0
