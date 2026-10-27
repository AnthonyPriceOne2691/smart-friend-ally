---
type: Runbook
title: Голосовой цикл приложения — сборка, веса, запуск, журнал
description: Как собрать Ally, положить веса модели на телефон, переустановить одной командой, запустить с консолью взрослого и забрать след хода без слов; что делает сессия в консоли и чего не делает.
status: draft
tags: [engineering, app, voice, runbook]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-27T23:50:00+03:00
stale_after: 2027-01-31T00:00:00+03:00
implementation:
  - App/project.yml
  - App/Resources/model.json
  - App/Resources/hearing.json
  - App/Sources/VoiceLoop.swift
  - App/Sources/PhoneListener.swift
  - App/Sources/AllyApp.swift
  - scripts/reinstall_app.sh
  - scripts/copy_voice.py
  - App/Resources/voice.json
  - App/Sources/Audio/AudioIO.swift
  - App/Sources/Audio/SystemVoice.swift
  - App/Sources/Audio/SupertonicVoice.swift
  - App/Sources/Audio/EnginePlayer.swift
  - App/Sources/Speech/DictationRecognizer.swift
  - App/Sources/Hearing/RecognitionPhrase.swift
  - Packages/AllyLlama/Sources/AllyLlama/LlamaModel.swift
  - Packages/AllyLlama/Sources/AllyLlama/LlamaSettings.swift
  - Packages/AllyLlama/Sources/AllyLlama/Resources/lines.json
---

# Purpose

Приложение на телефоне родителя (D1.2 `app-voice-loop`, D2.2 `app-session`): тап «Разбудить» будит подругу, дальше
разговор идёт сессией без кнопок — каждая реплика проходит маршрутизатор, каждый ответ модели — контракт хода. Запуск —
всегда в консоль «Для взрослых»; детский экран открывает «Дочке, при мне» только по подписанному исключению родителя
(R `child-lock`, [Child mode](/product/child-mode.md)), его облик — «оболочка» (Ш3: Элли в пузыре с венком). Здесь — что делает сессия и как собрать,
поставить, переустановить, открыть детский режим, запустить и проверить приложение командами.

# Canonical rules

- **Сессия (D2.2):** «Разбудить» → приветствие → слушание, пока сессия слушает (listening, windingDown) — драйвер
  `Conversation` ядра со слухом `PhoneListener` → `RouterRouting` до модели (скрипт — без модели; реплика с `forget` к
  модели не идёт) → энциклопедия на «pass» (Э2) → `TurnRunner` с решением и её репликой → голос → запись следа. Промахи,
  отдых, её «пока» и мягкий лимит (`session_limit_minutes`, по умолчанию 10) решает сессия
  ([Session](/engineering/session.md)). «Стоп» глушит сразу, без фразы, и слушание в полёте кончается тут же. Новая
  сессия ждёт конца прежней (L69).
- **Микрофон и голос — один движок на сессию** (D6.1 `duplex-audio`). `AudioIO` держит один `AVAudioEngine` от
  пробуждения сессии до сна, обе сессии приложения — по очереди.
  - **С Supertonic** узел проигрывателя голоса подключается к этому движку до включения voice processing (X9).
    Аудиосессия — `.playAndRecord` + `.voiceChat` + `.defaultToSpeaker`, AGC — из реестра слуха
    (`voice_processing.agc`; замер включённым и выключенным — в сессии теста).
  - Микрофон открыт и пока Элли говорит. Вне слушания кадры после эхоподавления идут в кольцо 1,5 с и в счётчик
    наложений. Голос звучит для счётчика по `SoundingPlayer` — от начала `play` до последнего отсчёта.
  - Слушание начинается с кольца, если в нём есть её речь (свой Silero кольца): её речь поверх голоса — в
    распознавателе с первого слога (X11).
  - В журнале — этапы `overlap` (наложения за ответ) и `started_over_voice` (на сколько её речь началась раньше
    слушания), версия `audio`: `vp+agc`, `vp` или `half`.
  - **С Milena** (её голос мимо движка) — полудуплекс, как прежде: вне слушания кадры отбрасываются. Консоль пишет
    «звук: дуплекс · vp+agc» или «звук: полудуплекс (Milena)».
