# Plan: слух — D7 `turn-detector` (эта ветка), D7.1 `turn-speculation`, D7.2 `silero-vad`, D7.3 `gigaam-asr`

Уроки архива. **L33**: спека, план и примеры — первым коммитом ветки, до кода; подпись родителя — отдельным коммитом;
`eval-smoke.md` — после подписи, до кода; D7.1–D7.3 начинают свои ветки коммитом документов с примерами таблицей дословно и
ссылкой на коммит этой спеки. **L34, L41, L52, L61, L58**: бюджет движка с двойниками виртуального времени — по Swift
прошлых поставок с поправкой ×1,25 (session-core +25%, black-box +31%), проводки — по плану (app-session +7%); тесты
выходят не меньше исходников; покрытие AllyCore — по своему `Sources/`. **L51**: буква U свободна во всех тест-файлах main
и рабочих деревьев (поиск 2026-10-23). **L50, L58**: тип хода, «я всё», спекуляция, Silero и GigaAM приходят вместе с вызывающим;
новое поле или метод проверяются на обёртках — `Conversation` пересобирает `SessionParts` и оборачивает сток, двойник
слуха и драйвер получают тип хода и `endTurn()`, мутация «обёртка теряет тип хода» в U2. **L44**: длина кадра — вход
алгоритма: энергия судит кадры 20 мс, Silero — окна 512 отсчётов 16 кГц (32 мс), запаздывание флага — параметр
активности (U18); фактический буфер тапа пишет `tap_buffer`. **L45**: числа реестра слуха — `Codable` с `Double`, без
`as? Float`. **L46**: снимков экрана телефона нет; экран и точку микрофона подтверждает родитель на глаз. **L60**:
`AudioIO.listen` отменить нельзя — «я всё» живёт в определителе ядра (просьба конца на следующем кадре), а рисковый путь
звука не трогается; отмена — D6. **L59**: мутации названы по механизму («`done()` без сверки слушания», «„не
расслышала“ сбрасывает тип»), а не по проверке, которую предполагают в коде. **L40**: нарезка потока не меняется,
`SentenceStream` и `TurnRunner` D7 не трогает. **L23, L37**: поведение вендора — гипотеза до пробы:
`finalize(through:)` у `SpeechAnalyzer` без конца ввода (D7.1) — проба на Mac до кода; sherpa и отображение весов на iOS
— исполнение на телефоне (U20, U28). **L17, L22**: числа памяти — с рантаймом (ORT 1.28.0, sherpa 1.13.8) и метрикой (`phys_footprint`). **L36**:
лицензии — с открытым первоисточником (sherpa Apache-2.0 — LICENSE репозитория; ORT MIT — LICENSE pod-архива; Silero и
GigaAM MIT). **L56, L19, L47, L48**: шаг 3 судит тот звук, на котором посчитан живой текст (GigaAM получает те же 16 кГц
Int16, что пишет ящик); метрики инструмента заморожены до её записей; инструмент печатает хэши моделей, которые мерил; строка
вердикта судит обе части правила (WER и однословные) и проверяется на заведомо проваливающей сводке. **L49**: доля
совпавших текстов на «возможно, конец» на стенде — не оценка: её меряет телефон (U15). **L26, L43**: новые тест-файлы
(`TurnKindTests`, `HearingTests`) обязаны появиться в сводке утверждений Swift; `STRICT=1 BASE=origin/main python3
scripts/lint/check_digest_report.py` — до пуша сдачи. **L35**: перед ссылкой на CI — `mergeable`; `PhoneListener.swift`
правит голос V4, `Session.swift` и `Conversation.swift` — R и D3.2, `knowledge/log.md` — все: слияние main без перезаписи
истории. **L14**: если ведущий накатит канон — сразу строгий `delivery_check --require-ci --diff-base origin/main`. **L7,
L16**: места «один хвост 0,8 с», «20 с речи — предел реплики» и контракт экрана находит поиск (`voice-loop.md`,
`turn-detector.md`, `session.md`, `CLAUDE.md`), а не память. **L38**: checksum в `Package.swift` (D7.2) — с `pragma:
allowlist secret`, как у AllyLlama. **L10**: шаги скриптов судятся кодом возврата. **L25**: промпт, реестр модели и пакет
модели не трогаем; `model.json` теряет только ключи слуха (A23 — дифференциальный прогон). **L28**: признаки типа хода —
формой вопроса, а не списком фраз: ложные срабатывания формы меряет корпус ходов Элли в чёрном ящике, а не дописывание слов.
Не применимы: **L1, L12** — n/a «до `App/*.swift`» истекли; **L2** — нового манифеста в D7 нет (в D7.2 — строка на путь
`Packages/AllyHearing/Package.swift`); **L24** — закрыт `delivery@2.04`; **L29, L30** — прогонов судей нет; **L39** —
классификатор — десятки сравнений строк на ход; **L42** — наката канона в плане нет; **L57** — гейт данных ребёнка не
меняется.

