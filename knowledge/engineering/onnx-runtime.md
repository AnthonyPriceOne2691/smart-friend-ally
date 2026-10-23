---
type: Decision
title: Один ONNX Runtime на приложение — пакет AllyOnnx
description: Голос и слух делят одну сборку ORT — официальный pod Microsoft onnxruntime-c 1.28.0 в Packages/AllyOnnx, слой над C API, страж «один ORT»; sherpa-onnx подключается своим xcframework без ORT.
status: accepted
tags: [engineering, onnx, runtime, voice, speech]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-23T22:00:00+03:00
implementation:
  - Packages/AllyOnnx/Package.swift
  - Packages/AllyOnnx/Sources/AllyOnnx/Onnx.swift
  - Packages/AllyOnnx/Sources/AllySherpa/Sherpa.swift
  - scripts/lint/check_single_ort.sh
---

# Context

Голосу нужен ORT для Supertonic и RUAccent, слуху — для Silero VAD и GigaAM через sherpa-onnx. Два статических ORT в одном
бинаре дают двойные символы или два рантайма разных версий API. Решение ведущего 2026-10-23, поставка `voice-onnx`
(серия голоса, пример Z1).

# Decision

- **ORT — только в `Packages/AllyOnnx`:** `binaryTarget` по URL официального pod `onnxruntime-c` 1.28.0 с checksum
  (статический xcframework iOS, симулятор, macOS; MIT; бинаря в git нет). Версия API — 28.
- **Слой над C API** (`Onnx.swift`): окружение — одно на процесс (ORT и сам держит его одним); опции — 2 потока, без
  spin, оптимизация графа; сессия из файла, external data отображается из файла; тензоры float32 и int64; ошибка с
  текстом ORT.
- **Линковка:** статическому ORT нужны `libc++` и CoreML в `linkerSettings` — без них SwiftPM падает на символах `std::`.
- **sherpa-onnx** 1.13.8 (статический xcframework) ORT не несёт: `nm -u` — только `_OrtGetApiBase` и
  `_OrtSessionOptionsAppendExecutionProvider_CoreML`, заголовки собраны с API 28. С D7.2 он в том же пакете: два
  `binaryTarget` релиза k2-fsa (iOS и macOS, url и checksum как в его `Package.swift` 1.13.8) и библиотека `AllySherpa`
  (`Sherpa.version`, `Sherpa.api = 28`); `OnnxRuntime.serves(api:)` проверяет пару на рантайме (ORT 1.28.0 отдаёт 28 и
  не отдаёт 29), а слух без неё слушает энергией.
- **Страж** `scripts/lint/check_single_ort.sh` (Linux-джоба `swift`, с отрицательным контролем): красный на втором
  `binaryTarget` с ORT и на пакетах `onnxruntime-swift-package-manager`, `onnxruntime-libs`, `k2-fsa/sherpa-onnx`
  (последний прикрепляет `onnxruntime-libs`); зелёный на `binaryTarget` sherpa из releases. Пару пинует он же (D7.2):
  sherpa 1.13.8 (iOS `6b8e769c…`, macOS `93f7a064…`) только с ORT 1.28.0 (`b503cf59…`); копия с 1.13.9 или 1.24.2 —
  красный с названием файла (отрицательный контроль в джобе `swift`).
- **Фикстура тестов** `add.onnx` (c = a + b, float32 [n, 3]) лежит в git исключением из маски `*.onnx`: без неё тесты
  `AllyOnnx` не собираются — V1a слита без неё, ручная джоба `ios.yml` не запускалась (найдено в D7.2).

# Rejected

- ObjC-обёртка Microsoft 1.24.2 — API 24 меньше 28 sherpa. Сборка `csukuangfj` 1.28.2 — чужая, без своего файла лицензии;
  оставлена запасной строкой `binaryTarget`.

# Consequences

- Бамп ORT — одна строка и прогон тестов AllyOnnx в ручной macOS-джобе; API не ниже того, с которым собран sherpa.
- Вызывающий в приложении появится с движком голоса (поставка `voice-engine`) и слухом.

# Sources

- ORT: https://github.com/microsoft/onnxruntime (MIT, v1.28.0 от 2026-07-25), pod
  https://download.onnxruntime.ai/pod-archive-onnxruntime-c-1.28.0.zip (sha256 b503cf59…a327).
- Спайки: `local/spike/tts-swift/` (Supertonic на ORT в Swift), `local/spike/speech-in/` (sherpa-onnx 1.13.8 и ORT 1.28.2).
