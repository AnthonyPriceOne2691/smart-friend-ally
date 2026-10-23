# Tasks

Уроки по путям диффа (§2.2a): L33, L34, L50, L51, L52, L53, L54 — как применены, сказано в `plan.md`.

## V4a `voice-fx` — эта ветка

- [x] T1: спека V4 (V4a — таблица Z27–Z31, V4b — Z19–Z26 списком с правками третьего круга) и STATUS — коммит bf827a4
- [x] T2: план, задачи, решения, eval-smoke; пресет «Совсем малышка»; замер прототипа `psola_c` и своего трекера на
  стенде — до кода
- [ ] T3: подпись родителя под Z27–Z31 и правками V4b — отдельным коммитом; `human_ok_spec`, `human_ok_plan` → `yes`
- [ ] T4: C-ядро — `pitch.c` (свой трекер), `psola.c` (порт `dsp.py`), `eq.c`; `VoiceFX.swift`
- [ ] T5: тесты Z27, Z28, Z29, Z31 (Linux); стенд Z30 (Mac) с контролем `psola_c`; CI — `LINT_SWIFT_PACKAGES`, jscpd
- [ ] T6: verify-report, OKF (`engineering/voice-engine` — стадия обработки), PR, сдача с уроком L55, строки
  `voice-engine` и `voice-fx` в `delivery/OBSERVATIONS.md`

## V4b `voice-app` — своя ветка после V4a

Приложение: голос Supertonic через протоколы, PSOLA и эквалайзер по пресету «Совсем малышка», имя «Э́льли», файлы
голоса и словари RUAccent (распаковка `.gz` и sha256 распакованного на Mac), первый звук и этапы в журнал, порт звука,
Milena при нехватке файлов; Z19–Z26.