## Разбиение

| Поставка | Что | План, строк | Файлов | Рисковый путь | Когда |
|---|---|---|---|---|---|
| **D7 `turn-detector`** | тип хода, реестр слуха `hearing.json`, «я всё», предел из реестра | ≈ 371 | 20 | нет (звук и распознавание не тронуты) | эта ветка, после подписи |
| D7.1 `turn-speculation` | спекуляция: `Speculation` в ядре, события слуха, текст диктовки на «возможно, конец» | ≈ 433 | 11 | `App/Sources/Speech/` | после мержа D7 |
| D7.2 `silero-vad` | sherpa в `AllyOnnx`, пара версий, `AllyHearing`, Silero за протоколом активности | ≈ 380 | 16 | `Packages/AllyHearing/` | после мержа V1 `voice-onnx` и D7.1 |
| D7.3 `gigaam-asr` | GigaAM за протоколом распознавателя, external data, инструмент шага 3 | ≈ 484 | 12 | `Packages/AllyHearing/` | после мержа D7.2 |

Ожидание по поправке: D7 ≈ 465, D7.1 ≈ 540, D7.2 ≈ 475, D7.3 ≈ 605 — все ниже порога стопа 780. Вместе D7 и D7.1 —
≈ 805 по плану (≈ 1 005 с поправкой): одной поставкой — выше предела, поэтому две.

## Approach — D7

1. **Порядок.** Подпись родителя под спекой, планом и ответами 1–8 → `eval-smoke.md` (U1–U6) до кода → implement срезами
   (`tasks.md`) → verify → сдача. `AllyDiscipline`, `AllyLlama`, `App/Sources/Audio/`, `App/Sources/Speech/` не трогаем.
2. **Классификатор (`TurnKinds.swift`).** `TurnKind.after(_ sentences: [String]) -> TurnKind`: нижний регистр, «ё» → «е»,
   знаки → пробел, слова; счёт — признак в любой фразе; дальше по последней фразе: без «?» → `open`; «или» → `closed`;
   первое вопросительное слово «сколько» → `closed`; есть вопросительное слово → `open`; иначе `closed`. Признаки —
   `Resources/turn_kinds.json` (`counting`, `choice`, `number`, `open`); чтение — как `SessionData`, ресурс модуля.
3. **Сессия (`Session.swift`).** `nonisolated var expect: TurnKind` (под `Locked`): после `phrase` и после хода — по
   `turn.sentences`, кроме `misheard`; в `greet` — по фразам приветствия. `TraceHead.turnKind` — тип слушания, на которое
   отвечает запись (`nil` у приветствия); `TurnTrace.turnKind` → `turn_kind`.
4. **Драйвер (`Conversation.swift`).** `Listener.listen(_ kind: TurnKind)` и `endTurn()`; цикл слушания передаёт
   `session.expect`; `done()` — `listener.endTurn()` только при `session.state.listens`.
5. **Определитель (`TurnDetector.swift`).** `TurnEnding` — общий флаг просьбы конца (`Locked<Bool>`), его ставит слух;
   `process` на следующем кадре отдаёт `.ended(lastVoiced: lastVoiced ?? time, byLimit: false)`. Сигнатуры событий не
   меняются: `AudioIO` их читает как раньше.
