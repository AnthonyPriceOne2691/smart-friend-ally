# Tasks

Уроки по путям диффа (§2.2a): L33, L34, L50, L51, L52, L53, L54, L55 — как применены, сказано в `plan.md`. По путям
`Packages/AllyCore/`, `App/`, `delivery/evals/` индекс называет ещё уроки других поставок:
- **применены:**
  - L41 — покрытие AllyCore гейт считает по его собственному `Sources/`;
  - L45 — числа строки пресета читаются `Codable` как `Double`, без моста `NSNumber`;
  - L61, L91 — запас +50% и манифест JSON по строке на объект (27 строк, а не 5 на объект);
  - L79 — в строках утверждений нет токенов «буква + цифры», кроме id примеров (стиль «F2» вынесен в свойство);
  - L80 — вне git только стенд Z30 и `~/models`; фикстуры S8 смок создаёт сам, тест Z19 читает `voice.json` из git;
  - L90 — порог скорости судят три точки: 0,80, ровно 0,85 и 0,9;
  - L7, L16, L70 — граница «продукт не ходит в сеть» не тронута: команда копирует с Mac через `devicectl`, приложение
    ничего не скачивает — сверено поиском по `voice.json` и `copy_voice.py`;
- **не задеты этой поставкой** (приложение, слух, сессии, память, энциклопедия, снимки — V4b2 и чужие поставки): L28,
  L40, L44, L46, L56, L57, L58, L59, L60, L68, L69, L71, L72, L73, L77, L78, L89.

## V4b1 `voice-config` — эта ветка

- [x] T1: спека V4b (V4b1 — таблица Z19, Z20, Z29, Z30; V4b2 — список) и STATUS — коммит d825a5d
- [x] T2: план, задачи, решения, eval-smoke — до кода
- [x] T3: эквалайзер в `AllyVoiceFX` (`eq.c`, `VoiceEQ`, `VoiceFX(pitch:formant:eq:)`), тесты Z29
- [x] T4: `VoiceSettings`, `VoiceCheck` в `AllyCore`, `voice.json`; тесты Z19, Z20
- [x] T5: `scripts/copy_voice.py`, smoke S8 `voice_copy_check.sh`
- [x] T6: полный Z30 на стенде (Mac) — PASS 2026-10-25, `results/z30_light_verdict.json`
- [x] T7: OKF (`voice-fx`, `voice-engine`, runbook `voice-loop`), verify-report, архив, урок, строка `voice-config` в
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
