# Plan: V1 `voice-onnx` — один ONNX Runtime и движок Supertonic (серия голоса V1–V4)

## Уроки по путям диффа (§2.2a) и как применены

- **L33.** Спека — отдельным коммитом до кода, подпись — отдельным коммитом до кода.
- **L34, L52.** Перенос с Python занижает Swift: исходники на 17%, тесты на 43%. Поэтому план V1 ≈ 690 ≤ 700. Кандидат на
  перенос — заранее (ниже): выше 780 — стоп и `escalation.md`.
- **L36.** Лицензии ORT, Supertonic и RUAccent сверены 22–23.10 открытием первоисточника (`gh api`, карточки HF), а не
  по отчётам стендов.
- **L47.** Путь по умолчанию — тихий выбор объекта замера. Тесты печатают, откуда взяли модель и эталоны, и пропускают
  с названием причины, если их нет (П34).
- **L50.** Двоичный sherpa-onnx в V1 не кладётся: у него нет вызывающего. У движка вызывающий появится в V4 — объявлено
  в спеке, подключённым он до V4 не числится.
- **L51.** Буква Z свободна: поиск `\bZ[0-9]+\b` по `Packages/*/Tests` main и рабочих деревьев 23.10 пуст.
- **L22, L23.** Память на iOS — это отпечаток (`phys_footprint`), а не RSS; формат и скорость iOS могут отличаться от
  macOS. Замеры V1 — на Mac с этой оговоркой, телефон судит V4 (Z22).
- **L44.** Длина кадра — вход алгоритма. В V1 кадров нет; в V4 голос отдаёт звук буферами и время первого отсчёта, а не
  время вызова.

## Архитектура V1

### `Packages/AllyOnnx` — единственный ORT приложения

- `Package.swift`:
  - `binaryTarget(name: "onnxruntime", url: "https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.28.0.zip",
    checksum: "b503cf5949ab718a1dff17d1643237ecc0fecf50ad86264572dcafddb140a327")`; <!-- pragma: allowlist secret -->
  - C-цель `COnnxRuntime` — зонтичный заголовок с `#include <onnxruntime/onnxruntime_c_api.h>`;
  - Swift-цель `AllyOnnx`;
  - `linkerSettings: [.linkedLibrary("c++"), .linkedFramework("CoreML")]` — без них статический ORT не линкуется:
    проба 23.10 упала на символах libc++, после правки печатает `ORT 1.28.0 api ok`;
  - платформы — iOS 17, macOS 14.
- API (`Onnx.swift`, ≈ 140 строк):
  - `OnnxRuntime.version`, `OnnxRuntime.apiVersion` — 1.28.0 и 28;
  - `OnnxOptions` — `intraOpThreads` (2), `allowSpinning` (false), уровень графа `all`; их же пишет `description` для журнала;
  - `OnnxSession(path:options:)` — сессия из файла; external data ORT читает рядом с графом и отображает из файла;
  - `run(_ inputs: [String: OnnxTensor], outputs: [String]) throws -> [String: OnnxTensor]`;
  - `OnnxTensor` — `.float([Float], shape: [Int])` и `.int64([Int64], shape: [Int])`;
  - `OnnxError` — текст ORT и путь.
- Окружение `OrtEnv` — одно на процесс, ленивое. ORT и сам держит его одним, так что env sherpa в поставке слуха — тот же.
- Тесты (`AllyOnnxTests`, Mac): версия и API; нет файла — `OnnxError` с путём; запуск крошечной модели «сложение».
  `add.onnx` ≈ 150 байт сделан `onnx.helper` на Mac, лежит в ресурсах теста.

### `Packages/AllyVoice` — движок за протоколом

- `SpeechEngine.swift`:
  - `protocol SpeechEngine: Sendable { func synthesize(_ text: String, voice: VoicePreset) throws -> SpeechAudio }`;
  - `SpeechAudio` — отсчёты float32, частота, этапы (текст, длительность, денойзинг, вокодер);
  - `VoicePreset` — стиль, скорость синтеза, шаги, seed;
  - пол скорости — `VoicePreset.minSpeed = 0.85`, ниже — ошибка (Z4).
