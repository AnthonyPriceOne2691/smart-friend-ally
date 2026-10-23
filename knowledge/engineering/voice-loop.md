---
type: Runbook
title: Голосовой цикл приложения — сборка, веса, запуск, журнал
description: Как собрать Ally, положить веса модели на телефон, переустановить одной командой, запустить с консолью взрослого и забрать след хода без слов; что делает сессия в консоли и чего не делает.
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
  - App/Sources/PhoneListener.swift
  - App/Sources/AllyApp.swift
  - scripts/reinstall_app.sh
  - App/Sources/Audio/AudioIO.swift
  - App/Sources/Audio/SystemVoice.swift
  - App/Sources/Speech/DictationRecognizer.swift
  - Packages/AllyLlama/Sources/AllyLlama/LlamaModel.swift
---

# Purpose

Приложение на телефоне родителя (D1.2 `app-voice-loop`, D2.2 `app-session`): тап «Разбудить» будит подругу, дальше
разговор идёт сессией без кнопок — каждая реплика проходит маршрутизатор, каждый ответ модели — контракт хода. Детской
поверхности нет — только консоль «Для взрослых» (E2; детский режим — поставка R и «оболочка»). Здесь — что делает
сессия и как собрать, поставить, переустановить, запустить и проверить приложение командами.

# Canonical rules

- **Сессия (D2.2):** «Разбудить» → приветствие → микрофон открывается сам, только пока сессия слушает (listening,
  windingDown), и закрыт, пока Элли говорит (полудуплекс) — драйвер `Conversation` ядра со слухом `PhoneListener` →
  `RouterRouting` до модели (скрипт — без модели; реплика с `forget` к модели не идёт) → `TurnRunner` с решением и её
  репликой → голос → запись следа. Промахи, отдых, её «пока» и мягкий лимит (`session_limit_minutes`, по умолчанию 10)
  решает сессия ([Session](/engineering/session.md)). «Стоп» глушит сразу, без фразы; если Элли слушала, микрофон гаснет к
  концу слушания (≤ 8 с: у `AudioIO` нет отмены, правка — D6), а новая сессия ждёт его конца.
- **Слушание:** микрофон (`.playAndRecord`, `.default`, `.defaultToSpeaker`, буфер 20 мс) → кадры по 20 мс в
  определитель конца речи ядра (хвост 0,8 с, тип `closed` — один хвост для взрослой консоли; детские хвосты и
  спекуляция — D7) и буферы — в распознаватель → конец речи → микрофон закрыт → `DictationTranscriber` ru-RU дописывает
  текст. 8 с без речи — тишина (сессия скажет «не расслышала», на второй раз — отдых); 20 с речи — предел реплики.
- **Модель** — `LlamaModel` (llama.cpp b10809): веса через mmap с ленивым чтением, все слои на GPU, n_ctx 8192, четыре
  последовательности с общим KV и полным окном SWA (KV 448 МиБ — сверено по журналу llama.cpp на Mac). Системный ход
  персоны (1764 токена) живёт в последовательности 0, разговор — её копия в 1 и остаётся в KV: ход дописывает только
  себя. Отменённый или упавший ход из KV удаляется. Префикс пишется файлом состояния ≈ 49,9 МБ в `Caches/` с ключом из
  персоны, имени и размера весов и параметров рантайма; на Mac чтение 0,015–0,018 с против сборки 1,9–3,1 с, а файл с
  чужим ключом не читается — префикс собирается заново.
- **Кадр определителя — 20 мс, как в его тестах.** iOS отдаёт буфер микрофона ≈ 100 мс даже при запросе 1024 кадров:
  на телефоне 2026-10-22 хвост срабатывал на 0,90 с вместо 0,8, и ещё ≈ 0,1 с уходило на конец буфера. Поэтому сессия
  просит буфер 20 мс, а буфер тапа режется на кадры по 20 мс; фактическая длина буфера — `tap_buffer` в журнале.
