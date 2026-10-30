# Knowledge Bundle Update Log

## 2026-10-30 — голос: обрезка тишины и пауза из строки (voice-tuning)

* **Update**: `engineering/voice-fx` — вариант 6 родителя, растяжка и интонация, `SilenceTrim`: тишина синтеза снимается до
  обработки, порог −45 дБ, поля 30 и 80 мс; `engineering/voice-engine` — ключи `stretch`, `range`, `gap` строки пресета,
  `SpokenVoice.settle`; `engineering/speech-text` — строки `stress` и две причины ошибок RUAccent; `engineering/voice-loop` —
  слушание ждёт тихую комнату; `engineering/session`, `ops/test-session`, `product/persona`, `engineering/index` — голос.
## 2026-10-30 — рот Элли только при звуке (mouth-sync)

* **Update**: `product/look-and-feel` — строка «в коде (mouth-sync)». `engineering/character-rendering` — как сделано:
  вход `sound` у `Motion`, удержание позы до первого звука, закрытие рта в `Syllables`. `engineering/voice-loop` — признак
  `VoiceLoop.sounding`. `engineering/design-demo` — звук сценария по таймеру. `ops/test-session` — N6 на телефоне.
  `product/child-mode` — рот на детском экране; `engineering/safety-below-model` — признак только для экрана.
* **Источник**: поставка `mouth-sync` (слово родителя 2026-10-30 после первого разговора на Mac; примеры N1–N6 подписаны
  2026-10-30).

## 2026-10-29 — Элли на Mac: приложение для iPhone прямо на Mac (sim-app)

* **Creation**: `engineering/mac-run` — ADR: разговоры на Mac — приложение для iPhone («My Mac (Designed for
  iPhone)»), запуск ⌘R в Xcode, файлы через кнопку «Файлы с Mac…» (`MacImport`: только пути реестров, размер и
  sha256 копии), ход строкой без слов в системном журнале (`TraceLine`); симулятор отклонён замером зонда — в нём нет
  диктовки, Metal без apple7 и metal3; запуск вне Xcode убивает Gatekeeper, контейнер закрыт для агентов (TCC).
* **Update**: `engineering/voice-loop` — раздел «Элли на Mac» (`mac_files.py`, `mac_app.sh`, кнопка, журнал `turn`,
  строка «модель: Metal — …»); `engineering/voice-engine` — `VoiceFile.sha256` для сверки копии;
  `engineering/safety-below-model` — путь реплики на Mac тот же; `ops/child-data` — контейнер на Mac и барьер для
  агентов; `references/repo-map` — входные точки на Mac; `engineering/index` — строка решения.
* **Источник**: поставка `sim-app` (решения родителя 2026-10-29; примеры N1–N10 подписаны 2026-10-29).
## 2026-10-29 — значок приложения из рисунка Элли (app-icon)

* **Update**: `product/look-and-feel` — правило «значок приложения — та же Элли» (выбор родителя «В»: мордочка крупно в
  пузыре, ночная пара для тёмной темы, у демо — пометка «демо»), строка «в коде (app-icon)»; `implementation:` +=
  `IconScene.swift`. `engineering/character-rendering` — как сделан значок: квадрат 440 pt, конвейер PNG со снятием
  дизеринга, почему не Icon Composer, имя `AppIcon` пресетом XcodeGen; `implementation:` += `IconScene.swift`,
  `scripts/render_app_icon.sh`. `references/repo-map` — `IconScene`, каталоги значка, `render_app_icon.sh`.
  `engineering/design-demo` — значок демо. `product/index` — строка облика. `ops/test-session` — взгляд на значок
  в блоке 3.1.
* **Источник**: поставка `app-icon` (слово родителя 2026-10-29; выбор варианта «В» на странице — 2026-10-29).

## 2026-10-29 — новая форма блока памяти, второй замер M40, блок включён (memory-block-form)

* **Update**: `engineering/memory` — правило «Блок для промпта» новой формы (шапка с «верь ей» и приоритетом правил
  безопасности и подсказки, без её имени, бюджет 200); раздел «Блок в разговоре: две попытки и решение родителя» вместо
  «Отложено»: второй M40 не выдержан (имя D1 74%, вываливание 1 из 221, живость 38%), родитель — «Включить: имя держит
  код»; «В приложении — помнит» — блок включён. `engineering/safety-below-model` — реестр правил шапки блока с замером;
  строка о блоке в шапке концепта. `engineering/voice-loop`, `engineering/app-architecture`, `ops/child-data` — блок
  включён. `ops/test-session` — M36, M37 теперь в сессии теста.
* **Источник**: поставка `memory-block-form` (слова подписаны родителем 2026-10-29; M40 — спека серии памяти; решение
  родителя после замера 2026-10-29).
## 2026-10-29 — детский экран открыт всегда, загрузка до Элли (child-open)

* **Update**: `product/child-mode` (Policy) переписана: детский экран открыт всегда, без замка и надписи, — решение
  родителя дословно (ответы на два вопроса, довод про Face ID и пароль телефона, сказанное ему про 15% при цели 5%);
  запуск — загрузка, потом Элли (`Launch`), знак стопа — консоль без Face ID, детская сессия `supervised`, приёмка R2 —
  на будущее; `scripts/child_mode.sh` удалён. `product/look-and-feel` — строка «в коде (child-open)», поправки правил 1,
  13, 14; `implementation:` += `LoadingBubble.swift`. `engineering/voice-loop` — запуск через загрузку, строки консоли,
  исключение снято; `implementation:` += `LoadingScreen.swift`. `ops/black-box`, `ops/child-data`, `engineering/session`,
  `engineering/safety-below-model`, `product/session-limit` — каждая детская сессия, перерыв после перезапуска забыт.
  `ops/test-session` — шаг подписи и G8, G10 сняты, новые J1, J2, J5. `engineering/design-demo` — загрузка в демо и
  превью. `references/repo-map`, индексы `product`, `ops`; `KNOWLEDGE.md` — решение 2026-10-29.
* **Источник**: поставка `child-open` (решение родителя 2026-10-29 через ведущего; примеры J1–J6 подписаны
  2026-10-29).

## 2026-10-29 — забыть один факт или сущность, окно брата и имени (memory-forget)

* **Update**: `engineering/memory` — правило «Забыть» один факт или сущность (с историей и повторами, `secure_delete`,
  чекпойнт WAL; надгробие без значения — сессия, начатая раньше, не возвращает) и раздел «В приложении — забывает»;
  «ещё не подключено» — без `memory-forget`; `implementation:` += `MemoryForget.swift`. `engineering/session` — окно
  брата и имени (`TurnWindow`, имена из памяти на пробуждении, через `Conversation`); `implementation:` +=
  `TurnWindow.swift`, `window.json`. `engineering/safety-below-model` — строка реестра «Брат 1–2 раза, имя только при
  встрече»: верхние границы держит окно, «хотя бы раз» — персона и замер M42. `engineering/voice-loop` — «Забыть…» в
  консоли, имена в обе сессии. `ops/child-data` — «Забыть» не оставляет байтов, надгробие без значения.
  `ops/test-session` — телефонная проверка M41. `product/persona` — имя и брат: гарантию верхних границ даёт окно. `references/repo-map` — «забыть», `TurnWindow`. `engineering/design-demo` — «Забыть…» в общем `ConsoleView` простыми значениями.
* **Источник**: поставка `memory-forget` (M41, M42 спеки серии памяти, подписанной родителем 2026-10-23).
## 2026-10-29 — энциклопедия: текст карточки, когда в ответе нет сути (card-fallback)

* **Update**: `engineering/encyclopedia` — правило «текст карточки, когда в ответе нет сути»: ключ карточки судит
  оставленное контрактом, карточка — тем же контрактом после прозвучавшей первой фразы, заготовка остаётся, след
  `knowledge.fallback`, ключ проверяется при загрузке; `implementation:` += `CardFallback.swift`; серия и отложенное.
  `engineering/safety-below-model` — реестр: суть ниже модели исполняется. `engineering/session` — карточка из плана в
  раннер, `knowledge.fallback` в следе. `engineering/index` — строка энциклопедии. `references/repo-map` —
  `encyclopedia-replay --said`. `ops/test-session` — P20: текст карточки и `knowledge.fallback`. Замер: перегон P18 на
  seed 48–50 — 48 из 48, артефактов 0, карточка на 12 ходах из 48.
