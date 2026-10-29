# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (новых утверждений тестов нет — дайджест ниже, asserts_without_example: 0; оракулы примеров — гейт `check_demo_boundary.sh`, прежние пробы `ShellUITests` и прогоны в симуляторе; Y1–Y7 подписаны родителем 2026-10-29 до кода, Y4 изменён по его слову после показа)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40939103669 (gates, delivery, swift — зелёные)
**Commit:** 3863d32 (спека — b2c632c, подпись и eval-smoke до кода — 6672847, код — 75cb5fd, без надписи и знание — 467dcbd, гейт объявлен — d8c098a, be0bde2, уроки поимённо — 3863d32); macOS-джоба по метке на образе `xcode-27` — https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40939132847; сдача — следующим коммитом, PR #86

## Shape oracles
- [x] PASS — pre-commit (STRICT=1) локально и в CI:
  - `file-length`; jscpd — 7 прогонов, рост 0, `App/Demo` — 5 файлов, 0 пар (локально — jscpd 4.0.5 через npx);
  - SwiftLint `--strict` — 239 файлов, 0 находок (ратчет 0); `child_screen_text` и `child_screen_gestures` без новых
    исключений;
  - секреты, данные ребёнка, `gate-coverage`, новый хук `demo-boundary`.
- [x] PASS — `okf_validate.py`: 0 ошибок (53 файла). `okf_sync_gate.py --base origin/main`: 19 концептов сверены. В том
  же диффе правлены `product/look-and-feel`, `engineering/character-rendering`, `engineering/voice-loop`,
  `references/repo-map`; новый `engineering/design-demo`.
- [x] PASS — доктор контура `contour_doctor.py`: DEAD 0. Канарейка `check_demo_boundary.sh` поймана; область — «просмотрено
  2 цели».
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок. Предохранитель — 13 файлов, net 395
  из 800 (план ≈ 515, с поправкой экранного кода ≈ 665). Предупреждение «нет реляционного оракула»: детектор знает только
  hypothesis и fast-check. Реляционный оракул здесь — Y6: пробы оболочки до и после переноса чисел в `Look` совпадают
  при прежних порогах, ожидаемых новых чисел нет.

## Behavior oracles
- [x] PASS — сборка демо под симулятор на Mac (Xcode 27.1, 27A9275): `xcodebuild -scheme AllyDemo -destination
  'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` — BUILD SUCCEEDED, 16 с с нуля; `run_demo.sh` — 6,5 с
  повторно. Десять `#Preview` компилируются этой же сборкой.
- [x] PASS — `swift test --disable-keychain --package-path Packages/AllyShell` на Mac под `nice -n 10`: 32 из 32
  (`ShellCoreTests` и `ShellUITests`: `SnapshotTests` V8, V21, V36, F2; `GlassSnapshotTests` F3, F4 на настоящем стекле).
- [x] PASS — оракул границы на собранном `AllyDemo.app` (Mac): `com.anthonypriceone.ally.demo`, «Ally Demo»,
  `MinimumOSVersion` 27.0. Ключей микрофона, распознавания и сети нет. В `AllyDemo.debug.dylib` 19 476 символов, ни
  одного llama/ggml, ORT, sherpa или сети. Файлов модели и голоса нет. Метка `ally-demo` — 8 вхождений.
- [x] PASS — macOS-джоба `ios.yml` по метке (https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40939132847, образ `xcode-27`, 6 мин 20 с): AllyShell — 32 из 32
  со снимками и настоящим стеклом; `Ally.app` для устройства — BUILD SUCCEEDED (вынесенная консоль собирается в
  приложении), оракул артефакта — OK; `AllyDemo.app` под симулятор — BUILD SUCCEEDED; граница демо — OK на обоих:
  «Ally.app — бинарей 6» без метки, «AllyDemo.app — бинарей 3».
- [x] PASS — мутации в ту же сессию (П30, L64 — по видимому эффекту), 6 из 6 убиты, файлы восстановлены:
  - Y2 «`- path: Demo` в источниках Ally» — «у цели Ally источник Demo»;
  - Y2 «код демо в Ally.app» (бандл с `AllyDemo.debug.dylib`) — «в Ally.debug.dylib метка демо»;
  - Y1/Y3 «`- package: AllyLlama` у AllyDemo» — «зависимость package: AllyLlama»;
  - Y3 «символ llama в AllyDemo.app» (dylib с `llama_backend_init`) — «символы … _llama_backend_init»;
  - Y5 «нет превью паузы» — «у фазы paused нет #Preview»;
  - Y6 «`Look.buttonHeight` 36» — F4 красный: «("36.0") is less than ("44.0")».
- [x] PASS — канарейка гейта (доктор): с `App/build-demo/DemoCanary.app/Info.plist` (ключ микрофона) — красный, без неё —
  зелёный.
- [x] PASS — красное по делу, пороги не менялись. Хук `demo-boundary` на первом коммите кода упал: в хуке git задаёт
  `GIT_DIR`, и `git -C scripts/lint rev-parse --show-toplevel` ответил самим каталогом. Корень скрипта теперь берётся
  по его месту (L155). `run_demo.sh` из соседнего клона судил не тот репозиторий — исправлено так же.
- [x] PASS — Builder ≠ Verifier: код писал агент-исполнитель; гейты, мутации и CI — механика; ожидания — примеры,
  подписанные родителем до кода.

