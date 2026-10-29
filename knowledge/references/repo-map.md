---
type: Reference
title: Repository map
description: Где входные точки, где что лежит, где грабли.
status: stable
tags: [repo, onboarding]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-18T19:31:37Z
stale_after: 2027-01-02T00:00:00Z
# Только структурные якоря (OKF §3.5a): тронули файл — предложение карты стало
# ложным. Источник Xcode-проекта — App/project.yml (XcodeGen).
implementation:
  - requirements-dev.txt
  - scripts/merge_guard.sh
  - App/project.yml
---

# Входные точки

- **Приложение** — `App/` (XcodeGen: `cd App && xcodegen generate`, проект в git не лежит); сборка, веса на телефон,
  переустановка одной командой (`bash scripts/reinstall_app.sh <UDID>`), исключение «при родителе»
  (`bash scripts/child_mode.sh <UDID> --until <дата>`, ключ родителя — `.github/allowed_signers`), запуск и след хода —
  runbook [Voice loop](/engineering/voice-loop.md); на Mac — `python3 scripts/mac_files.py` (папка файлов) и
  `bash scripts/mac_app.sh` (проект в Xcode, запуск — ⌘R родителя; [Mac run](/engineering/mac-run.md)); память — пакет `AllyMemory` в `App/project.yml`: отбор реплик
  `MemoryTap`, очередь и разбор после прощания (`MemoryLlama`). Модель — пакет `Packages/AllyLlama` (llama.cpp
  b10809; паритет со стендом: `swift test --disable-keychain --package-path Packages/AllyLlama`, веса в `~/models`).
- **Дисциплина ответа** — пакет `Packages/AllyDiscipline` (ремонт текста, контракт хода, маршрутизатор до модели):
  `swift test --package-path Packages/AllyDiscipline`.
- **Ядро голосового цикла** — `Packages/AllyCore` (ход через контракт, конец реплики, журнал хода без слов, реестр
  модели, сессия с мягким лимитом и крючком маршрутизатора, драйвер сессии со слухом `Conversation`, маршрутизатор на
  живом ходе `RouterRouting`, след хода и его файл `TraceFile`; тексты сессии — `Resources/session.json`; энциклопедия
  «почему» `Encyclopedia` — основы Snowball, SQLite FTS5 через `AllySQLite`, списки — `Resources/encyclopedia.json`,
  база — `Resources/encyclopedia.ru.jsonl`, подсказка во входе модели — `Knowledge.swift`):
  `swift test --package-path Packages/AllyCore` (тулчейн Xcode: `DEVELOPER_DIR`). Паритет энциклопедии со стендом —
  `swift run -c release --package-path Packages/AllyCore encyclopedia-replay <база.jsonl> [конфиг.json] < вопросы.jsonl`.
- **Детский экран (оболочка)** — `Packages/AllyShell`: `ShellCore` (позы фаз, кадры, движение, раскладка, палитра,
  венок, правило тапа `Tap`, перерыв после лимита `Nap` — Linux) и `ShellUI` (Элли с венком, пузырь и небо `SkyArt` в
  SwiftUI под `#if canImport(SwiftUI)`; экран дочки `ChildShell` с зоной взрослых в стекле; фон консоли `AdultSky` и
  стеклянные кнопки `GlassCapsule`). Цель пакета и приложения — iOS 27 (app-glass; `App/project.yml`), тесты пакета на
  Mac — macOS 27. Приложение берёт `ShellUI` и `ShellCore` через `App/project.yml`, тело `App/Sources/ChildScreen.swift`
  — `ChildShell`, вид консоли — `App/Sources/ConsoleView.swift` (данные даёт `Console` в `AllyApp.swift`); токены облика
  взрослых — `ShellUI/Look.swift`, краски — `ShellCore/Palette.swift`. Снимки семи фаз, лист `sheet.png`,
  полосы движения и экран целиком (`app/`) пишет `swift test --disable-keychain --package-path Packages/AllyShell` на
  Mac в `local/shell-snapshots/`; на Linux снимки пропускаются видимо. Настоящее стекло (`glass/`) снимает своё окно
  на Mac — окно на миг у правого верхнего края экрана; `ImageRenderer` стекло не рисует. Снимков экрана телефона нет
  никогда (L46).
- **Расстановщик ударений** — `Packages/AllyAccent` (RUAccent на Swift: токенизаторы; паритет на Mac — файлы в
  `~/models/tts/ruaccent` и `~/models/tts/ruaccent-parity`): `swift test --disable-keychain --package-path Packages/AllyAccent`.
- **Текст для синтеза** — `Packages/AllySpeechText` (ударения, закреплённый словарь, правила чтения; данные —
  `Resources/speech-text.json`): `swift test --disable-keychain --package-path Packages/AllySpeechText`.
- **Обработка голоса после синтеза** — `Packages/AllyVoiceFX` (C-ядро: трекер основного тона, PSOLA, эквалайзер;
  обёртка `VoiceFX`, `VoiceEQ`, `PitchTrack`): `swift test --disable-keychain --package-path Packages/AllyVoiceFX`; звук против
  цепочки стенда — `local/spike/voice-fx/scripts/port_vs_py.py` на Mac (Z30). Строка пресета и файлы голоса —
  `App/Resources/voice.json` (`VoiceSettings` в `AllyCore`); на телефон — `python3 scripts/copy_voice.py <UDID>`.
