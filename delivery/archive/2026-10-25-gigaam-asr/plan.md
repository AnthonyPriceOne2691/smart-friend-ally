# Plan: D7.3 `gigaam-asr`

Уроки архива: **L33** — документы и eval-smoke первыми коммитами, примеры таблицей дословно; **L34, L52, L61, L91** —
бюджет по файлам с поправкой ведущего +50%, порог переноса до кода (U27 → D7.4); **L36** — лицензия GigaAM (MIT) и sherpa
(Apache-2.0) сверены `gh api` 2026-10-23; **L41** — покрытие AllyCore по своему `Sources/`, `AllyHearing` на Linux не
собирается; **L44** — кадр распознавателя — 16 кГц Int16, как у ящика; **L50, L58** — GigaAM приходит с вызывающим
(выбор в `VoiceLoop`, фраза в `PhoneListener`), новое поле проверяется через обёртку; **L56** — шаг 3 судит тот звук, на
котором посчитан живой текст (U25); **L60** — `AudioIO` и `App/Sources/Speech/` не трогаются; **L68, L69, L71** — две сессии
на одном слухе: распознаватель один на слух; **L72** — свойства на виртуальном времени — с пределом настоящего времени;
**L22, L17** — память с метрикой и рантаймом; **L23, L37** — поведение на iOS — исполнение (U28); **L35, L43, L14** —
слияние main, `mergeable`, сверка дайджеста; **L7, L16, L70** — места «распознаёт диктовка» — поиском по смыслу. Не
применимы: **L42** — наката канона нет; **L62–L64** — экран не трогается.

## Approach

1. AllyCore: `BatchPhrase` (предзапись, расшифровка с повтором только после продолжения) с декодером-замыканием; `Hearing`
   — `asr` и `recognizer(present:pair:)` с причиной; тесты U22, U25, U26 на Linux.
2. AllyHearing: `GigaAMRecognizer` над C API sherpa (`AllySherpa` D7.2), модель из external data; тесты U23, U24 на Mac.
3. App: протокол фразы для диктовки (расширение над `Phrase`) и GigaAM (`AVAudioConverter` → 16 кГц Int16 →
   `BatchPhrase`); `PhoneListener` передаёт фразе начало речи и продолжение; `VoiceLoop` — выбор, строка, `versions.asr`.
4. Знание и runbook: копирование весов GigaAM (external data), выбор распознавателя.

## Budget (800 строк, 25 файлов, рисковых путей 1: `Packages/AllyHearing/`)

| Файл | строк |
|---|---|
| `Packages/AllyCore/Sources/AllyCore/BatchPhrase.swift` | 45 |
| `Packages/AllyCore/Sources/AllyCore/Hearing.swift` (`asr`, выбор) и ресурс строк | 30 |
| `Packages/AllyCore/Tests/AllyCoreTests/RecognitionTests.swift` (U25, U26), `HearingTests.swift` (U22) | 95 |
| `Packages/AllyHearing/Sources/AllyHearing/GigaAMRecognizer.swift` | 50 |
| `Packages/AllyHearing/Tests/AllyHearingTests/GigaAMTests.swift` (U23, U24) | 60 |
| `App/Sources/Hearing/RecognitionPhrase.swift` | 55 |
| `App/Sources/PhoneListener.swift`, `App/Sources/VoiceLoop.swift`, `App/Resources/hearing.json` | 30 |
| **итого, ≈ 10 файлов** | **≈ 365** |

С поправкой +50% ≈ 550. Выше 780 — стоп и `escalation.md`.

## Rejected alternatives

- Инструмент шага 3 в этой поставке — отклонено, потому что с ним план ≈ 565, с поправкой ≈ 850 — выше стопа 780; запасной
  вариант плана серии — отдельная поставка D7.4, данные для неё появятся только после записей ящика.
- Свой fbank на C API ORT без перепаковки весов — отклонено, потому что sherpa даёт паритет со спайком бит в бит, а
  бюджет памяти держит 0,4 ГБ (решение серии).

## Test / eval strategy

`RecognitionTests` (U25, U26), `HearingTests` (U22) — Linux; `GigaAMTests` (U23, U24) — Mac; U28 — телефон.
