# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; V1–V10 подписаны родителем 2026-10-22 «Подписываю (Рекомендую)»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39988129358
**Commit:** f8262d5 (код, знание, исключение предохранителя; спека — 2285571, подпись — bbc9775, eval-smoke — 3c9d0fe; main влит до 8f938a6; эта сдача — следующим коммитом, PR #41)

## Shape oracles
- [x] PASS — pre-commit в CI (STRICT=1): `file-length` — 77 файлов по маске `*.swift *.py`, снимок 0; jscpd 4.0.5 —
  третья пара `AllyShell/Sources/ShellCore` + `ShellUI`, 9 файлов, 0 пар (и локально через `npx jscpd@4.0.5` до
  коммита — 0 клонов в обоих каталогах); SwiftLint 0.65.0 — 75 файлов, 0 находок (снимок 0); секреты; данные
  ребёнка; `gate-coverage`
- [x] PASS — правило `child_screen_text` (V10): канарейка `scripts/lint/canaries.json` — ратчет SwiftLint exit 1
  («находки выросли 0 → 1», errors 1), без неё — exit 0; доктор в CI —
  `AUTO 46 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений (43 файла); `okf_sync_gate.py --base origin/main`: 9
  концептов с `implementation:` сверены (`product/look-and-feel` — `Pose`, `Layout`, `Palette`;
  `engineering/character-rendering` — `Frame` и `ShellUI`)
- [x] PASS — строгий `delivery_check --diff-base origin/main`: 0 ошибок; предохранитель — 17 файлов, net 946 при
  исключении `max_loc_diff=1000` (подпись родителя 2026-10-23, вариант A `escalation.md`; только Ш1). Предупреждение
  «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а реляционный оракул здесь — свойство V9
  (ни один параметр кадра не прыгает за 1/120 с внутри фазы; ожидаемых чисел в нём нет)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27.1, Swift 6.4, macOS 27): `ShellCoreTests` 8 из 8 (V1–V7, V9),
  `ShellUITests` 1 из 1 (V8: семь PNG 1320×2868 и `sheet.png`). CI на Linux (swift-6.4-RELEASE), джоба `swift`:
  AllyShell — 4 файла `Sources/` (`ShellCore`), 140 из 156 строк, 89%; `ShellUI` на Linux пуст под
  `#if canImport(SwiftUI)`, тест снимков пропущен с причиной; отрицательный контроль порогом 101% покраснел
- [x] PASS — мутации в ту же сессию (П30), 9 из 9 убиты, файлы восстановлены: без упора `w − 48` (V6: 272 → 275,2);
  контур розовым #F28DB2 (V7: 4,54 → 2,04); глаза спящей открыты (V1, V5); `windingDown` как `thinking` (V2, V5); рот
  0,05 + 0,9·a (V4); волна жабр ступенькой (V9: 2634 нарушения); обод цветом контура (V8, 14 проб); рот открыт у
  слушающей (V8); глаза нарисованы открытыми у спящей (V8: 1428 > 500 pt²). Мутация «яблоко глаза видно всегда»
  не покраснела — её маскирует сжатие глаза по `eyeOpen` (0,06); заменена на «глаза нарисованы открытыми» (урок L64)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода; облик — снимки, которые родитель утвердил на зонде

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-22 «Подписываю (Рекомендую)»); подпись — отдельным коммитом
  `bbc9775` раньше кода `caaad38` (L33)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (V1–V10)
- [x] PASS — облик: лист семи фаз `local/shell-snapshots/sheet.png` (вне git) повторяет снимки зонда, утверждённые
  родителем, в объёме Ш1 — без ночи, свечения, пузырьков и венка (Ш2а, Ш2б, Ш3); снимков экрана телефона нет (L46)

## Исполнение рисковых путей

- `runtime_paths: none` — пакет SwiftPM без приложения: позы, кадры, раскладка и палитра — тестами на Linux и Mac,
  рисунок — снимками `ImageRenderer` на Mac; экран в приложении на телефоне — Ш3. Исполнение —
  `swift test --disable-keychain --package-path Packages/AllyShell` на Mac (macOS 27) и в CI на Linux. at=2026-10-23

## Spec coverage gaps
- **Движение и свет** — Ш2а и Ш2б: пружины между позами, моргание, приветствие и прощание с зевком, ночь и оттенки,
  свечение и жемчужинки, пузырьки, ритм рта, частота кадров по позе. План Ш2 ≈ 600 с поправкой +50% ≈ 900 > 800 —
  поэтому две поставки (решение ведущего: «режь по 800 заранее»).
