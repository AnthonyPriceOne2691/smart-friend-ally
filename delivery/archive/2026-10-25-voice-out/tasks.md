# Tasks

Уроки по путям диффа (§2.2a) — как применены, сказано в `plan.md`.

## V4b2a `voice-out` — эта ветка

- [x] T1: спека V4b2 (V4b2a — таблица Z21, Z23–Z25; V4b2b — список; стык D6.1) и STATUS — коммит 1f25c9c
- [x] T2: план, задачи, решения, eval-smoke — до кода
- [x] T3: `VoicePorts.swift`, `SpokenVoice.swift`; подсказка в `TurnRunner`, `Session`, `Speaking`; `first_steps`
- [x] T4: `SpokenVoiceTests` (Z21, Z23, Z24, Z25), `first_steps` тремя точками; мутации вручную
- [x] T5: OKF, verify-report, архив, строка `voice-out` в `delivery/OBSERVATIONS.md`, PR

## V4b2b `voice-app` — своя ветка после V4b2a

Приложение: `SupertonicVoice(engine:)` — рендер (текст с заглушкой расстановщика, Supertonic, PSOLA и эквалайзер по
пресету) и проигрыватель на переданном `AVAudioEngine`; Milena при нехватке файлов; журнал; `EchoVoice` передаёт
подсказку; `project.yml`; сборка. Телефон — сессия теста.
