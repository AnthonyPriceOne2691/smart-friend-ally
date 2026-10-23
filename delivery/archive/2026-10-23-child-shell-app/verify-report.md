# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; V19–V36 подписаны родителем 2026-10-23 «Подписываю (Рекомендую)», перерыв — «Без перерыва»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40016563898
**Commit:** db68e91 (код и знание — 3e1e195, факты eval-smoke — 8f2eaef; спека — 4c61d3c, подпись — 48b39f7, eval-smoke до кода — 26d43d3; main влит до 1b70868, после сдачи — до f0d62ef; сдача — следующим коммитом, PR #61)

## Shape oracles
- [x] PASS — pre-commit (STRICT=1) в CI и локально: `file-length` по маске `*.swift *.py`, снимок 0; jscpd — пара
  `AllyShell/Sources` `ShellCore` + `ShellUI`, 0 пар; SwiftLint 0.65.0 — 126 файлов, 0 находок (снимок 0) с новым
  правилом `child_screen_gestures`; секреты; данные ребёнка; `gate-coverage`
- [x] PASS — `okf_validate.py`: 0 ошибок (48 файлов); `okf_sync_gate.py --base origin/main`: 15 концептов сверены —
  `engineering/character-rendering`, `product/look-and-feel`, `product/session-limit`, `engineering/voice-loop`,
  `engineering/safety-below-model`, `references/repo-map` правлены в том же диффе (плюс `product/child-mode`,
  `engineering/session` — места L16, L70)
- [x] PASS — строгий `delivery_check --diff-base origin/main`: 0 ошибок; предохранитель — 22 файла, net 653 из 800, без
  исключений. Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а реляционные
  оракулы здесь — свойство V20 (блёстки вразнобой: разброс яркостей в каждый момент 60 с) и V12 Ш2а (непрерывность на 100
  сценариях с зерном, теперь и со сжатием тела в долях кадра)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27.1, Swift 6.4, macOS 27, под `nice -n 10`): `ShellCoreTests` 22 из 22 (V1–V7,
  V9, V11–V17 без правок; V19, V20, V22–V26), `ShellUITests` 3 из 3 (V8 и V18 без правок порогов, V21). CI на Linux,
  джоба `swift`: AllyShell — 9 файлов Sources/, строк 374 из 375, 99% (порог 70%); `ShellUI` на Linux пуст, тесты снимков пропущены с причиной
- [x] PASS — мутации в ту же сессию (П30, L64 — по видимому эффекту), 10 из 10 убиты, файлы восстановлены: блёстки в такт
  (V20: разброс 0); «говорит → разбудить» и попадание без радиуса (V22); сжатие без затухания (V23: 0,913); ключ 181 принят
  и по умолчанию 60 (V24); перерыв не начат после лимита и `<=` вместо `<` в срок (V25); венок не нарисован (V21: зелень
  0) и метка без срока (V21: 1812 pt²)
- [x] PASS — канарейки (V27): `LongPressGesture` в `ShellUI` и `onTapGesture(count: 2)` в `App/Sources/ChildScreen.swift`
  — ошибка `child_screen_gestures`; текст в `ShellUI` вне файла зоны взрослых — ошибка `child_screen_text`
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23 «Подписываю (Рекомендую)», Ш3 и Ш2б одной подписью; перерыв —
  «Без перерыва»); подпись — отдельным коммитом `48b39f7` раньше кода (L33)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (V19–V28; V29 — общая сессия теста, waiver)
- [x] PASS — облик экрана: снимки `local/shell-snapshots/app/` (вне git) — Элли с венком в пузыре, плашка «при родителе ·
  до 29.10 в 21:00» и стоп сверху справа, как на снимке зонда, подписанном родителем; снимков экрана телефона нет (L46)

## Артефакт (V28)

- `xcodebuild -project Ally.xcodeproj -scheme Ally -destination 'generic/platform=iOS' -derivedDataPath build
  -packageAuthorizationProvider netrc CODE_SIGNING_ALLOWED=NO build` — BUILD SUCCEEDED; в собранном `Info.plist`
  `CADisableMinimumFrameDurationOnPhone` = true, `CFBundleShortVersionString` 0.1 и `CFBundleVersion` 1 — как до Ш3;
  `bash scripts/lint/check_app_artifact.sh` — OK (4 бинаря, сети нет, права без подписи не проверены); мутация «Info.plist
  без ключа» — ERROR. at=2026-10-23