- **Венок и экран в приложении** — Ш3 после мержа R: тело `ChildScreen` R, тап → `onWake`, значок стопа → `onStop`,
  метка «при родителе · до …», перерыв после прощания по лимиту, замер бюджета на телефоне.
- **Бюджет анимации на телефоне** (память +10 МБ, рывки, скорость модели ≥ 95%, нагрев) — не мерился: экрана в
  приложении нет до Ш3; цели и способ — в спеке.

## Ревью рисковых мест

- **Публичный API:** `ShellCore` — `Pose.at`, `Frame.at` и `Frame(_:time:)`, `Gill.all`, `Layout`, `Point`, `Box`,
  `Tone`, `Border`, `Palette`; `ShellUI` — `ShellScene(phase:time:voice:mic:safeTop:safeBottom:)`. Входом служит фаза
  `SessionState` и `TalkState.pose` из AllyCore — своих перечислений нет.
- **Платформы:** `ShellCore` — только Foundation и AllyCore (CoreGraphics не нужен: свои `Point`, `Box`); `ShellUI` —
  целиком под `#if canImport(SwiftUI)`, иначе джоба `swift` на Linux упала бы на `import SwiftUI`.
- **Безопасность ребёнка:** экран ничего не решает и ничего не говорит; ни одной надписи — правило `child_screen_text`
  с канарейкой; сети и ассетов нет.
