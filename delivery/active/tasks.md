# Tasks — V3b accent-logic

Уроки по путям: L14, L26, L33, L43, L50, L51, L59, L64, L67, L75, L92, L93, L94, L101 — как применены, сказано в `plan.md`.

- [x] T1: влита ветка V3a целиком (`origin/feat/voice-accent` 0a1dab1, слияние 652d5cf; решение — `decisions.md`):
  каркас, токенизаторы, тестовый таргет `AllyAccentTests` с `Fixtures`; `.build` пакета в `excluded` SwiftLint (L93),
  пакет в `LINT_SWIFT_PACKAGES`, пятый прогон jscpd и `adapted.json` — от V3a (L94, сверено)
- [x] T2: текст и словари (`AccentText`, `AccentDictionaries`) — пробы фильтра и пунктуации, `fix_capital`
- [x] T3: протоколы и решения: «ё», омографы (оба пути, причуды группировки, ответы по порядку), ударения (словарь и
  модель слов)
- [x] T4: `RuAccentPlacer` и зависимость на `../AllySpeechText`; адаптер `RuAccentTokenizers` над токенизаторами V3a
- [x] T5: запись V3a → фикстура стенда 385 КБ (генератор `local/spike/tts-swift/scripts/make_accent_replay.py`,
  самопроверка Python) → Z14 163 из 163 и 9 фраз страницы, Z15 8 из 8, Z16 на Mac; 9 проб причуд; мутации 25 из 25
- [ ] T6: слить main после мержа V3a (PR #55, f416f21 — слито 3d97898, дифф только свой); eval-smoke, verify-report (L43), строгий
  `delivery_check`, CI на Linux; архив в том же PR с уроком L102; slug `accent-logic` — строкой в конец
  `delivery/OBSERVATIONS.md`; мерж — ведущий

## Точка остановки (2026-10-23) — снята

Пауза была по решению ведущего (приоритет D5); доделывает второй исполнитель с T1. Push ждёт мержа V3a: пока её код в
диффе против main, предохранитель считает net 1219 строк при пределе 800 (свой дифф — net 683).