6. **Реестр слуха (`Hearing.swift`).** `Hearing.decode(_:)`: `turn` (`TurnTiming` без изменений) и `listen_timeout`;
   `ModelRegistry` теряет `turn` и `listenTimeout`. `App/Resources/hearing.json`: `open` 1,8, `closed` 1,2*, `counting`
   2,5, `tentative` 0,3, `pre_roll` 1,5, `max_turn` 30*, `listen_timeout` 8 (* — ответы 2, 3). Снимок
   `delivery/model_surface.txt` — новый хэш `model.json`, блок «Изменение поверхности модели» в verify-report.
7. **Приложение.** `PhoneListener`: `TurnDetector(kind:timing:)` с типом сессии и таймингом реестра слуха; `endTurn()`
   ставит флаг текущего слушания; этапы `turn_limit`, `turn_done`. `VoiceLoop`: читает `hearing.json` (нет файла или не
   читается — строка консоли и прежние значения ядра), `done()`. Консоль: кнопка «Я всё», активна при
   `talk.pose == .listens`.
8. **Знание.** `turn-detector.md` (тип хода, реестр слуха, «я всё», предел; `implementation:` — `TurnKinds.swift`,
   `Hearing.swift`), `session.md` (`done()`, `turn_kind`), runbook `voice-loop.md` (`hearing.json`, «Я всё»), места «один
   хвост 0,8 с» и «20 с» — поиском, `engineering/index.md`, карта репозитория, `knowledge/log.md`; `okf_validate` и
   `okf_sync_gate` зелёные.

## Approach — D7.1 (следующая ветка)

1. **`Speculation` (AllyCore)** — обёртка `LanguageModel`, которой владеет сессия: `start(_ utterance:)` начинает ответ и
   копит последний снимок текста; `cancel()` обрывает поток — у `LlamaModel` обрыв откатывает ход из KV; `reply(to:)` с
   тем же текстом (по буквам) отдаёт накопленное и дальше живой поток, с другим — отменяет начатый и зовёт модель заново.
   Счётчики: `spec_reused`, `spec_lead`, `spec_cancels`, `spec_stale` (ответ дописан до отмены) — в этапы записи хода.
2. **Сессия.** События `.tentative(String)` и `.resumed` — только в listening и windingDown, состояние не меняют. Общий
   план реплики (`plan(text)`: не расслышала, её прощание, скрипт, заготовка `forget`, модель) зовут и `hear`, и
   спекуляция: к модели идёт только то, что пошло бы к ней на хвосте (U9).
3. **Драйвер.** События слуха — по порядку через поток с одним потребителем; после конца слушания поток допивается, затем
   `.heard`. Определитель отдаёт «возможно, конец» и «продолжение» через сток событий — `AudioIO` по-прежнему не меняется.
4. **Приложение.** `Phrase.tentative()` — `analyzer.finalize(through: nil)` без конца ввода и текст собранного итога
   (`App/Sources/Speech/`, рисковый путь; поведение `finalize(through:)` — проба на Mac до кода, L37). `PhoneListener` на
   «возможно, конец» берёт этот текст и отдаёт событие.
5. **Знание.** `turn-detector.md`, `session.md`, `safety-below-model.md` (спекуляция не пускает к модели реплику, которую
   не пустил бы ход), runbook.

## Approach — D7.2 (после мержа V1 `voice-onnx`)

1. **`AllyOnnx`:** два `binaryTarget` sherpa 1.13.8 static — iOS и macOS, с условием платформы, как в `Package.swift`
   k2-fsa v1.13.8, — и C-модуль с `sherpa-onnx/c-api/c-api.h`; ORT — тот же `binaryTarget` голоса; `linkerSettings` —
   `libc++`, CoreML. Страж голоса `check_single_ort.sh` — пропускает эти xcframework (объектов ORT в них нет, `nm -u`) и
   пинует пару «sherpa 1.13.8 — ORT 1.28.x»; отрицательный контроль — копия с sherpa 1.13.9 и с ORT 1.24.2.
