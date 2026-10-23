---
type: Design
title: Расстановщик ударений — RUAccent на Swift (серия голоса V3)
description: Пакет AllyAccent — настоящий StressPlacer для текста синтеза; V3a — три токенизатора RUAccent с паритетом HF, V3b — текст, словари и решения, V3c — модели через AllyOnnx и примеры Z14–Z18.
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

# Status

V3a — токенизаторы; логика (V3b) и модели (V3c) — следом; до V4 вызывающего в приложении нет (L50).
