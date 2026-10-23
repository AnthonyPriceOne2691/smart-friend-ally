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
  runbook [Voice loop](/engineering/voice-loop.md). Модель — пакет `Packages/AllyLlama` (llama.cpp
  b10809; паритет со стендом: `swift test --disable-keychain --package-path Packages/AllyLlama`, веса в `~/models`).
- **Дисциплина ответа** — пакет `Packages/AllyDiscipline` (ремонт текста, контракт хода, маршрутизатор до модели):
  `swift test --package-path Packages/AllyDiscipline`.
- **Ядро голосового цикла** — `Packages/AllyCore` (ход через контракт, конец реплики, журнал хода без слов, реестр
  модели, сессия с мягким лимитом и крючком маршрутизатора, драйвер сессии со слухом `Conversation`, маршрутизатор на
  живом ходе `RouterRouting`, след хода и его файл `TraceFile`; тексты сессии — `Resources/session.json`):
  `swift test --package-path Packages/AllyCore` (тулчейн Xcode: `DEVELOPER_DIR`).
- **Детский экран (оболочка)** — `Packages/AllyShell`: `ShellCore` (позы фаз, кадры, раскладка, палитра — Linux) и
  `ShellUI` (Элли, пузырь и небо в SwiftUI под `#if canImport(SwiftUI)`). Снимки семи фаз и лист `sheet.png` пишет
  `swift test --disable-keychain --package-path Packages/AllyShell` на Mac в `local/shell-snapshots/`; на Linux снимки
  пропускаются видимо. Снимков экрана телефона нет никогда (L46).
- **Текст для синтеза** — `Packages/AllySpeechText` (ударения, закреплённый словарь, правила чтения; данные —
  `Resources/speech-text.json`): `swift test --disable-keychain --package-path Packages/AllySpeechText`.
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
| `scripts/`, `scripts/lint/` | механика контура; канонные файлы правятся только перевендориванием; продуктовые — `scripts/reinstall_app.sh` (E4), `scripts/child_mode.sh` (R) |
| `docs/canon/` | снимок канонов с самопроверкой (вариант C) |
| `App/` | приложение iOS: `project.yml`, `Sources/` (консоль, цикл, звук, распознавание), `Resources/` (персона, реестр) |
| `Packages/` | Swift-пакеты: `AllyDiscipline` (дисциплина ответа), `AllyCore` (ядро хода), `AllyLlama` (модель), `AllyShell` (детский экран), `AllySpeechText` (текст для синтеза), `AllyOnnx` (один ONNX Runtime приложения), `AllyVoice` (движок голоса), `AllySQLite` (общий SQLite), `AllyMemory` (память о ребёнке) |
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
- **`raw.githubusercontent.com` из песочницы агента недоступен** (таймаут);
  содержимое GitHub — через `gh api`.
- **Синхронизация с каноном — по содержимому, не по SHA:** HEAD Prepare двигают правки
  BACKLOG и обход флота без смены канона (`9323136` → `ce08a07` — один `BACKLOG.md`).
  Накатывать только из чистого и отправленного Prepare — процедура в `CLAUDE.md`.
