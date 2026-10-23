# Tasks

Уроки по путям диффа (§2.2a): L40, L41 (`Packages/AllyCore/`, `knowledge/engineering/turn-detector.md`), L50, L51, L52
(`Packages/AllyCore/`, `knowledge/engineering/session.md`), L56, L58 (`Packages/AllyCore/`, `session.md`), L59, L60, L61
(`Packages/AllyCore/`, `App/Sources/`, `session.md`, `voice-loop.md`), L44, L45, L46 (`App/`, `voice-loop.md`), L9, L10,
L36, L37, L42, L43 (`CLAUDE.md`), L25 (`App/Resources/model.json` — поверхность модели) — как применены, сказано в
`plan.md`.

## D7 `turn-detector` — эта ветка

### Slice 0 — документы и подпись
- [x] T1: документы серии первым коммитом ветки `feat/turn-detector`, до кода (L33): STATUS, spec (U1–U6 таблицей,
  U7–U28 списком), plan (четыре бюджета), tasks, decisions с вопросами родителю 1–8; снятие риска ORT —
  `local/spike/speech-in-ort/README.md` (вне git)
- [x] T2: подпись родителя под спекой и планом, ответы на вопросы 1–8 — отдельным коммитом до кода; `human_ok_spec`,
  `human_ok_plan` → `yes` (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony: 1–8 по рекомендациям;
  в U3 и U5 — 1,2 с и 30 с)
- [x] T3: `eval-smoke.md` — строки U1–U6 с оракулом и ожиданием, до кода; `phase: implement`

### Slice 1 — тип хода (AllyCore, Linux)
- [x] T4: `TurnKinds.swift` и `Resources/turn_kinds.json`; U1; мутации «вопросительное слово раньше „или“», «счёт только
  в последней фразе» краснят тест (реляционный оракул снят словом родителя 2026-10-23 «сейчас собираем»: только
  подписанные примеры)
- [x] T5: сессия держит ожидаемый тип, драйвер передаёт его слуху, `turn_kind` в записи; двойник слуха пишет тип каждого
  вызова; U2; мутация «„не расслышала“ сбрасывает тип»; S1–S12, W1–W7, B1–B12 без правок утверждений

### Slice 2 — реестр слуха, «я всё», предел
- [x] T6: `Hearing.swift`, `App/Resources/hearing.json`, `model.json` без ключей слуха; U3; снимок
  `delivery/model_surface.txt`; A23 на Mac — 37 из 37
- [x] T7: просьба конца в `TurnDetector`, `Conversation.done()` → `endTurn()` только во время слушания; U4, U5; мутация
  «`done()` без сверки слушания»

### Slice 3 — приложение
- [x] T8: слить `origin/main` (L35; влиты R и Ш1 — `done()` зовёт показанную сессию, тап по кругу во время слушания —
  `done()`); `PhoneListener` — тип хода и тайминг реестра слуха, `endTurn()`, этапы `turn_limit`, `turn_done`;
  `VoiceLoop` — `hearing.json`, `done()`; консоль — кнопка «Я всё»; SwiftLint, сборка для устройства без подписи и
  оракул артефакта — зелёные на Mac
  <!-- выше 780 строк — стоп, escalation.md и к ведущему: реестр слуха в model.json либо «я всё» в D7.1 -->

### Slice 4 — телефон (с родителем)
- [ ] T9: U6 — в сессию теста после D7.1 (вопрос 8); `turns.jsonl` — в `local/`, в отчёт — числа и команды; снимков
  экрана нет (L46)

### Slice 5 — знание
- [x] T10: `turn-detector.md` (`implementation:` — `TurnKinds.swift`, `Hearing.swift`), `session.md` (`done()`,
  `turn_kind`), runbook `voice-loop.md`; места «один хвост 0,8 с», «20 с — предел реплики» — поиском (L7, L16); карта
  репозитория, `engineering/index.md`, `knowledge/log.md`; `okf_validate` и `okf_sync_gate` зелёные

### Slice 6 — сдача
- [ ] T11: verify-report — `swift test`, покрытие AllyCore ≥ 70%, сводка утверждений Swift (новые тест-файлы в ней, L26),
  мутации, блок «Изменение поверхности модели» (`model.json`, A23), `mergeable` и ссылка на зелёный CI (L35); строгий
  `delivery_check --require-ci --diff-base origin/main`; `STRICT=1 BASE=origin/main python3
  scripts/lint/check_digest_report.py` до пуша (L43)
- [ ] T12: сдача — `delivery/archive/<дата>-turn-detector` в том же PR, `.gitkeep`, строка INDEX с уроком L71,
  `turn-detector` в обязательствах CLAUDE.md, `observe_until` 2026-11-30; доклад ведущему «готово к мержу»; мерж — ведущий

## D7.1 `turn-speculation` — следующая ветка, после мержа D7
- [ ] ST1: документы первым коммитом: спека с U7–U15 таблицей дословно и ссылкой на коммит этой спеки; STATUS
  (`runtime_paths: App/Sources/Speech/`); `eval-smoke.md` до кода
- [ ] ST2: проба `SpeechAnalyzer.finalize(through:)` без конца ввода на Mac — до кода (L37)
- [ ] ST3: `Speculation.swift`, события `.tentative`, `.resumed`, общий план реплики; U7–U13; мутации «спекуляция без
  плана реплики» (U9), «отмена не обрывает поток» (U8), «голос до хвоста» (U13)
- [ ] ST4: `Phrase.tentative()`, события в `PhoneListener`; сборка и оракул артефакта
- [ ] ST5: телефон — U14, U15 вместе с U6 (сессия теста); знание; verify; сдача с уроками L72, L73

## D7.2 `silero-vad` — после мержа V1 `voice-onnx` и D7.1
- [ ] SV1: документы с U16–U21; согласовать через ведущего стык со стражем «один ORT» и раскладку `AllyOnnx`
- [ ] SV2: sherpa в `AllyOnnx`, `AllyHearing` (`OnnxPair`, `SileroVAD`, `Resampler16k`); U16, U17 на Mac
- [ ] SV3: `VoiceActivity` и `EnergyActivity` в ядре, A17 и A25–A27 без правок; U18, U19
- [ ] SV4: приложение — Silero по реестру, запас — энергия; ручная macOS-джоба — тесты `AllyHearing`
- [ ] SV5: телефон — U20, U21 (сессия теста после D7.3); знание; verify; сдача с уроком L80

## D7.3 `gigaam-asr` — после мержа D7.2
- [ ] SG1: документы с U22–U28; протокол распознавателя и предзапись в ядре; U25, U26
- [ ] SG2: `GigaAMRecognizer` и `hearing-step3`; веса external data; U23, U24 на Mac
- [ ] SG3: диктовка и GigaAM за протоколом в `App/Sources/Hearing/`, выбор по `asr`; U22
- [ ] SG4: `scripts/asr_step3.py` и тест на синтетике — U27; правило вердикта проверено заведомо проваливающей сводкой (L48)
- [ ] SG5: телефон — U28; знание; verify; сдача с уроками L81, L82

## Перенесено (не эта серия)

- Отмена слушания в `AudioIO`, перебивание и эхоподавление — D6 `full-duplex`; откат несказанного ответа спекуляции из
  памяти модели — D5 `kv-spoken`.
- Тайм-аут до речи и хвосты по её записям, `contextualStrings` диктовки — по данным чёрного ящика, отдельным решением.
- Подготовка синтеза первой фразы до хвоста — стык с голосом после V4.
