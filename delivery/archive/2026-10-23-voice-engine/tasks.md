# Tasks

Уроки по путям диффа (§2.2a): L33, L34, L47, L50, L52, L53 — как применены, сказано в `plan.md`.

## V1b `voice-engine` — эта ветка

- [x] T1: код и тесты движка — коммит dbd34be (до разреза, под той же подписью); `VoiceSpec` → `VoicePreset`
- [x] T2: слияние V1a (`feat/voice-onnx`) без перезаписи истории (L35); документы V1b — спека с таблицей Z2–Z7 (ссылка на
  68202f0), STATUS, план, решения, eval-smoke
- [x] T3: Z6 в тихое окно Mac (ведущий, 21:44, load 6,7): медиана 0,98 с; полный прогон `swift test --package-path Packages/AllyVoice` под
  `nice -n 10`; мутация «пол скорости убран» краснит Z4 — сделано 2026-10-23, тест красный, файл восстановлен
- [x] T4: `verify-report.md`, OKF — concept `engineering/voice-engine`, `index.md`, `log.md`; PR, CI зелёный
- [x] T5: handoff — архив поставки, строка `INDEX.md` с уроком L54; мерж — ведущий (`merge_guard.sh`)