2. **`Packages/AllyHearing`** (зависит от `AllyOnnx`): `OnnxPair` — рантайм-проверка (`OrtGetApiBase()->GetApi(28)`,
   `SherpaOnnxGetVersionStr()`); `SileroVAD` — VAD sherpa (порог 0,5, речь 0,25 с, тишина 0,1 с, окно 512, 1 поток);
   `Resampler16k` — кадры тапа в 16 кГц Float (`AVAudioConverter`). Тесты — Mac: U16, U17 на данных спайка вне git.
3. **AllyCore:** `VoiceActivity` (кадр → флаг речи, `hangover`) и `EnergyActivity` — логика энергии переезжает из
   `TurnDetector` без изменений (A17, A25–A27 без правок); политика конца хода — одна для любой активности (U18).
4. **Приложение:** `hearing.json` — `vad` (`energy`, `silero`; файл, байты); Silero-активность в `PhoneListener`; нет
   файла, не та пара — строка консоли и энергия (U16, U19). Файл Silero — в `Library/Application Support/Models`, команда
   копирования — в runbook.

## Approach — D7.3 (после мержа D7.2)

1. **AllyCore:** протокол распознавателя на реплику (`feed`, `tentative`, `finish`, `cancel`) и предзапись для пакетного
   распознавателя (кольцо 1,5 с до флага речи, но не раньше открытия микрофона); реестр слуха — `asr`.
2. **`AllyHearing`:** `GigaAMRecognizer` — офлайн-распознаватель sherpa (NeMo CTC, 2 потока, веса external data);
   исполняемый `hearing-step3`: расшифровки реплик ящика — в файл в `local/`, на экран — ничего.
3. **Приложение:** диктовка за протоколом — обёрткой над `Phrase` в `App/Sources/Hearing/` (рисковый путь
   `App/Sources/Speech/` не трогается); GigaAM — 16 кГц Int16 → Float, расшифровка на «возможно, конец» — она же на
   хвосте; выбор по `asr`, запас — диктовка со строкой консоли.
4. **`scripts/asr_step3.py`** (только stdlib): выгрузка ящика + `refs.csv` + расшифровки → суммы и вердикт; тест —
   синтетический набор из публичных клипов, проверка «ни одной строки эталона и гипотез в выводе» (U27).
5. **Веса:** `model.int8.onnx` + `model.int8.onnx.data` (конвертация — onnx 1.23.2, команда в runbook), sha256 — в
   runbook и реестре слуха (байты); копирование на телефон — шаг родителя.

## Stack / boundaries

- Swift tools 5.10, XCTest. AllyCore — Linux (джоба `swift`) и Mac; `AllyOnnx`, `AllyHearing` — Mac и iOS, ручная
  macOS-джоба `ios.yml` и локально; данные тестов Silero и GigaAM — `~/models` и `local/spike/` (публичные), без них —
  видимый пропуск.
- Зависимости вниз: App → AllyHearing → AllyOnnx; App → AllyLlama → AllyCore → Discipline. AllyCore ничего платформенного
  не импортирует.
- Сеть: ни одного сетевого API; модели — копированием с Mac.
- Новых зависимостей в D7 нет; D7.2 — манифест `Packages/AllyHearing/Package.swift` и `binaryTarget` sherpa-onnx 1.13.8
  (`new_dependency` строкой на путь и на пакет, L2).

## Budget D7 (800 строк, 25 файлов, рисковых путей 0)

