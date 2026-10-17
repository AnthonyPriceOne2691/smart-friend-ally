# Plan: Swift-контур и ремонт текста

Уроки архива: **L8** — у каждого правила проба-нарушитель и хитрая чистая; **L16** — места канона, где живут
объявления ролей, собираются поиском (`grep -rn "swift\|Swift" scripts/lint/*.json .pre-commit-config.yaml
.github/workflows`); **L14** — после правки контура сразу строгий `delivery_check --require-ci --diff-base
origin/main`; **L25** — правило исполнителя принимается полным прогоном, а не на глаз.

## Approach

1. **Пакет** `Packages/AllyDiscipline` (SPM, только Foundation): `Repair.apply(_:disabled:)` — перенос эталона
   `local/spike/discipline/output_filter.py` (разметка, символы, латиница, цифры) и `strip_endearments`
   (`local/spike/persona-v2/judge_sheet.py`). Данные — `Resources/repair.json`, одна копия для Swift и стенда.
2. **Тесты:** пробы с обеих сторон на каждое правило; абляция каждого правила (роль мутаций); паритет с эталоном на
   фикстурах из реальных ответов модели (генератор `Fixtures/make_fixtures.py` рядом, эталон вне git — фикстуры в
   git); метаморфная проверка ё/е, пробелов и регистра.
3. **Гейты Swift** (канонные скрипты не правятся — адаптация в конфигах, CQG §5.5):
   - `.swiftlint.yml` + свой `scripts/lint/check_swiftlint_ratchet.sh` (глобальный счётчик только вниз, по образцу
     lash-try-on): сложность 8/10, длина файла, правила-аналоги `no_print`, `empty_catch`, `env_access`,
     `inline_prompt`; имена файлов-помоек — в том же скрипте;
   - file-length: хук из комментария `.pre-commit-config.yaml` с `LINT_LENGTH_GLOBS="*.swift"`;
   - jscpd: канонный гейт с `LINT_PY_SRC=Packages/AllyDiscipline/Sources LINT_JSCPD_PY_FORMAT=swift`;
   - `swift test --enable-code-coverage` и свой `scripts/lint/check_swift_coverage.sh` (llvm-cov, порог 70%) — новая
     джоба CI на Linux со Swift из образа раннера, с `timeout-minutes` и отрицательным контролем порогом 101%;
   - SwiftLint и jscpd ставятся в джобе gates с закреплёнными версиями; шаг «инструменты на месте» их проверяет.
4. **19 ключей `na-expiry`:** подключённые гейты — убрать из `not-applicable.json`; роли, которые держат правила
   SwiftLint, тесты абляции и SPM-таргеты, — переобъявить с причиной, верной при коде; роли, которых у пакета нет
   (async, веб-слой, DI), — переобъявить и поставить новое условие истечения на код приложения
   (`Packages/AllyApp/**/*.swift`). Все 19 — убрать из маски `*.swift`.
5. Доктор контура, мета-гейт покрытия гейтов, строгий `delivery_check` — зелёные; `adapted.json` — что изменено.

## Stack / boundaries

- Swift 6.4 локально (Xcode 27), в CI — Swift из образа `ubuntu-latest` (версия в логе); SwiftLint 0.65.0, jscpd 4.0.5.
- Без внешних зависимостей пакета; приложение и модель в репозиторий не входят.

## Risks

- NSRegularExpression на Linux и Darwin различаются в Юникоде — паритет гоняется в CI на Linux и локально на Mac.
- Пользовательские правила SwiftLint на Linux — проверить на CI, что правило краснеет на пробе (C6).
- Покрытие на Linux: путь к `default.profdata` и бинарю тестов — скрипт печатает, что посчитал.
