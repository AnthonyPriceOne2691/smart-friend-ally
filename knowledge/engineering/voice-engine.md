---
type: Design
title: Движок голоса — Supertonic 3 за протоколом SpeechEngine
description: Одна фраза за вызов на общем ONNX Runtime (AllyOnnx), веса в external data, 2 потока без spin, скорость синтеза не ниже 0,85; паритет с Python бит в бит; другой движок — другая реализация протокола.
status: draft
tags: [engineering, voice, tts, supertonic]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-23T23:00:00+03:00
implementation:
  - Packages/AllyVoice/Sources/AllyVoice/SpeechEngine.swift
  - Packages/AllyVoice/Sources/AllyVoice/SupertonicEngine.swift
  - Packages/AllyVoice/Sources/AllyVoice/SupertonicText.swift
  - Packages/AllyCore/Sources/AllyCore/VoiceSettings.swift
---

# Purpose

Голос Элли на телефоне — нейросетевой синтез вместо Milena (решение родителя 2026-10-22). Здесь — что держит движок
(`Packages/AllyVoice`, поставка `voice-engine`, серия голоса); текст для синтеза — [Speech text](speech-text.md), рантайм —
[ONNX Runtime](onnx-runtime.md).

# Canonical rules

- **Протокол `SpeechEngine`:** фраза → моно float32 с частотой и предсказанной длительностью; пустой текст — ошибка, не
  падение. Приложение зависит только от протокола: другой движок — другая реализация (слово родителя 2026-10-23).
- **Одна фраза за вызов:** реплика из нескольких предложений одним вызовом повторяет слова уже с 0,95, по одной фразе — 0
  из 96 при 0,85–1,05 (замер 2026-10-22).
- **Скорость синтеза не ниже 0,85** (`VoicePreset.minSpeed`): при 0,8 — 3 повтора из 96 длинных предложений. Ниже —
  ошибка «скорость синтеза … ниже 0,85».
- **Пресет** — стиль голоса («F2» или линейная смесь «F2+F5:w», как у стенда), скорость, шаги денойзинга, seed.
- **Строка пресета** — одна строка `App/Resources/voice.json` (V4b1). В ней стиль, скорость, шаги, высота, форманты и
  полосы эквалайзера; по умолчанию «Совсем малышка». Правка строки меняет голос без кода. Скорость ниже 0,85 — строка
  консоли «скорость 0,80 ниже 0,85 — взято 0,85» и 0,85. Неизвестная полоса — ошибка строки, не тихое умолчание.
- **Веса — в external data:** ORT отображает их из файла, отпечаток +33 МБ после загрузки и +64 МБ на пике фразы на Mac;
  2 потока без spin-wait. Весов в git нет.
- **Паритет с эталоном:** разбор текста шаг в шаг с supertonic-py 1.3.1 на скалярах Unicode (U+0301 — обычный символ
  словаря); на шуме эталона звук совпадает с Python бит в бит (4 фразы из 5 и смесь), на пятой — 107 дБ.

# Sources

- Supertonic 3: https://huggingface.co/Supertone/supertonic-3 (модель — OpenRAIL-M), код — MIT, репозиторий в архиве.
- Стенды: `local/spike/tts-swift/` (Swift на ORT), `local/spike/voice-samples/` (повторы и скорость, образцы).