## Product oracles
- [x] PASS — `human_ok_spec: yes`: родитель 2026-10-29, «Подписываю (Рекомендую)» через ведущего. Строку вписал ведущий.
  Вопрос дословно: «Демо облика на Mac: отдельное приложение „Ally Demo“ для симулятора. В нём нет модели, микрофона и
  голоса, на телефон оно не попадает. Детский экран сам идёт по кругу: спит 4 с → здоровается 3 с → слушает 4 с →
  думает 3 с → говорит 5 с → прощается 4 с. Внизу стеклянная плашка: можно выбрать фазу руками, включить метку „при
  родителе“, открыть консоль или скрыть плашку. Консоль та же, что в приложении, со строками-примерами без имён. В Xcode —
  десять превью: восемь фаз и консоль дважды. Цвета лежат в Palette.swift, размеры, радиусы и шрифты — в одном файле
  Look.swift. Сейчас всё как подписано 28.10, правим после показа. Запуск одной командой: bash scripts/run_demo.sh.
  Подписываешь эти семь проверок?» Варианты: «Подписываю (Рекомендую)» / «Поправить».
- [x] PASS — показ родителю в симуляторе (ведущий, 2026-10-29). После показа Y4 изменён по его слову дважды:
  поведение (детский режим, сценарий, знак стопа — консоль, переключатель — только аргументом) и надпись («Убрать и
  надпись, и замок»). Выдержки дословно — `spec.md` и `decisions.md`. Его итог: «Демо в детском режиме — то, что нужно»
  (через ведущего).
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (Y1–Y7).
- [x] PASS — облик: кадры симулятора `local/demo-frames/` (вне git): старт в детском режиме без надписи; сценарий от
  пробуждения (`-demo-wake YES`) — приветствие, слушает, думает, говорит, слушает без ответа, прощание, сон; консоль
  (`-demo-screen console`); переключатель (`-demo-panel YES`). Снимков экрана телефона нет (L46).

## Исполнение рисковых путей

- `runtime_paths: none`. Демо идёт только в симуляторе без модели, микрофона и голоса. Консоль приложения — тот же вид,
  вынесенный в `ConsoleView.swift`; условия кнопок и раскладка сверены механически с прежним `AllyApp.swift` (замена
  `loop.` → `model.` и чисел → `Look`, `diff` пуст). Сборку `Ally.app` судит macOS-джоба; вид на телефоне — общая
  сессия теста. at=2026-10-29

## Spec coverage gaps
- **Тапы в симуляторе из командной строки.** `simctl` касаний не умеет, поэтому сценарий в кадрах запущен аргументом
  `-demo-wake YES`. Тапы по Элли и по знаку стопа проверял глаз (показ родителю).
- **Канвас Xcode.** Превью компилируются сборкой Y1, но отрисовку канваса судит глаз в Xcode.
- **Без рантайма iOS 27.** Отказ `run_demo.sh` проверен устройством, которого не знает ни один рантайм iOS 27
  («iPhone 99»): ветка та же — подходящего рантайма нет. Удалять рантаймы с Mac ради проверки не стал.

## Ревью рисковых мест

- **Консоль приложения.** Вид вынесен из `AllyApp.swift` в `ConsoleView.swift` без `VoiceLoop`. `Console` подаёт
  `loop.console` и `loop.consoleActions`; `start()`, `isIdleTimerDisabled` (L130) и `refreshAccess()` остались в
  обёртке. «Что помнит Элли» читает текст памяти только по нажатию, как раньше.
- **Публичный API `ShellUI`:** `Look` — роли, размеры, шрифты, тонировки, нажатие; значения прежние.
- **Граница демо.** Цель `AllyDemo` берёт `App/Demo` и один файл `App/Sources/ConsoleView.swift`; у цели `Ally`
  источники не менялись. Метка демо — длинная строка: короткие строки Swift живут в инструкциях (L156).
- **Аргументы проверки** `-demo-panel`, `-demo-screen`, `-demo-phase`, `-demo-wake` читаются из defaults только в
  демо-цели; в приложении их нет.
- **Безопасность ребёнка:** продуктовый детский экран не менялся. Строки консоли демо вымышленные и без имён.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 13 кода под предохранителем (+5 вне: `ios.yml`, `.pre-commit-config.yaml`, `adapted.json`, `canaries.json`, `check_demo_boundary.sh`; +13 документов и знания) / net 395 из 800; план ≈ 515, с поправкой ≈ 665 |
| commits | 8 до сдачи (спека, подпись и eval-smoke, код, без надписи и знание, гейт объявлен, область гейта, уроки поимённо, отчёт); сдача — следующим |
| time_to_accepted_spec | 0,1 ч (спека b2c632c → подпись 6672847) |
| rework_after_done | 0 |
| harness_hardened | yes — `check_demo_boundary.sh` (хук `demo-boundary`, шаг `ios.yml`, канарейка), jscpd видит `App/Demo`, сборка демо в `ios.yml` |
| implement_retries | 3 — `@Published` на трёх переменных одной строкой; корень скрипта из соседнего клона; `GIT_DIR` в хуке (L155) |
| verify_fails_before_green | 0 — первый прогон CI зелёный (quality 40939103669, ios 40939132847); локально — хук `demo-boundary` на первом коммите кода (L155) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

**Новых утверждений нет.**

Изменения — реализация, гейт `check_demo_boundary.sh` (оракул Y1–Y3, Y5 с мутациями выше) и прогоны в симуляторе;
прежние пробы `ShellUITests` судят перенос чисел в `Look` с прежними порогами (Y6).

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