- **Память о ребёнке** — `Packages/AllyMemory` (факты с опорой на ход, замена по дате, блок для промпта, «стереть всё»,
  запрет на любом пути, разбор разговора; слова блока — `Resources/memory.json`, правила запрета —
  `Resources/forbidden.json`, промпт разбора — `Resources/extract.*`) поверх общего SQLite приложения
  `Packages/AllySQLite` (системный модуль `CSQLite` и тонкая обёртка):
  `swift test --disable-keychain --package-path Packages/AllyMemory`;
  [Memory](/engineering/memory.md).
- **Контур:** `python3 scripts/delivery_check.py` — фазы поставки;
  `.venv/bin/pre-commit run --all-files --verbose` — гейты;
  `python3 scripts/lint/contour_doctor.py` — судят ли гейты;
  `bash scripts/merge_guard.sh <ветка> main` — единственный путь в `main`.
- **Инструменты контура** ставятся из `requirements-dev.txt` в `.venv/` в корне
  (`uv venv .venv && uv pip install --python .venv/bin/python -r requirements-dev.txt`).

# Где что лежит

| Путь | Что |
|---|---|
| `KNOWLEDGE.md` | база исследования и принципы П1–П37 — читать до решения о продукте |
| `knowledge/` | канон домена (OKF v0.2) |
| `delivery/` | поставки: `active/` — текущая, `archive/` — завершённые с уроками |
| `scripts/`, `scripts/lint/` | механика контура; канонные файлы правятся только перевендориванием; продуктовые — `scripts/reinstall_app.sh` (E4), `scripts/child_mode.sh` (R), `scripts/run_demo.sh` (демо в симуляторе) |
| `docs/canon/` | снимок канонов с самопроверкой — только локально, в git его нет (вариант D с 2026-10-25: репозиторий публичный, канон проприетарный; `.git/info/exclude` и хук `canon-texts-stay-out`); в свежем клоне и новом ворктри каталога нет — снимок раскладывается локально |
| `App/` | приложение iOS: `project.yml`, `Sources/` (консоль, цикл, звук, распознавание), `Resources/` (персона, реестр); `Demo/` — демо облика для симулятора, своя цель `AllyDemo` без модели, микрофона и голоса, в приложение не попадает (`bash scripts/run_demo.sh`, граница — `scripts/lint/check_demo_boundary.sh`; [Design demo](/engineering/design-demo.md)) |
| `Packages/` | Swift-пакеты: `AllyDiscipline` (дисциплина ответа), `AllyCore` (ядро хода), `AllyLlama` (модель), `AllyShell` (детский экран), `AllySpeechText` (текст для синтеза), `AllyOnnx` (один ONNX Runtime приложения, sherpa-onnx), `AllyVoice` (движок голоса), `AllyVoiceFX` (PSOLA и эквалайзер), `AllyAccent` (RUAccent на Swift, в приложении — расстановщик), `AllySQLite` (общий SQLite), `AllyMemory` (память о ребёнке), `AllyHearing` (слух: Silero VAD) |
| `local/` | данные ребёнка и прочее локальное — игнорируется, гейт не пускает в git |

# Грабли

- **Пробел в пути** (`Smart frend Ally`): пути в скриптах и `entry:` хуков — только в кавычках.
- **Xcode не выбран**: активный developer dir — Command Line Tools. Команды Xcode
  и SwiftLint — с `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- **Гейт детских данных ловит по сигнатуре**: переименованная запись тоже
  красная, а неигнорируемый аудиофайл в дереве блокирует коммит, даже не
  добавленный. Записи держать в `local/`.
- **Пакеты с удалёнными артефактами — без связки ключей**: `swift build/test --disable-keychain`, `xcodebuild
  -packageAuthorizationProvider netrc` (без `.netrc`): иначе macOS спрашивает владельца о доступе к паролю github.com,
  хотя ассет llama.cpp публичный. Симулятора нет: в xcframework llama.cpp b10809 только срезы iOS-устройства и macOS.
- **Роли «до кода приложения» решены** (`app-voice-loop`): `cpu-in-async` и `unbounded-list` держат правила SwiftLint
  `blocking_wait` и `unbounded_stream`; объявлений с `until` в `scripts/lint/not-applicable.json` больше нет.
- **Сторож скорости маршрутизатора на общем Mac** (`RouterTests.testDecisionIsFast`, отладочная сборка, p95 < 50 мс):
  вне CI при загрузке за минуту выше числа производительных ядер (`hw.perflevel0.physicalcpu`) — пропуск с причиной в
  логе, на CI судит всегда; R12 (p95 5 мс) меряет release-реплей `discipline-replay` (поставка `router-guard-load`).
- **`raw.githubusercontent.com` из песочницы агента недоступен** (таймаут);
  содержимое GitHub — через `gh api`.
- **Синхронизация с каноном — по содержимому, не по SHA:** HEAD Prepare двигают правки
  BACKLOG и обход флота без смены канона (`9323136` → `ce08a07` — один `BACKLOG.md`).
  Накатывать только из чистого и отправленного Prepare — процедура в `CLAUDE.md`.