* **Источник**: поставка `card-fallback` (решение родителя 2026-10-27 «Слить, чинить сразу после»; примеры P21–P24
  подписаны 2026-10-29 «Подписываю: фраза + карточка (Рекомендую)»).
## 2026-10-29 — демо облика на Mac, превью и токены (design-demo)

* **Creation**: `engineering/design-demo` (Runbook) — демо-цель `AllyDemo` в симуляторе одной командой
  (`scripts/run_demo.sh`), детский режим и сценарий разговора без модели и микрофона, консоль приложения на вымышленных
  строках, превью Xcode, токены облика (`Look` и `Palette`), оракул границы `check_demo_boundary.sh`, грабли Xcode 27.1
  (DeviceHub вместо Simulator.app, рантайм iOS 27.1 знает только iPhone Duo, у llama.cpp b10809 нет слайса симулятора).
* **Update**: `product/look-and-feel` — строка «Токены облика (design-demo)», в демо надписи «при родителе» нет;
  `implementation:` += `Look.swift`. `engineering/character-rendering` — числа облика взрослых в `Look`, рисунок
  смотрят на Mac демо и превью. `engineering/voice-loop` — две цели проекта, вид консоли `ConsoleView.swift`;
  `implementation:` += `ConsoleView.swift`. `references/repo-map` — `App/Demo`, `run_demo.sh`, `ConsoleView`, `Look`.
  `engineering/index` — строка runbook.
* **Источник**: поставка `design-demo` (слово родителя 2026-10-29, примеры Y1–Y7 подписаны 2026-10-29; поправки Y4 —
  по его слову после показа).

## 2026-10-28 — жидкое стекло и розовое небо (app-glass)

* **Update**: `product/look-and-feel` — правило «жидкое стекло и розовое небо» (слова и цвета на непрозрачной
  подложке, стекло вокруг, у дочки кнопок не прибавилось), строка «в коде (app-glass)»; `implementation:` +=
  `SkyArt.swift`, `GlassCapsule.swift`. `engineering/character-rendering` — как сделано: небо данными палитры,
  системное стекло, `ImageRenderer` его не рисует — настоящее стекло судит снимок окна на Mac. `product/index` —
  строка облика. `engineering/voice-loop` — цель iOS 27.0 и Xcode 27, образ `xcode-27`, консоль в стекле.
  `references/repo-map` — `SkyArt`, `AdultSky`, `GlassCapsule`, снимки настоящего стекла.
* **Источник**: поставка `app-glass` (слово родителя 2026-10-27; примеры F1–F5 и вид подписаны 2026-10-27).

## 2026-10-27 — память в разговоре: блок в префиксе персоны, консоль памяти, стирание из консоли (memory-recall)

* **Update**: `engineering/memory` — раздел «В приложении — помнит»: системный ход «персона + блок» по токенизатору
  модели, пересборка префикса после разбора и стирания в стороне (последовательность 3), строки консоли памяти,
  «Что помнит Элли», «Стереть память» с подтверждением; «ещё не подключено» — `memory-forget`. `engineering/voice-loop` —
  префикс с блоком и кнопки памяти в консоли. `engineering/safety-below-model` — персона в префиксе не ломается
  пересборкой; `engineering/app-architecture` — префикс с блоком собирается в стороне. `ops/child-data` — файл префикса несёт блок: полная защита, уходит со стиранием. `ops/test-session` —
  телефонные части M36, M37, M39.
* **Update (2026-10-28)**: замер M40 не выдержан (запрет в быту 30 из 45 против 33, «почему» с подсказкой 37 из 48
  против 43, детали D1 5 из 7, имя в 74% реплик D1) — родитель: «Слить с выключенной (Рекомендую)». `engineering/memory`
  — раздел «Отложено: новая форма блока», блок выключен (`in_conversation`); `voice-loop`, `test-session`,
  `child-data`, `app-architecture`, `safety-below-model` — то же.
* **Источник**: поставка `memory-recall` (M36, M37, M39, M40 спеки серии, подписанной родителем 2026-10-23; разрез —
  ведущий 2026-10-27; решение по M40 — родитель 2026-10-28).
## 2026-10-28 — энциклопедия: замеры Э2 и отложенное

* **Update**: `engineering/encyclopedia` — замеры v3, v4 и P18 с решениями родителя; отложено: поставка `card-fallback`
  (текст карточки, когда ответ без сути) и добор попаданий формулировками из чёрного ящика. `ops/test-session` — архив
  Э2 у шага P20.
* **Источник**: сдача `app-encyclopedia` (Э2), решения родителя 2026-10-27.

## 2026-10-27 — энциклопедия: подсказка после её фразы (формат B), формат A убран

* **Update**: `engineering/encyclopedia` — формат B и почему (P18: A 24, B 36, C 34 из 48; ключ судьи `er01` не узнавал
  ответ новой карточки), решение родителя об исправленном судье; `engineering/session`, `product/persona` — строка
  подсказки после её фразы.
* **Источник**: поставка `app-encyclopedia` (Э2), решения родителя 2026-10-27 «Исправить и перегнать (Рекомендую)» и
  «Принять строгий (Рекомендую)».

## 2026-10-27 — энциклопедия: одно слово может не найтись только поверх целой формулировки

* **Update**: `engineering/encyclopedia` — правило покрытия: пропуск одного слова из трёх и больше — только если в её
  вопросе есть целая формулировка карточки; замер на 300 открытых вопросах справки по финальной базе — неверных
  подсказок 8 → 1, верных 90 → 84.
* **Источник**: поставка `app-encyclopedia` (Э2) — провал P16 на слепом наборе v3 (без карточки 3 из 40), правка по
  открытым наборам (L49), проверка — свежий v4.

## 2026-10-25 — энциклопедия «почему» в ходе: база в ресурсах, поиск после «pass», подсказка во входе модели

* **Update**: `engineering/encyclopedia` — где спрашивают, формат подсказки A (рамка и место в `encyclopedia.json`),
  режим `why`, база-ресурс и строка консоли; `implementation:` += `encyclopedia.ru.jsonl`, `Knowledge.swift`.
  `engineering/session` — энциклопедия после маршрутизатора в общем плане реплики, поле `knowledge` следа.
  `engineering/voice-loop` — прогрев грузит базу, строка консоли, обе сессии; режим `why` больше не в «чего нет».
  `engineering/safety-below-model` — строка реестра о подсказке (§14.2a). `product/persona`, `engineering/index`,
  `references/repo-map` — Э2 вместо «приложение не зовёт».
* **Источник**: поставка `app-encyclopedia` (Э2 серии «энциклопедия почему», подпись родителя 2026-10-23).
## 2026-10-27 — память в приложении: отбор, очередь, разбор после прощания, хранилище (memory-app)

* **Update**: `engineering/memory` — раздел «В приложении — записывает»: `MemoryTap`, очередь в базе, разбор E4B в
  последовательности 2 с JSON-грамматикой после сна сессии, отмена тапом и фоном, `Application Support/Memory`;
  «ещё не подключено» — `memory-recall`. `ops/test-session` — телефонные части M35, M38.
* **Источник**: поставка `memory-app` (M33–M35, M38 спеки серии, подписанной родителем 2026-10-23; разрез — ведущий
  2026-10-27).
## 2026-10-27 — живой разговор: перебивание голосом и тапом, пауза при звонке в приложении (barge-in)

* **Update**: `engineering/session` — приложение зовёт перебивание (наложение, тап, «Перебить») и паузу (уведомления
  аудиосессии); время X13 — 0,3 с от набранных 250 мс её речи. `engineering/voice-loop` — перебивание и пауза в
  приложении, движок после прерывания запускается снова. `product/look-and-feel` — тап во время речи перебивает.
  `engineering/turn-detector` — кадр наложения перебивает, кашель короче 250 мс — нет. `engineering/character-rendering`
  — тап `ChildShell` по фазе: говорит — перебить.
* **Источник**: поставка `barge-in` (D6.2; X13–X17 подписаны серией 2026-10-23, план и время X13 — родителем 2026-10-25).
## 2026-10-25 — живой разговор: перебивание и пауза при звонке — ядро (barge-in)

* **Update**: `engineering/session` — состояние `paused`, события `bargeIn`, `interruptionBegan`, `interruptionEnded`;
  отмена хода с причиной (`Cut`): перебивание — сразу слушание, прерывание — пауза; записи отменённого хода с этапами.
  `engineering/safety-below-model` — перебивание не обходит контракт и прощание. `product/look-and-feel` — тап на паузе
  ничего не делает, перебивание тапом подключит экран. `engineering/voice-loop` — консоль называет паузу; приложение
  событий пока не шлёт.
