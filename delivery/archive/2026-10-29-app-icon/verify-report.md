# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; вариант В и примеры I1–I7 подписаны выбором родителя 2026-10-29 до кода)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40951885309
**Commit:** 856ee73 (спека — 8772e28, выбор родителя — 41979c3, подпись — c06ae77, код и знание — 552301a, main влит до 9cba72e — 78ff43d, факты и уроки — 1278182, main влит до 88e9920 — 3f9de70, уроки child-open — 856ee73); macOS-джоба по метке на образе `xcode-27` — https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40951641296 на 3f9de70 (после него — только документы поставки); сдача — следующим коммитом, PR #91

## Shape oracles
- [x] PASS — pre-commit (STRICT=1) локально и в CI: `file-length`, jscpd — рост 0; SwiftLint 0.65.0 — 0 находок
  (ратчет 0; `large_tuple` в первом черновике `IconPicture` поймал хук, тройка заменена структурой); секреты; данные
  ребёнка; `check-added-large-files` — PNG 452, 467 и 423 КиБ при пределе 512; `gate-coverage`; граница демо
- [x] PASS — `okf_validate.py`: 0 ошибок (53 файла); `okf_sync_gate.py`: 19 концептов сверены. В том же диффе правлены
  `product/look-and-feel`, `engineering/character-rendering` (`implementation:` += `IconScene.swift`,
  `render_app_icon.sh`), `engineering/design-demo` (её `implementation:` держит `check_demo_boundary.sh`),
  `references/repo-map`, `product/index`, `ops/test-session`, `log.md`
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 11 файлов, net
  454 из 800 (план ≈ 355, с поправкой рисунка ≈ 530). Предупреждение «нет реляционного оракула» — разбор ниже

## Behavior oracles
- [x] PASS — `swift test` пакета `AllyShell` на Mac (Xcode 27.1, macOS 27.2, под `nice -n 10`, без оконных тестов
  стекла `GlassSnapshotTests` — их окно на экране Mac не открывал): 41 тест зелёный, `IconTests` 4 из 4 (I1–I4). CI на
  Linux, джоба `swift`: `IconTests` пропущены видимо, покрытие AllyShell — 12 файлов `Sources/`, строк 683 из 685, 99% (порог 70%; `ShellUI` на Linux пуст)
- [x] PASS — ручная macOS-джоба по метке `macos` на образе `xcode-27` (Xcode 27.1): на слитом main (3f9de70,
  40951641296) и до слияния (1278182, 40951045401) — `IconTests` 4 из 4 на раннере, I3 — сверка каталогов с рендером
  другой машины в допуске; сборка `Ally.app` — `check_app_artifact.sh` OK (I6: `CFBundleIconName AppIcon`,
  `Assets.car`); сборка `AllyDemo.app` — `check_demo_boundary.sh` OK (I6 демо); `GlassSnapshotTests` сняты, не пропущены
- [x] PASS — мутации в ту же сессию (П30, L64 — по видимому эффекту), 7 из 7 убиты, файлы восстановлены побайтно:
  - I4 «без глаз» (`Face` без глаз) — глаза 3 и 1 при порогах 360 и 60;
  - I3 «Элли × 1,25 вместо 1,5» — средняя разница 16,6 и 15,0 уровня, далёких пикселей 27%;
  - I1 «без неба» — 355 208 прозрачных пикселей рендера;
  - I2 «без ночной пары» в `Contents.json` — список файлов и тёмная тема красные;
  - I5 «без снятия дизеринга» — после `pngcrush` 814 994 байта, скрипт отказал до копирования, каталоги не тронуты;
  - I6 «без `CFBundleIcons`» и «без `Assets.car`» — `check_app_artifact.sh` на поддельном `Ally.app` и
    `check_demo_boundary.sh` на поддельном `AllyDemo.app` красные, бандлы со значком — OK (L156: сначала
    положительный случай).
- [x] PASS — I7: скрипт с мутацией «Элли × 1,25» пересобрал каталоги, после него I3 зелёный; после возврата — день и
  демо побайтно те же, что до мутации, ночь — в допуске I3 (разбор ниже)
- [x] PASS — `xcodegen generate`: `App/Resources/Assets.xcassets` — в ресурсах цели Ally, `App/Demo/Assets.xcassets` — в
  ресурсах AllyDemo, `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` у обеих; `actool` на обоих каталогах: `Assets.car`
  с `AppIcon.png` и `AppIcon-night.png` (`UIAppearanceDark`), в Info — `CFBundleIconName AppIcon`
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры и замер стенда до кода, вариант выбрал родитель

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-29, «В» через ведущего; строку вписал ведущий): вариант значка и
  ночная пара; страница выбора `local/checkpoint/app-icon/index.html` (вне git)
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (I1–I7)
- [x] PASS — облик: рендеры `local/shell-snapshots/icon/` (вне git); снимков экрана телефона нет (L46)

