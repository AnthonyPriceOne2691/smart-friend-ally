# Tasks — V3b accent-logic

- [ ] T1: влить ветку V3a (`origin/feat/voice-accent`, a73c80b); проверить `.build` пакета в `excluded` SwiftLint (L93)
  и пакет в `LINT_SWIFT_PACKAGES` (L94)
- [ ] T2: текст и словари (`AccentText`, `AccentDictionaries`), пробы `fix_capital`, `split_by_words`
- [ ] T3: протоколы и решения: «ё», омографы (оба пути, причуды группировки), ударения (словарь и модель слов)
- [ ] T4: `RuAccentPlacer` и зависимость на `../AllySpeechText`
- [ ] T5: запись V3a в `~/models/tts/ruaccent-parity` → фикстура стенда (< 512 КБ) → Z14 163 из 163, Z15, Z16 в CI
- [ ] T6: eval-smoke, verify-report (L43), строгий `delivery_check`, CI; архив в том же PR с уроком L102; slug
  `accent-logic` — строкой в конец `delivery/OBSERVATIONS.md`; мерж — ведущий