* **Источник**: поставка `barge-in` (D6.2 серии «живой разговор»; план и время X13 подписаны родителем 2026-10-25).
## 2026-10-27 — детский экран: ритм рта по слогам (оболочка Ш2в)

* **Update**: `engineering/character-rendering` — как сделано в Ш2в (`Syllables`: слоги, паузы слов и фраз, уровень
  с подъёмом 26/с и спадом 16/с без «дрожи» прототипа; `Motion.voiceLevel` — переданный уровень или ритм, пока она
  говорит); `implementation:` += `Syllables.swift`. `product/look-and-feel` — строка «в коде (Ш2в)».
* **Источник**: поставка `child-shell-mouth` (оболочка Ш2в; пример V34 подписан родителем 2026-10-23 одной подписью с
  Ш3 и Ш2б; телефон — в общей сессии теста, слово родителя 2026-10-27).

## 2026-10-27 — живой разговор: микрофон и голос в одном движке (duplex-audio)

* **Update**: `engineering/voice-loop` — один `AVAudioEngine` на сессию: с Supertonic — voice processing, `.voiceChat`,
  AGC из реестра, кольцо и счётчик вне слушания, этапы `overlap` и `started_over_voice`, версия `audio`; с Milena —
  полудуплекс; стоп кончает слушание сразу. `engineering/turn-detector` — ядро подключено в приложении.
  `engineering/safety-below-model` — путь реплики тот же.
* **Источник**: поставка `duplex-audio` (D6.1; X9–X12, X18, X19 подписаны родителем 2026-10-23 и 2026-10-25).
## 2026-10-25 — живой разговор: окно голоса от проигрывателя (duplex-audio)

* **Update**: `engineering/turn-detector` — `SoundingPlayer`: голос звучит с начала `play` до последнего отсчёта
  (`started + frames / rate` V4b2a), конец буфера окно не сдвигает.
* **Источник**: поставка `duplex-audio` (D6.1), сверка плана с V4b2a `voice-out` (T1).

## 2026-10-25 — живой разговор: речь поверх голоса Элли — ядро (duplex-audio)

* **Update**: `engineering/turn-detector` — кольцо микрофона через голос (`VoiceRing`: с её первого флага речи минус
  0,8 с, без её речи не отдаётся) и счётчик наложений (`OverlapCounter`: речь ≥ 250 мс поверх голоса или в 0,8 с
  после, только счёт); ключи реестра слуха `overlap` и `voice_processing`; `implementation:` — `Overlap.swift`.
  `engineering/voice-loop` — ключи лежат в реестре, приложение пока слушает полудуплексом.
* **Источник**: поставка `duplex-audio` (D6.1 серии «живой разговор»; X18, X19 и план подписаны родителем 2026-10-25).
## 2026-10-27 — расстановщик ударений в приложении (хвост серии голоса)

* **Update**: `engineering/voice-loop` — RUAccent вместо заглушки, файлы группы `accent` в раскладке V3c, строка
  консоли без файлов. `engineering/voice-engine` — проверка файлов по группам. `engineering/safety-below-model` —
  расстановщик меняет только текст для движка. `references/repo-map` — `AllyAccent` в приложении.
* **Источник**: поставка `voice-accent-wire` (хвост серии голоса; примеры подписаны родителем 2026-10-23).

## 2026-10-25 — память: качество разбора на E4B (memory-quality, M32)

* **Update**: `engineering/memory` — раздел «Качество на E4B»: справка — ловушек и запрещённого 0, «Мурка — кошка» и
  обновления 3 из 3, D1 7/7, точность 0,957; свежий набор — ловушек и запрещённого 0, точность 0,696 и полнота 0,792
  ниже порогов (решение родителя); правила разбора, уточнённые прогоном справки. `engineering/safety-below-model` —
  строка отрицания. Слепой разбор: точность 0,899, полнота 0,792 — родитель 2026-10-25: «Принять как замер
  (Рекомендую)»; отложено на полировку — `namesake`, `age`, опора и отказы.
* **Источник**: поставка `memory-quality` (M32 спеки серии, подписанной родителем 2026-10-23); стенд вне git.
## 2026-10-25 — сторож скорости маршрутизатора на занятом Mac

* **Update**: `references/repo-map` — грабли: сторож `testDecisionIsFast` вне CI пропускается при загрузке выше
  числа производительных ядер, на CI судит всегда; R12 — release-реплей.
* **Источник**: поставка `router-guard-load` (класс S, поручение ведущего 2026-10-25).

## 2026-10-25 — канон вне git: вариант D

* **Update**: `references/repo-map` — `docs/canon/` лежит только локально (вариант D, AGENT_STACK §7.1a): репозиторий
  публичный до 2026-11-01, канон проприетарный; путь закрыт в `.git/info/exclude`, повторный коммит ловит хук
  `canon-texts-stay-out`; в свежем клоне и новом ворктри снимка нет.
* **Источник**: поставка `canon-variant-d` (класс S); решение родителя 2026-10-24 «Открыт, канон вне git (Рекомендую)».
## 2026-10-25 — голос Элли в приложении (голос V4b2b)

* **Update**: `engineering/voice-loop` — Supertonic «Совсем малышка» вместо Milena, голос собирает приложение — проигрыватель на движке сессии снаружи (стык D6.1),
  аудиосессия до первой фразы, Milena — запасной голос со строкой консоли. `engineering/safety-below-model` — голос
  приложения говорит только фразы хода. `references/repo-map` — пакеты приложения.
* **Источник**: поставка `voice-app` (V4b2b серии голоса; телефонные Z20–Z26 — в сессии теста 26.10).

## 2026-10-25 — детский экран: свет и пузырьки (оболочка Ш2б)

* **Update**: `engineering/character-rendering` — как сделано в Ш2б (`Light`: ночь, оттенок, свечение и жемчужинки,
  покачивание; `Bubbles`: небо, вода, «думает», «Z»); `implementation:` += `Light.swift`, `Bubbles.swift`, `Night.swift`,
  `Glow.swift`, `BubbleArt.swift`. `product/look-and-feel` — строка «в коде (Ш2б)», непрозрачная плашка.
* **Источник**: поставка `child-shell-light` (оболочка Ш2б; примеры подписаны родителем 2026-10-23 одной подписью с
  Ш3, ритм рта — в Ш2в; исключение предохранителя до 850 — решение родителя 2026-10-25).
## 2026-10-25 — расстановщик ударений: модели RUAccent и сборка (V3c)

* **Update**: `engineering/accent-placer` — модели через `AllyOnnx` в `AllyVoice`, сборка `RUAccentVoice`, числовой
  паритет по версии ORT (Z18 переподписан 2026-10-23), цена на Mac (Z17: порог отпечатка 170 МБ, переподписан
  2026-10-25; сжатие словарей — на полировку); `implementation:` — `RUAccentModels.swift`, `RUAccentVoice.swift`.
* **Источник**: поставка `accent-onnx` (V3c серии голоса; Z14–Z18, подпись родителя 2026-10-23 и 2026-10-25).
## 2026-10-25 — голос хода в ядре (голос V4b2a)

* **Update**: `engineering/voice-engine` — `SpokenVoice` и порты голоса, `first_steps`. `engineering/session` —
  следующие фразы голосу заранее (`VoiceLookahead`). `engineering/safety-below-model` — заранее готовится только
  пропущенное контрактом.
* **Источник**: поставка `voice-out` (V4b2a серии голоса; примеры подписаны родителем 2026-10-23).
## 2026-10-25 — слух: инструмент шага 3 — диктовка против GigaAM на выгрузке ящика, только суммы

* **Update**: `engineering/turn-detector` — шаг 3 одной командой (`asr-step3`): тот же `GigaAMRecognizer`, что на
  телефоне, живой `heard` диктовки, нормализация, WER с парным бутстрэпом, однословные, пустые, вердикт по обеим
  частям правила, вывод — только суммы; `implementation:` — `StepThree.swift`, `step3.json`, `StepThreeRun.swift`.
  `ops/black-box` — формат `refs.csv` и команда шага 3. `engineering/index` — строка концепта.
* **Источник**: поставка `asr-step3` (D7.4 серии «слух»; пример U27 подписан родителем 2026-10-23).

