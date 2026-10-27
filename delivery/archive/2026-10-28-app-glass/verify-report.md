# Verify report

**Date:** 2026-10-28
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; F1–F5 подписаны родителем 2026-10-27; порог дня V36 0,75 — решение родителя 2026-10-28, by=human:anthony)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40594040906
**Commit:** e15f86a (спека — 28ad32a, подпись — 9dc5792, eval-smoke до кода — 6984984, код — 73e6457, знание и уроки — 7e60272, 377c764, F3 на раннере — 0ee551e; main влит до 7b9aa9e); macOS-джоба по метке на образе `xcode-27` — https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40594112814; сдача — следующим коммитом, PR #85

## Shape oracles
- [x] PASS — pre-commit (STRICT=1) в CI и локально: `file-length`, jscpd — рост 0; SwiftLint 0.65.0 `--strict` — 0
  находок (ратчет 0); секреты; данные ребёнка; `gate-coverage`
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: 18 концептов сверены. В том
  же диффе правлены `product/look-and-feel`, `engineering/character-rendering`, `engineering/voice-loop` (цель iOS 27,
  образ `xcode-27`, консоль в стекле) и `references/repo-map`
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 11 файлов, net
  291 из 800 (план ≈ 250, с поправкой рисунка ≈ 375). Предупреждение «нет реляционного оракула»: детектор знает только
  hypothesis и fast-check, а реляционный оракул здесь — F3: пробы на настоящем стекле и без стекла совпадают в пределах
  10% (замер ≤ 2,9%), ожидаемых чисел нет

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27.1, macOS 27.0.1, под `nice -n 10`): `ShellCoreTests` 32 из 32 (V7, F1),
  `ShellUITests` 7 из 7 (V8, V18, V21, V36, F2, F3, F4). CI на Linux, джоба `swift`: AllyShell — 12 файлов `Sources/`,
  строк 683 из 685, 99% (порог 70%); `ShellUI` на Linux пуст, снимки и стекло пропущены с причиной
- [x] PASS — ручная macOS-джоба по метке `macos` на образе `xcode-27` (Xcode 27.1, 27A9275): пакеты, AllyShell со
  снимками и настоящим стеклом (F3, F4 сняты, не пропущены), сборка `Ally.app` — BUILD SUCCEEDED, оракул артефакта — OK
- [x] PASS — мутации в ту же сессию (П30, L64 — по видимому эффекту), 7 из 7 убиты, файлы восстановлены:
  - F1 «сиреневый огонь `#C9A0F0`» — обод 2,7:1;
  - F2 «верх и голубой огонь розовые» — синий выше красного на 0,88 при пороге 20. Одиночная «верх розовый» выжила:
    голубизну полосы держит и голубой огонь — поэтому мутация берёт оба;
  - F3 «плашка без белой подложки» — на стекле белого 0 (V21 на `ImageRenderer` тоже краснеет);
  - F3 «знак без сливы» — сливы 0;
  - F4 «недоступная не бледнеет» — 155,75 pt² сливы; F4 «высота 36» — 36 pt;
  - F5 «MinimumOSVersion 26.0» — оракул артефакта на поддельном Info.plist отказывает.
- [x] PASS — красное по делу, пороги примеров не менялись:
  - первый прогон macOS-джобы (40587960448) краснел на F3: первая картинка `ImageRenderer` в свежем процессе раннера
    вышла пустой (днём белого и сливы 0, ночью — как на Mac); пустая картинка теперь рисуется заново;
  - локально V36 краснел на пороге дня (0,773 при 0,85) — разбор ниже
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-27, «Подписываю (Рекомендую)»): F1–F5 и вид мок-снимков
  (`local/checkpoint/glass-mockups/`, вне git)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (F1–F5)
- [x] PASS — облик: снимки настоящего стекла `local/shell-snapshots/glass/` (вне git); снимков экрана телефона нет (L46)
- [x] PASS — порог дня V36: решение родителя 2026-10-28, by=human:anthony — «Перенести порог (Рекомендую)». Вопрос
  дословно: «Дизайн со стеклом готов, все проверки зелёные. Осталась одна мелочь. Небо, которое ты утвердил, чуть темнее, чем ждала старая проверка экрана „день светлый“: верх неба днём 0,77 по яркости, а старый порог 0,85. Ночью 0,28, так что день от ночи отличается хорошо. Перенести порог на 0,75 или осветлить верх неба?» Варианты: «Перенести порог (Рекомендую)» / «Осветлить небо». Ответ: «Перенести порог (Рекомендую)».
  Подписанное небо F1 (`#DCEEFF`) не проходило прежний порог «полоса неба
  днём ≥ 0,85»: верх сам по себе — 0,836, полоса с огнями — 0,773. Порог считали под прежнее небо (0,94). В коде он
  0,75, ночь — прежние ≤ 0,70 (замер 0,277). Строка F2 «V36 — прежние пороги» — ошибка спеки: на стенде снят цвет
  полосы, но не пересчитана её яркость против V36. Вариант «осветлить верх неба и переподписать вид» родитель не выбрал.

## Исполнение рисковых путей

- `runtime_paths: none` — облик: палитра, стекло и стиль кнопок — рисунок SwiftUI с тестами на Mac и в macOS-джобе;
  вид на телефоне — общая сессия теста (слово родителя 27.10: телефон не трогать). at=2026-10-28

