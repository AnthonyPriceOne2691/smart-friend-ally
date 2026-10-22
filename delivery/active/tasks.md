# Tasks

Уроки по путям диффа (§2.2a): L50, L51, L52 (`Packages/AllyCore/`), L40, L41 (`Packages/AllyCore/`), L44, L45, L46 (`App/`,
`knowledge/engineering/voice-loop.md`), L25, L28, L33, L34, L35, L38 (`knowledge/engineering/safety-below-model.md`), L7,
L16 (`knowledge/product/`), L47, L48, L49 (маршрутизатор и его замеры) — как применены, сказано в `plan.md`.

## D2.2 `app-session` — эта ветка

### Slice 0 — документы и подпись
- [x] T1: документы D2.2 и R первым коммитом ветки `feat/app-session`, до кода (L33): STATUS, spec (W1–W11 таблицей,
  G1–G11 списком), plan, tasks, decisions с вопросами родителю 1–9 — этот коммит
- [ ] T2: подпись родителя под спекой и планом, ответы на вопросы 1–9 — отдельным коммитом до кода; `human_ok_spec`,
  `human_ok_plan` → `yes`
- [ ] T3: после мержа D1.2 — слить `origin/main` (без перезаписи истории, L35); `eval-smoke.md` — строки W1–W11 с
  оракулом и ожиданием, до кода; `phase: implement`

### Slice 1 — драйвер и след (AllyCore, Linux)
- [ ] T4: `Conversation.swift` — `Listener`, `TalkState` с позой, поток `updates`, `wake()`/`stop()`, поколение сессии,
  обёртка стока; слушатель-двойник в `Doubles.swift`; W1–W3, W7 и свойство на 200 лентах; мутации «без поколения»,
  «слушаем в любом состоянии», «позы перепутаны» краснят тесты; ожидания — с пределом по настоящему времени (L41)
- [ ] T5: `TraceStamp.stages` и слияние этапов в `TurnTrace`; `TraceFile.swift`; W6; мутация «этапы теряются»

### Slice 2 — маршрутизатор на живом ходе
- [ ] T6: `RouterRouting` в `Routing.swift`; `forget` без модели в `Session.swift`; W4 (данные main), W5; мутация
  «forget не смотрим»; тесты S1–S12 и D1.1 зелёные без правок

### Slice 3 — приложение
- [ ] T7: `PhoneListener.swift` (слушание D1.2 за `Listener`, одноразовые этапы); `VoiceLoop` на `Conversation`:
  `RouterRouting`, `TraceFile(Caches/turns.jsonl)`, штамп, ключ лимита из `UserDefaults`, `@Published talk`, `wake()`,
  `stop()`; консоль — «Разбудить», «Стоп», строки состояния, лимита и самопроверки маршрутизатора; `TurnLog` больше не
  пишется; SwiftLint и оракул артефакта зелёные на Mac
  <!-- замер выше 780 строк — стоп, escalation.md и сразу к ведущему: E4 в R либо подпись предохранителя -->

### Slice 4 — переустановка одной командой (E4)
- [ ] T8: `scripts/reinstall_app.sh` — шаги плана по кодам возврата (L10); чужой UDID — стоп до сборки; runbook
  `voice-loop.md` — команда вместо пяти ручных

### Slice 5 — телефон (с родителем)
- [ ] T9: установка — `scripts/reinstall_app.sh` (исполнение W11); W8–W10 с фразами родителя; экран и точку микрофона
  подтверждает родитель на глаз, снимков нет (L46); `turns.jsonl` — в `local/`, в отчёт — числа и команды; попутно —
  числа отложенных A10–A12 D1.2 из того же прогона

### Slice 6 — знание
- [ ] T10: `engineering/session.md` (сессия в приложении, слушание по состоянию, контракт экрана, маршрутизатор подключён,
  `forget`; `implementation:` — `Conversation.swift`, `TraceFile.swift`); реестр `safety-below-model.md` (маршрутизатор
  на живом ходе, `forget`); runbook `voice-loop.md` (`implementation:` — `scripts/reinstall_app.sh`); места «ход по тапу» —
  поиском (L7, L16); карта репозитория, `engineering/index.md`, `knowledge/log.md`; `okf_validate` и `okf_sync_gate`
  зелёные

### Slice 7 — сдача
- [ ] T11: verify-report — `swift test` и покрытие AllyCore ≥ 70%, сводка утверждений Swift (новые тест-файлы в ней, L26),
  мутации, «Исполнение рисковых путей» (W11), `mergeable` и ссылка на зелёный CI (L35); строгий `delivery_check
  --require-ci --diff-base origin/main`; `STRICT=1 BASE=origin/main python3 scripts/lint/check_digest_report.py` до пуша
  (L43)
- [ ] T12: сдача — `delivery/archive/<дата>-app-session` в том же PR, `.gitkeep`, строка INDEX с уроками L59–L61 (если
  уроки есть), `app-session` в обязательствах CLAUDE.md, `observe_until` 2026-11-30; мерж — ведущий

## R `child-lock` — следующая ветка, после мержа D2.2

- [ ] RT1: ветка от main; документы R первым коммитом: спека с таблицей G1–G11 дословно и ссылкой на коммит этой спеки,
  подпись — ссылкой на ответ родителя; STATUS (`runtime_paths: scripts/child_mode.sh`); `eval-smoke.md` до кода (L33)
- [ ] RT2: шаг владельца — ключ ECDSA P-256 в Secretive, открытая строка в `.github/allowed_signers` (пространство
  `ally-child-mode`)
- [ ] RT3: `ReleaseGate.swift`, `Resources/release.json`; G1–G6, G9; мутации «без предела 7 дней», «без сверки поверхности»,
  «без самопроверки», «неподписанное принято»
- [ ] RT4: `SSHSignature.swift` под `#if canImport(CryptoKit)`; фикстуры настоящим `ssh-keygen` тестовыми ключами
  (закрытые — не в git), G7 на Mac, видимый пропуск на Linux; шаг AllyCore в ручной macOS-джобе `ios.yml`
- [ ] RT5: приложение — `ChildMode.swift`, `ChildScreen.swift` (заглушка), строки замка и кнопки консоли, `audience` в
  штампе, проверки доступа на границах; ключ в бандл через `project.yml`
- [ ] RT6: `scripts/child_mode.sh` по образцу `sign_irreversible.sh` (окно с текстом, «Не подписывать» по умолчанию, сокет
  Secretive переменной, `2>/dev/null` у подписи)
- [ ] RT7: телефон и Mac с родителем — G8, G10, G11
- [ ] RT8: знание — `product/child-mode.md`, `safety-below-model.md`, `engineering/session.md`, runbook; все места E2 —
  поиском (L7, L16)
- [ ] RT9: verify-report, строгий `delivery_check`, сдача, уроки, мерж — ведущий

## Перенесено (не эти поставки)

- Пороги замка без присмотра (цели 18.10) и `release-gate.json` — R2 `release-gate`: правило переноса, R с ними — 716 > 700
  (L52); числа подписывает родитель сейчас (вопрос 9).
- Перерыв 60 минут после прощания по лимиту и детский экран с аксолотликом — «оболочка» (ответ родителя 6, правка объёма
  2026-10-22).
- Отмена слушания в `AudioIO` и перебивание тапом — D6 `full-duplex`; откат хода из KV модели — D5 `kv-spoken`; слова и звук
  чёрного ящика (только при `audience: supervised`) — D3; Face ID и экран настроек — D8 `parent-zone`.
