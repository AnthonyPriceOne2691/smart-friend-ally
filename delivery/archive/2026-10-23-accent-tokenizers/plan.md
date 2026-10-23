# Plan: токенизаторы RUAccent (V3a `accent-tokenizers`)

## Уроки по путям диффа (§2.2a)

- **L33, L51:** документы — первым коммитом до кода; Z14 — общий id серии (в V3a — часть до моделей).
- **L34, L52, L61, L63:** поправка +50% к плану (слово ведущего); стоп 780.
- **L93:** новый пакет вносит свой `.build` в `excluded` SwiftLint; **L94:** запись адаптации (`adapted.json`, карта
  ролей) — вместе с конфигом.
- **L47:** тест на Mac печатает путь и sha256 эталона и пропускает с причиной, если файлов нет.
- **L26, L43:** у каждого утверждения id примера; сверка дайджеста до пуша.

## Approach

1. `Encoding` — вход модели: `ids`, `tokens`, `typeIds`, `attentionMask`, `specialTokensMask`, `offsets` (диапазоны в
   скалярах Unicode исходной строки, у служебных — `0..<0`).
2. `CharTokenizer` — `vocab.txt`: `[bos]`, буквы строчными (`do_lower_case`), `[eos]`; неизвестная — `[unk]`.
3. `WordPieceTokenizer` — из `tokenizer.json`: BertNormalizer (чистка управляющих, пробельные → пробел; без нижнего
   регистра и снятия ударений; CJK во входе Элли нет), BertPreTokenizer (пробелы и знаки пунктуации — отдельные слова),
   жадный WordPiece с `##` (длиннее 100 знаков или без куска — `[UNK]`), `[CLS] A [SEP]`, смещения.
4. `ByteLevelBPETokenizer` — из `tokenizer.json`: добавленные токены (левый длиннейший, как Aho–Corasick
   LeftmostLongest HF), остальное — регулярка GPT-2, карта байтов в знаки, слияния по рангу, пара RobertaProcessing.
5. Оракулы: Linux — игрушечные токенизаторы, обученные HF (`tokenizers`), и их выходы на фразах — фикстуры в тестах;
   Mac — настоящие файлы и выходы токенизаторов HF, записанные в настоящем конвейере RUAccent на 163 позициях
   (`~/models/tts/ruaccent-parity/tokenizers.jsonl`). Генератор — стенд `local/spike/tts-swift/scripts/` вне git, путь и
   версии — в шапке фикстур.
6. CI: пакет — в `LINT_SWIFT_PACKAGES`, прогон jscpd, `.build` — в `excluded` SwiftLint; записи в `adapted.json` и карте
   ролей.

## Бюджет (план + 50%)

| Файл | строк |
|---|---|
| `Packages/AllyAccent/Package.swift` | 12 |
| `Encoding.swift`, чтение `tokenizer.json` | 45 |
| `CharTokenizer.swift` | 25 |
| `WordPieceTokenizer.swift` | 95 |
| `ByteLevelBPETokenizer.swift` | 100 |
| `TokenizerParityTests.swift` (Linux и Mac) | 110 |
| фикстуры (токенизаторы HF и их выходы, по записи на строку) | 15 |
| `.swiftlint.yml` | 1 |
| **итого** | **≈ 400, с поправкой ≈ 600** |

Выше 780 — стоп, `escalation.md` и к ведущему.

## Rejected alternatives

- **Свои ожидания на игрушечных словарях** — отклонено: ожидание придумал бы исполнитель; игрушечные токенизаторы
  обучает и кодирует HF, ожидание приходит из другого источника (§3.1d).
- **Пакетирование гипотез с паддингом** — отклонено: одна пара — одно `Encoding`; логиты на фиксированных токенах
  сравнит Z18 в V3c.