## 2026-10-23 — слух: GigaAM-v3 за протоколом распознавателя, выбор в реестре слуха

* **Update**: `engineering/turn-detector` — распознаватель за протоколом фразы: `asr` реестра слуха (диктовка по
  умолчанию до правила шага 3; GigaAM при файлах своего размера и паре ORT; строка отказа), веса external data, звук
  GigaAM — 16 кГц Int16 ящика с предзаписью 1,5 с, одна расшифровка на «возможно, конец»; `implementation:` —
  `BatchPhrase.swift`, `recognizers.json`, `GigaAMRecognizer.swift`. `engineering/voice-loop` — перепаковка и
  копирование весов GigaAM, включение `engine: gigaam`, `versions.asr`; `implementation:` — `RecognitionPhrase.swift`.
  `engineering/safety-below-model` — распознаватель не меняет путь реплики. `engineering/index` — строка концепта.
* **Источник**: поставка `gigaam-asr` (D7.3 серии «слух»; примеры U22–U26, U28 подписаны родителем 2026-10-23; U27 —
  D7.4).

## 2026-10-25 — память: чужое, выдуманное, любимое и отрицание в разборе (memory-sense)

* **Update**: `engineering/memory` — окно вымысла, хозяин питомца, отрицание, маркеры любимого, «больше не люблю»
  снимает «любит»; `implementation:` — `Sense.swift`, `sense.json`. `engineering/safety-below-model` — правила 3–7
  промпта разбора исполняются.
* **Источник**: поставка `memory-sense` (M30, M31 спеки серии, подписанной родителем 2026-10-23; разрез — ведущий).
## 2026-10-23 — живой разговор: в памяти модели только сказанное (kv-spoken)

* **Update**: `engineering/session` — после хода модели `commit(spoken:)` с доигранными предложениями, скрипт —
  `remember(heard:spoken:)`, `forget` — ничего; брошенный ответ спекуляции — `retract`, этап `spec_retracted` вместо
  `spec_stale`. `engineering/voice-loop` — KV держит только прозвучавшее, `swa_full: false` — отказ загрузки и строка
  консоли из `lines.json`; `implementation:` — `LlamaSettings.swift`, `lines.json`. `engineering/safety-below-model` —
  срезанное контрактом в память модели не попадает. `engineering/index` — строка сессии.
* **Источник**: поставка `kv-spoken` (D5 серии «живой разговор»; примеры X1–X8 подписаны родителем 2026-10-23).
## 2026-10-25 — эквалайзер, строка пресета, файлы голоса (голос V4b1)

* **Update**: `engineering/voice-fx` — эквалайзер RBJ вернулся в цепочку (`eq.c`, `VoiceEQ`), полный Z30 против p9f5.
  `engineering/voice-engine` — строка пресета в `voice.json` и `VoiceSettings`. `engineering/voice-loop` — команда
  копирования файлов голоса `scripts/copy_voice.py`. `engineering/index`, `references/repo-map`.
* **Источник**: поставка `voice-config` (V4b1 серии голоса; примеры подписаны родителем 2026-10-23).
## 2026-10-23 — сессия теста с родителем: один runbook на все телефонные проверки

* **Creation**: `ops/test-session` (Runbook) — решение родителя 2026-10-23 «всё в общую сессию»: подготовка на Mac
  (переустановка, веса E4B, Silero, позже GigaAM, Supertonic и RUAccent — с sha256 и командами), шаг владельца (ключ
  Secretive, подпись детского режима), отложенные проверки подписанных спек по порядку без лишних переустановок (A10–A12,
  W8–W11, G8, G10, G11, U6, U14–U15, U20–U21, U28, Z22, Z26, B13–B19, B21, B22, X8, X10–X17, V29, M37, P20), итоги в
  `observed.md`. **Update**: `engineering/voice-loop` — сравнение с энергией через путь U19; `ops/index`.
