---
type: Runbook
title: Голосовой цикл приложения — сборка, веса, запуск, журнал
description: Как собрать Ally, положить веса модели на телефон, переустановить одной командой, запустить с консолью взрослого и забрать след хода без слов; что делает сессия в консоли и чего не делает.
status: draft
tags: [engineering, app, voice, runbook]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-23T23:30:00+03:00
stale_after: 2027-01-31T00:00:00+03:00
implementation:
  - App/project.yml
  - App/Resources/model.json
  - App/Resources/hearing.json
  - App/Sources/VoiceLoop.swift
  - App/Sources/PhoneListener.swift
  - App/Sources/AllyApp.swift
  - scripts/reinstall_app.sh
  - App/Sources/Audio/AudioIO.swift
  - App/Sources/Audio/SystemVoice.swift
  - App/Sources/Speech/DictationRecognizer.swift
  - App/Sources/Hearing/RecognitionPhrase.swift
  - Packages/AllyLlama/Sources/AllyLlama/LlamaModel.swift
---

# Purpose

Приложение на телефоне родителя (D1.2 `app-voice-loop`, D2.2 `app-session`): тап «Разбудить» будит подругу, дальше
разговор идёт сессией без кнопок — каждая реплика проходит маршрутизатор, каждый ответ модели — контракт хода. Запуск —
всегда в консоль «Для взрослых»; детский экран открывает «Дочке, при мне» только по подписанному исключению родителя
(R `child-lock`, [Child mode](/product/child-mode.md)), его облик — «оболочка». Здесь — что делает сессия и как собрать,
поставить, переустановить, открыть детский режим, запустить и проверить приложение командами.

# Canonical rules

- **Сессия (D2.2):** «Разбудить» → приветствие → микрофон открывается сам, только пока сессия слушает (listening,
  windingDown), и закрыт, пока Элли говорит (полудуплекс) — драйвер `Conversation` ядра со слухом `PhoneListener` →
  `RouterRouting` до модели (скрипт — без модели; реплика с `forget` к модели не идёт) → `TurnRunner` с решением и её
  репликой → голос → запись следа. Промахи, отдых, её «пока» и мягкий лимит (`session_limit_minutes`, по умолчанию 10)
  решает сессия ([Session](/engineering/session.md)). «Стоп» глушит сразу, без фразы; если Элли слушала, микрофон гаснет к
  концу слушания (≤ 8 с: у `AudioIO` нет отмены, правка — D6), а новая сессия ждёт его конца.
- **Слушание:** микрофон (`.playAndRecord`, `.default`, `.defaultToSpeaker`, буфер 20 мс) → кадры по 20 мс в
  определитель конца речи ядра (хвост по типу хода из `hearing.json`: открытый 1,8 с, закрытый 1,2, счёт 2,5 — D7) и
  буферы — в распознаватель (`asr` реестра слуха, D7.3: диктовка или GigaAM за одним протоколом фразы); на «возможно,
  конец» — текст без конца ввода (диктовка — `finalize(through: nil)`, GigaAM — расшифровка копии 16 кГц Int16 с
  предзаписью 1,5 с), по нему модель молча начинает ответ (D7.1) → конец речи или «Я всё» → микрофон закрыт →
  `DictationTranscriber` ru-RU дописывает текст, GigaAM отдаёт ту же расшифровку, если речь не вернулась, иначе
  расшифровывает заново. 8 с без речи — тишина (сессия скажет «не расслышала», на второй раз — отдых); 30 с речи —
  предел реплики. Этапы `turn_limit` и `turn_done` в следе — ход кончил предел или «Я всё».
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
  на экране.
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

# Детский режим при родителе (R) и без присмотра (R2)

Исключение подписывает только родитель — на своём Mac, касанием ключа в Secretive, через окно с исключением целиком
(по умолчанию «Не подписывать»); срок — не больше 7 дней, на ту сборку, что стоит на телефоне:

```bash
bash scripts/child_mode.sh <UDID> --until 2026-10-29T21:00:00+03:00        # окно, подпись, сверка, копия на телефон
bash scripts/child_mode.sh <UDID> --until 2026-10-29T21:00:00+03:00 --dry  # только текст окна, без подписи
```

Файлы ложатся в контейнер — `Library/Application Support/Ally/child-mode.json` и `.sig`; ключ родителя — строка в
`.github/allowed_signers`, приложение берёт её из бандла (нет строки — «в сборке нет ключа родителя»). Консоль пишет
строки замка («при родителе: до 29.10 в 21:00» или причину отказа; «без присмотра: закрыт до целей безопасности») и
строку приёмки (R2): «приёмка: нет файла приёмки» — пока целей нет; причину по первой несработавшей проверке или по
целям; «приёмка: цели безопасности приняты» — и тогда «без присмотра: открыт — цели безопасности приняты». Приёмка —
`release-gate.json` и `.sig` в `App/Resources/` (едут в бандл сами); её подписывает родитель в пространстве
`ally-release` после замера всех девяти целей на этой сборке. «Дочке, при мне» — детский экран (только при открытом
режиме: при исключении или приёмке); значок стопа в его углу — тишина и консоль; «Закрыть детский режим» — исключение
удалено, приёмку из бандла убирает только новая сборка. Срок, истёкший посреди разговора, его не обрывает: проверка —
на границах сессии.

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
# Silero VAD (D7.2, 2,3 МБ, MIT): без файла слух — по энергии, консоль пишет «нет silero_vad.onnx — слушаю по энергии»
curl -fL -o ~/models/silero_vad.onnx https://github.com/snakers4/silero-vad/raw/v6.2.3/src/silero_vad/data/silero_vad.onnx
shasum -a 256 ~/models/silero_vad.onnx              # 1a153a22…8788e3, 2 327 524 байта — размер в hearing.json
xcrun devicectl device copy to --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source ~/models/silero_vad.onnx \
  --destination "Library/Application Support/Models/silero_vad.onnx"
