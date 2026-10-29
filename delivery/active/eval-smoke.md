# Eval smoke — design-demo (демо облика в симуляторе, превью и токены)

Оракул поставки — примеры спеки Y1–Y7. Факт — по сборке демо под симулятор (Mac и macOS-джоба `ios.yml` на образе
`xcode-27`), оракулу границы `check_demo_boundary.sh`, пробам `ShellUITests` на Mac и прогону `run_demo.sh` в симуляторе
iPhone 17 Pro Max (iOS 27). Кадры симулятора — `local/`, вне git; снимков экрана телефона нет (L46).

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| Y1 | `xcodebuild -scheme AllyDemo` под симулятор без подписи; `check_demo_boundary.sh` | BUILD SUCCEEDED; `com.anthonypriceone.ally.demo`, «Ally Demo», `MinimumOSVersion` 27.0; зависимости — `AllyCore`, `ShellUI`, `ShellCore` | — |
| Y2 | `check_demo_boundary.sh` (проект и `Ally.app`) | у `Ally` нет источника `Demo`; в бинарях `Ally.app` нет меток демо; мутация «`- path: Demo` в Ally» — красный | — |
| Y3 | `check_demo_boundary.sh` (`AllyDemo.app`) | нет ключей микрофона, распознавания, сети; нет символов llama/ggml, ORT, sherpa, сети; нет файлов модели и голоса; прав нет; мутация «AllyLlama у демо» — красный | — |
| Y4 | демо в симуляторе iPhone 17 Pro Max (iOS 27) | тур 23 с: спит 4 → здоровается 3 → слушает 4 → думает 3 → говорит 5 → прощается 4; плашка: 8 фаз, «Тур», «Метка», «Консоль», «Скрыть»; тап и стоп — как в приложении; консоль — тот же вид | — |
| Y5 | `DemoPreviews.swift`; `check_demo_boundary.sh` | 10 `#Preview` (8 фаз и консоль дважды) компилируются; каждая фаза `SessionState` есть в превью | — |
| Y6 | `swift test --package-path Packages/AllyShell` на Mac | числа облика — из `Look`, значения прежние: V8, V21, V36, F2–F4 зелёные без смены порогов; мутация «высота 36» краснит F4 | — |
| Y7 | `bash scripts/run_demo.sh` на Mac | xcodegen → сборка → устройство → установка → запуск, последняя строка «демо запущено: …»; без рантайма — выход 1 до сборки с подсказкой; повтор — поверх на то же устройство | — |