- После слияния main до f0d62ef (D7.2 добавила пакет `AllyHearing` в приложение) — пересборка тем же `xcodebuild`:
  BUILD SUCCEEDED; `check_app_artifact.sh` — OK (6 бинарей, сети нет). at=2026-10-23

## Исполнение рисковых путей

- `App/Sources/*.swift` — исполнено на Mac сборкой приложения без подписи и оракулом артефакта (блок выше); экран
  целиком — снимками `ImageRenderer` той же `ChildShell` и `AdultZone`. На телефоне (тап, «я всё», стоп, перерыв по
  ключу, 120 Гц, замер бюджета) не исполнено: проверки на телефоне — в общую сессию теста, решение родителя 2026-10-23 —
  «Да, всё в общую сессию (Рекомендую)» (waiver V29 в STATUS). at=2026-10-23

## Spec coverage gaps
- **Телефон (V29):** экран в приложении, тап, «я всё», стоп, перерыв по ключу, системные полоски и «Гид-доступ», 120 Гц
  (Instruments), замер бюджета по таблице Ш1 — общая сессия теста.
- **Свет и пузырьки, «Z» на тап по спящей, ритм рта** — Ш2б (примеры V30–V36 подписаны, таблицей — в её спеку).

## Ревью рисковых мест

- **Публичный API:** `Crown` (данные, `twinkle`, `tempo`), `Tap` (`action`, `label`), `Layout.hits(x:y:)`, `Nap`,
  `Motion.poke`, `Frame.glints` и `Frame.squash`, `ChildShell`, `AdultZone`, `LiveScene(pokes:)`. `Frame.at` и
  `ShellScene(phase:time:)` Ш1 — без изменений поведения, кроме венка на голове.
- **Стык R:** `ChildScreen(talk:until:onWake:onStop:)` не менялся; `VoiceLoop.childWake` — запрет пробуждения в перерыв
  после сверки доступа (срок проверяется раньше перерыва), `show` начинает перерыв на конце детской сессии; строка
  консоли «перерыв до …» — только при ключе больше 0.
- **Безопасность ребёнка:** экран ничего не говорит и путь реплики не меняет (зовёт `wake` и `done`); надписи — только в
  зоне взрослых (правило `child_screen_text` с исключением одного файла), жесты — только тап.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 22 (21 кода и `.gitignore`; +12 документов и знания) / +696/-43 (net +653); предохранитель — 22 файла, net 653 из 800 |