# GigaAM-v3 CTC (D7.3, MIT): веса перепаковываются в external data (footprint 0,4 ГБ вместо 0,65) — onnx 1.23.2 даёт
# те же байты, что в hearing.json; слушает только с "engine": "gigaam" в App/Resources/hearing.json (по умолчанию —
# диктовка до правила шага 3) и после переустановки
curl -fL -o ~/models/asr/giga-ctc.tar.bz2 \
  https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-ctc-giga-am-v3-russian-2025-12-16.tar.bz2
tar -xjf ~/models/asr/giga-ctc.tar.bz2 -C ~/models/asr    # model.int8.onnx f86ebfa0…66437ec, 224 721 476 байт
python3 -m venv ~/models/asr/.venv && ~/models/asr/.venv/bin/pip install onnx==1.23.2
G=~/models/asr/sherpa-onnx-nemo-ctc-giga-am-v3-russian-2025-12-16 && mkdir -p ~/models/asr/gigaam-extdata
~/models/asr/.venv/bin/python -I -c 'import onnx, sys; onnx.save_model(onnx.load(sys.argv[1]), sys.argv[2],
  save_as_external_data=True, all_tensors_to_one_file=True, location="model.int8.onnx.data", size_threshold=1024,
  convert_attribute=False)' "$G/model.int8.onnx" ~/models/asr/gigaam-extdata/model.int8.onnx
cp "$G/tokens.txt" ~/models/asr/gigaam-extdata/
shasum -a 256 ~/models/asr/gigaam-extdata/*   # 02a443f4… 2 939 169 · fa9a4816… 221 818 368 · 17cc5144… 196 байт
for f in model.int8.onnx model.int8.onnx.data tokens.txt; do
  xcrun devicectl device copy to --device <UDID> --domain-type appDataContainer \
    --domain-identifier com.anthonypriceone.ally --source ~/models/asr/gigaam-extdata/$f \
    --destination "Library/Application Support/Models/$f"
done
```

Консоль при запуске пишет, кто слушает: «слух: Silero · sherpa 1.13.8 · ORT 1.28.0» или причину энергии; след —
`versions.vad`, время окон Silero — журнал (`devicectl … --console`, категория `hearing`). Те же фразы с энергией (U21) —
без файла Silero на телефоне: удалить его из `Library/Application Support/Models` и перезапустить.
С `"engine": "gigaam"` консоль пишет отказ, если GigaAM не слушает («GigaAM нет: нет файла model.int8.onnx.data —
диктовка» и так далее), след — `versions.asr` (`gigaam-v3-ctc:224757733` или `dictation`), время расшифровки — этап
`recognize`. Откат — `"engine": "dictation"` и переустановка; файлы GigaAM можно не удалять.

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
«файл:байты», `vad`, `asr`), `memory` (`footprint_mb`, `footprint_peak_mb`, `available_mb`, `context_tokens`), `thermal`. Строки
журнала D1.2 в том же файле остаются от прошлых прогонов.

# Замер на телефоне 2026-10-22 (сборка до правки кадров)

25 ходов одной сессии на динамике: от конца фразы до голоса p50 2,02 с, p95 2,65 с на первых 20 (порог A10 — 2,5 с:
провал; гейт проекта 3 с — проходит); хвост 0,90, распознавание 0,14, первая фраза p50 0,98 / p95 1,61. Пик
`phys_footprint` 690 МБ, на старте доступно 6134 МБ, KV 448 МиБ; первый запуск — веса 6,9 с, префикс 4,3 с, второй —
префикс из файла 0,03 с. Перемер после правки кадров, авиарежим и экран — в первую сессию теста (решение родителя).

# Как откатить и кого звать

Откат — удалить приложение с телефона (веса и журнал уходят вместе с контейнером); код — revert коммита поставки. Решения
об установке и о данных на телефоне принимает родитель; сборку и проверки ведёт агент поставки по этому runbook.

# Related

- [Model on phone](/engineering/model-on-phone.md) — зонд, с которого перенесены настройки звука, речи и модели.
- [Turn detector](/engineering/turn-detector.md) — конец реплики ядра.
- [Safety below the model](/engineering/safety-below-model.md) — контракт хода и реестр правил персоны.
- [App architecture](/engineering/app-architecture.md) — ADR: слои приложения и отклонённые варианты.