- **Перебивание и пауза** (D6.2 `barge-in`). Наложение — кадр, на котором набралось 250 мс её речи поверх голоса, — а
  также тап детского экрана, пока Элли говорит, и кнопка консоли «Перебить» перебивают показанную сессию: голос
  замолкает, модель отменена, её реплика идёт обычным ходом с кольца ([Session](/engineering/session.md)).
  - Уведомление аудиосессии о прерывании (звонок, Siri, будильник) кончает слушание в полёте и ставит сессию на паузу.
    Когда прерывание кончилось, `AudioIO` снова запускает движок, и сессия слушает.
  - С Milena перебивания голосом нет: её голос мимо движка, наложение не считается. Тап и кнопка работают.
- **Слушание:** микрофон (буфер 20 мс; аудиосессия — выше) → кадры по 20 мс в
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
  себя. В KV — только прозвучавшее (D5, [Session](/engineering/session.md)):
  - `commit` срезает ответ хода с первого сгенерированного токена (`seq_rm`) и дописывает прозвучавшее;
  - `retract` убирает ход целиком, `remember` дописывает ход без модели;
  - стоп оставляет её реплику, упавший ход уходит целиком.
  Срез точен только с полным окном SWA (стенд 19.10: при `swa_full=false` хвост 600 токенов расходится). Поэтому с
  `swa_full: false` в `model.json` модель не грузится, а консоль пишет «swa_full выключен — память модели не держит
  только сказанное» (строка — ресурс пакета модели `lines.json`). Пустой ход модели (стоп до конца первой фразы)
  Gemma 4 не сбивает: на Mac следующий ответ — обычная реплика по-русски.
  Префикс пишется файлом состояния ≈ 49,9 МБ в `Caches/` с ключом из персоны, имени и размера весов и параметров
  рантайма; на Mac чтение 0,015–0,018 с против сборки 1,9–3,1 с, а файл с чужим ключом не читается — префикс
  собирается заново. С памятью (`memory-recall`) системный ход может нести блок памяти — сейчас он выключен
  решением родителя 2026-10-28 (`in_conversation: false` в `memory.json`). Когда включён: загрузка считает блок
  токенизатором модели, пересборка после разбора и стирания идёт в стороне (последовательность 3) и только целой
  копируется в 0 — полусобранный префикс разговору не достаётся; файл — с полной защитой, в нём блок.
- **Кадр определителя — 20 мс, как в его тестах.** iOS отдаёт буфер микрофона ≈ 100 мс даже при запросе 1024 кадров:
  на телефоне 2026-10-22 хвост срабатывал на 0,90 с вместо 0,8, и ещё ≈ 0,1 с уходило на конец буфера. Поэтому сессия
  просит буфер 20 мс, а буфер тапа режется на кадры по 20 мс; фактическая длина буфера — `tap_buffer` в журнале.
- **Голос — Supertonic «Совсем малышка»** (V4b2b `voice-app`).
  - Голос собирает приложение: `SpokenVoice(renderer:player:)` из `SupertonicRenderer` и `EnginePlayer` на движке
    сессии. `SupertonicVoice` поверх него добавляет строку консоли и версию.
  - Рендер: текст `speech-text.json` — «Э́льли», «сево́дня» — поверх расстановщика RUAccent (`voice-accent-wire`). Дальше
    Supertonic по строке пресета `voice.json` — шаги первой фразы `first_steps` — и PSOLA с эквалайзером.
  - Расстановщик грузится на прогреве по группе `accent`: консоль пишет «ударения: RUAccent · N с». Без его файлов —
    «ударения: нет файлов RUAccent — без расстановщика», голос звучит с закреплёнными словами и именами. Отказ
    расстановщика на фразе даёт фразу без его ударений, а не ошибку хода.
  - Проигрыватель стоит на движке `AudioIO` и обёрнут `SoundingPlayer` (D6.1).
  - Аудиосессию ставит `AudioIO` до первой фразы: `.playAndRecord` со звуком в динамик (`soloAmbient` молчит при
    переключателе «без звука»), с Supertonic — режим `.voiceChat`.
  - Консоль пишет «голос: Supertonic F2 · 9/5 · ORT 1.28.0». Версия `voice` в журнале — движок, пресет, ORT; этапы
    `voice_text`, `voice_synth`, `voice_fx`, `voice_start` идут в запись хода вместе с этапами слуха.