- **Голос** — системная Milena по идентификатору из реестра; нет enhanced — compact с видимой пометкой в консоли (П23);
  темп 0,42 из реестра (`voice_rate`; родитель: на 0,5 «торопится, глотает слова») ставится в каждом вызове (П17).
  Значение реестра читается как Double: `NSNumber` 0,42 не приводится к Float, и чтение `as? Float` молча давало 0,5.
  Milena — временный голос: ударения и тон не те (родитель на слух 2026-10-22), голос с ударениями — следующая поставка.
- **Сети нет:** правило SwiftLint `no_network` на исходниках и `scripts/lint/check_app_artifact.sh` на собранном `.app`.
  Нет русской диктовки — строка «нет русской модели диктовки», загрузки нет.
- **Данные:** веса — `Library/Application Support/Models` (каталог помечен «не в бэкап»), след хода —
  `Library/Caches/turns.jsonl` (вне бэкапа, без слов: кириллица пишется как `redacted`), услышанное и сказанное — только
  на экране. Чёрный ящик (D3.2) — `Library/Application Support/BlackBox`: только детские сессии при родителе (`audience:
  supervised`), класс `NSFileProtectionComplete`, пометка «не в бэкап» читается обратно; её звук — отсчёты того же
  буфера, что ушёл в распознаватель (крючок в `Phrase.feed`, только PCM16 моно, формат — в строке готовности
  диктовки); строка ящика — в консоли и в журнале `blackbox:` без слов; «Стереть чёрный ящик» — с подтверждением, только
  когда Элли спит. Начала её речи аудиопуть не отдаёт — паузы до речи в записи нет.
- **Чего нет:** режима `why`, памяти, перебивания и эхоподавления (D6), детского режима и экрана (R, «оболочка»),
  экрана настроек под замком (D8).

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

# Переустановка одной командой (E4)

Бесплатная подпись живёт 7 дней — раз в неделю приложение ставится заново поверх, без удаления:

```bash
bash scripts/reinstall_app.sh <UDID>
```

Скрипт проверяет, что телефон на связи (нет — стоп до сборки), снимает список `Library/Application Support/Models`,
собирает с подписью, гоняет оракул артефакта, ставит поверх (`devicectl device install app`), снова снимает список —
веса из реестра на месте и того же размера, иначе печатает команду копирования и выходит с 1, — печатает срок новой
подписи и запускает приложение. Приложение и файлы контейнера не удаляет никогда. Ставит на телефон только решение
родителя.

# Установка, веса, запуск

```bash
xcrun devicectl device install app --device <UDID> build/Build/Products/Debug-iphoneos/Ally.app
xcrun devicectl device process launch --device <UDID> --console --terminate-existing com.anthonypriceone.ally
# лимит сессии на прогон (ключ session_limit_minutes, 1–60; вне диапазона — 10 и строка в консоли):
xcrun devicectl device process launch --device <UDID> --terminate-existing com.anthonypriceone.ally -- -session_limit_minutes 2
# первый запуск создаёт Models и пишет «модели нет: скопируй с Mac»; затем веса (4,64 ГБ, ≈ 3,5 мин по Wi-Fi):
shasum -a 256 ~/models/gemma-4-E4B-it-Q4_K_M.gguf    # 85a896a0… — пин в delivery/model_surface.txt
xcrun devicectl device copy to --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source ~/models/gemma-4-E4B-it-Q4_K_M.gguf \
  --destination "Library/Application Support/Models/gemma-4-E4B-it-Q4_K_M.gguf"
```

Первый запуск новой подписи — доверие сертификату на телефоне: Настройки → Основные → VPN и управление устройством (L15).
Бесплатная подпись живёт 7 дней: консоль пишет «подпись: осталось N дн.», при N ≤ 1 — «переустанови с Mac».
Телефон во время прогонов не блокировать: блокировка останавливает работу GPU.

# След хода и падения