* **Источник**: поставка `test-session` (класс S, документ; waiver'ы и списки ожиданий серий в архивах и ветках).

## 2026-10-23 — память: разбор разговора в кандидаты с опорой на её слова (memory-extract)

* **Update**: `engineering/memory` — разбор: запрос из ресурсов `extract.*`, модель за протоколом, повтор при мусоре,
  опора «сама / код / согласилась / без опоры»; серия с разрезом на `memory-sense` и `memory-quality`;
  `implementation:` — `Extract.swift`, `ExtractPrompt.swift`, `ModelAnswer.swift`, `Anchors.swift`, ресурсы.
  `engineering/safety-below-model` — реестр правил промпта разбора. `engineering/index`, `references/repo-map` — строки.
* **Источник**: поставка `memory-extract` (M26–M28 спеки серии, подписанной родителем 2026-10-23; разрез — ведущий).
## 2026-10-23 — детский экран в приложении: венок, тап, стоп, метка, перерыв (оболочка Ш3)

* **Update**: `engineering/character-rendering` — как сделано в Ш3 (венок `Crown` и `CrownArt`, экран `ChildShell`,
  сонное шевеление, 120 Гц), порядок серии Ш3 → Ш2б; `implementation:` += `Crown.swift`, `CrownArt.swift`,
  `ChildShell.swift`. `product/look-and-feel` — правила 2, 3, 4, 13, 15 в коде, цвета венка прототипа;
  `implementation:` += `Tap.swift`, `AdultZone.swift`. `product/session-limit` — перерыв после лимита по умолчанию
  выключен («Без перерыва»), ключ 0–180; `implementation:` += `Nap.swift`. `product/child-mode`,
  `engineering/session` — заглушка R → оболочка. `engineering/voice-loop` — детский экран, «Гид-доступ», ключ перерыва.
  `engineering/safety-below-model` — экран путь реплики не меняет. `references/repo-map` — `AllyShell` в приложении.
* **Источник**: поставка `child-shell-app` (оболочка Ш3; Ш3 и Ш2б подписаны родителем 2026-10-23 «Подписываю
  (Рекомендую)», перерыв — ответ «Без перерыва»).
## 2026-10-23 — расстановщик ударений: логика RUAccent на Swift

* **Update**: `engineering/accent-placer` — логика V3b (`RuAccentPlacer`, «ё», омографы, ударения, текст, словари) с
  причудами Python, стыки `AccentModels` и `AccentTokenizers`, оракул — повтор Python по записи; `implementation:` —
  исходники логики. `engineering/index` — строка концепта.
* **Источник**: поставка `accent-logic` (V3b серии голоса; доля V3b в Z14–Z16, подпись родителя 2026-10-23).
## 2026-10-23 — расстановщик ударений: токенизаторы RUAccent на Swift

* **Creation**: `engineering/accent-placer` (Design) — пакет `AllyAccent`, `Encoding` и три токенизатора RUAccent с
  паритетом HF; `implementation:` — исходники пакета. **Update**: `engineering/index`, `references/repo-map`.
* **Источник**: поставка `accent-tokenizers` (V3a серии голоса; часть Z14, подпись родителя 2026-10-23).
## 2026-10-23 — слух: Silero VAD на sherpa-onnx и общем ORT, активность голоса за протоколом

* **Update**: `engineering/turn-detector` — активность голоса за протоколом (энергия или Silero), тишина от речи за
  флагом, параметры Silero в `vad` реестра слуха, выбор и строки консоли, запасной путь — энергия; `implementation:` —
  `VoiceActivity.swift`, `SileroVAD.swift`, `SileroActivity.swift`. `engineering/onnx-runtime` — sherpa-onnx 1.13.8 в
  `AllyOnnx`, `AllySherpa`, пин пары в страже, фикстура `add.onnx` в git. `engineering/voice-loop` — копирование
  Silero на телефон, строка консоли, сравнение с энергией без файла. `references/repo-map` — пакет `AllyHearing`.
* **Источник**: поставка `silero-vad` (D7.2 серии «слух»; примеры U16–U21 подписаны родителем 2026-10-23).
## 2026-10-23 — энциклопедия «почему»: движок, подсказка только когда поиск уверен

* **Creation**: `engineering/encyclopedia` (Design) — порядок решения и правила `knowledge.*`, строгое покрытие по
  формулировкам с замером 2026-10-23, основы Snowball, SQLite FTS5 в памяти через `AllySQLite`, отказ закрытый, запись без
  слов, схема карточки и серия Э1–Э2; `implementation:` — исходники движка и `encyclopedia.json`.
* **Update**: `product/persona` — поиск по основам слов, ссылка на движок; `references/research/kids-encyclopedia` —
  строка о замере 2026-10-23 и перенумерации приёмки; `references/research/index`, `engineering/index`,
  `references/repo-map` — новые входные точки; `KNOWLEDGE.md` §12 п. 5 и §13 — решение 2026-10-23.
* **Источник**: поставка `encyclopedia-core` (Э1; спека и план подписаны родителем 2026-10-23).
## 2026-10-23 — обработка голоса после синтеза (голос V4a)

* **Creation**: `engineering/voice-fx` (Design): своё TD-PSOLA по цепочке стенда третьего круга (эквалайзер — V4b,
  разрез родителя), свой трекер основного тона по методу Boersma 1993 вместо YIN прототипа (замер дребезга), пресет
  «Совсем малышка» — данные строки конфига; `implementation:` — C-ядро и обёртка `AllyVoiceFX`. `engineering/index`, `references/repo-map` —
  новый пакет.
* **Источник**: поставка `voice-fx` (V4a серии голоса; примеры Z27–Z31 подписаны родителем 2026-10-23).

## 2026-10-23 — память: запрет на любом пути записи (memory-guard)

* **Update**: `engineering/memory` — «не хранится никогда» исполняется: правила `forbidden.json`, проверка записи с
  отчётом по id правил, заражение по её репликам сессии, SQL-функция `forbidden` в триггерах `fact` и `seen`;
  `implementation:` — `Forbidden.swift`, `forbidden.json`. `engineering/index` — строка концепта.
* **Источник**: поставка `memory-guard` (M29 спеки серии, подписанной родителем 2026-10-23; разбиение — ведущий).
## 2026-10-23 — расстановщик ударений: токенизаторы RUAccent на Swift

* **Creation**: `engineering/accent-placer` (Design) — пакет `AllyAccent`, `Encoding` и три токенизатора RUAccent с
  паритетом HF; `implementation:` — исходники пакета. **Update**: `engineering/index`, `references/repo-map`.
* **Источник**: поставка `accent-tokenizers` (V3a серии голоса; часть Z14, подпись родителя 2026-10-23).
## 2026-10-23 — слух: спекуляция — ответ модели начинается в её паузе

* **Update**: `engineering/session` — `Speculation` (общий план реплики, этапы `spec_*`, `spec_stale` до D5);
  `implementation:` — `Speculation.swift`. `engineering/turn-detector` — события паузы до сессии.
  `engineering/voice-loop` — текст диктовки на «возможно, конец». `engineering/safety-below-model` — спекуляция не
  обходит план реплики.
* **Источник**: поставка `turn-speculation` (D7.1 серии «слух»; примеры U7–U15 подписаны родителем 2026-10-23).
## 2026-10-23 — память о ребёнке: база фактов и блок для промпта (memory-core)

* **Creation**: `engineering/memory` (Design) — что хранится, опора на её ход и уверенность кодом, замена
  однозначного по дате, узнавание сущностей, блок ≤ 300 токенов с ядром, «стереть всё» удалением файлов, общий SQLite
  `AllySQLite`; что из серии ещё не подключено (L50); `implementation:` — исходники `Packages/AllyMemory`.
* **Update**: `ops/child-data` — спутники базы (`-wal`, `-shm`, `-journal`) в игноре и в гейте, смоук S7.
  `engineering/index`, `references/repo-map` — пакеты `AllySQLite` и `AllyMemory`. `KNOWLEDGE.md` §9 — ссылка на
  концепт (OKF §6).
* **Источник**: поставка `memory-core` (спека и план серии подписаны родителем 2026-10-23 «Подписываю (Рекомендую)»).
## 2026-10-23 — движок голоса Supertonic за протоколом (голос V1b)

* **Creation**: `engineering/voice-engine` (Design): `SpeechEngine`, фраза за вызов, скорость синтеза не ниже 0,85, веса в
  external data на общем ORT, паритет с Python бит в бит; `implementation:` — исходники `AllyVoice`.
  `engineering/index`, `references/repo-map` — новый пакет.
* **Источник**: поставка `voice-engine` (V1b серии голоса; спека подписана родителем 2026-10-23).

## 2026-10-23 — один ONNX Runtime на приложение (голос V1a)

* **Creation**: `engineering/onnx-runtime` (Decision): ORT только в `Packages/AllyOnnx` — официальный pod 1.28.0, слой над
  C API, страж `check_single_ort.sh`; sherpa-onnx 1.13.8 подключается своим xcframework без ORT; `implementation:` —
  `Package.swift`, `Onnx.swift`, страж. `references/repo-map`, `engineering/index` — новая входная точка.
* **Источник**: поставка `voice-onnx` (V1a серии голоса; спека подписана родителем 2026-10-23 «Подписываю (Рекомендую)»).
## 2026-10-23 — текст для синтеза: строки второго круга образцов

* **Update**: `engineering/speech-text` — строки проверенной таблицы второго круга (фонемная модель, 8 озвучек):
  «йиво́», «до́рога», «ску́шно», «здра́ствуй», «че́сный», «ща́стье», «мя́хкий», исключения -ого/-его, имя «Э́льли»,
  закреплённое «ле́том» (ключ без различия «е/ё»), список «не брать», пометка «ничево́ — на слух».
* **Источник**: поставка `voice-text-table` (последний пункт Z10 спеки V2, подпись родителя 2026-10-23).
## 2026-10-23 — детский экран: Элли живая (оболочка Ш2а)

* **Update**: `engineering/character-rendering` — как сделано в Ш2а: аниматор `Motion` (пружины ω = 11 на шести группах
  поз, накопленные фазы, моргание с зерном, зевок после прощания), частота кадров по позе и нагреву, `LiveScene` на
  `TimelineView`; `implementation:` += `Motion.swift`, `FrameRate.swift`, `LiveScene.swift`. `product/look-and-feel` —
  правило 10 в коде (переходы, моргание, пробуждение, зевок, Reduce Motion).
* **Источник**: поставка `child-shell-motion` (оболочка Ш2а; примеры V11–V18 подписаны родителем 2026-10-23
  «Подписываю (Рекомендую)»).
## 2026-10-23 — без присмотра: пороги целей 18.10 в коде, подписанная приёмка в бандле (R2)

* **Update**: `product/child-mode` — путь без присмотра: приёмка `release-gate.json` в пространстве `ally-release`,
  девять порогов в коде (`Goal`), счёт на замороженном наборе, порядок причин, формат файла, `audience: child`; чего это
  не даёт (стоп ведёт в консоль, замер на одной поверхности). `engineering/safety-below-model` — абзац о приложении:
  пороги в коде, приёмки пока нет. `ops/black-box` — сессии `child` не пишутся. `engineering/voice-loop` — строка
  приёмки в консоли и где лежит файл. `product/index`.
* **Источник**: поставка `release-gate` (R2; пороги подписаны родителем 2026-10-22 «Подписываю (Рекомендую)», вопрос 9).

## 2026-10-23 — слух: тип хода по реплике Элли, хвосты из реестра слуха, «я всё»

* **Update**: `engineering/turn-detector` — тип хода кодом, хвосты 1,8 / 1,2 / 2,5 с и предел 30 с в
  `App/Resources/hearing.json`, «я всё»; `implementation:` — `TurnKinds.swift`, `Hearing.swift`. `engineering/session` —
  тип хода, `turn_kind`, `done()`. `engineering/voice-loop` — слушание по типу хода, «Я всё», предел 30 с.
  `engineering/safety-below-model` — тип хода путь реплики не меняет. `engineering/app-architecture` — реестр слуха.
  `engineering/index` — описание.
* **Источник**: поставка `turn-detector` (D7 серии «слух»; спека подписана родителем 2026-10-23).

## 2026-10-23 — правки контракта: запрет не вытесняется, заготовка опасности старше страха, вопрос-обрывок уступает

* **Update**: `engineering/safety-below-model`:
  * раздел «Правки контракта» — указатель на взрослого не вытесняет запрет (места нет — запрет старше), заготовка
    опасности старше запасной фразы темы без своей защиты («потерялась» — своя), вопрос-обрывок уступает полному;
    замер на открытых наборах; находка паритета эталона и Swift (5 ответов, 13 расхождений) — отложена;
  * реестр «опасное»: второй взгляд E4B отложен решением родителя 2026-10-22 (метка ответ не меняет: страж
    20 → 20) — вернуться по данным чёрного ящика; пункт «Указатель страха не знает о запрете» — исправлен.
* **Источник**: поставка `contract-fixes` (решение родителя 2026-10-22 «Делать сейчас», спека H1–H16 подписана).

## 2026-10-23 — текст для синтеза: ударения, закреплённый словарь и правила чтения только во входе движка

* **Creation**: `engineering/speech-text` (Design) — конвейер `AllySpeechText` над протоколом расстановщика:
  ударения по исходному написанию, закреплённое и имена поверх, правила чтения с переносом ударения по номеру
  гласной, U+0301 на словах от двух слогов, кроме «ё»; данные `speech-text.json`; `implementation:` — исходники
  и таблица пакета. **Update**: `product/persona` — строка о тексте для синтеза; `engineering/index`,
  `references/repo-map` — новый пакет.
* **Источник**: поставка `voice-text` (V2 серии голоса; примеры Z8–Z13 подписаны родителем 2026-10-23).

## 2026-10-23 — детский режим только при родителе: подписанное исключение, замок на телефоне

* **Creation**: `product/child-mode` (Policy) — решение родителя 2026-10-22: при родителе по его исключению (подпись
  ключом Secretive касанием, проверка на телефоне, срок ≤ 7 дней, только эта сборка, граница сессии, стоп, что видит дочь
  и что пишется); без присмотра закрыт до целей 18.10 (R2); чего это не даёт.
* **Update**: `engineering/safety-below-model` — абзац о приложении (сессия и маршрутизатор подключены в D2.2, детский
  режим — при родителе) и читатель целей; `engineering/session` — две сессии на одном слухе, стык `ChildScreen`;
  `engineering/voice-loop` — раздел «Детский режим при родителе»; `references/repo-map`, `product/index`.
* **Источник**: поставка `child-lock` (R; спека и план подписаны родителем 2026-10-22 в D2.2 + R).

## 2026-10-23 — детский экран: облик Элли в коде (оболочка Ш1)

* **Update**: `product/look-and-feel` — позы состояний, раскладка и палитра в коде (`implementation:` — `Pose.swift`,
  `Layout.swift`, `Palette.swift`), правило «без надписей» — SwiftLint `child_screen_text`. `engineering/character-rendering`
  — как сделано в Ш1: `Frame` и рисунок одним `Canvas`, снимки на Mac с пробами (`implementation:` — `Frame.swift` и
  `ShellUI`). `references/repo-map` — пакет `AllyShell`, снимки в `local/shell-snapshots/`.
* **Источник**: поставка `child-shell` (оболочка Ш1; спека подписана родителем 2026-10-22 «Подписываю (Рекомендую)»).

## 2026-10-22 — чёрный ящик: обе стороны разговора текстом и звуком (ядро)

* **Update**: `ops/black-box` — переписан по поставке: пишутся только сессии `audience: supervised`; на ход — её
  реплика (WAV бит в бит, как слышал распознаватель), текст модели до контракта и сказанное после, звук Элли с выхода
  (AAC 32 кбит/с), тайминги, версии; форматы и объём с замером 2026-10-22, предел 1 ГБ, класс защиты `Complete`,
  раскладка и заголовок `ALLY-BLACKBOX/1`, серия D3 → D3.2 → D3.3; `implementation:` — файлы ядра AllyCore.
  `ops/child-data` — гейт узнаёт запись ящика по заголовку и `.allybox`, смоук S6. `engineering/session` — слова хода
  в сток, признак `audience`. `engineering/safety-below-model` — журнал нарушений: текст модели до контракта — в записи
  ящика. `ops/index` — описание.
* **Источник**: поставка `black-box` (D3; спека и план подписаны родителем 2026-10-22, стык `audience` с D2.2+R).

## 2026-10-22 — сессия в приложении: слушание по состоянию, маршрутизатор на живом ходе, переустановка одной командой

* **Update**: `engineering/session` — драйвер `Conversation` (слушание только в listening и windingDown, одно за раз,
  поздний результат остановленной сессии не попадает в новую), `TalkState` для экрана, маршрутизатор подключён, реплика
  с `forget` к модели не идёт, этапы слушания в следе и `TraceFile`; `implementation:` — `Conversation.swift`,
  `TraceFile.swift`. `engineering/safety-below-model` — раздел «Маршрутизатор на живом ходе», строки реестра «опасное»
  и «адрес»; `implementation:` — `Routing.swift`, `Session.swift`. `engineering/voice-loop` — сессия вместо хода по
  тапу, переустановка одной командой, лимит аргументом запуска, поля следа `TurnTrace`. `references/repo-map`,
  `engineering/index` — новые входные точки.
* **Источник**: поставка `app-session` (D2.2; спека и план подписаны родителем 2026-10-22 «Подписываю (Рекомендую)»).

## 2026-10-22 — облик персонажа: первая версия в 2D

* **Update**: `engineering/character-rendering` (ADR, `stable`) — первая версия — 2D-вектор в SwiftUI `Canvas` по
  прототипу v3, серия «оболочка» Ш1–Ш3; бюджет первой версии (память +10 МБ, рывки, скорость модели ≥ 95%, нагрев) — с
  тестом родителя после Ш3; Rive «2.5D», RealityKit и клипы — следующий шаг, база зонда — 2D; отклонены `WKWebView` с
  прототипом и SpriteKit.
* **Update**: `product/look-and-feel` — персонаж в первой версии в 2D, открытый вопрос «2.5D или 3D» — после её теста;
  `engineering/index`. `KNOWLEDGE.md` §12 п.6 и `CLAUDE.md` — с первым кодом Ш1 (на фазе спеки гейт считает их кодом).
* **Источник**: решение родителя 2026-10-22 (через ведущего); спека оболочки Ш1 `child-shell` (ветка `feat/child-shell`)
  и зонд облика на Mac (`local/spike/shell/`, вне git); проба на macOS 27: `ImageRenderer` рисует и вид AppKit.

## 2026-10-22 — приложение: голосовой цикл на телефоне через контракт хода

* **Creation**: `engineering/voice-loop` (Runbook) — что делает цикл (тап, конец речи 0,8 с, полудуплекс, диктовка ru-RU,
  контракт `talk`, голос по идентификатору, журнал без слов) и команды сборки, весов, запуска, журнала и снимка экрана;
  `engineering/app-architecture` (ADR-002) — слои приложения и отклонённые варианты плана D1.
* **Update**: `engineering/safety-below-model` — цикл приложения зовёт контракт на каждом ответе, режим всегда `talk`,
  маршрутизатор в цикл не включён до D2; `implementation:` — `App/Sources/VoiceLoop.swift`. `references/repo-map` —
  входные точки `App/` и `AllyLlama`, грабли связки ключей и симулятора, роли «до кода» решены.
* **Источник**: поставка `app-voice-loop` (D1.2; спека и план подписаны родителем 2026-10-20); паритет со стендом A23 на
  Mac 2026-10-22; телефон 2026-10-22 — 25 ходов, A10 на первом замере p95 2,65 с (правка: кадры 20 мс), темп голоса
  0,42 по слуху родителя.

## 2026-10-22 — маршрутизатор до модели: быт и улица, нож, «больно»

* **Update**: `engineering/safety-below-model`:
  * раздел «Быт и улица, нож, «больно»» — 12 тем, травма называет источник, указатель «больно», привязанность в любом
    порядке слов (находка D2), объединение атомов в грамматике условий; замер на открытых наборах и счёт fresh-2;
  * реестр: «опасное» — исполняется (20 тем набора проверки и нож); справочный прогон скрытого набора — 84,7% при
    цели 95%, вред — заготовки чужой темы; строить ли второй взгляд E4B — открытый вопрос к родителю;
  * итог справочного прогона по типу решения и разбор указателя страха на открытых наборах (запрет третьим
    предложением вытесняется; запасная фраза страха старше заготовки опасности) — исправления предложены;
  * раздел сессии и строка реестра «когда уходит»: находка «Я буду по тебе скучать!» исправлена этой поставкой.
* **Источник**: поставка `router-events` (серия «маршрутизатор до модели», упрощение родителя 2026-10-19; тексты —
  `local/checkpoint/router-scripts-basic.json`).

## 2026-10-22 — сессия разговора: состояния и прощание кодом, крючок маршрутизатора, след хода

* **Creation**: `engineering/session` — состояния сессии, фразы сессии через контракт своего режима, промахи и отдых,
  её «пока» списком, лимит на границах хода, крючок маршрутизатора, одна запись следа без слов на ход, `stop`.
* **Update**: `product/session-limit` — фраза прощания родителя вместо «давай завтра продолжим?», ключ
  `session_limit_minutes` 1–60 минут, перерыв 60 минут после прощания по лимиту (детский экран); `implementation:`.
* **Update**: `engineering/safety-below-model` — реестр «когда уходит»: исполнитель — сессия; раздел о реплике и
  решении в контракте хода; находка «Я буду по тебе скучать!» для серии контракта. `references/repo-map` — сессия
  в `AllyCore`.
* **Источник**: поставка `session-core` (D2; спека, тексты и ответы родителя 2026-10-22; `ReleaseGate` — в R).

## 2026-10-20 — ядро голосового цикла: ход через контракт и конец реплики

* **Creation**: `engineering/turn-detector` — конец реплики ядра: пороги зонда, хвост по типу хода (1,8 / 0,8 / 2,5 с)
  по замеру speech-in, «возможно, конец» через 0,3 с, предзапись ≥ 1,5 с, предел хода 20 с; Smart Turn снят.
* **Update**: `engineering/safety-below-model` — раздел «Ход через контракт в коде»: `TurnRunner` и граница первой фразы
  (`SentenceStream`), журнал без слов; `implementation:` — пути ядра. `references/repo-map` — входная точка `AllyCore`.
* **Источник**: поставка `voice-core` (D1.1; спека D1 подписана родителем 2026-10-20).

## 2026-10-20 — маршрутизатор до модели: люди, тайны, «потерялась», правила содержания

* **Update**: `engineering/safety-below-model`:
  * раздел «Люди, тайны, «потерялась» и правила содержания» — темы-статьи в данных, приоритет, страх — страж с
    указателем на взрослого, флаг `forget` для адреса, правила содержания контракта; замер на открытых наборах;
  * реестр: адрес, секрет от мамы, «сказочная подружка» — исполняется; опасное — плюс темы людей;
  * текст заготовки «ты живая?» — 2026-10-19 (без «люблю»); `implementation:` — `Clause.swift`, `Content.swift`.
* **Update**: `references/research/kids-ux` — правило E1: в продукте текст «ты живая?» без «люблю» (поиск по L16).
* **Источник**: поставка `router-people` (серия «маршрутизатор до модели», упрощение родителя 2026-10-19; тексты —
  `local/checkpoint/router-scripts-basic.json`).

## 2026-10-19 — маршрутизатор до модели: движок, спички и розетка

* **Update**: `engineering/safety-below-model`:
  * раздел «Маршрутизатор до модели в коде» — решение до модели, движок прототипа v3 через эталон, двойники частотного
    списка с хэшем, флаг игры по R3, fail-closed, журнал без слов; замер на открытых наборах;
  * реестр: «Опасное — запрет и куда бежать» — маршрутизатор для спичек и розетки; счётчики «брат/имя» — отдельная
    маленькая поставка после серии (решение родителя 7);
  * `implementation:` — пути маршрутизатора.
* **Источник**: поставка `router-core` (серия «маршрутизатор до модели», решения родителя и «Упрощение» 2026-10-19).

## 2026-10-19 — четыре исследования 18.10: ударения, распознавание, память, энциклопедия

* **Creation**: `references/research/tts-stress-bench`, `asr-child-speech`, `memory-portrait`, `kids-encyclopedia` —
  выжимки отчётов агентов 2026-10-18: числа, методы, оговорки, приёмка M1–M14 и E1–E11, протокол записи шага 3.
* **Сверка лицензий** при записи (`gh api`, API Hugging Face, правовые тексты): OpenStax — CC BY-NC-SA, а не CC BY;
  общественное достояние текстов NASA Space Place и NOAA SciJinks не подтвердилось; Gemma 4 — Apache 2.0; Викидия —
  CC BY-SA 3.0; остальные утверждения отчётов подтвердились, непроверяемое помечено.
* **Update**: `product/persona` — знак U+0301 Supertonic 3 модель слушается (55 из 60 против 33 из 60), запись «даёт
  артефакты» опровергнута; замер поиска энциклопедии — BM25 хватает. `references/research/tts-stress`,
  `phone-runtime-speech` — та же поправка; `memory-prototype` — ссылка на продолжение.
* **Update**: `KNOWLEDGE.md` §6, §9, §12, §13 — указатели на справки (OKF §6); бюджет связки с GigaAM — footprint
  ~0,7 ГБ по замеру на Mac вместо оценки ~0,3 ГБ.
* **Источник**: поставка `research-reports`; отчёты — `local/research/` (вне git).

## 2026-10-18 — вопрос в конце: цель 4 в уточнении родителя

* **Update**: `engineering/safety-below-model`:
  * цель 4 и реестр — исполняет правило `closing_question`: в обычном разговоре вопрос, которым она передаёт ход,
    звучит четвёртым; в «почему», на прощание, после запрета и вторым вопросом — нет;
  * раздел «Контракт хода в коде» — замер: кандидат стенда, эталон и Swift совпали на 743 ответах; цели 3, 5, 6 и быт
    без изменений, цель 4 — ноль нарушений новой замороженной проверкой;
  * скрытый набор — две потери второго судьи в теме «секрет» разобраны: те же слова, что у сырого ответа, разброс
    между кругами судей, а не действие правила; живость на свежих парах — за слепыми судьями.

## 2026-10-18 — накат канона cqg@2.70: свои обходы сняты

* **Update**: `references/repo-map` — истечение объявлений n/a «до кода приложения» держит мета-гейт канона (`until: "App/*.swift"` в `not-applicable.json`, `cqg@2.66`), свой гейт `na-expiry` снят; во входных точках — пакет `Packages/AllyDiscipline` вместо «продукта пока нет».
* **Источник**: поставка `sync-cqg-2.70` (Prepare `76c42c3`, накат из чистого клона).

## 2026-10-18 — контракт хода: замер, живость, обращения

* **Update**: `engineering/safety-below-model`:
  * раздел «Контракт хода в коде» — режимы хода, отбор, готовые запреты по опасностям (подписаны родителем);
  * замер на сохранённых ответах v2.4 — цели 3, 5, 6 держатся, быт вровень с сырой (33 из 45);
  * скрытый набор по парным слепым судьям — вровень с сырой (254–256 из 360 против 255–256, каппа судей 0,90);
  * цель 4 уточнена родителем: вопрос в конце может идти четвёртым — строгие три давали 29% по живости, «три и
    вопрос» — 52% и 50% на новых ответах; правило — отдельной поставкой, живость — долг этой;
  * обращения «, моя принцесса» снимаются правилом притяжательного обращения, а не списком слов (было 26 из 293 ответов).

## 2026-10-18 — первый код: ремонт текста, слепой замер опасных фраз, цели дисциплины

* **Update**: `engineering/safety-below-model` — `implementation:` на пакет `Packages/AllyDiscipline` (ремонт текста до
  голоса, паритет с эталоном на 110 ответах, три дефекта эталона исправлены); слепой замер на 150 фразах: сырая v2.4
  безопасна в 71% ответов по слепым судьям-агентам, прототип 2026-10-17 не помогает; судья безопасности — агенты
  атомарными вопросами, словарный судья — сигнал (каппа 0,43); цели приёмки дисциплины, принятые родителем.

## 2026-10-17 — персона v2: семь кругов, лист вслепую, итог v2.4

* **Creation**: `engineering/persona-eval` (Metric). Семь кругов замороженных проверок на двойнике телефона (E4B).
  Итог — персона v2.4: родитель на листе вслепую выбрал её живее в 21 паре из 24; бытовая безопасность 33 из 45
  против 9 у v1; «почему» с подсказкой энциклопедии — 43 из 48. Частоту («иногда») маленькая модель не держит,
  гарантии держит код. Слепые судьи по критериям родителя совпали с ним в 19 парах из 23.
* **Creation**: `references/research/persona-v2-inputs` — промпт v2.4, диалоги и наборы байт в байт.
* **Creation**: `references/research/kids-dialogue`, `child-knowledge-level`, `tts-stress`, `agent-theory-library`,
  `memory-prototype`, `games-catalog` — выжимки отчётов агентов.
* **Update**: `product/persona`:
  * «Как она разговаривает» — естественность, детали, брат, эрудиция 8–9 лет, бытовая безопасность, приёмы ровесницы;
  * обращение только по имени, без «моя хорошая» (решение родителя), гарантию даёт фильтр;
  * голос — ласковый девчачий.
* **Update**: `engineering/safety-below-model` — прототип маршрутизатора и фильтра. Что промпт не удержал:
  привязывание, вопрос на прощание, опасная концовка ответа. Ещё нужен игровой режим маршрутизатора и фильтр обращений.
* **Update**: `engineering/on-device-model` — `stable`: персона прошла проверку родителя на слух; дообучение отложено.

## 2026-10-17 — спайк, шаг 2: модель на телефоне; как она разговаривает

* **Creation**: `engineering/model-on-phone` (Metric): E4B и E2B на iPhone 17 Pro Max в llama.cpp b10809 — footprint 0,3–0,5 ГБ из 6 ГБ (веса из файла в лимит не идут), первая фраза 1,0 и 0,3 с, от конца речи до первого звука p95 1,9 и 1,3 с, 7 деталей длинного разговора из 7; у SpeechTranscriber нет русского — распознаёт DictationTranscriber. `references/research/phone-runtime-speech` — выжимка отчётов агентов с метками сверки.
* **Update**: `product/persona` — «Как она разговаривает»: пожелания родителя (естественность фраз — главное, не теряет деталей, спрашивает про брата); имя должно распознаваться («Элли» → «Нелли»); ударения — критерий выбора голоса (замечание родителя на живой проверке: временный голос ставит их неправильно).
* **Update**: `engineering/on-device-model` — E4B основной после замера, рантайм llama.cpp, LiteRT-LM отложен; `engineering/model-bakeoff` — «5,2 ГБ» было RSS, вывод про LiteRT-LM снят; `engineering/memory-limit`, `engineering/character-rendering` (персонажу ~4,3 ГБ вместо ≈200 МБ), `product/look-and-feel` — бюджет по замеру.

## 2026-10-17 — визуал утверждён: прототип v3

* **Update**: `product/look-and-feel` — родитель утвердил визуал прототипа v3 (аксолотлик в водяном пузыре, венок включён); вопрос «венок или нет» закрыт, визуальные итерации остановлены.

## 2026-10-17 — спайк, шаг 2: бейк-офф моделей на Mac

* **Creation**: `engineering/model-bakeoff` (Metric): 4 модели на 40 детских репликах в четырёх классах П35 — E4B 8/6/8/4, E2B 10/6/3/4, Bonsai 8B 3/4/2/3, Bonsai 27B 4/3/3/3 (seed 42); чистый промпт — безопасность держит промпт; задержка на Mac — только порядок. `references/research/model-bakeoff` и `model-bakeoff-inputs` — отчёт и входы байт в байт.
* **Update**: `engineering/on-device-model` — кандидаты E4B и E2B, оба Bonsai отклонены; `engineering/safety-below-model` — довод чистого промпта.

## 2026-10-17 — образ выбрала дочь: аксолотлик

* **Update**: `product/look-and-feel` — персонаж — аксолотлик (выбор дочери парами: выиграл все три пары и финал, картинка `axolotl-3d-s12`): облик, жабры как «корона настроения», состояния телом, имя, отличие от известных героев; слоняшка с пятачком и венком — история выбора, венок на аксолотлике — на сравнении. `product/persona`, `engineering/character-rendering`, `product/index` — согласованы.

## 2026-10-17 — итоговый венок: по центру, три ряда, блёстки

* **Update**: `product/look-and-feel` — венок набок с веточкой заменён решением родителя: компактный венок по центру головы в три ряда (розовые розы, гвоздики, лизиантусы), присыпан мерцающими блёстками, листочки средние, без веточки и не на ушах.

## 2026-10-17 — венок из цветочков набок

* **Update**: `product/look-and-feel` — решение родителя («на голове пустовато»): венок-корона из пастельных цветочков, набок; справа букетик крупнее, веточка свисает по уху и покачивается при движении головы.

## 2026-10-17 — пятачок вместо хобота

* **Update**: `product/look-and-feel` — решение родителя: вместо хобота милый пятачок (анимация хобота выглядит плохо); рот виден всегда, риск «рот под хоботом» снят; пузыри — ртом; отличие от розовых свинок (Пеппа, Нюша) держат слоновьи ушки, крылышки-пузыри и сердечко. `product/persona` — образ уточнён.

## 2026-10-17 — исследования облика: детский UX, показ персонажа, дизайн персонажа

* **Creation**: `engineering/character-rendering` (ADR, proposed): Rive «2.5D» основным, RealityKit + VRMKit запасным, клипы HEVC резервом; бюджет памяти персонажа ≈200 МБ при E4B, цель ≤100 МБ; пороги зонда M1–S2 и слепой выбор родителя V1. `references/research/` — отчёты агентов (детский UX, показ, облик в двух частях).
* **Update**: `product/look-and-feel` — правила экрана для пятилетки, этика честной подруги, рабочий концепт «Крылатая слоняшка» и три альтернативы, правила имени, пути производства и решения родителя; «машет лапками» прочитано как жест в собственной речи, пока говорит дочь — слушание. `engineering/safety-below-model` — правило против привязанности и честный ответ на «ты живая?». `product/persona` — женские образ и имя.
* **Сверка**: экспорт Rive на платных планах и MIT рантайма, остановка кадров в покое (`RiveView.swift`), одна длительность на фразу у Supertonic (`helper.py`), предупреждение Common Sense Media (январь 2026), контрасты WCAG — проверены 2026-10-17.

## 2026-10-17 — облик приложения и персонаж: пожелания родителя

* **Creation**: `product/look-and-feel` (Design, draft): интерфейс с пузырьками, обтекаемый, в нежно-розовых тонах; анимации максимально плавные; персонаж в круге в 3D — первый кандидат розовый слоник с крылышками, машет лапками, когда говорит. Память и GPU он делит с моделью, поэтому способ рендера решит замер на телефоне.
* **Update**: `product/persona` и `product/overview` — образ задан направлением, открыто имя; в обзоре — направление «возможный продукт» (идея, не решение) и правило выбирать компоненты с лицензией, разрешающей платное распространение.
* **Источник**: пожелания родителя 2026-10-17.

## 2026-10-17 — замер лимита памяти на телефоне

* **Creation**: `engineering/memory-limit` (Metric): без entitlement потолок ≈3,3 ГБ (3374 МБ на старте), с `increased-memory-limit` ≈6,0 ГБ (6142 МБ); зонд занял и записал 5,75 ГБ без вылета; entitlement выдан бесплатной Personal Team. Исходник зонда — в концепте.
* **Update**: `engineering/on-device-model` — контекст ADR опирается на замер, а не на цифры вендора.

## 2026-10-02 — решения о персонаже, сессии и чёрном ящике

* **Creation**: `product/persona` (подруга, голос девочки; кандидаты — Supertonic 3 F2 и производные; чужой голос не клонируется), `product/session-limit` (мягкие 10 минут), `ops/black-box` (текст и звук каждой сессии, выгрузка только на Mac без облака).
* **Update**: `product/overview` и `ops/child-data` — граница «данные не покидают телефон» уточнена: единственный выход — выгрузка родителем на свой Mac; `engineering/safety-below-model` — журнал нарушений живёт в чёрном ящике.
* **Источник**: решения пользователя 2026-10-02; голоса Supertonic сверены по официальной документации (`supertone-oss-archive/supertonic-py`, `docs/voices.md`).

## 2026-10-02

* **Initialization**: создан OKF v0.2 bundle (`knowledge/`) при развёртывании контура (`okf@1.19`).
* **Preflight**: upstream SPEC сверен через GitHub API (`raw.githubusercontent.com` из песочницы агента недоступен): `**Version 0.2**` совпадает с pinned `0.2`. После сверки канона (2026-07-26) upstream внёс правку #323 (2026-08-21): каждая метка времени — ISO 8601 datetime с явным смещением, `stale_after` — момент, а не дата. Канон `okf@1.19` её не отражает (пример §3.5 записан датой). Bundle пишет метки по upstream; гейты канона это принимают (`okf_sync_gate` ищет дату внутри строки). Правка канона — за его владельцем.
* **Creation**: seed-concept'ы `product/overview`, `ops/child-data`, `engineering/on-device-model`, `engineering/safety-below-model`, `references/repo-map`.
* **Scope**: `KNOWLEDGE.md` не переносился big-bang — остаётся базой исследования. Концепты фиксируют поверх него принятые решения и инварианты; `implementation:` пока есть только у политики детских данных — кода продукта нет.