## Реляционный оракул (детектор канона его не видит)

I3 — PNG каталога против свежего рендера того же кода: ожидаемых чисел нет, есть разность с самим собой (L128).
Детектор знает только hypothesis и fast-check, отсюда предупреждение. Допуск — средняя разница ≤ 1 уровня и не больше
0,5% пикселей с разницей > 16. Ночной рендер от прогона к прогону расходится в 1,7% пикселей, не больше чем на 4
уровня (средняя 0,006); дневной и демо — побайтно те же. Побайтное равенство было бы ложным красным.

## Исполнение рисковых путей

- `runtime_paths: none` — значок — ресурс каталога; в собранных `.app` его судит I6 в macOS-джобе, вид на домашнем
  экране — общая сессия теста (блок 3.1 runbook `ops/test-session`). at=2026-10-29

## Spec coverage gaps
- **Телефон:** вид значка на домашнем экране, в поиске и в настройках, ночная пара в тёмной теме, режимы iOS
  «прозрачный» и «тонированный» (их строит система из дневного PNG) — общая сессия теста.
- **Icon Composer (`.icon`)** — не делали (`decisions.md`); пересмотр — после сессии теста.

## Ревью рисковых мест

- **Публичный API `ShellUI`:** `IconScene` (`init(night:)`). Тестовые помощники `IconPicture` и `DemoIcon` — в тестах;
  надпись «демо» рисует тест: `Text` в `ShellUI` запрещён правилом `child_screen_text`.
- **`App/project.yml` не тронут** — его правят и соседние поставки (`child-open`).
- **Двоичные файлы в git:** три PNG, 1,3 МБ в сумме; каждый под пределом гейта; запас у ночного — 45 КиБ.
- **Безопасность ребёнка:** на значке надписей нет; демо с пометкой на телефон не ставится.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 11 кода под предохранителем (+2 вне: `check_app_artifact.sh`, `check_demo_boundary.sh`; +3 PNG; +13 документов и знания) / net 454 из 800; план ≈ 355, с поправкой рисунка ≈ 530 |
| commits | 6 до сдачи (спека, выбор, подпись, код и знание, слияние main, факты); сдача — следующим |
| time_to_accepted_spec | 0,1 ч (спека 8772e28 → выбор 41979c3) |
| rework_after_done | 0 |
| harness_hardened | yes — `IconTests` (новый оракул: каталоги = код), I6 в `check_app_artifact.sh` и `check_demo_boundary.sh` |
| implement_retries | 2 — снятие дизеринга на Swift в отладочной сборке шло 126–140 с на тест (переписано на vImage — 0,4–8 с); `large_tuple` SwiftLint |
| verify_fails_before_green | 0 — красных прогонов нет; quality на 3f9de70 отменён следующим пушем (856ee73) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **15**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
I1	XCTAssertEqual(IconPicture.translucent(try XCTUnwrap(IconPicture.drawing(view), name)), 0, name)
I1	XCTAssertEqual([image.width, image.height], [1024, 1024], name)
I1	XCTAssertEqual(image.colorSpace?.name, CGColorSpace.sRGB, name)
I2	XCTAssertEqual(app.map(\.file), ["AppIcon.png", "AppIcon-night.png"])
I2	XCTAssertEqual(app.map(\.dark), [false, true])
I2	XCTAssertEqual(demo.map(\.file), ["AppIcon.png"])
I2	XCTAssertEqual(demo.map(\.dark), [false])
I2	XCTAssertEqual(entry.form, ["universal", "ios", "1024x1024"], entry.file)
I2	XCTAssertEqual([image.width, image.height], [1024, 1024], entry.file)
I2	XCTAssertTrue([.none, .noneSkipLast, .noneSkipFirst].contains(image.alphaInfo), entry.file)
I3	XCTAssertLessThanOrEqual(mean, 1, "\(name) mean \(mean)")
I3	XCTAssertLessThanOrEqual(far, 0.005, "\(name) far \(far)")
I4	XCTAssertGreaterThanOrEqual(home.area(where: eyes), 360, "night \(night)")
I4	XCTAssertGreaterThanOrEqual(settings.area(where: eyes), 60, "night \(night)")
I4	XCTAssertGreaterThanOrEqual(home.area(where: rim), 420, "night \(night)")
```

✅ **Каждое утверждение ведёт к примеру спеки** (I1 I2 I3 I4), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
