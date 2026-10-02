# Stack acceptance

**Date:** 2026-10-02
**Stack:** delivery@1.98 · cqg@2.43 · okf@1.19 · stack-map@1.52
**Где лежат каноны:** снимок в `docs/canon/` (вариант C, коммитится), провенанс — `docs/canon/VENDORED.json` (`agent-canon-stack` @ `4c3caa1`, `dirty: false`)

checked_at: 2026-10-02
stale_after: 2026-12-31

stack-selftest: ci (vendored)

## Что развёрнуто

| Слой | Состояние | Примечание |
|---|---|---|
| ① delivery/ | deployed | `delivery_check`, метрики, пара подписи необратимого, права агента в `.claude/settings.json` |
| ② гейты | deployed | хуков на коммите: 7 (гигиена конфигов ×5, secrets, child-data) + мета-гейт; на pre-push: 3. Адаптация под Swift: Python- и TS-гейты `n/a`, Swift-роли ждут первого кода |
| ③ knowledge/ | deployed | концептов: 5, с `implementation:` — 2 (`ops/child-data`, `references/repo-map`) |
| ④ CI + гейт мержа | ожидает первого прогона | merge_guard: да; branch protection: нет (бесплатный тариф GitHub) |

## Карта ролей гейтов

Заполнено по CQG «Применимость → Карта ролей». Технологический стек продукта —
Swift, кода продукта пока нет: роли, которым нечего смотреть, объявлены в
`scripts/lint/not-applicable.json` с причиной, и мета-гейт печатает её на каждом
прогоне.

| Роль | Канонический скрипт | В этом проекте | Статус |
|---|---|---|---|
| Конфиги парсятся | `check-yaml` / `check-json` / `check-toml` | хуки pre-commit-hooks | как есть |
| CI зелёный, не только локально | `check_ci_status.sh` | внутри `merge_guard.sh` | как есть |
| Доступ к настройкам только типизированно | `check_grep_gate.sh --rule config-access` | — | n/a: паттерн питоновский, Swift-кода нет |
| DI вместо importlib-магии | `check_grep_gate.sh --rule di-indirection` | — | n/a: паттерн питоновский, Swift-кода нет |
| Сервис не знает про web | `check_grep_gate.sh --rule service-no-web` | — | n/a: паттерн питоновский, Swift-кода нет |
| Нет модулей-помоек | `check_grep_gate.sh --rule no-grab-bag-module` | — | n/a: маска .py, Swift-кода нет |
| Ошибки не молчат | `check_ast_gate.py --rule silent-except` | — | n/a: python-`ast`, стек Swift |
| Длинные промпты — в файлы | `check_ast_gate.py --rule inline-prompt` | — | n/a: python-`ast`; Swift-аналог — свой гейт первой поставки с промптами |
| Event loop не голодает | `check_ast_gate.py --rule cpu-in-async` | — | n/a: python-`ast`, стек Swift |
| Список-эндпоинт имеет границу | `check_ast_gate.py --rule unbounded-list` | — | n/a: python-`ast`, эндпоинтов нет |
| Длина файлов под контролем | `check_file_length.sh` | — | n/a до первого Swift-кода: форма хука с `LINT_LENGTH_GLOBS="*.swift"` — комментарием в конфиге |
| Копипаст не растёт | `check_jscpd_gate.sh` | — | n/a: Swift-кода нет, jscpd не установлен |
| Warnings линтера не растут | `check_eslint_warnings.sh` | — | n/a: ts нет; роль займёт ратчет SwiftLint с первым кодом |
| Сложность функций под контролем | `check_complexity_gate.sh` | — | n/a: половины py/ts; роль займёт `cyclomatic_complexity` SwiftLint |
| Сообщения ошибок с контекстом | `check_grep_gate.sh --rule blind-error` | — | n/a: паттерн питоновский, Swift-кода нет |
| Зависимости без известных уязвимостей | `check_deps_audit.sh` | — | n/a: SPM не покрыт (F17) — названный остаток |
| Тесты действительно утверждают | `check_mutation_gate.sh` | — | n/a: mutmut/Stryker не для Swift |
| Направление зависимостей | `check_layers_gate.sh` | — | n/a: у Swift — таргеты SPM, решит первая поставка с кодом |
| Покрытие изменённого кода | `check_diff_coverage.sh` | — | n/a: тестов нет; для Swift — `swift test --enable-code-coverage` |
| Снимки только вниз | `check_baseline_ratchet.sh` | pre-push + CI | как есть (снимков пока нет: ратчет-гейты не подключены) |
| Все гейты подключены | `check_gate_coverage.sh` | хук `gate-coverage` + CI | как есть |
| **Секреты не в git** | `detect-secrets-guard` | хук + `.secrets.baseline` | как есть |
| **Данные ребёнка не в git** (своё) | — | `check_child_data.py`, хук `child-data`, канарейка | своё: индекс + неигнорируемое дерево; каталог `local/`, расширение, сигнатура содержимого |