| commits | 7 до сдачи (спека, подпись, два слияния main, eval-smoke, код, факты); сдача — следующим |
| time_to_accepted_spec | 1h |
| rework_after_done | 0 |
| harness_hardened | yes — правило SwiftLint `child_screen_gestures` с канарейкой, ключ 120 Гц в оракуле артефакта, тесты `CrownTests`, `TapTests`, `NapTests`, экран целиком V21 |
| implement_retries | 2 — `Layout` неоднозначен с протоколом SwiftUI в позиции типа; ключ версий в Info.plist XcodeGen |
| verify_fails_before_green | 0 — первый прогон CI 40016563898 зелёный |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **53**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
V19	XCTAssertEqual([kinds[.rose], kinds[.carnation], kinds[.lisianthus]], [7, 7, 8])
V19	XCTAssertLessThanOrEqual(gap, 0.2, "no mirror for \(flower.x), \(flower.y)")
V19	XCTAssertEqual(Crown.flowers.filter { abs($0.x) <= 0.1 }.count, 2)
V19	XCTAssertEqual(Crown.flowers.map(\.x).reduce(0, +) / Double(Crown.flowers.count), 0, accuracy: 0.1)
V19	XCTAssertEqual([Crown.leaves.count, Crown.leaves.filter(\.dark).count], [22, 11])
V19	XCTAssertEqual([Crown.leafLength, Crown.leafWidth], [8.2, 3.8])
V19	XCTAssertEqual([stars.count, dots.count], [44, 12])
V19	XCTAssertEqual((0..<3).map { tone in stars.filter { $0.tone == tone }.count }, [11, 22, 11])
V19	XCTAssertEqual(seat.left, -68.8, accuracy: 0.5)
V19	XCTAssertEqual(seat.right, 78.9, accuracy: 0.5)
V19	XCTAssertEqual(seat.top, -143, accuracy: 0.5)
V19	XCTAssertEqual(seat.bottom, -85.7, accuracy: 0.5)
V19	XCTAssertLessThan(seat.bottom, -74 - 5)  // above the brows even in a yawn (brows at −74, −5 higher)
V20	XCTAssertGreaterThanOrEqual(spread, 0.5)
V20	XCTAssertTrue(lows.allSatisfy { $0 >= 0.35 - 1e-9 && $0 <= 0.40 }, "\(lows)")
V20	XCTAssertTrue(highs.allSatisfy { $0 >= 0.95 && $0 <= 1 + 1e-9 }, "\(highs)")
V20	XCTAssertTrue((0..<count).allSatisfy { (1.4...3.2).contains(Crown.tempo($0)) })
V20	XCTAssertTrue((0..<count).allSatisfy { Crown.twinkle($0, at: 7.3, calm: true) == 0.8 })
V23	XCTAssertEqual(1 + squash, height, accuracy: 0.005, "calm \(calm)")
V23	if !calm { XCTAssertEqual(1 - 0.75 * squash, 1.042, accuracy: 0.005) }
V23	XCTAssertTrue(shots.dropFirst(71).allSatisfy { abs($0.squash) <= 0.005 })
V23	XCTAssertTrue(zip(shots, shots.dropFirst()).allSatisfy { abs($1.squash - $0.squash) <= 0.01 })
V23	XCTAssertTrue(shots.allSatisfy { abs($0.eyeOpen - 0.06) < 1e-9 && $0.pose.eyesShut == 1 })
V24	XCTAssertEqual(Nap().minutes, 0)
V24	XCTAssertNil(Nap().note)
V24	XCTAssertEqual(Nap(raw: raw).minutes, minutes, raw)
V24	XCTAssertNil(Nap(raw: raw).note, raw)
V24	XCTAssertEqual(Nap(raw: raw).minutes, 0, raw)
V24	XCTAssertEqual(Nap(raw: raw).note, "перерыв вне 0–180 мин — взято 0", raw)
V25	XCTAssertFalse(none.holds(at: end + 1))
V25	XCTAssertNil(none.line(at: end + 1, zone: moscow))
V25	XCTAssertTrue(nap.holds(at: end + 3599))
V25	XCTAssertEqual(nap.line(at: end + 3599, zone: moscow), "перерыв до 18:40")
V25	XCTAssertFalse(nap.holds(at: end + 3600))
V25	XCTAssertNil(nap.line(at: end + 3600, zone: moscow))
V25	XCTAssertFalse(other.holds(at: end + 1), reason)
V25	XCTAssertFalse(running.holds(at: end + 1))
V25	XCTAssertEqual(nap.line(at: end + 7300, zone: moscow), "перерыв до 20:40")
V22	XCTAssertTrue(phone.hits(x: 220, y: 535))
V22	XCTAssertTrue(phone.hits(x: 220, y: 724))
V22	XCTAssertFalse(phone.hits(x: x, y: y), "\(x), \(y)")
V22	XCTAssertEqual(Tap.action(phase), action, "\(phase)")
V26	XCTAssertEqual(Tap.label(until: until, zone: moscow), "при родителе · до 29.10 в 21:00")
V26	XCTAssertNil(Tap.label(until: nil, zone: moscow))
V21	XCTAssertGreaterThanOrEqual(leaves, 100, "\(phase)")
V21	XCTAssertLessThanOrEqual(probe.area(where: leaf) - leaves, 5, "\(phase)")
V21	XCTAssertGreaterThanOrEqual(probe.area(in: stop, where: plum), 500, "\(phase)")
V21	XCTAssertGreaterThanOrEqual(probe.area(in: plate, where: white), 1500, "\(phase)")
V21	XCTAssertTrue(phase == .asleep ? eyes <= 500 : eyes >= 1000, "\(phase) eyes \(eyes)")
V21	XCTAssertTrue(speaks ? mouth >= 100 : mouth <= 85, "\(phase) mouth \(mouth)")
V21	XCTAssertLessThanOrEqual(bare.area(in: plate, where: white), 100)
V21	XCTAssertGreaterThanOrEqual(bare.area(in: stop, where: plum), 500)
V21	XCTAssertNotNil(ImageRenderer(content: live.frame(width: phone.width, height: phone.height)).cgImage)
```

✅ **Каждое утверждение ведёт к примеру спеки** (V19 V20 V21 V22 V23 V24 V25 V26), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
