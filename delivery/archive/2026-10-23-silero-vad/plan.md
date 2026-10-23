# Plan: D7.2 `silero-vad` — sherpa-onnx в `AllyOnnx`, `AllyHearing`, Silero за протоколом активности

Уроки архива. **L33**: документы и eval-smoke — первым коммитом ветки, до кода; примеры — таблицей дословно со ссылкой
на коммит спеки серии. **L34, L52, L61, L63, L91**: бюджет — план серии (≈ 380) по файлам с поправкой +50% (поручение
ведущего); ресурс JSON считается по выводу форматтера, проверка на настоящих байтах (U16, U17) — отдельными строками.
**L2**: новый манифест `Packages/AllyHearing/Package.swift` и `binaryTarget` sherpa — строками `new_dependency` (гейт
`binaryTarget` не разбирает). **L36**: лицензии — с первоисточника (sherpa Apache-2.0, Silero MIT — `gh api`). **L38**:
checksum в `Package.swift` — с `pragma: allowlist secret`. **L93**: `.build` нового пакета — в `excluded` SwiftLint, иначе
локальный `swift test` красит ратчет. **L41**: покрытие AllyCore — по своему `Sources/`; `AllyHearing` на Linux не
собирается. **L44**: длина кадра — вход алгоритма: энергия судит кадры 20 мс, Silero — окна 512 отсчётов 16 кГц,
запаздывание флага — параметр активности (U18). **L45**: числа реестра слуха — `Decodable` с `Double`. **L50, L58**:
Silero приходит вместе с вызывающим — `VoiceLoop` выбирает, `PhoneListener` кормит, определитель судит; новое поле
`activity` проверяется через обёртку (`TurnDetector` в тесте U18 — тот же тип, что строит слух). **L59**: мутации — по
механизму («запаздывание не вычитается», «размер файла не сверяется», «API не проверяется»). **L60**: `AudioIO` не
трогаем — Silero берёт буферы из того же `feed`, что и диктовка. **L68**: стыки с D7.1 — дословными строками, его
`TurnEnding(pauses:)` и `ending?.saw(…)` не трогаем. **L69, L71**: две сессии на одном слухе — активность одна на слух,
сбрасывается на каждом слушании. **L7, L16, L70**: места «конец речи меряет энергия» ищем поиском и по смыслу. **L89**:
у проверки пары — положительный случай на настоящем рантайме (U16 на Mac), а не только двойник отказа. **L90**: время
события U18 — окно, где порог достигнут, и окно перед ним. **L35**: перед ссылкой на CI — `mergeable`. **L43**:
`STRICT=1 BASE=origin/main python3 scripts/lint/check_digest_report.py` — до пуша сдачи. **L94**: прогоны jscpd не
меняются. Урок поставки — L80 (раскладка серии).

## Approach

1. **AllyCore.** `VoiceActivity` (протокол: `loud(_:) -> Bool?`, `lag`, `reset()`), `EnergyActivity` — блок энергии из
   `TurnDetector` дословно (калибровка 8 кадров, порог). `TurnDetector.init(…, activity: VoiceActivity? = nil)`; nil —
   энергия; три кадра подряд остаются в определителе; `lastVoiced = time − activity.lag`. `Hearing.vad` и выбор слуха:
   `listening(pair:fileBytes:)` → Silero или энергия со строкой из `Resources/listening.json`.
2. **AllyOnnx.** `binaryTarget` `SherpaOnnxIOS` и `SherpaOnnxMacOS` (URL релиза xcframework и checksum k2-fsa v1.13.8),
   библиотека `AllySherpa` (`Sherpa.version`, `Sherpa.api = 28`); `OnnxRuntime.serves(api:)` в слое C API. Страж —
   пин пары в `check_single_ort.sh`, отрицательный контроль — копия с 1.13.9 и с 1.24.2 в джобе `swift`.
3. **AllyHearing** (`Packages/AllyHearing`, зависит от `AllyCore` и `AllyOnnx`): `SileroVAD` (C API sherpa, конфиг
   спайка), `SileroActivity` (`feed(AVAudioPCMBuffer)` → 16 кГц → окна → флаг; `reset()` на каждом слушании; время окон
   — в журнал `os.Logger`), `OnnxPair.current`, `SileroActivity.choose(hearing, models:)`. Тесты (Mac): U16 (а), U17.