- **Milena — запасной голос.** Нет файла или размер не тот («голоса нет: скопируй с Mac», «голос не тот: N байт вместо
  M»), голос не загрузился — звучит Milena по идентификатору из реестра, и консоль пишет причину.
  - Нет enhanced — compact с видимой пометкой (П23).
  - Темп 0,42 из реестра (`voice_rate`; родитель: на 0,5 «торопится, глотает слова») ставится в каждом вызове (П17).
    Значение читается как Double: `NSNumber` 0,42 не приводится к Float, и чтение `as? Float` молча давало 0,5.
- **Сети нет:** правило SwiftLint `no_network` на исходниках и `scripts/lint/check_app_artifact.sh` на собранном `.app`.
  Нет русской диктовки — строка «нет русской модели диктовки», загрузки нет.
- **Данные:** веса — `Library/Application Support/Models` (каталог помечен «не в бэкап»), след хода —
  `Library/Caches/turns.jsonl` (вне бэкапа, без слов: кириллица пишется как `redacted`), услышанное и сказанное — только
  на экране.
- **Энциклопедия (Э2):** прогрев грузит базу из ресурсов AllyCore (`Encyclopedia.bundled()`) и пишет в консоль
  «энциклопедия: карточек — N, поиск p95 … мс» или «энциклопедия: выключена (причина)» — так на телефоне видно, есть ли
  FTS5. Энциклопедию получают обе сессии: консоли и детского экрана. Ход с подсказкой — режим `why`
  ([Encyclopedia](/engineering/encyclopedia.md)).
- **Чего нет:** экрана настроек под замком (D8). Детский режим — R и R2, его экран — «оболочка» Ш3; свет и пузырьки
  экрана — Ш2б.

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

Детский экран (оболочка Ш3): Элли в пузыре с венком; тап по спящей — она сонно вздрагивает и просыпается, тап, пока
слушает, — «я всё», пока говорит — ничего; строка состояния и полоска «домой» скрыты, системный свайп — со второго
раза. Чтобы дочка не вышла из приложения совсем, родитель включает «Гид-доступ» (Настройки → Универсальный доступ →
Гид-доступ; тройное нажатие боковой кнопки в приложении). Перерыв после прощания по лимиту по умолчанию выключен
(ответ родителя «Без перерыва»); включается ключом запуска `-rest_after_limit_minutes 1` (0–180 минут): тап по
спящей только шевелит её, консоль пишет «перерыв до …».

# Установка, веса, запуск