| Файл | строк |
|---|---|
| `Packages/AllyCore/Sources/AllyCore/TurnKinds.swift` (классификатор, признаки) | 45 |
| `Packages/AllyCore/Sources/AllyCore/Resources/turn_kinds.json` | 15 |
| `Packages/AllyCore/Sources/AllyCore/Hearing.swift` (реестр слуха) | 20 |
| `Packages/AllyCore/Sources/AllyCore/ModelRegistry.swift` (без ключей слуха) | −2 |
| `Packages/AllyCore/Sources/AllyCore/TurnDetector.swift` (просьба конца) | 12 |
| `Packages/AllyCore/Sources/AllyCore/Session.swift` (ожидаемый тип, тип в записи) | 14 |
| `Packages/AllyCore/Sources/AllyCore/Conversation.swift` (`listen(kind)`, `done()`) | 10 |
| `Packages/AllyCore/Sources/AllyCore/TurnTrace.swift` (`turn_kind`) | 4 |
| `Packages/AllyCore/Tests/AllyCoreTests/TurnKindTests.swift` (U1) | 55 |
| `Packages/AllyCore/Tests/AllyCoreTests/ConversationTests.swift` (U2, U4) | 75 |
| `Packages/AllyCore/Tests/AllyCoreTests/TurnDetectorTests.swift` (U4, U5) | 35 |
| `Packages/AllyCore/Tests/AllyCoreTests/HearingTests.swift` (U3) | 30 |
| `Packages/AllyCore/Tests/AllyCoreTests/CoreTests.swift` (проверка хвостов реестра переезжает в `HearingTests`) | −5 |
| `Packages/AllyCore/Tests/AllyCoreTests/Doubles.swift` (слух-двойник: тип, `endTurn`) | 20 |
| `App/Sources/PhoneListener.swift` (тип, «я всё», этапы) | 18 |
| `App/Sources/VoiceLoop.swift` (`hearing.json`, `done()`) | 10 |
| `App/Sources/AllyApp.swift` (кнопка «Я всё») | 5 |
| `App/Resources/hearing.json` | 8 |
| `App/Resources/model.json` (без `turn` и `listen_timeout`) | −2 |
| `CLAUDE.md` (сдача: обязательство наблюдения) | 4 |
| **итого, 20 файлов** | **≈ 371** |

Замер выше 780 — стоп, `escalation.md` и сразу к ведущему. Вариант 1: реестр слуха остаётся в `model.json` (−30 строк,
блок поверхности модели и A23 нужны и так); вариант 2: «я всё» уходит в D7.1 (−65). Цена первого — параметры слуха и
модели в одном файле до конца серии; второго — шум без выхода до D7.1.

## Budget D7.1 (800, 25, рисковых путей 1: `App/Sources/Speech/`)

| Файл | строк |
|---|---|
| `Packages/AllyCore/Sources/AllyCore/Speculation.swift` | 70 |
| `Packages/AllyCore/Sources/AllyCore/Session.swift` (события, общий план реплики, этапы спекуляции) | 35 |
| `Packages/AllyCore/Sources/AllyCore/Conversation.swift` (события слуха по порядку) | 22 |
| `Packages/AllyCore/Sources/AllyCore/TurnDetector.swift` (сток событий) | 6 |
| протокол `Listener` (события) | 4 |
| `Packages/AllyCore/Tests/AllyCoreTests/SpeculationTests.swift` (U7–U12) | 170 |
| `Packages/AllyCore/Tests/AllyCoreTests/ConversationTests.swift` (U13) | 45 |
| `Packages/AllyCore/Tests/AllyCoreTests/Doubles.swift` (модель с историей и отменой, слух с событиями) | 45 |
| `App/Sources/Speech/DictationRecognizer.swift` (`Phrase.tentative()`) | 10 |
| `App/Sources/PhoneListener.swift` (события, текст на «возможно, конец») | 22 |
| `CLAUDE.md` | 4 |
| **итого, 11 файлов** | **≈ 433** |

Выше 780 — стоп. Вариант: свойство U13 и счётчик `spec_stale` — в D7.2 (−60); цена — свойство спекуляции позже её кода.

## Budget D7.2 (800, 25, рисковых путей 1: `Packages/AllyHearing/`)

