# Tasks

Уроки — в `plan.md`; урок поставки — L80. По путям (§2.2a): L53 — `libc++` и CoreML уже в `COnnxRuntime`, sherpa ссылается
на два символа ORT — `AllySherpa` линкуется без своих настроек; L73 — Silero вошёл через шов активности, прежние тесты
определителя прошли без правок утверждений; L72 — U18 на конечных кадрах без async, повиснуть нечему; L51 — U16–U21
свободны в `Packages/*/Tests` (буква U серии); L46 — снимков телефона нет; L56 — Silero судит звук тапа, а не сжатый;
L57 — гейт данных ребёнка не меняется, данные U17 — публичные, вне git; L28, L40 — n/a: признаков-списков и нарезки
потока поставка не трогает.

- [x] T1: документы D7.2 и eval-smoke первым коммитом (L33) — этот коммит
- [x] T2: AllyCore — `VoiceActivity`, `EnergyActivity` (переезд энергии без правок A17, A25–A27), `activity` в
  `TurnDetector`, `lastVoiced = time − lag`; U18; мутация «запаздывание не вычитается» — bcd0c46
- [x] T3: AllyCore — `Hearing.vad`, выбор слуха и строки консоли (`listening.json`); U16 (б), U19; мутации «API не
  проверяется», «размер файла не сверяется» — 82a1a9d
- [x] T4: `AllyOnnx` — `binaryTarget` sherpa iOS и macOS, `AllySherpa`, `OnnxRuntime.serves(api:)`; пин пары в
  `check_single_ort.sh` и отрицательный контроль (1.13.9, 1.24.2) в джобе `swift`; фикстура `add.onnx` — 82a1a9d
- [x] T5: `AllyHearing` — `SileroVAD`, `SileroActivity`, `OnnxPair.current`, выбор; U16 (а), U17 на Mac; `.swiftlint.yml`;
  шаг `ios.yml` — 464daec
- [x] T6: приложение — `hearing.json`, `project.yml`, `VoiceLoop`, `PhoneListener` (стык с D7.1); сборка без подписи и
  оракул артефакта — 567c644
- [x] T7: знание — `turn-detector.md`, `onnx-runtime.md`, `voice-loop.md`, `safety-below-model.md`, `repo-map.md`, log;
  места «конец речи меряет энергия» — поиском по «Silero», «энерги», «по энергии» (L7, L16, L70): нашлись
  `KNOWLEDGE.md` §5 и строка Smart Turn в `turn-detector.md`
- [x] T8: verify-report, строгий `delivery_check`, L43, архив, урок L80 (строка INDEX), slug в `delivery/OBSERVATIONS.md`;
  слияние main после D7.1; доклад «готово к мержу» — сдача