4. **Приложение.** `hearing.json` — `vad`; `project.yml` — пакет `AllyHearing`; `VoiceLoop` — выбор и строка консоли,
   `versions.vad`; `PhoneListener` — `activity` в init, в определитель и в `feed` у `audio.listen`. Сборка без подписи и
   оракул артефакта; `ios.yml` — шаг тестов `AllyHearing`.
5. **Знание.** `turn-detector.md`, `onnx-runtime.md`, `voice-loop.md` (копирование Silero, сравнение с энергией без
   файла), `knowledge/log.md`; сдача — `delivery/OBSERVATIONS.md`.

## Budget (800 строк, 25 файлов, рисковых путей 1: `Packages/AllyHearing/`)

| Файл | строк |
|---|---|
| `Packages/AllyOnnx/Package.swift` (+ sherpa iOS и macOS, `AllySherpa`) | 20 |
| `Packages/AllyOnnx/Sources/AllySherpa/Sherpa.swift`, `Onnx.swift` (`serves(api:)`) | 15 |
| `Packages/AllyHearing/Package.swift` | 22 |
| `Packages/AllyHearing/Sources/AllyHearing/SileroVAD.swift` | 45 |
| `Packages/AllyHearing/Sources/AllyHearing/SileroActivity.swift` (ресемплер, окна, выбор, журнал) | 75 |
| `Packages/AllyHearing/Tests/AllyHearingTests/SileroTests.swift` (U16 а, U17) | 80 |
| `Packages/AllyCore/Sources/AllyCore/VoiceActivity.swift` и `TurnDetector.swift` (переезд энергии) | 28 |
| `Packages/AllyCore/Sources/AllyCore/Hearing.swift` (`vad`, выбор) и `Resources/listening.json` | 43 |
| `Packages/AllyCore/Tests/AllyCoreTests/TurnDetectorTests.swift` (U18) | 40 |
| `Packages/AllyCore/Tests/AllyCoreTests/HearingTests.swift` (U16 б, U19) | 35 |
| `App/Sources/PhoneListener.swift`, `App/Sources/VoiceLoop.swift`, `App/project.yml`, `App/Resources/hearing.json` | 21 |
| `.swiftlint.yml` (`.build` пакета) | 1 |
| **итого, 16 файлов кода** | **≈ 425** |

С поправкой +50% — ≈ 640, ниже стопа 780. Выше 780 — стоп, `escalation.md` и сразу к ведущему. Вариант: `SileroActivity.
choose` и строка консоли уходят в D7.3 вместе с выбором распознавателя (−60); цена — приложение не включит Silero до
D7.3. Вне предохранителя: `scripts/lint/check_single_ort.sh`, `.github/workflows/`, `delivery/`, `knowledge/`.

## Rejected alternatives

- **Silero прямо на C API ORT со своим окном и состоянием LSTM** — отклонено решением ведущего и снятием риска: sherpa
  1.13.8 на общем ORT даёт флаги спайка бит в бит (1434 из 1434), свой путь — паритет, который пришлось бы доказывать
  заново.
- **Пакет `k2-fsa/sherpa-onnx` целиком** — отклонено: тянет свой ORT, второй рантайм в бинаре (страж «один ORT»).
- **Частота тапа — правкой `AudioIO`** — отклонено: рисковый путь звука, второй сверх объявленного; буферы с форматом
  уже идут в `feed` для диктовки.
- **Silero на тех же 16 кГц Int16, что получает распознаватель** (`Phrase`, D3.2) — отклонено: формат анализатора на
  телефоне — проба устройства, а стык — `App/Sources/Speech/` поставки D7.1; свой ресемплер не зависит от диктовки.
- **Порог и минимумы Silero константами кода** — отклонено: параметры слуха — у слуха (П10, `hearing.json`).
- **Переключатель «энергия/Silero» ключом запуска** — отклонено: сравнение U21 делает отсутствие файла (путь U19) без
  нового кода.
