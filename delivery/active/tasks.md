# Tasks — V3b accent-logic

- [ ] T1: влить ветку V3a (`origin/feat/voice-accent`, a73c80b); проверить `.build` пакета в `excluded` SwiftLint (L93)
  и пакет в `LINT_SWIFT_PACKAGES` (L94)
- [ ] T2: текст и словари (`AccentText`, `AccentDictionaries`), пробы `fix_capital`, `split_by_words`
- [ ] T3: протоколы и решения: «ё», омографы (оба пути, причуды группировки), ударения (словарь и модель слов)
- [ ] T4: `RuAccentPlacer` и зависимость на `../AllySpeechText`
- [ ] T5: запись V3a в `~/models/tts/ruaccent-parity` → фикстура стенда (< 512 КБ) → Z14 163 из 163, Z15, Z16 в CI
- [ ] T6: eval-smoke, verify-report (L43), строгий `delivery_check`, CI; архив в том же PR с уроком L102; slug
  `accent-logic` — строкой в конец `delivery/OBSERVATIONS.md`; мерж — ведущий

## Точка остановки (2026-10-23)

Пауза по решению ведущего: слита D7.1 (fad20f3), приоритет — D5. Кто доделает V3b, решит ведущий. Кода нет;
документы — 297e1e6, запись V3a разобрана.

**Следующий шаг — T1.** Влить `origin/feat/voice-accent` — каркас V3a, коммит 9682036:
- `Package.swift`: библиотека и таргет `AllyAccent`, только Foundation, iOS 17 и macOS 14; тестового таргета нет.
- `Encoding.swift`: `init(ids:tokens:typeIds:specialTokensMask:offsets:)` со значениями по умолчанию — для двойника;
  `attentionMask` вычисляемая, у BPE `offsets` пустой.
- `.swiftlint.yml` исключает `.build` (L93); `LINT_SWIFT_PACKAGES` и `adapted.json` сверить (L94).
- Конфликт `delivery/active/*` — оставить свои файлы. Тестовый таргет — `AllyAccentTests`, папка `Fixtures`,
  `resources: [.copy("Fixtures")]` (договорённость с V3a через ведущего). Если V3a к тому времени слита — влить main.

**Что известно для T2–T5:**
- Запись `~/models/tts/ruaccent-parity/` (сверять по `logits` — их Python реально посчитал):
  - `pipeline.jsonl` (977 строк, sha256 `7794c779306f3e66a283741c16ec1b3b17cf52122dddf1c93eafb4dada43158f`);
  - строка на вызов `{pos, model, text, pair, ids, tokens, special, offsets, logits, batched, logits_single}`:
    accent 419, yo 157, omograph 228 (218 пакетных, 10 одиночных, переворотов решения 0);
  - строка на позицию `{pos, id, cat, text_in, text_out}`: 173 позиции — 0–162, 1000–1008 (несколько
    предложений), `Z16`;
  - `tokenizers.jsonl` (sha256 `a9c6f6c4d96f82ca69615d21cc84dce8029e2292d9b9e89089454189e750fe01`), `manifest.json`
    (sha256 `5fe2ae4cf56d1aa2e6443db2196ff02b3268bdb043b344a9581677596c63fa83`).
- Метки: «ё» — 0 NO_YO, 1 PUNCT, 2 YO; модель слов — 0 NO, 1 STRESS_PRIMARY, 2 STRESS_SECONDARY.
- razdel на 1000–1008 режет только после `.`, `!`, `?` с пробелом; пробел между предложениями уходит к следующему
  (`string[l.stop:r.start] + r.text`), выходы склеиваются без разделителя.
- Исходник RUAccent 1.5.8.3 — `ruaccent/` в site-packages `local/research/tts/.venv`; особые слова — список в
  `omograph_model.py`. Словари рабочего каталога записи `local/spike/tts-swift/models/ruaccent-int8/dictionary`
  совпадают с `~/models/tts/ruaccent/dictionary` по sha256.
- Генератор фикстуры `local/spike/tts-swift/scripts/make_accent_replay.py` ещё не написан (T5).