| Файл | строк |
|---|---|
| `Packages/AllyOnnx/Package.swift` (+ sherpa iOS и macOS, C-модуль) и модуль `SherpaC` | 24 |
| `Packages/AllyHearing/Package.swift` | 20 |
| `Packages/AllyHearing/Sources/AllyHearing/OnnxPair.swift` | 25 |
| `Packages/AllyHearing/Sources/AllyHearing/SileroVAD.swift` | 50 |
| `Packages/AllyHearing/Sources/AllyHearing/Resampler16k.swift` | 35 |
| `Packages/AllyHearing/Tests/AllyHearingTests/SileroTests.swift` (U16, U17) | 70 |
| `Packages/AllyCore/Sources/AllyCore/VoiceActivity.swift` и `TurnDetector.swift` (энергия — переезд, политика) | 35 |
| `Packages/AllyCore/Sources/AllyCore/Hearing.swift` (`vad`, проверка файла) | 18 |
| `Packages/AllyCore/Tests/AllyCoreTests/TurnDetectorTests.swift` (U18) | 50 |
| `App/Sources/PhoneListener.swift`, `App/Sources/VoiceLoop.swift`, `App/Resources/hearing.json`, `App/project.yml` | 49 |
| `CLAUDE.md` | 4 |
| **итого, ≈ 16 файлов** | **≈ 380** |

## Budget D7.3 (800, 25, рисковых путей 1: `Packages/AllyHearing/`)

| Файл | строк |
|---|---|
| `Packages/AllyCore/Sources/AllyCore/Recognition.swift` (протокол, предзапись) и `Hearing.swift` (`asr`) | 50 |
| `Packages/AllyCore/Tests/AllyCoreTests/RecognitionTests.swift` (U25, U26) | 60 |
| `Packages/AllyHearing/Sources/AllyHearing/GigaAM.swift` | 50 |
| `Packages/AllyHearing/Sources/hearing-step3/main.swift` | 50 |
| `Packages/AllyHearing/Tests/AllyHearingTests/GigaAMTests.swift` (U23, U24) | 55 |
| `App/Sources/Hearing/DictationPhrase.swift`, `App/Sources/Hearing/GigaAMPhrase.swift` | 65 |
| `App/Sources/VoiceLoop.swift`, `App/Resources/hearing.json` | 20 |
| `scripts/asr_step3.py` и его тест (U27) | 130 |
| `CLAUDE.md` | 4 |
| **итого, ≈ 12 файлов** | **≈ 484** |

Выше 780 — стоп. Вариант: инструмент шага 3 — отдельной поставкой после первых записей ящика (−180); цена — шаг 3 ждёт ещё
одну поставку.

## Rejected alternatives

- **Silero и GigaAM прямо через C API ORT со своим fbank** — отклонено решением ведущего 2026-10-23 и замером: sherpa
  1.13.8 на общем ORT 1.28.0 даёт гипотезы и флаги спайка бит в бит (300 из 300, 88 из 88, 1434 из 1434), а свой fbank
  GigaAM (окно Ханна, 64 мел, без предыскажения) и разбор CTC — ≈ 150 строк и паритет, который пришлось бы доказывать
  заново. Его плюс — опция «без перепаковки весов» (footprint 27–38 МБ против 398) — оставлен запасным, если бюджет памяти
  не сойдётся на телефоне (U28).
- **Пакет `k2-fsa/sherpa-onnx` целиком** — отклонено: тянет свой ORT (`csukuangfj/onnxruntime-libs` 1.28.2, сборка третьего
  лица без файла лицензии) — второй ORT в бинаре рядом с ORT голоса.
- **Вся серия одной поставкой** — отклонено: ≈ 1 670 строк при пределе 800 и три рисковых пути.
- **Тип хода моделью** (метка в ответе или второй проход) — отклонено: решение родителя — кодом; модель не держит частоты и
  гарантии (L25), а метку в ответе надо было бы ещё и вырезать до голоса.
- **Smart Turn v3** — отклонено замером спайка: на русской речи AUC конец/пауза 0,70, раннего конца больше, чем у хвоста.
- **Один хвост 1,8 с для всего** — отклонено: закрытые ответы и скрипты ждали бы лишние 0,6–1,0 с без пользы.
- **«Я всё» через отмену слушания в `AudioIO`** — отклонено: рисковый путь звука, второй сверх нужного; просьба конца в
  определителе ядра тестируется на Linux. Цена — ход кончается на следующем кадре (≤ 20 мс + буфер тапа).