## Полнота, не только зелёность

- [x] `check_gate_coverage.sh` — OK: 16 скриптов, подключено 4, осознанно нет 12 (причины печатаются)
- [x] `pre-commit run --all-files` — зелено (7 хуков, toml — нет файлов)
- [x] `stack_selftest.py` — OK: 116 блоков, 0 ошибок
- [x] Каждый подключённый гейт показал непустое число: secrets — 77 файлов, child-data — 77 файлов; гейт длины не подключён (n/a), поэтому «0 просмотрено» нигде не выдаётся за успех

## Замеры (строки measure §6)

| Что | Число |
|---|---|
| `contour_doctor.py` | AUTO 32 · WEAK 15 · ABSENT 4 · TOOL 3 · SKIP 0 · DEAD 0 |
| pre-commit на коммите одного файла | 1,17 с (бюджет ≤ 5 с) |
| pre-commit `--all-files` | 5,44 с, из них detect-secrets 5,27 с — снимок канонов 1,6 МБ; это прогон CI, бюджет — минуты |
| `delivery_metrics.py` | 8 метрик в блоке (до первого коммита поставки: `files_touched 0`) |
| pre-push | — замер после появления `origin` |
| Цена CI | — замер после первого прогона |

## Остатки (не закрыто — и почему)

| Инвариант | Почему не закрыт | Компенсация |
|---|---|---|
| force-push / обход админом | бесплатный тариф GitHub: защиты ветки у приватного репозитория нет | правило «мерж только merge_guard.sh», `deny` на force-push в `.claude/settings.json`, workflow `main-guard` |
| Форма Swift-кода (длина, линтер, сложность, слои, копипаст, покрытие, мутации) | кода продукта нет — гейтам нечего смотреть, а подключённый гейт с нулём доктор зовёт DEAD | первая поставка с кодом подключает роли (формы записаны в `not-applicable.json` и конфиге) и повторяет приёмку |
| Аудит Swift-зависимостей | pip-audit и npm audit не видят SPM (F17) | ревью `new_dependency:` в STATUS; гейт `new-dependency` читает `Package.swift` |
| Канон OKF отстаёт от upstream #323 | метки времени ISO 8601 со смещением (2026-08-21); правка канона — за владельцем Prepare | bundle пишет метки по upstream, гейты канона их принимают |

## Разбор: где эта процедура подвела

### 2026-10-02 — подключённый гейт без предмета

- **Симптом:** `file-length` с маской `*.swift` подключён, pre-commit зелёный, а доктор — `DEAD 1`: «подключён и смотрит в ПУСТОТУ».
- **Причина:** на проекте без кода у Swift-гейта нет предмета, а одноправильный гейт, просмотревший ноль файлов, неотличим от гейта с шаблонной маской. Подключать «на вырост» нельзя.
- **Усиление:** гейт объявлен `n/a` с причиной и формой будущего хука; вернуть его — задача первой поставки с кодом.
- **Проверено воспроизведением:** с подключённым хуком доктор `DEAD 1`, без него и с объявлением — `DEAD 0`.