```bash
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source Library/Caches/turns.jsonl --destination local/…/turns.jsonl
xcrun devicectl device info files --device <UDID> --domain-type systemCrashLogs
```

Снимков экрана телефона не делаем: `devicectl device capture screenshot` снимает то, что на переднем плане, — на личном
телефоне это бывает чужое приложение с перепиской (случай 2026-10-22: снимок удалён сразу). Экран (консоль «Для
взрослых», точка микрофона) подтверждает родитель на глаз.

Строка следа (`TurnTrace`, с D2.2 вместо журнала `TurnLog`; одна на ход, включая фразы сессии): `session`, `turn`,
`phase`, `mode`, `source` (`model`, `canned:…`, `script:<ключ>`, `session:<фраза>`), `route` (вид, тема, ключ, правила,
хэш данных маршрутизатора, `forget`), `rules`, `contract_hash`, `model_timeout`, `cancelled`, `error`, `elapsed`, `limit`,
`end` (у последней записи сессии: `limit`, `goodbye_word`, `rest`, `parent`, `error`), `stages` (`tail`, `recognize`,
`speech_end_to_sound`, `tap_buffer` — этапы слушания приложения; `first_text`, `first_sentence`, `first_sound`,
`reply_end` — этапы хода; секунды), `versions` (iOS, сборка llama.cpp, sha256 персоны, голос, вес по ключу
«файл:байты»), `memory` (`footprint_mb`, `footprint_peak_mb`, `available_mb`, `context_tokens`), `thermal`. Строки
журнала D1.2 в том же файле остаются от прошлых прогонов.

# Чёрный ящик: выгрузка и стирание

Телефон разблокирован (файлы ящика закрыты, пока он заперт). Выгрузка кладёт сессии в `local/blackbox/<дата>/` и
отказывается, если путь не игнорируется git или каталог синхронизируется с iCloud; стирание сначала выгружает и стирает
на телефоне только сверенное (подписанная поверхность §3.4a).

```bash
python3 scripts/blackbox.py pull --device <UDID>    # «выгружено: N сессий, M МБ, сверено N из N»
python3 scripts/blackbox.py erase --device <UDID>   # «стёрто: N сессий, M МБ»; несверенная сессия остаётся и названа
xcrun devicectl device process launch --device <UDID> --console --terminate-existing com.anthonypriceone.ally
# в журнале: «ящик: вне бэкапа: true · NSFileProtectionComplete», «blackbox: ● запись: …», «слух: в распознаватель N отсч.»
```

# Замер на телефоне 2026-10-22 (сборка до правки кадров)

25 ходов одной сессии на динамике: от конца фразы до голоса p50 2,02 с, p95 2,65 с на первых 20 (порог A10 — 2,5 с:
провал; гейт проекта 3 с — проходит); хвост 0,90, распознавание 0,14, первая фраза p50 0,98 / p95 1,61. Пик
`phys_footprint` 690 МБ, на старте доступно 6134 МБ, KV 448 МиБ; первый запуск — веса 6,9 с, префикс 4,3 с, второй —
префикс из файла 0,03 с. Перемер после правки кадров, авиарежим и экран — в первую сессию теста (решение родителя).

# Как откатить и кого звать

Откат — удалить приложение с телефона (веса, журнал и невыгруженный чёрный ящик уходят вместе с контейнером — сначала
`blackbox.py pull`); код — revert коммита поставки. Решения
об установке и о данных на телефоне принимает родитель; сборку и проверки ведёт агент поставки по этому runbook.

# Related

- [Model on phone](/engineering/model-on-phone.md) — зонд, с которого перенесены настройки звука, речи и модели.
- [Turn detector](/engineering/turn-detector.md) — конец реплики ядра.
- [Safety below the model](/engineering/safety-below-model.md) — контракт хода и реестр правил персоны.
- [App architecture](/engineering/app-architecture.md) — ADR: слои приложения и отклонённые варианты.