- **Реестр слуха в `model.json`** — отклонено: каждая поставка серии трогала бы поверхность модели и требовала блок §14.4,
  а параметры слуха модель не читает (П10). Цена — одно касание поверхности в D7 (A23).
- **Спекуляция с удержанием голоса внутри хода сессии** — отклонено для D7.1: состояния и записи хода пришлось бы делать
  «черновыми»; обёртка модели оставляет сессию прежней, звук начинается на хвосте и так. Подготовку синтеза первой фразы
  до хвоста (Supertonic) — отдельным стыком с голосом после V4.
- **Откат несказанного ответа спекуляции в D7.1** — отклонено: правка `Packages/AllyLlama` — второй рисковый путь; место —
  D5 `kv-spoken`; до неё — счётчик `spec_stale` (вопрос 5).
- **Модели слуха в бандле или в git** — отклонено: GigaAM 222 МБ к каждой установке, Silero 2,3 МБ двоичного в git; веса
  живут, как веса модели, в контейнере (вопрос 6).
- **Своя сборка sherpa против общего ORT** — не нужна: релизный static xcframework sherpa объектов ORT не содержит и
  ссылается только на `_OrtGetApiBase` (проба голоса и снятие риска 23.10).

## Risks

- Бюджет — выше; пороги и варианты названы у каждой поставки.
- Телефонные примеры требуют времени родителя (фразы вслух, телевизор, копирование моделей) — прогон назначает ведущий.
- До D7.1 открытые ходы отвечают на ≈ 1 с позже: D7 без D7.1 на телефон не ставится (вопрос 8).
- `finalize(through:)` может вести себя не так, как написано: проба на Mac до кода D7.1; не держит — текст на «возможно,
  конец» берётся из промежуточных результатов, и U15 скажет, хватает ли.
- Страж «один ORT» и стык `AllyOnnx` — через ведущего, до кода D7.2.
- `PhoneListener.swift` правит голос V4: правки D7 — минимальные, одним блоком.

## Rollout

- Мерж — ведущий через `merge_guard.sh`; на телефон — отдельным решением родителя (`manual-deploy`), первая установка —
  `scripts/reinstall_app.sh` после D7.1.
- Модели слуха (D7.2, D7.3) — команда копирования из runbook, шаг родителя; без них приложение слушает энергией и
  диктовкой и говорит об этом строкой консоли.

## Test / eval strategy

- Метки `// U<n>`: `TurnKindTests` — U1; `ConversationTests` — U2, U4; `TurnDetectorTests` — U4, U5; `HearingTests` — U3.
  U6 — строка `eval-smoke.md`, исполнение на телефоне, команды и числа — в verify-report.
- Двойники D1.1, D2, D2.2 (`TestClock`, `ReplyQueue`, `RecordingVoice`, `ScriptedEar`, `RecordingSink`) — слух-двойник
  получает тип хода и `endTurn()`, пишет тип каждого вызова.
- Мутации в ту же сессию (П30): вопросительное слово раньше «или» (U1); счёт только в последней фразе (U1); «не
  расслышала» сбрасывает тип (U2); обёртка теряет тип хода (U2, L58); `done()` без сверки слушания (U4); просьба конца не
  смотрится (U4); предел не из реестра (U5).
- Реляционный оракул D7: на 200 случайных ходах Элли (наборы фраз-шаблонов, seed закреплён) тип не зависит от регистра,
  «ё»/«е» и знаков после слов; добавление фразы без вопроса в начало хода не меняет тип, кроме счёта. Детектор канона
  знает только hypothesis и fast-check — предупреждение разбирается в verify-report, как у D2.2.
- Покрытие AllyCore ≥ 70% — по своему `Sources/` (L41); поверхность модели — A23 на Mac (ответы модели те же).
