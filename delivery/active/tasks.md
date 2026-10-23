# Tasks

Уроки по путям диффа (§2.2a): L33, L34, L36, L47, L50, L51, L52 (серия и бюджет), L22, L23, L44 (`App/`, замеры
телефона) — как применены, сказано в `plan.md`.

## V1 `voice-onnx` — эта ветка

### Slice 0 — документы и подпись
- [x] T1: `spec.md` (серия V1–V4, примеры Z1–Z26: таблица V1, списки V2–V4) и `STATUS.md` первым коммитом ветки
  `feat/voice-supertonic`, до кода (L33) — коммит 68202f0
- [x] T2: `plan.md`, `tasks.md`, `decisions.md`, `eval-smoke.md` — вторым коммитом, до кода — коммит bbcd6b3
- [x] T3: подпись родителя под спекой и планом — отдельным коммитом до кода; `human_ok_spec`, `human_ok_plan` → `yes`,
  `phase: implement` (родитель 2026-10-23 «Подписываю (Рекомендую)»: вопросы 3–5 по рекомендациям, 1–2 ждут второй круг;
  ведущий: строки V1 — вариант (а))

### Slice 1 — `Packages/AllyOnnx`
- [ ] T4: `Package.swift` — `binaryTarget` ORT 1.28.0 (URL и checksum), `COnnxRuntime`, `AllyOnnx`, `linkerSettings`
  (c++, CoreML)
- [ ] T5: `Onnx.swift` — окружение, опции, сессия, тензоры, запуск, ошибка; `AllyOnnxTests` (версия и API, нет файла,
  `add.onnx`)
- [ ] T6: `scripts/lint/check_single_ort.sh` и отрицательный контроль в `quality.yml` (Z1)

### Slice 2 — `Packages/AllyVoice`
- [ ] T7: `SpeechEngine.swift`, `VoiceStyle.swift`, `Noise.swift`; Z7 с двойником
- [ ] T8: `SupertonicText.swift` — индексы фраз паритета равны индексам Python (из эталона)
- [ ] T9: `SupertonicEngine.swift`; Z2–Z6; мутация «пол скорости убран» краснит Z4
- [ ] T10: шаги `ios.yml`; прогон меткой `macos` один раз, когда Slice 2 зелёный локально

### Slice 3 — проверка и передача
- [ ] T11: `verify-report.md` — факты Z1–Z7 с числами (SNR, отпечаток, время), диф по строкам против плана
- [ ] T12: OKF — concept `knowledge/engineering/voice-synthesis.md` (`implementation`: `Packages/AllyOnnx/`,
  `Packages/AllyVoice/`), `index.md` и `log.md`; `KNOWLEDGE.md` §6 — выжимка
- [ ] T13: PR, CI зелёный, мерж — ведущий (`merge_guard.sh`); архив и строка `INDEX.md` с уроками L53–L55

## V2–V4 — свои ветки после мержа V1 (V2 можно параллельно)

Задачи — в их `tasks.md`; примеры — Z8–Z26 этой спеки.
