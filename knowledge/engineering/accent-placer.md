---
type: Design
title: Расстановщик ударений — RUAccent на Swift (серия голоса V3)
description: Пакет AllyAccent — настоящий StressPlacer для текста синтеза; V3a — три токенизатора RUAccent с паритетом HF, V3b — текст, словари и решения как в Python (повтор по записи), V3c — модели через AllyOnnx и примеры Z14–Z18.
status: draft
tags: [engineering, speech, tts, stress]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-23T22:30:00Z
implementation:
  - Packages/AllyAccent/Sources/AllyAccent/Encoding.swift
  - Packages/AllyAccent/Sources/AllyAccent/TokenizerFile.swift
  - Packages/AllyAccent/Sources/AllyAccent/CharTokenizer.swift
  - Packages/AllyAccent/Sources/AllyAccent/WordPieceTokenizer.swift
  - Packages/AllyAccent/Sources/AllyAccent/ByteLevelBPETokenizer.swift
  - Packages/AllyAccent/Sources/AllyAccent/AccentText.swift
  - Packages/AllyAccent/Sources/AllyAccent/AccentDictionaries.swift
  - Packages/AllyAccent/Sources/AllyAccent/AccentModels.swift
  - Packages/AllyAccent/Sources/AllyAccent/YoDecision.swift
  - Packages/AllyAccent/Sources/AllyAccent/OmographDecision.swift
  - Packages/AllyAccent/Sources/AllyAccent/StressDecision.swift
  - Packages/AllyAccent/Sources/AllyAccent/RuAccentPlacer.swift
---

# Purpose

Текст для синтеза (V2, [Speech text](/engineering/speech-text.md)) стоит над протоколом `StressPlacer`; настоящий
расстановщик — RUAccent 1.5.8.3 в tiny mode (turbo3.1 int8, «поняла»), перенесённый на Swift поверх общего ONNX Runtime.
V3 разрезана на три поставки под одной подписью (решение ведущего 2026-10-23): токенизаторы, логика, модели.

# Canonical rules

- **Вход модели — `Encoding`:** id, строки токенов, type ids, маска служебных, смещения в скалярах Unicode (как индексы
  `str` в Python); одно `Encoding` — один вход без паддинга.
- **Токенизаторы — те же id, что у HF:** посимвольный (модель слов, `vocab.txt`), WordPiece со смещениями (модель «ё»,
  `tokenizer.json`), byte-level BPE с 10 007 добавленными токенами и парой `<s> A </s></s> B </s>` (омографы).
  Паритет держат тесты: на Linux — игрушечные токенизаторы, обученные HF; на Mac — настоящие файлы и 804 входа,
  записанные в конвейере Python на 163 позициях (`~/models/tts/ruaccent-parity`).
- **Файлы моделей и словарей — вне git** (`~/models/tts/ruaccent`); в приложение их копирует команда V4.
- **Логика — Python как есть, с причудами (V3b):** `RuAccentPlacer` — фильтр `normalize` (двойная кавычка, «…», «–» и
  «+» выпадают), предложения по «.!?» перед пробельным (правила сокращений razdel не перенесены: расстановщик получает
  одну фразу контракта), слова `split_by_words` (« - » → « ~ » и обратно), «ё», омографы, ударения, склейка с
  `delete_spaces_before_punc`. «ё»: `yo_words`, модель — только если во фразе есть «е», метка — на слово RUAccent с
  тем же номером. Омографы — с учётом регистра; все гипотезы чётные — пары и softmax по всему пакету, хоть одна
  нечётная — `group_words` (особые слова тройками, чётные группы больше трёх парами) и softmax на вызов; ответы — на
  омографы по порядку, даже когда их больше (у «йодатович» две пары: второй ответ уходит соседу); меньше ответов, чем
  омографов, Python не переживает — Swift оставляет остаток без знака. Ударения: «+» словаря переносится циклом
  Python (со второго «+» позиция съезжает); модель слов — для слова не из словаря, без пунктуации, от двух гласных:
  STRESS_PRIMARY с оценкой от 0,55 ставит «+» на букву раньше позиции, позиция 0 — на последнюю букву.
- **Стыки:** `AccentModels` (стык ведущего: логиты `[2]` омографа, метки «ё» и модели слов на токен; одно `Encoding` —
  один вызов) и `AccentTokenizers` (входы — ровно строки, что Python подаёт токенизаторам; `RuAccentTokenizers` — V3a
  за протоколом). Словари — четыре простых JSON (`AccentDictionaries(directory:)`), добавки — «о» → «+о», «коса» и
  закреплённое «поняла» → «понял+а».
- **Оракул логики — повтор Python:** фикстура 385 КБ (`Tests/AllyAccentTests/Fixtures/accent_replay.json`, генератор
  `local/spike/tts-swift/scripts/make_accent_replay.py` вне git): выборка словарей под слова фраз, разметка и логиты
  каждого вызова 173 позиций и 9 проб причуд, снятых с настоящего конвейера Python с заданными логитами; генератор
  пишет фикстуру, только если Python сам повторяет по ней все 182 текста. Двойник отказывает на входе, которого Python
  не подавал, и считает несделанные вызовы. Запись стенда судит только ветки, по которым прошли её фразы (L102):
  фильтр, « - », «о», «##»-куски и [UNK] модели «ё», группы омографов держат пробы.

# Status

V3a — токенизаторы; V3b — логика: 163 из 163 позиций стенда, 9 фраз страницы, Z15 и Z16 по записи Python (Mac и
Linux). Модели — V3c; расстановщик готов, но до V4 вызывающего в приложении нет (L50).
