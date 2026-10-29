---
type: ADR
title: "Элли на Mac: приложение для iPhone прямо на Mac, а не симулятор"
description: Разговоры на Mac — то же приложение для iPhone («My Mac (Designed for iPhone)»), запуск кнопкой ⌘R в Xcode, файлы — через кнопку «Файлы с Mac…», ход — строкой без слов в системном журнале; симулятор отклонён замером — в нём нет диктовки.
status: stable
tags: [engineering, app, mac, adr]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-29T23:40:00+03:00
stale_after: 2027-01-31T00:00:00+03:00
implementation:
  - Packages/AllyCore/Sources/AllyCore/MacImport.swift
  - Packages/AllyCore/Sources/AllyCore/TraceLine.swift
  - Packages/AllyCore/Sources/AllyCore/FileDigest.swift
  - App/Sources/MacFilesButton.swift
  - scripts/mac_files.py
  - scripts/mac_app.sh
---

# Status

Принято. Решения родителя 2026-10-29 (через ведущего): «Приложение для iPhone прямо на Mac (Рекомендую)» и «Кнопка ▶
в Xcode + «Файлы с Mac…» (Рекомендую)»; примеры N1–N10 подписаны 2026-10-29 (поставка `sim-app`).

# Context

Родитель хотел, чтобы правки шли быстро, а дочь говорила с Элли через микрофон компьютера при нём: «Сначала собрать
всё на симулятор». Зонд до кода (`local/spike/sim-probe/`, вне git, фразы — синтетика `say`) показал, что симулятор
этого не даёт, а сам Mac — даёт:

| Что | Симулятор iOS 27.0 и 27.1 | Mac (macOS 27.2, M5) |
|---|---|---|
| DictationTranscriber | ассет ru-RU встаёт (`installed`, 26–58 с), но `bestAvailableAudioFormat` = nil и анализ — «Model not available»; журнал: `Assets do not support requested task name "Dictation"`; en-US — то же | ru-RU работает: проба 23.10 перегнана 29.10, `finalize` 0,03 с |
| Metal | «Apple iOS simulator GPU»: apple7, apple9, metal3 — нет, буфер ≤ 256 МБ — llama.cpp только на CPU | M5, семейства Apple — модель на GPU |
| Модель | нужен свой xcframework b10809 со слайсом симулятора | официальный слайс `ios-arm64` — те же байты, что на телефоне |
| Типы устройств | 27.1 — только «iPhone Duo», 17 Pro Max — на 27.0 | — |

Микрофон симулятора упирается в разрешение macOS для `SimulatorTrampoline`; без ответа вход ждёт 9 с и падает с RPC
timeout. На Mac приложению для iPhone предел памяти — 16 ГБ (журнал runningboard), а не 6 ГБ телефона.

# Decision

- **То же приложение для iPhone на Mac** — устройство «My Mac (Designed for iPhone)» в Xcode. Подпись — Personal Team
  из `App/Local.xcconfig`; Mac внесла в профиль автоматическая подпись Xcode под входом родителя; профиль живёт
  7 дней, его обновляет тот же ⌘R. Право `increased-memory-limit` — в профиле.
- **Запуск — только из Xcode, кнопкой родителя.** macOS исполняет приложение с подписью Apple Development лишь из
  Xcode (у него исключение для инструментов разработчика). Обёртку `Wrapper/` + `open` и прямой запуск бинаря
  syspolicyd убивает: «Terminating process due to Gatekeeper rejection», «Code did not match any currently allowed
  policy» — и показывает родителю окно «Ally не открыт». Агент приложение не запускает. `scripts/mac_app.sh` готовит
  проект и открывает его в Xcode.
- **Файлы — через само приложение.** В контейнер (`~/Library/Containers/com.anthonypriceone.ally/Data`) macOS
  оболочку агентов не пускает: TCC `SystemPolicyAppDataDetailed` — отказ по политике службы, без окна. Этот же
  запрет закрывает от агентов разговоры дочки. Поэтому:
  - `python3 scripts/mac_files.py` раскладывает `~/models/ally-mac` — `Models/`, `Voice/` и `manifest.json`. Источники
    сверяются до записи; файлы ложатся клонами APFS (на этом Mac 28 файлов, 5,50 ГБ за 5 с, место — минус 12 МБ на
    распакованные словари). В `~/Library/Containers` скрипт не пишет никогда.
  - Кнопка консоли «Файлы с Mac…» — только при `isiOSAppOnMac` и спящей Элли. Системное окно выбора папки.
    `MacImport` пускает лишь пути реестров бандла с их байтами: sha256 голоса — из `voice.json`, весов и Silero — из
    списка, который скрипт сверил с пином. Чужой путь или не тот размер — отказ целиком.
  - Каждый файл копируется рядом под временным именем, копия сверяется по размеру и sha256 (CryptoKit, `FileDigest`)
    и только потом встаёт на место; `Memory/`, `Caches/` и прочее импорт не трогает. После успешной копии прогрев
    запуска (child-open: один раз, за экраном загрузки) идёт заново; у прогретого приложения новые файлы — после ⌘R.
- **Ход — строкой в системном журнале.** `TraceLine` пишет ту же строку, что `Caches/turns.jsonl`, в os_log
  `com.anthonypriceone.ally` / `turn`; слова отбрасываются конструкцией приёмника (K9, тест N8 с мутацией). Агент
  снимает ход командой `log show --predicate 'subsystem == "com.anthonypriceone.ally" AND category == "turn"'`,
  контейнер не читая.
- **Metal или CPU** — строка консоли «модель: Metal — <устройство>» и версия `metal` следа: устройство, которое видит
  приложение и куда велено идти 99 слоям; подтверждение — время сборки префикса в «прогрев».

# Rejected alternatives

- Симулятор со своей сборкой llama.cpp и GigaAM вместо диктовки — родитель отказался: на Mac работало бы не то, что на
  телефоне, модель — на CPU.
- Исключение Gatekeeper («Всё равно открыть») и полный доступ к диску для Терминала — родитель отказался: Терминал
  видел бы данные всех приложений, включая разговоры дочки.
- Чтение файлов прямо из выбранной папки по закладке — меняет пути весов и голоса во всём приложении; копия в контейнер
  оставляет их как на телефоне.
- sha256 весов в `model.json` и отчёт llama.cpp о слоях — правки поверхности модели (§14.4) ради проверки копии и
  строки консоли.
- Нативное приложение macOS и Mac Catalyst — другие слайсы и звук мимо `AVAudioSession`.

# Consequences

- Каждый запуск и новая версия — ⌘R родителя; агент готовит папку и проект, первый ход говорит синтетикой из колонок.
- Данные дочки на Mac — в контейнере приложения: агентам недоступны, Time Machine на этом Mac не настроена (если
  включить — контейнер попадёт в копию).
- Детский экран на Mac — по поставке `child-open` (замок «при родителе» снят родителем 2026-10-29).
- Телефон не меняется: сборка `generic/platform=iOS`, `reinstall_app.sh`, пакет модели — прежние.

# Related

- [Voice loop](/engineering/voice-loop.md) — runbook: раздел «Элли на Mac».
- [Child data](/ops/child-data.md) — контейнер на Mac.
- [App architecture](/engineering/app-architecture.md) — слои приложения.
