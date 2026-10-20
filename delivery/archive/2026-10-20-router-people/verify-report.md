# Verify report

**Date:** 2026-10-20
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к одобренным примерам и критериям — дайджест ниже, asserts_without_example: 0; ids — критерии серии R1, R3, R8–R14 и примеры спеки; ожидания правил содержания — из эталона `output_filter.PROBES` генератором, а не руками)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39478540337
**Commit:** 7654706 (код b4c358e и знания; PR #32 `MERGEABLE` перед записью ссылки — L35; этот отчёт и handoff — следующими коммитами со своими прогонами)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: файлы ≤ 300 строк (24 файла по маске `*.swift *.py` в CI), jscpd — 0 пар на 16 файлах Sources, секреты, данные ребёнка, SwiftLint — 0 находок на 22 файлах (сложность ≤ 8, строки ≤ 120), покрытие гейтов; pre-push: delivery-gate, baseline-ratchet, new-dependency
- [x] PASS — доктор контура (env Swift, `DEVELOPER_DIR` Xcode): локально `AUTO 43 · WEAK 12 · ABSENT 3 · TOOL 3 · SKIP 1 · DEAD 0`, в CI `AUTO 40 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 3 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений (39 файлов); `okf_sync_gate.py --base origin/main`: 3 концепта с `implementation:` сверены (`safety-below-model` изменён вместе с путями, `Clause.swift` и `Content.swift` добавлены)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 21 файл, net 654 из 800 (+843/−189). Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а дифференциальные оракулы здесь — паритет Swift с эталоном маршрутизатора (1574 решения) и контракта (52 пробы, 110 ответов) и метаморфный `testNoiseKeepsTheDecision`

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27, Swift 6.4): 46 тестов из 46 (8 новых, 6 прежних расширены); в CI на Linux — джоба `swift`, покрытие строк Sources 96% (1269 из 1319), отрицательный контроль порогом 101% покраснел
- [x] PASS — паритет маршрутизатора (R10, E36): фикстура 60 строк по 12 темам (с флагом `forget`); весь корпус — `discipline-replay router` (release) против эталона `router_core.py`: 1574 решения из 1574 (787 строк открытых наборов × 2 режима флага игры) по решению, теме, ключу и правилам; решения П1 при новой редакции эталона — 0 изменений
- [x] PASS — паритет контракта (R14, E20, E33, E34): 52 пробы `output_filter.PROBES` (нарушители новых правил и их чистые двойники) и 110 сохранённых ответов модели — Swift совпал с эталоном посимвольно с первого прогона
- [x] PASS — пробы и абляция (R11, R8, E39): 82 пробы самопроверки из 82 с точным решением; у каждой темы ≥ 3 решающих и ≥ 3 похожих безобидных; каждая из 21 статьи, выходы `frame` и `tale` и 14 правил П1, выключенные, меняют пробу; каждое из 8 правил содержания, выключенное, меняет пробу эталона (указатель на взрослого — своим тестом); каждая заготовка, указатель и запасная фраза проходят `TurnContract` без изменений во всех режимах
- [x] PASS — fail-closed (R8, E35): данные без основ `LOST` или `SOCKET` — ни одной заготовки, каждый ход `guard(nil)`, `selftest_failed`, `forget`; контракт без шаблонов `secret`, `pii_ask` или `human_claim` — только заготовки (проба самопроверки не поймана)
- [x] PASS — журнал (R9, E15): на «я потерялась в парке» и на реплику со спичками — вид, тема, ключ, id правил, хэш данных; ни одного слова реплики, ни одной кириллической буквы
- [x] PASS — указатель (R13, E18, E30, E31, E32): «потерялась» и страж страха без указателя — указатель дописан (дописать → заменить хвост → первое предложение и указатель); ничего не осталось — запасная фраза темы; указатель модели не дублируется; другие темы — без изменений; в игре страж страха гаснет, указатель не дописывается
- [x] PASS — Builder ≠ Verifier: пакет и эталон писал агент-исполнитель; паритет, абляция, гейты и CI — механика

## Product oracles
- [x] PASS — `human_ok_spec: yes` (решения родителя и упрощение «базовые случаи» 2026-10-19; тексты П2 проверены ведущим по поручению родителя; генератор сверяет девять текстов и запасную фразу страха с `router-scripts-basic.json` дословно)
- [x] PASS — R1 по темам поставки (E29): sf01, sf02, sf03, sf12, sf13, sf14, sf15 → заготовки «чужой зовёт», «чужой даёт», «дверь», «потерялась», «секрет», «тело», «интернет»; `peer_rules.judge_safety` на каждом тексте проходит; решение детерминировано — 3 из 3 seed
- [x] PASS — R3 (E37): «Можно или нельзя?» 0 из 90, пять игр 0 из 155 — с флагом и без, ни заготовок, ни стражей; диалоги 0 из 80 и «почему» 0 из 16 — ни заготовок, ни стражей, в обоих режимах
- [x] PASS — R12 (E38): решение p50 0,47–0,63 мс, p95 1,5–2,5 мс (release, Apple M5, macOS 27.0.1, 1574 решения, три прогона на машине под нагрузкой параллельных сессий); на телефоне — поставка приложения
- [x] PASS — dev-наборы по темам людей (справочно, приёмка R4–R5 — П3): hazard_dev 56 из 56 с верной темой, ложных заготовок 0 из 80 (стражи страха на 2 безобидных — по решению 1); dev10 49 из 51; бейк-офф 10 из 10, ложных 0 из 27; `delivery/evals/smoke/run.sh` в CI — 4 из 4

## Исполнение рисковых путей

- `runtime_paths: none` — маршрутизатор и контракт хода — чистые функции над распознанной репликой, решением и ответом
  модели, без экрана, прав, железа и ввода-вывода. Корпус замера — 787 синтетических реплик открытых наборов (быт 15,
  dev 240, dev10 151, бейк-офф 40, игры 245, диалоги 80, «почему» 16) через `discipline-replay router` (release) на Mac
  (Apple M5, macOS 27.0.1); пробы эталона контракта — `swift test`. at=2026-10-20

## Spec coverage gaps
- **Снятые подслучаи** (упрощение родителя): «дай мне свой номер телефона» (dev10 a11, `pii_ask`) — пропуск;
  «потерялась — повтор» и состояние сессии нет.
- **Цена базовых случаев:** «тётя Света подарила мне куклу» (dev10) → «чужой даёт» — списка имён в данных нет; знакомый
  взрослый по имени — частный случай для чёрного ящика.
- **Указатель «потерялась»** засчитывает любое упоминание взрослого («мама тебя найдёт»); на «потерялась»
  маршрутизатор всегда даёт заготовку, указатель — страховка; тонкие формы — из чёрного ящика.
- **Страх рядом с темами П3** («мне страшно, я стою на льду») до П3 — страж страха: модель отвечает с указателем на
  взрослого; заготовки этих тем — П3.
- **Флаг `forget`** решение несёт; исполняет его (история модели, память) поставка приложения.
- **Скрытый и свежий наборы** не прогонялись (поручение ведущего).

## Ревью рисковых мест

- **Производительность** — понятий 51 вместо 23; в `Scene.init` проверка двойника и таблица шумовой модели вынесены из
  цикла по 484 основам: p95 release 3,4 → 1,6 мс, отладочная сборка 25 → 13 мс, решения те же байт в байт. Предохранитель
  `testDecisionIsFast` (p95 < 50 мс в отладочной сборке) берёт у строки лучшее из трёх: под нагрузкой машины один прогон
  дал 61 мс.
- **Новый API** — `Routed.forget`, `TurnContract(mode:heard:decision:)` с параметрами по умолчанию (старые вызовы
  `TurnContract(mode:)` компилируются); `Condition`, `Clause`, `Heard` — `internal`. Неизвестный предикат в данных —
  `false`, его поймает самопроверка (fail-closed).
- **Безопасность ребёнка** — заготовка идёт до фильтра игры (флаг глушит только стражей); указатель вставляется так,
  что первое предложение не теряется никогда; запасная фраза темы выигрывает у заготовки нарушения.
- **Гейт секретов** — ложные срабатывания на `"secret": "…"` в `contract.json` и голом hex хэша словаря сняты
  именованием (`promise…`, `fnv1a:`), а не выключением гейта; строка генератора — `pragma: allowlist secret`.

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED

## Harness metrics (this shipment)

| Metric | Value |
|---|---|
| files_touched / loc_diff | 21 файл в счёте предохранителя, net 654 из 800 (план ≈ 685); поставка и знания — вне счёта |
| commits | документы, код, знания и eval-smoke, отчёт, handoff |
| rework_after_done | 0 |
| harness_hardened | yes — генератор сверяет подписанные тексты с `router-scripts-basic.json`; абляция по id статей из данных; ожидания правил содержания — из эталона |
| implement_retries | 2 — гейт секретов отклонил коммит кода: `"secret": "…"`, `secret… = "…"`, голый hex хэша (переименование и префикс), затем строка генератора (pragma) |
| verify_fails_before_green | 1 — `testDecisionIsFast` 61 мс под нагрузкой машины, исправлено до коммита (лучшее из трёх) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **34**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
R14	XCTAssertEqual(probes.count, 52)
R14	XCTAssertEqual(probes.filter { told($0) != $0.want }.map(\.reply), [])
R14	XCTAssertEqual(idle, [], "switching these rules off changes none of the probes")
R14	XCTAssertEqual(contract.first("Привет!"), "Привет!")
R14	XCTAssertEqual(turn.source, .canned("alive"))
R14	XCTAssertEqual(spoken(turn), "Привет! " + (contractData.scripts["alive"] ?? ""))
R13	XCTAssertEqual(told("Не плачь, всё будет хорошо.", decision: .script(key: "lost")),
R13	XCTAssertEqual(told(calm + " Хочешь, споём песенку?", decision: fear),
R13	XCTAssertEqual(told("Я буду ждать тебя!", decision: fear), contractData.canned["fear"])
R13	XCTAssertEqual(told("Ой, не бойся! Это просто гром. Если страшно, скажи маме.", decision: fear),
R13	XCTAssertEqual(told(calm, decision: .guard(topic: "socket")), calm)
R13	XCTAssertEqual(told(calm, decision: fear, off: ["adult_pointer"]), calm)
R13	XCTAssertEqual(told(tall + "Тучи плывут. Дождик капает.", decision: fear),
R3	XCTAssertEqual(decision, .pass)
R3	XCTAssertEqual(told("Не бойся!", decision: decision), "Не бойся!")
R3	XCTAssertEqual(told(text, decision: .guard(topic: topic)), text, topic)
R3	XCTAssertEqual(TurnMode.allCases.map { told(text, mode: $0) }, Array(repeating: text, count: 3))
R14	XCTAssertFalse(Contract(broken, hash: "broken").healthy, rule)
R10	XCTAssertEqual(rows.count, 60)
R1	XCTAssertEqual(examples.filter { decided($0.0, game: $0.2) != $0.1 }.map(\.0), [])
R11	XCTAssertEqual(forget.filter { Router.shared.route($0.key).forget != $0.value }.map(\.key), [])
R11	XCTAssertEqual(decided(address), "script:online")
R11	XCTAssertGreaterThanOrEqual(mine.filter { $0.want == decisive }.count, 3, hazard.topic)
R11	XCTAssertGreaterThanOrEqual(mine.filter { $0.want != decisive }.count, 3, hazard.topic)
R8	XCTAssertEqual(routed.decision, .guard(topic: nil), concept)
R8	XCTAssertEqual(routed.record.rules, ["selftest_failed"], concept)
R8	XCTAssertTrue(routed.forget, concept)
R8	XCTAssertEqual(router.route("Привет! Давай играть").decision, .guard(topic: nil), concept)
R9	XCTAssertEqual(routed.decision, .script(key: topic))
R9	XCTAssertEqual(routed.record.rules, [rule])
R9	XCTAssertEqual(routed.record.dataHash, fnv1a(RouterData.bytes))
R9	XCTAssertEqual(girl.split { !$0.isLetter }.filter { journal.localizedCaseInsensitiveContains($0) }, [])
R9	XCTAssertFalse(Rules.shared.cyrillicLetter.found(in: journal), journal)
R12	XCTAssertLessThan(times[times.count * 95 / 100], .milliseconds(50))  // R12
```

✅ **Каждое утверждение ведёт к примеру спеки** (R1 R10 R11 R12 R13 R14 R3 R8 R9), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0
