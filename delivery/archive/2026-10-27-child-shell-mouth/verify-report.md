# Verify report

**Date:** 2026-10-27
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примеру спеки — дайджест ниже, asserts_without_example: 0; V34 подписан родителем 2026-10-23 одной подписью с Ш3 и Ш2б)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40566339179
**Commit:** 737bdce (документы — 4c025b9, eval-smoke до кода — 2c8f2ae, код — 390e1bf, уроки по путям — 194f4bc, разностная сверка V34 — 11a83da; main влит до 8ef99ea); сдача — 12b787a, её CI 40567599453 зелёный; попутная починка macOS-сборки по слову ведущего — 59a6be3, main влит до 8fe4bf2; PR #80

## Shape oracles
- [x] PASS — pre-commit (STRICT=1) в CI и локально: `file-length` в снимке 0; jscpd — рост 0; SwiftLint 0.65.0 —
  0 находок (`--strict` по `Packages/AllyShell`, ратчет 0); секреты; данные ребёнка; `gate-coverage`
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: 18 концептов сверены —
  `engineering/character-rendering` (`implementation:` += `Syllables.swift`) и `product/look-and-feel` правлены в том
  же диффе
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 6 файлов, net 147
  (+163/−16) из 800, исключений нет: Ш2в — 4 файла, net 140, попутная починка macOS — 2 файла тестов, +7. Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и
  fast-check, а реляционные оракулы здесь есть:
  - свойство V12/V35: на 100 случайных сценариях с зерном ничто не прыгает между кадрами, теперь в половине из них —
    ритм; ожидаемых чисел нет;
  - разностная сверка: уровень `Motion` равен уровню `Syllables` того же зерна кадр в кадр.

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27.1, Swift 6.4, под `nice -n 10`): `ShellCoreTests` — 30 из 30 (V34 — 2
  теста; прежние без правок, кроме сценариев V12/V35 и шага с явным типом в V32), `ShellUITests` — 4 из 4. CI на Linux, джоба `swift`: AllyShell —
  12 файлов `Sources/`, строк 681 из 683, 99% (порог 70%)
- [x] PASS — мутации в ту же сессию (П30, L64 — по видимому эффекту): 7 из 7 убиты, файлы восстановлены.
  - «Без следования»: шаг рта за кадр 0,233 при границе 0,09.
  - «Пауза фразы как пауза слова»: 47 слогов одной серией, фраз нет.
  - «Ритм и в других фазах»: уровень в `listening` 0,82, не совпадает с генератором.
  - «Переданный уровень заменён ритмом»: уровень 0 вместо 0,3, рот 0,05 вместо 0,335.
  - «Ритм только в `speaking`»: в `greeting` уровень 0 против генератора.
  - «Ровный уровень 0,6 вместо ритма»: 0,6 против генератора.
  - «Сброс вместо гашения»: V12 красный на сценарии 0 в 6,71 с, скачок долей — 2,41 границы.
- [x] PASS — замер генератора в Swift на 500 зёрнах до выбора зерна теста (L37): у всех 39–44 слога (39 — 1, 40 — 43,
  41 — 122, 42 — 203, 43 — 114, 44 — 17), рот ≥ 0,586 в каждую секунду, в паузе фразы ≤ 0,052, шаг за кадр ≤ 0,0889.
  У модели 23.10 на Python у одного зерна было 45, здесь это не повторилось. Зерно теста — 1 (43 слога, без подбора)
- [x] PASS — тесты зелёные с первого прогона. Порог «размах рта за 2 с больше 0,4» в проверке `Motion` был придуман
  под замер, а не взят из примера. Его заменила разностная сверка с генератором (решение в `decisions.md`); мутации
  повторены на новом тесте
- [x] PASS — попутная починка по слову ведущего. macOS-джоба (Xcode 26.6, прогон 40567351117 на PR #79) не проверила
  типы выражения `SnapshotTests.swift:218` (код Ш2б из main) за разумное время.
  - Подсчёт пикселей разбит на шаги с явными типами (`pixel(at:)`); заодно диапазон из литералов в
    `BubblesTests.swift:32`.
  - Swift 6.3.2 (CLT, ближайший к раннеру компилятор на этом Mac): выражение в изоляции — 851 мс до правки и 1–2 мс
    после (на Swift 6.4 — 4 мс, поэтому локально и собиралось).
  - Чистая сборка пакета на 6.3.2: в AllyShell ни одного выражения дольше 60 мс (было 256 мс у `BubblesTests:32`).
  - Xcode 27.1: тесты зелёные, пробы V8, V18, V21, V36 — прежние.
  - Саму macOS-джобу запускает метка `macos` — решение ведущего.
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  пример, подписанный родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23, одной подписью с Ш3 и Ш2б); пример — таблицей со ссылкой на
  коммит спеки серии (L51), новых примеров сверх подписанного нет
