# Tasks

Уроки — в `plan.md`; урок поставки — L80.

- [x] T1: документы D7.2 и eval-smoke первым коммитом (L33) — этот коммит
- [ ] T2: AllyCore — `VoiceActivity`, `EnergyActivity` (переезд энергии без правок A17, A25–A27), `activity` в
  `TurnDetector`, `lastVoiced = time − lag`; U18; мутация «запаздывание не вычитается»
- [ ] T3: AllyCore — `Hearing.vad`, выбор слуха и строки консоли (`listening.json`); U16 (б), U19; мутации «API не
  проверяется», «размер файла не сверяется»
- [ ] T4: `AllyOnnx` — `binaryTarget` sherpa iOS и macOS, `AllySherpa`, `OnnxRuntime.serves(api:)`; пин пары в
  `check_single_ort.sh` и отрицательный контроль (1.13.9, 1.24.2) в джобе `swift`
- [ ] T5: `AllyHearing` — `SileroVAD`, `SileroActivity`, `OnnxPair.current`, выбор; U16 (а), U17 на Mac; `.swiftlint.yml`;
  шаг `ios.yml`
- [ ] T6: приложение — `hearing.json`, `project.yml`, `VoiceLoop`, `PhoneListener` (стык с D7.1); сборка без подписи и
  оракул артефакта
- [ ] T7: знание — `turn-detector.md`, `onnx-runtime.md`, `voice-loop.md`, log; места «конец речи меряет энергия» —
  поиском (L7, L16, L70)
- [ ] T8: verify-report, строгий `delivery_check`, L43, архив, урок L80 (строка INDEX), slug в `delivery/OBSERVATIONS.md`;
  слияние main после D7.1; доклад «готово к мержу»