- **Данные:** на снимках только Элли; снимки — в `local/` (игнор git).

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 21 code (+12 process docs) / +963/-8 (net +955); предохранитель — 17 файлов, net 946 при исключении 1000 |
| commits | 9 до сдачи (спека, подпись, eval-smoke, два слияния main, первый код, рисунок, знание и стоп, исключение); сдача — десятым |
| time_to_accepted_spec | 0.1h |
| rework_after_done | 0 |
| harness_hardened | yes — правило SwiftLint `child_screen_text` с канарейкой, третья пара jscpd, шаг AllyShell в `ios.yml`, пакет в `LINT_SWIFT_PACKAGES` |
| implement_retries | 2 — сборка `CGRect` без CoreGraphics (свои `Point`, `Box`); строки длиннее 120 под ратчетом SwiftLint |
| verify_fails_before_green | 0 — первый прогон CI 39988129358 зелёный (delivery, swift, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **66**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
V6	XCTAssertEqual(phone.diameter, 378.4, accuracy: 0.001)
V6	XCTAssertEqual(phone.centre.x, 220, accuracy: 0.001)
V6	XCTAssertEqual(phone.centre.y, 535, accuracy: 0.001)
V6	XCTAssertEqual(phone.bottomGap, 231.8, accuracy: 0.001)
V6	XCTAssertEqual(phone.sideGap, 30.8, accuracy: 0.001)
V6	XCTAssertEqual(phone.stopTarget.midX, 402, accuracy: 0.001)
V6	XCTAssertEqual(phone.stopTarget.midY, 84, accuracy: 0.001)
V6	XCTAssertEqual(phone.stopTarget.width, 44)
V6	XCTAssertEqual(phone.centre.y - phone.diameter / 2 - phone.stopTarget.maxY, 239.8, accuracy: 0.001)
V6	XCTAssertEqual(narrow.diameter, 272, accuracy: 0.001)
V6	XCTAssertEqual(narrow.sideGap, 24, accuracy: 0.001)
V6	XCTAssertEqual(narrow.centre.y, 292, accuracy: 0.001)
V6	XCTAssertEqual(narrow.bottomGap, 140, accuracy: 0.001)
V6	XCTAssertGreaterThanOrEqual(Layout(width: 200, height: 400).diameter, 240)
V7	XCTAssertEqual(border.line.contrast(with: border.fill), ratio, accuracy: 0.005)
V7	XCTAssertEqual(Palette.borders.count, expected.count)
V7	XCTAssertTrue(Palette.borders.allSatisfy { $0.line.contrast(with: $0.fill) >= 3 })
V7	XCTAssertEqual(Tone(0xF28DB2).contrast(with: Palette.blossom), 2.06, accuracy: 0.005)
V1	XCTAssertEqual(pose.eyesShut, 1)
V1	XCTAssertEqual(frame.eyeballs, 0)
V1	XCTAssertEqual(frame.lids, 1)
V1	XCTAssertEqual([pose.gillLift, pose.gillSpread], [-16, -4])
V1	XCTAssertEqual(pose.headTilt, 9, accuracy: 1)
V1	XCTAssertEqual([pose.mouthOpen, pose.smile, pose.bodyY], [0, 0.8, 10])
V1	XCTAssertEqual(period, 4.83, accuracy: 0.005)
V1	XCTAssertGreaterThanOrEqual(period, 3)  // rule 10: a resting loop of 3 s or longer
V1	XCTAssertEqual(breaths.max() ?? 0, 0.028, accuracy: 0.0001)
V1	XCTAssertEqual(breaths.min() ?? 0, -0.028, accuracy: 0.0001)
V1	XCTAssertEqual(Frame.at(.asleep, time: 1 + period).breath, Frame.at(.asleep, time: 1).breath, accuracy: 1e-9)
V2	XCTAssertEqual([pose.gillLift, pose.gillSpread, pose.gillScale, pose.gillFlutter],
V2	XCTAssertEqual(pose.headTilt, 8, accuracy: 1.2)
V2	XCTAssertEqual([pose.eyeWide, pose.browY, pose.armLeft, pose.armRight, pose.mouthOpen],
V2	XCTAssertEqual(Pose.at(.windingDown, time: t, mic: mic), pose)
V2	XCTAssertEqual(Frame.at(.windingDown, time: t, mic: mic), Frame.at(.listening, time: t, mic: mic))
V2	XCTAssertEqual(Gill.spread.map { $0 * 10 }, [10, 3, -6])
V3	XCTAssertEqual(pose.eyeY, -7.5)
V3	XCTAssertEqual(pose.eyeX, 4, accuracy: 1.2)
V3	XCTAssertEqual(pose.armRight, 126, accuracy: 3)
V3	XCTAssertEqual([pose.armLeft, pose.mouthWidth, pose.smile, pose.gillCount], [18, 0.6, 0.6, 1])
V4	XCTAssertEqual(pose.mouthOpen, mouth, accuracy: 1e-9)
V4	XCTAssertEqual(pose.gillLift, 2 + 3 * voice, accuracy: 1e-9)
V4	XCTAssertGreaterThanOrEqual(pose.armLeft, 24 + 9 * voice - 1e-9)
V4	XCTAssertLessThanOrEqual(pose.armLeft, 24 + 30 * voice + 1e-9)
V4	XCTAssertEqual(Pose.at(.speaking, time: 3).mouthOpen, 0.62, accuracy: 1e-9)
V4	XCTAssertEqual(Pose.at(phase, time: t).armRight, -128, accuracy: 20 + 1e-9)
V4	XCTAssertEqual(Pose.at(phase, time: crest).armRight, -108, accuracy: 1e-9)
V4	XCTAssertEqual(Pose.at(phase, time: 3 * crest).armRight, -148, accuracy: 1e-9)
V5	XCTAssertEqual(Set(phases), Set(expected.keys))
V5	XCTAssertEqual(TalkState(phase: phase).pose, expected[phase])
V5	XCTAssertEqual(greeting, speaking)
V5	XCTAssertEqual(goodbye, speaking)
V5	XCTAssertEqual(Pose.at(.windingDown, time: t), Pose.at(.listening, time: t))
V5	XCTAssertEqual(phases.filter { Pose.at($0, time: t).eyesShut == 1 }, [.asleep])
V5	XCTAssertEqual(phases.filter { Pose.at($0, time: t).gillCount == 1 }, [.thinking])
V9	assertClose(frame.angles, previous.angles, within: 1.5, phase)
V9	assertClose(frame.offsets, previous.offsets, within: 0.5, phase)
V9	assertClose(frame.shares, previous.shares, within: 0.05, phase)
V9	private func assertClose(_ now: [Double], _ before: [Double], within bound: Double, _ phase: SessionState) {
V9	if jump > bound { XCTFail("\(phase): jump \(jump) > \(bound)") }
V8	XCTAssertEqual([image.width, image.height], [1320, 2868])
V8	if phase == .asleep { XCTAssertLessThanOrEqual(eyes, 500, "\(phase)") } else {
V8	XCTAssertGreaterThanOrEqual(eyes, 1000, "\(phase)")
V8	if TalkState(phase: phase).pose == .speaks { XCTAssertGreaterThanOrEqual(mouth, 100, "\(phase)") } else {
V8	XCTAssertLessThanOrEqual(mouth, 85, "\(phase)")
V8	XCTAssertTrue(near(rim, 0xC2185B, 12), "\(phase) rim \(rim)")
V8	XCTAssertTrue(CGImageDestinationFinalize(target))
```

✅ **Каждое утверждение ведёт к примеру спеки** (V1 V2 V3 V4 V5 V6 V7 V8 V9), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