- `SupertonicText.swift`: текст → индексы шаг в шаг с supertonic-py 1.3.1, на скалярах Unicode — NFKD, замены символов,
  U+0301 как обычный символ словаря, метка языка `ru`. Из стенда переносится всё, кроме многоязычного списка и нарезки
  на куски: фраза приходит одна.
- `VoiceStyle.swift`: `style_ttl` [1, 50, 256] и `style_dp` [1, 8, 16] из `voice_styles/<имя>.json`; смесь «A+B:w» —
  линейная, как `style_for` стенда.
- `Noise.swift`: SplitMix64 и Бокс–Мюллер, как в стенде. Паритет подаёт шум эталона из файла.
- `SupertonicEngine.swift`:
  - конфиг `tts.json`, четыре сессии `AllyOnnx`;
  - длительность / скорость, длина латента, цикл из `steps` шагов vector estimator, вокодер;
  - обрезка до предсказанной длительности.
- Тесты (Mac): `SupertonicParityTests` (Z2, Z3), `SupertonicEngineTests` (Z4–Z6), `SpeechEngineContractTests` (Z7 —
  двойник и Supertonic под одним набором проверок).
- Модель — `~/models/tts/supertonic-3`, эталоны — `~/models/tts/supertonic-parity`. Оба пути можно переопределить
  переменной окружения. Без них тест пишет «пропуск: нет … в …» и не валит прогон.

### Страж «один ORT» (Z1)

- `scripts/lint/check_single_ort.sh` (механика контура, вне подсчёта строк):
  - по всем `Package.swift`, `Package.resolved` и `App/project.yml` — ровно один `binaryTarget` с ORT, в
    `Packages/AllyOnnx`;
  - ни одной ссылки на `onnxruntime-swift-package-manager`, `onnxruntime-libs`, `k2-fsa/sherpa-onnx` как пакет или на
    другой URL `onnxruntime`.
- Шаг в джобе `quality`, рядом — отрицательный контроль: копия дерева с добавленной зависимостью обязана покраснеть
  (CQG §6).

### CI

- `ios.yml`: шаги `swift test --disable-keychain --package-path Packages/AllyOnnx` и `… Packages/AllyVoice`. Запуск —
  меткой `macos` один раз на поставку; минуты macOS ×10.
- Linux: `quality` — страж Z1, SwiftLint и jscpd по новым исходникам. Джоба `swift` пакеты V1 не собирает: двоичный ORT
  на Linux не идёт, как у AllyLlama. Логика без ORT появится в V2 (`AllySpeechText`) и пойдёт под покрытие ≥ 70%.

## Бюджет строк V1 (план до кода)

| Файл | Строк |
|---|---|
| `Packages/AllyOnnx/Package.swift` | 30 |
| `COnnxRuntime` (заголовок и пустой .c) | 7 |
| `AllyOnnx/Onnx.swift` | 140 |
| `AllyOnnxTests` | 50 |
| `Packages/AllyVoice/Package.swift` | 25 |
| `SpeechEngine.swift` | 25 |
| `SupertonicText.swift` | 140 |
| `SupertonicEngine.swift` | 120 |
| `VoiceStyle.swift` | 40 |
| `Noise.swift` | 30 |
| `AllyVoiceTests` (Z2–Z7) | 105 |
| `.github/workflows/ios.yml`, `quality.yml` | 8 |
| **Итого** | **≈ 720** |

План выше 700, и правило переноса (L52) требует решения до кода.
- Z18 — паритет моделей RUAccent на ORT 1.28.0 — уже отнесён в V3: с ним план был ≈ 760.
- Дальше два варианта — решает ведущий:
  - (а) принять ≈ 720: остаётся запас 60 до стоп-линии 780;
  - (б) перенести Z6 (время на Mac) в замер V4 на телефоне и свести Z3 к равенству векторов стиля без звука. Это ≈ 690,
    но время на ORT 1.28.0 до V4 никто не мерит.

Рекомендую (а): время — одна из двух проверок, которые ведущий поручил V1. Если факт подойдёт к 780, переносится (б)
через `escalation.md`.

## Риски и запасные пути

- **Паритет на C API хуже 60 дБ.** Сравнить по стадиям — индексы, длительность, латент после каждого шага — и найти
  стадию. Запасной ORT — csukuangfj 1.28.2: одна строка `binaryTarget`.
