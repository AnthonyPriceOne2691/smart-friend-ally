# Tasks

## Slice 1 — пакет
- [x] T1: `Packages/AllyDiscipline` — `Repair` и `repair.json` (перенос эталона)
- [x] T2: тесты — пробы с обеих сторон, абляция, паритет с эталоном, метаморфная проверка

## Slice 2 — гейты Swift
- [x] T3: `.swiftlint.yml` и `scripts/lint/check_swiftlint_ratchet.sh` (сложность, длина, аналоги правил grep/ast, имена файлов), хук pre-commit, снимок
- [x] T4: file-length с маской `*.swift`; jscpd с форматом swift; хуки
- [x] T5: CI — джоба swift на Linux (`swift test`, покрытие `check_swift_coverage.sh` ≥ 70%), установка SwiftLint и jscpd в gates, «инструменты на месте»
- [x] T6: 19 ключей `na-expiry` — решения в `not-applicable.json` и `na-expiry.json`, `adapted.json`
- [x] T7: пробы гейтов (C6): `print(` и пустой `catch` в Sources, файл длиннее 500 строк — красные; доктор и мета-гейт зелёные

## Slice 3 — сдача
- [ ] T8: verify-report, eval-smoke (C1–C8), канон (`safety-below-model` — пакет вместо прототипа для ремонта), CLAUDE.md
