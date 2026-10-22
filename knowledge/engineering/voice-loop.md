---
type: Runbook
title: Голосовой цикл приложения — сборка, веса, запуск, журнал
description: Как собрать Ally, положить веса модели на телефон, запустить с консолью взрослого и забрать журнал хода без слов; что цикл делает и чего не делает.
status: draft
tags: [engineering, app, voice, runbook]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-22T19:30:00+03:00
stale_after: 2027-01-31T00:00:00+03:00
implementation:
  - App/project.yml
  - App/Resources/model.json
  - App/Sources/VoiceLoop.swift
  - App/Sources/Audio/AudioIO.swift
  - App/Sources/Audio/SystemVoice.swift
  - App/Sources/Speech/DictationRecognizer.swift
  - Packages/AllyLlama/Sources/AllyLlama/LlamaModel.swift
---

# Purpose

Первая сборка продукта (поставка `app-voice-loop`, D1.2): на телефоне родителя по тапу подруга отвечает голосом, и каждый
ответ модели проходит контракт хода. Детской поверхности нет — только консоль «Для взрослых» (E2). Здесь — что делает
цикл и как его собрать, поставить, запустить и проверить командами.

# Canonical rules

- **Ход:** тап → микрофон (`.playAndRecord`, `.default`, `.defaultToSpeaker`) → кадры в определитель конца речи ядра
  (хвост 0,8 с, тип `closed` — один хвост для взрослой консоли; детские хвосты и спекуляция — D7) и в распознаватель →
  конец речи → микрофон закрыт (полудуплекс: она не слышит себя) → `DictationTranscriber` ru-RU дописывает текст →
  `TurnRunner` (режим `talk`) → голос → строка журнала. 8 с без речи — ход кончается без ответа; 20 с речи — предел хода.
- **Модель** — `LlamaModel` (llama.cpp b10809): веса через mmap с ленивым чтением, все слои на GPU, n_ctx 8192, четыре
  последовательности с общим KV и полным окном SWA (KV 448 МиБ — сверено по журналу llama.cpp на Mac). Системный ход
  персоны (1764 токена) живёт в последовательности 0, разговор — её копия в 1 и остаётся в KV: ход дописывает только
  себя. Отменённый или упавший ход из KV удаляется. Префикс пишется файлом состояния ≈ 49,9 МБ в `Caches/` с ключом из
  персоны, имени и размера весов и параметров рантайма; на Mac чтение 0,015–0,018 с против сборки 1,9–3,1 с, а файл с
  чужим ключом не читается — префикс собирается заново.
- **Голос** — системная Milena по идентификатору из реестра; нет enhanced — compact с видимой пометкой в консоли (П23);
  темп ставится в каждом вызове (П17).
- **Сети нет:** правило SwiftLint `no_network` на исходниках и `scripts/lint/check_app_artifact.sh` на собранном `.app`.
  Нет русской диктовки — строка «нет русской модели диктовки», загрузки нет.
- **Данные:** веса — `Library/Application Support/Models` (каталог помечен «не в бэкап»), журнал — `Library/Caches/turns.jsonl`
  (вне бэкапа, без слов: кириллица пишется как `redacted`), услышанное и сказанное — только на экране.
- **Чего нет в D1.2:** маршрутизатора в цикле (крючок — D2), режимов `why` и `goodbye`, памяти, перебивания и эхоподавления,
  переустановки одной командой (D2).

# Сборка на Mac

Пакеты с удалёнными артефактами собираются без связки ключей (ассет llama.cpp публичный):

```bash
cd "<репозиторий>/App" && xcodegen generate
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Ally.xcodeproj -scheme Ally -destination 'generic/platform=iOS' -derivedDataPath build \
  -packageAuthorizationProvider netrc CODE_SIGNING_ALLOWED=NO build     # без подписи: CI и оракул артефакта
bash ../scripts/lint/check_app_artifact.sh                               # A7: сеть, ключи Info
swift test --disable-keychain --package-path ../Packages/AllyLlama        # A23: паритет со стендом (веса в ~/models)
```

Подпись на телефон — команда разработчика в `App/Local.xcconfig` (вне git, одна строка `DEVELOPMENT_TEAM = <команда>`):

```bash
xcodebuild -project Ally.xcodeproj -scheme Ally -destination "id=<UDID>" -derivedDataPath build \
  -packageAuthorizationProvider netrc -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
bash ../scripts/lint/check_app_artifact.sh build/Build/Products/Debug-iphoneos/Ally.app   # A8: права подписи
```

macOS может спросить доступ `codesign` к ключу разработчика — это окно для рук владельца Mac.

# Установка, веса, запуск

```bash
xcrun devicectl device install app --device <UDID> build/Build/Products/Debug-iphoneos/Ally.app
xcrun devicectl device process launch --device <UDID> --console --terminate-existing com.anthonypriceone.ally
# первый запуск создаёт Models и пишет «модели нет: скопируй с Mac»; затем веса (4,64 ГБ, ≈ 3,5 мин по Wi-Fi):
shasum -a 256 ~/models/gemma-4-E4B-it-Q4_K_M.gguf    # 85a896a0… — пин в delivery/model_surface.txt
xcrun devicectl device copy to --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source ~/models/gemma-4-E4B-it-Q4_K_M.gguf \
  --destination "Library/Application Support/Models/gemma-4-E4B-it-Q4_K_M.gguf"
```

Первый запуск новой подписи — доверие сертификату на телефоне: Настройки → Основные → VPN и управление устройством (L15).
Бесплатная подпись живёт 7 дней: консоль пишет «подпись: осталось N дн.», при N ≤ 1 — «переустанови с Mac».
Телефон во время прогонов не блокировать: блокировка останавливает работу GPU.

# Журнал, снимок экрана, падения

```bash
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source Library/Caches/turns.jsonl --destination local/…/turns.jsonl
xcrun devicectl device capture screenshot --device <UDID> --destination local/…/console.png
xcrun devicectl device info files --device <UDID> --domain-type systemCrashLogs
```

Строка журнала: `rules`, `contract_hash`, `source` (модель или `canned:…`), `model_timeout`, `stages` (`tail`,
`recognize`, `speech_end_to_sound`, `first_text`, `first_sentence`, `first_sound`, `reply_end` — секунды), `versions`
(iOS, сборка llama.cpp, sha256 персоны, голос, вес по ключу «файл:байты»), `memory` (`footprint_mb`,
`footprint_peak_mb`, `available_mb`, `context_tokens`), `thermal`.

# Как откатить и кого звать

Откат — удалить приложение с телефона (веса и журнал уходят вместе с контейнером); код — revert коммита поставки. Решения
об установке и о данных на телефоне принимает родитель; сборку и проверки ведёт агент поставки по этому runbook.

# Related

- [Model on phone](/engineering/model-on-phone.md) — зонд, с которого перенесены настройки звука, речи и модели.
- [Turn detector](/engineering/turn-detector.md) — конец реплики ядра.
- [Safety below the model](/engineering/safety-below-model.md) — контракт хода и реестр правил персоны.
- [App architecture](/engineering/app-architecture.md) — ADR: слои приложения и отклонённые варианты.