- [x] PASS — пример спеки: факт — `eval-smoke.md` (V34)
- [x] PASS — снимков экрана телефона нет (L46); рот на глаз родителя — общая сессия теста

## Исполнение рисковых путей

- `runtime_paths: none` — пакет SwiftPM без правок приложения: ритм рта — генератор и уровень кадра с тестами на Linux и
  Mac; экран на телефоне — общая сессия теста (слово родителя 27.10: «тесты на телефоне — потом»). at=2026-10-27

## Spec coverage gaps
- **Телефон:** рот по слогам рядом с голосом на глаз родителя — общая сессия теста.
- **Рот по настоящему звуку** — вне Ш2в: когда голос отдаст огибающую фразы, она пойдёт полем уровня «как есть».
- **macOS-сборка вне AllyShell:** на Swift 6.3.2 дольше 60 мс проверяется одно выражение — `AllyCore`
  `ReleaseGate.swift:137` (93 мс); на раннере оно собирается, чужую поставку не трогал.

## Ревью рисковых мест

- **Публичный API:** `Syllables` (`Syllable`, `level`, `current`, `step(_:at:speaking:)`), `Motion.voiceLevel`.
- **Смена поведения:**
  - без уровня голоса поза «говорит» раньше держала ровные 0,6 (рот 0,62), теперь — ритм;
  - после прощания бодрая часть дремоты гаснет к закрытому рту до зевка, а не держит 0,62 — V15 без правок зелёный;
  - `Pose.defaultVoice` (V4) остаётся для неподвижного кадра `Frame.at`.
- **Безопасность ребёнка:** экран ничего не говорит; вспышек нет — рот следует за огибающей и гаснет без скачка (V12).
- **CI:** первый пуш (194f4bc) не запустил CI вовсе — main ушёл на 8ef99ea (`log.md`), и PR стал CONFLICTING, а
  `merge=union` GitHub не применяет (L35). main влит локально сложением, CI пошёл на 737bdce.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 6 кода (+9 документов и знания) / +163/−16 (net +147): Ш2в — net 140 при плане ≈ 140 (с поправкой +50% было бы ≈ 210), починка macOS — +7 |
| commits | 10 (документы, eval-smoke, код, уроки по путям, разностная сверка, слияние main, сдача, починка macOS-выражений, слияние main, правка отчёта) |
| time_to_accepted_spec | 0h (подписано 23.10 вместе с Ш3 и Ш2б) |
| rework_after_done | 0 |
| harness_hardened | yes — `SyllablesTests` (новый оракул), сценарии V12/V35 с ритмом |
| implement_retries | 2 — три строки длиннее 120; порог 0,4 заменён разностной сверкой |
| verify_fails_before_green | 0 — прогоны CI этого PR 40566339179 и 40567599453 зелёные (пуш 194f4bc CI не запустил: PR в конфликте); красная macOS-джоба — на PR #79, починена здесь |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **16**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
V34	XCTAssertTrue((39...44).contains(spoken.count), "\(spoken.count) syllables")
V34	XCTAssertTrue(spoken.allSatisfy { (0.16...0.22).contains($0.end - $0.start) && (0.62...1).contains($0.peak) })
V34	XCTAssertTrue(gaps.allSatisfy { gap in [0, 0.06, 0.36].contains { abs(gap - $0) < 1e-9 } }, "\(gaps)")
V34	XCTAssertTrue(words.allSatisfy { (1...4).contains($0) }, "\(words)")
V34	XCTAssertTrue(phrases.count >= 3 && phrases.dropLast().allSatisfy { (8...14).contains($0) }
V34	XCTAssertGreaterThanOrEqual(opens.max() ?? 0, 0.55, "second \(second)")
V34	XCTAssertLessThanOrEqual(opens.min() ?? 1, 0.1, "the phrase's pause at \(last.end)")
V34	XCTAssertLessThanOrEqual(zip(mouth, mouth.dropFirst()).map { abs($1.open - $0.open) }.max() ?? 1, 0.09)
V34	XCTAssertEqual(level, rhythm.step(step, at: time, speaking: speaks), accuracy: 1e-12, "\(phase)")
V34	XCTAssertLessThanOrEqual(level, 0.001, "\(phase)")
V34	XCTAssertEqual(pose.mouthOpen, 0.05 + 0.95 * level, accuracy: 0.01)
V34	XCTAssertEqual(pose.headY, -2.2 * level, accuracy: 0.01)
V34	XCTAssertEqual(pose.gillLift, 2 + 3 * level, accuracy: 0.01)
V34	XCTAssertTrue(level < 0.1 || (8.9...30.1).contains((pose.armLeft - 24) / level), "\(phase)")
V34	XCTAssertEqual(motion.voiceLevel, 0.3)
V34	XCTAssertEqual(motion.step(step, phase: .speaking, voice: 0.3).pose.mouthOpen, 0.335, accuracy: 0.01)
```

✅ **Каждое утверждение ведёт к примеру спеки** (V34), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