- **Отпечаток выше 100 МБ** — значит, external data не отображается. Проверить опции сессии ORT 1.28.0 для отображения
  initializer'ов.
- **Время хуже 1,3 с** — проверить spin, число потоков и QoS вызывающего: под чужой нагрузкой стенд видел 21 с со spin.
- **Параллельно слух правит `Packages/AllyOnnx`** (sherpa и проверка пары) — конфликт при слиянии сложением (L35).
  Страж Z1 разрешает второй `binaryTarget` sherpa, но не второй ORT.

## Серия: как идут V2–V4 (уточнят свои планы)

- **V2 `voice-text`** (Linux, ≈ 480):
  - пакет `AllySpeechText`: `StressMarks` (знак на словах от двух слогов, кроме «ё»); `Respelling` (закреплённый
    словарь, правила чтения, имена — из `speech-text.json`, перенос ударения по номеру гласной); `SpeechTextPipeline`
    над протоколом `StressPlacer`;
  - тесты Z8–Z13 с мутацией «исключение не сработало»;
  - пакет — в `LINT_SWIFT_PACKAGES`.
- **V3 `voice-accent`** (≈ 680): RUAccent на Swift.
  - Linux, в `AllySpeechText`: словарь tiny mode (111 тыс. форм), список омографов, токенизаторы — byte-level BPE с
    10 007 добавленными токенами, WordPiece, посимвольный.
  - Mac, в `AllyVoice` через `AllyOnnx`: оценщики омографов (turbo3.1 int8), «ё» и модели слов.
  - Паритет с Python на 163 позициях — Z14–Z18.
- **V4 `voice-app`** (телефон, ≈ 450):
  - `App/Sources/Audio/SupertonicVoice.swift` — `VoiceOutput`: очередь синтеза на своём акторе; AVAudioEngine:
    player → стадия сдвига (`AVAudioUnitVarispeed` или `AVAudioUnitTimePitch` по конфигу) → микшер; тап микшера даёт
    время первого отсчёта и порт звука;
  - `VoiceRegistry` в AllyCore (Linux): разбор `voice.json`, сверка размеров, строки консоли;
  - `PlayedSoundSink` в AllyCore;
  - команда копирования со сверкой sha256;
  - Milena — запасной голос;
  - примеры Z19–Z26.

## Rejected alternatives

- **ObjC-обёртка Microsoft `onnxruntime-swift-package-manager` 1.24.2** (как в стенде) — отклонена, потому что API 24
  меньше 28: sherpa 1.13.8 в том же бинаре получил бы null, а второй ORT ради него — двойные символы.
- **Сборка `csukuangfj/onnxruntime-libs` 1.28.2 основной** — отклонена, потому что сборка чужая и без своего файла
  лицензии; остаётся запасной строкой `binaryTarget`.
- **Двоичный sherpa-onnx в V1** — отклонён, потому что это исполнитель без вызывающего (L50); его кладёт поставка слуха.
- **CoreML EP и FP16** — отклонены, потому что в стенде было 37–142 разбиения на модель, синтез в 4–7 раз медленнее CPU и
  до 1,3 ГБ, а FP16 медленнее в 4,4 раза.
- **Вся реплика одним вызовом** — отклонено, потому что повторы слов начинаются уже с 0,95 (фаза 1).
- **Нарезка по запятым ради первого звука** — отклонена, потому что ломает интонацию на стыке (фаза 1); рычаг — шаги
  первой фразы.
- **Медленная скорость растяжением звука (AVAudioUnitTimePitch rate)** — отклонена, потому что UTMOS 2,3 — уровень Milena.
- **«Помоложе» экстраполяцией стилей от F5/F1/F3/F4** — отклонено, потому что при той же высоте UTMOS ниже на 0,2–0,6 —
  хуже передискретизации.
- **+3 полутона** — отклонено, потому что UTMOS −0,5 и синтез ниже пола 0,85.
- **Знак ударения только на трудных словах** — отклонён, потому что без знака голос ошибался в половине слов с ударной
  «е», «девять» и «десять» в их числе.
- **Vosk TTS** — отклонён, потому что UTMOS 3,0–3,6 против 3,8–4,2 у Supertonic, 0,9 ГБ с BERT, а чьи голоса — не
  сказано.
