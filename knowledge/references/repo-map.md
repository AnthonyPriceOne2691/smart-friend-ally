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
# ложным. Появится Xcode-проект или Package.swift — вписать их сюда.
implementation:
  - requirements-dev.txt
  - scripts/merge_guard.sh
---

# Входные точки

- **Кода приложения пока нет** — Xcode-проект появится с поставкой приложения. Есть пакет
  `Packages/AllyDiscipline` (ремонт текста и контракт хода до голоса):
  `swift test --package-path Packages/AllyDiscipline`.
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
| `scripts/`, `scripts/lint/` | механика контура; канонные файлы правятся только перевендориванием |
| `docs/canon/` | снимок канонов с самопроверкой (вариант C) |
| `local/` | данные ребёнка и прочее локальное — игнорируется, гейт не пускает в git |

# Грабли

- **Пробел в пути** (`Smart frend Ally`): пути в скриптах и `entry:` хуков — только в кавычках.
- **Xcode не выбран**: активный developer dir — Command Line Tools. Команды Xcode
  и SwiftLint — с `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- **Гейт детских данных ловит по сигнатуре**: переименованная запись тоже
  красная, а неигнорируемый аудиофайл в дереве блокирует коммит, даже не
  добавленный. Записи держать в `local/`.
- **Объявления n/a «до кода приложения» истекают сами**: правила `cpu-in-async` и
  `unbounded-list` объявлены в `scripts/lint/not-applicable.json` с `until: "App/*.swift"`
  (`cqg@2.66`) — первый файл приложения в индексе или дереве краснит мета-гейт на коммите
  и в CI, пока роли не решены. Маска называет путь продукта: `*` в маске git проходит `/`,
  поэтому `Packages/*.swift` истёк бы сразу на коде пакета.
- **`raw.githubusercontent.com` из песочницы агента недоступен** (таймаут);
  содержимое GitHub — через `gh api`.
- **Синхронизация с каноном — по содержимому, не по SHA:** HEAD Prepare двигают правки
  BACKLOG и обход флота без смены канона (`9323136` → `ce08a07` — один `BACKLOG.md`).
  Накатывать только из чистого и отправленного Prepare — процедура в `CLAUDE.md`.
