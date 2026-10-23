# Tasks

Уроки по путям диффа (§2.2a): L33, L34, L50, L51, L52, L53, L54, L55 — как применены, сказано в `plan.md`.

## V4b1 `voice-config` — эта ветка

- [x] T1: спека V4b (V4b1 — таблица Z19, Z20, Z29, Z30; V4b2 — список) и STATUS — коммит d825a5d
- [x] T2: план, задачи, решения, eval-smoke — до кода
- [x] T3: эквалайзер в `AllyVoiceFX` (`eq.c`, `VoiceEQ`, `VoiceFX(pitch:formant:eq:)`), тесты Z29
- [x] T4: `VoiceSettings`, `VoiceCheck` в `AllyCore`, `voice.json`; тесты Z19, Z20
- [x] T5: `scripts/copy_voice.py`, smoke S8 `voice_copy_check.sh`
- [ ] T6: полный Z30 на стенде (Mac)
- [ ] T7: OKF (`voice-fx`, `voice-engine`, runbook `voice-loop`), verify-report, архив, урок, строка `voice-config` в
  `delivery/OBSERVATIONS.md`, PR

## V4b2 `voice-app` — своя ветка после V4b1

Голос Supertonic в приложении вместо Milena; Z20 (приложение), Z21–Z26.

## Точка остановки 23.10

Остановлено по слову родителя (лимиты сессии).

**Сделано и закоммичено:**
- эквалайзер в `AllyVoiceFX`: `eq.c`, `VoiceEQ`, `VoiceFX(pitch:formant:eq:)`; `VoiceEQTests` (Z29 и отношение) — 7 из 7
  тестов пакета зелёные на Mac;
- `VoiceSettings` и `VoiceCheck` в `AllyCore`, `App/Resources/voice.json` (пресет p9f5, 21 файл с sha256);
  `VoiceSettingsTests` (Z19, Z20) — 5 из 5;
- `scripts/copy_voice.py`: `--check` на настоящих файлах — 21 файл, 501 МБ сверено; smoke S8 `voice_copy_check.sh`
  зелёный и подключён в `run.sh`.

**Следующий шаг:**
- T6 — полный Z30 на стенде: CLI стенда с полосами «light», `port_vs_py.py` против p9f5;
- T7 — OKF (`voice-fx`, `voice-engine`, runbook `voice-loop` — команда копирования), покрытие и гейты, verify-report,
  архив, урок, строка `voice-config` в `OBSERVATIONS.md`, PR.
