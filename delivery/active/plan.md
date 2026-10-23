# Plan: модели RUAccent и сборка расстановщика (V3c `accent-onnx`)

## Уроки по путям диффа (§2.2a)

- **L33, L51:** документы — первым коммитом; Z14–Z18 — общие id серии.
- **L34, L52, L61, L63:** поправка +50% (слово ведущего), стоп 780.
- **L47:** тесты печатают пути и sha256 моделей и эталонов, без файлов — пропуск с причиной.
- **L22:** память — отпечаток (`phys_footprint`), а не RSS; Z17 меряет отпечаток.
- **L50:** расстановщик без вызывающего до V4 — «готов, не подключён».
- **L94:** запись адаптации — вместе с конфигом (`ios.yml`, если меняется).

## Approach

1. `Packages/AllyVoice` получает зависимость `../AllyAccent` (тип `Encoding`, позже `AccentModels` и `RuAccentPlacer`).
2. `RUAccentModels`: три `OnnxSession` (по умолчанию 2 потока, без spin); вход — `input_ids` и `attention_mask`
   (int64, `[1, n]`), у модели слов ещё `token_type_ids`; выход `logits`: омографы `[1, 2]` → `[Float]`, «ё» и модель
   слов `[1, n, 3]` → `[[Float]]`, строка на каждый токен.
3. Z18 (сразу): на каждый вызов модели из `pipeline.jsonl` — те же id в Swift, разница логитов с одиночным вызовом
   onnxruntime 1.31 ≤ 1e-4 (у пакетных омографов — `logits_single`).
4. После мержа V3b: `RUAccentModels: AccentModels`; `RuAccentPlacer(dictionaries:tokenizers:models:)`; Z14 (тексты
   Python, ≥ 162 из 163), Z15 (группа Y — 8 из 8, как Python), Z16 («аксолотлик» → «аксол+отлик» → «аксоло́тлик» через V2),
   Z17 (медиана ≤ 40 мс на фразу, отпечаток ≤ 120 МБ).

## Бюджет (план + 50%)

| Файл | строк |
|---|---|
| `Packages/AllyVoice/Package.swift` | 3 |
| `RUAccentModels.swift` | 60 |
| сборка расстановщика (`RUAccentVoice.swift`: пути, `RuAccentPlacer`) | 40 |
| `AccentOnnxParityTests.swift` (Z18) | 45 |
| `AccentParityTests.swift` (Z14–Z16), `AccentCostTests.swift` (Z17) | 90 |
| **итого** | **≈ 240, с поправкой ≈ 360** |

Выше 780 — стоп, `escalation.md` и к ведущему.

## Rejected alternatives

- **Пакетные вызовы омографов, как в Python** — отклонено: одна пара — один вызов (контракт V3b); решения те же (0 из
  109 пар перевернулось на записи), логиты сравниваются с одиночными вызовами Python.