## Spec coverage gaps
- **Телефон:** стекло рисует iOS 27 тем же API; блики и тонировка на телефоне, цена кадра рядом с моделью — общая
  сессия теста.
- **Консоль:** кнопки памяти M39 из main («Что помнит Элли», «Стереть память») влиты сложением и тоже стеклянные; их
  поведение — прежнее, вид — по F4.

## Ревью рисковых мест

- **Публичный API `ShellUI`:** `AdultSky`, `glassCard()`, `GlassCapsule`; в `ShellCore` — `Palette.sky`, `skyLights`,
  `skyTones`, `SkyLight`. Тестовые помощники `Pixels`, `near`, `snapshots`, `save` стали общими для двух файлов тестов;
  в дайджесте `CGImageDestinationFinalize` — перенесённый помощник `save`, к F2 его приписала последняя метка (L113).
- **Платформа:** `AllyShell` — `.iOS("27.0"), .macOS("27.0")` строкой (`swift-tools-version` прежний, Linux-джоба
  та же); `App/project.yml` — iOS 27.0; `ios.yml` — образ `xcode-27` (preview; очередь на прогонах этой поставки — 5 с).
- **Снимок окна:** на Mac окно стенда на миг показывается у правого верхнего края экрана; функция снятия устарела в SDK
  и вызывается по имени — исчезнет, и F3, F4 уйдут в видимый пропуск.
- **Безопасность ребёнка:** на детском экране ни слов, ни кнопок не прибавилось; стекло — у взрослых; вспышек нет.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 11 кода под предохранителем (+3 вне: `ios.yml`, `adapted.json`, `check_app_artifact.sh`; +12 документов и знания) / net 291 из 800; план ≈ 250, с поправкой рисунка ≈ 375 |
| commits | 8 до сдачи (спека, подпись, eval-smoke, код, знание, уроки, F3 на раннере, слияние main); сдача — следующим |
| time_to_accepted_spec | 0,3 ч (спека 28ad32a → подпись 9dc5792) |
| rework_after_done | 0 |
| harness_hardened | yes — `GlassSnapshotTests` (настоящее стекло снимком окна), F5 в `check_app_artifact.sh`, F2 в `SnapshotTests` |
| implement_retries | 3 — строки длиннее 120; привязка дайджеста у порога V36 (L113); пустая первая картинка `ImageRenderer` на раннере |
| verify_fails_before_green | 1 — macOS-джоба 40587960448 (F3, пустая картинка); Linux-прогоны зелёные |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **21**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
F1	XCTAssertEqual(Palette.borders.count, expected.count + Palette.skyTones.count)
F1	XCTAssertEqual(Palette.sky.map { $0.tone.rgb }, [0xDCEEFF, 0xF1E2FF, 0xFFDCEB, 0xFFD6C8])
F1	XCTAssertEqual(Palette.sky.map { $0.at }, [0, 0.3, 0.62, 1])
F1	XCTAssertEqual(Palette.skyLights.map(\.tone.rgb), [0xCFE6FF, 0xE3D3FF, 0xFFD3BF, 0xFFFFFF])
F1	XCTAssertEqual(Palette.skyTones.map(\.rgb),
F1	XCTAssertEqual(Palette.raspberry.contrast(with: tone), rims[index], accuracy: 0.005)
F1	XCTAssertEqual(Palette.plum.contrast(with: tone), plums[index], accuracy: 0.005)
F1	XCTAssertGreaterThanOrEqual(Palette.plum.contrast(with: tone), 4.5)
F1	XCTAssertTrue(Palette.skyTones.allSatisfy { tone in
F3	XCTAssertGreaterThanOrEqual(whites.0, 1500, name)
F3	XCTAssertGreaterThanOrEqual(plums.0, 500, name)
F3	XCTAssertLessThanOrEqual(abs(whites.0 - whites.1), 0.1 * whites.1, "\(name) white \(whites)")
F3	XCTAssertLessThanOrEqual(abs(plums.0 - plums.1), 0.1 * plums.1, "\(name) plum \(plums)")
F4	XCTAssertGreaterThanOrEqual(probe.area(in: CGRect(x: 0, y: 0, width: 440, height: 100), where: plum), 80)
F4	XCTAssertLessThanOrEqual(probe.area(in: CGRect(x: 0, y: 100, width: 440, height: 100), where: plum), 5)
F4	XCTAssertGreaterThanOrEqual(NSHostingView(rootView: Button("Стоп") {}.buttonStyle(GlassCapsule())).fittingSize
V36	XCTAssertGreaterThanOrEqual(try XCTUnwrap(probes["listening"]).mean(in: strip, luminance), 0.75)
F2	XCTAssertGreaterThanOrEqual(day.mean(in: top) { Double($0[2] - $0[0]) }, 20)
F2	XCTAssertGreaterThanOrEqual(day.mean(in: low) { Double($0[0] - $0[2]) }, 30)
F2	XCTAssertLessThanOrEqual(night.mean(in: top, luminance), 0.70)
F2	XCTAssertTrue(CGImageDestinationFinalize(target))
```

✅ **Каждое утверждение ведёт к примеру спеки** (F1 F2 F3 F4 V36), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (порог дня V36 — решение родителя 2026-10-28: «Перенести порог (Рекомендую)»)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