```bash
xcrun devicectl device install app --device <UDID> build/Build/Products/Debug-iphoneos/Ally.app
xcrun devicectl device process launch --device <UDID> --console --terminate-existing com.anthonypriceone.ally
# лимит сессии на прогон (ключ session_limit_minutes, 1–60; вне диапазона — 10 и строка в консоли):
xcrun devicectl device process launch --device <UDID> --terminate-existing com.anthonypriceone.ally -- -session_limit_minutes 2
# перерыв после прощания по лимиту (ключ rest_after_limit_minutes, 0–180; по умолчанию 0 — без перерыва):
xcrun devicectl device process launch --device <UDID> --terminate-existing com.anthonypriceone.ally -- \
  -session_limit_minutes 1 -rest_after_limit_minutes 1
# консольная сессия пополняет память только с ключом memory_console (вопрос 3 серии памяти; после проверки — стереть):
xcrun devicectl device process launch --device <UDID> --terminate-existing com.anthonypriceone.ally -- -memory_console 1
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
пустой файл того же имени поверх модели (путь U19: размер не тот), затем настоящий обратно; команды — в
[Test session](/ops/test-session.md).
С `"engine": "gigaam"` консоль пишет отказ, если GigaAM не слушает («GigaAM нет: нет файла model.int8.onnx.data —
диктовка» и так далее), след — `versions.asr` (`gigaam-v3-ctc:224757733` или `dictation`), время расшифровки — этап
`recognize`. Откат — `"engine": "dictation"` и переустановка; файлы GigaAM можно не удалять.

**Файлы голоса** (V4b1 `voice-config`) — одной командой. Манифест — `App/Resources/voice.json`: пресет «Совсем малышка» и
26 файлов с байтами и sha256.
- Группа `voice` — Supertonic, ≈ 400 МБ. Её проверяет приложение: «голоса нет: скопируй с Mac» или «голос не тот: N байт
  вместо M».
- Группа `accent` — RUAccent, ≈ 122 МБ: 4 словаря из `.gz`, модель омографов turbo3.1 int8, модели «ё» и ударений,
  токенизаторы — в раскладке V3c `ruaccent/nn/…`. Её проверяет загрузка расстановщика.

Источники лежат в `~/models/tts`. Словари `.gz` команда распаковывает на Mac и сверяет sha256 у распакованного. Всё
сверяется до первой копии, на расхождении — стоп с именем файла. Ничего не удаляет; повтор пропускает неизменённое.

```bash
python3 scripts/copy_voice.py --check     # сверка на Mac, без телефона
python3 scripts/copy_voice.py <UDID>      # сверка, копирование в Library/Application Support/Voice, список с телефона
```

Первый запуск новой подписи — доверие сертификату на телефоне: Настройки → Основные → VPN и управление устройством (L15).
Бесплатная подпись живёт 7 дней: консоль пишет «подпись: осталось N дн.», при N ≤ 1 — «переустанови с Mac».
Телефон во время прогонов не блокировать: блокировка останавливает работу GPU.

# Память (memory-app, memory-recall)

- При прогреве — строка консоли «память: включена» или «память выключена: …» (каталог не создан, пометка «не в бэкап»
  не прочиталась, база не открылась). База — `Library/Application Support/Memory/memory.sqlite` с полной защитой.
- После конца детской сессии при родителе (и консольной — с `-memory_console 1`) и при запуске приложение разбирает
  очередь той же E4B в последовательности 2 (`LlamaModel.complete`, JSON-грамматика); тап «Разбудить» или по Элли
  отменяет разбор и ждёт его, фон — тоже. Строка разбора без слов — `Library/Caches/memory.jsonl`.
- Блок памяти в разговор не идёт (решение родителя 2026-10-28): консоль пишет «память: в разговор не идёт — блок
  выключен». Когда он включён, после разбора с изменившимся блоком префикс пересобирается (на телефоне ≈ 4 с — тап
  ждёт, как разбор).
- Консоль: строки памяти («память: N фактов», «ждёт разбора: K», «разбор не удался», «память: стёрта ДД.ММ в ЧЧ:ММ»),
  кнопки «Что помнит Элли» (текст блока) и «Стереть память» — только при спящей, с подтверждением «Стереть всё, что
  помнит Элли? (N фактов)»; после стирания префикс собирается из одной персоны, тап ждёт.

# След хода и падения

```bash
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source Library/Caches/turns.jsonl --destination local/…/turns.jsonl
xcrun devicectl device copy from --device <UDID> --domain-type appDataContainer \
  --domain-identifier com.anthonypriceone.ally --source Library/Caches/memory.jsonl --destination local/…/memory.jsonl
xcrun devicectl device info files --device <UDID> --domain-type systemCrashLogs
```

Снимков экрана телефона не делаем: `devicectl device capture screenshot` снимает то, что на переднем плане, — на личном
телефоне это бывает чужое приложение с перепиской (случай 2026-10-22: снимок удалён сразу). Экран (консоль «Для
взрослых», точка микрофона) подтверждает родитель на глаз.

Строка следа (`TurnTrace`, с D2.2 вместо журнала `TurnLog`; одна на ход, включая фразы сессии): `session`, `turn`,
`phase`, `mode`, `source` (`model`, `canned:…`, `script:<ключ>`, `session:<фраза>`), `route` (вид, тема, ключ, правила,
хэш данных маршрутизатора, `forget`), `knowledge` (у хода с поиском: карточка, правило, хэш данных базы), `rules`,
`contract_hash`, `model_timeout`, `cancelled`, `error`, `elapsed`, `limit`,
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
