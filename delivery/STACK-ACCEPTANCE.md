# Stack acceptance

**Date:** 2026-10-02 · повторная приёмка 2026-10-18 — первый Swift-код (поставка `swift-contour`)
**Stack:** delivery@2.04 · cqg@2.63 · okf@1.21 · stack-map@1.53
**Где лежат каноны:** снимок в `docs/canon/` (вариант C, коммитится), провенанс — `docs/canon/VENDORED.json` (`agent-canon-stack` @ `c5585a5`, `dirty: false`; обновляется через `apply_update.py` — `4c3caa1` → `859152d` → `9323136` → `b5241ac` → `2eff5ed` → `c5585a5` (из чистого клона), замок `scripts/lint/payload.lock.json`)

checked_at: 2026-10-18
stale_after: 2026-12-31

stack-selftest: ci (vendored)

## Что развёрнуто

| Слой | Состояние | Примечание |
|---|---|---|
| ① delivery/ | deployed | `delivery_check`, метрики, пара подписи необратимого, права агента в `.claude/settings.json` |
| ② гейты | deployed | хуков на коммите: 11 (гигиена конфигов ×5, secrets, child-data, na-expiry, ратчет SwiftLint, file-length, jscpd) + мета-гейт; на pre-push: 3; джоба CI `swift` — тесты и покрытие пакета. Роли Python и TS на Swift держат свои конфиги и гейты (карта ниже) |
| ③ knowledge/ | deployed | концептов: 27, с `implementation:` — 3 (`ops/child-data`, `references/repo-map`, `engineering/safety-below-model` — пакет ремонта текста) |
| ④ CI + гейт мержа | tooling | `quality` зелёный (прогон 36991128518, все шаги исполнены); merge_guard: да; branch protection: нет (бесплатный тариф GitHub) |

## Карта ролей гейтов

Заполнено по CQG «Применимость → Карта ролей». Технологический стек продукта — Swift; первый код —
пакет `Packages/AllyDiscipline` (поставка `swift-contour`, 2026-10-18). Роли, которые канон держит
Python- и TS-скриптами, на Swift держат свои конфиги и гейты проекта; роли без предмета объявлены в
`scripts/lint/not-applicable.json` с причиной, верной при коде, и мета-гейт печатает её на каждом прогоне.

| Роль | Канонический скрипт | В этом проекте | Статус |
|---|---|---|---|
| Конфиги парсятся | `check-yaml` / `check-json` / `check-toml` | хуки pre-commit-hooks | как есть |
| CI зелёный, не только локально | `check_ci_status.sh` | внутри `merge_guard.sh` | как есть |
| Доступ к настройкам только типизированно | `check_grep_gate.sh --rule config-access` | правило SwiftLint `env_access` в ратчете `check_swiftlint_ratchet.sh` | аналог на Swift |
| DI вместо importlib-магии | `check_grep_gate.sh --rule di-indirection` | — | n/a: в Swift нет `importlib`; зависимости таргетов фиксирует SPM |
| Сервис не знает про web | `check_grep_gate.sh --rule service-no-web` | — | n/a: веб-слоя нет, продукт офлайн |
| Нет модулей-помоек | `check_grep_gate.sh --rule no-grab-bag-module` | имена `utils/misc/common/helpers.swift` в ратчете SwiftLint | аналог на Swift |
| Ошибки не молчат | `check_ast_gate.py --rule silent-except` | правило SwiftLint `empty_catch` | аналог на Swift |
| Длинные промпты — в файлы | `check_ast_gate.py --rule inline-prompt` | правило SwiftLint `inline_prompt`: русский литерал длиннее 40 знаков в Sources | аналог на Swift |
| Event loop не голодает | `check_ast_gate.py --rule cpu-in-async` | — | n/a до кода приложения: в пакете нет `async` (истечение — `App/*.swift`) |
| Список-эндпоинт имеет границу | `check_ast_gate.py --rule unbounded-list` | — | n/a до кода приложения: функции над одной репликой (истечение — `App/*.swift`) |
| Длина файлов под контролем | `check_file_length.sh` | хук `file-length`, `LINT_LENGTH_GLOBS="*.swift"` | как есть, маска Swift |
| Копипаст не растёт | `check_jscpd_gate.sh` | хук `jscpd`, формат `swift` по `Packages/AllyDiscipline/Sources` | как есть, формат Swift |
| Warnings линтера не растут | `check_eslint_warnings.sh` | ратчет SwiftLint `check_swiftlint_ratchet.sh`, снимок `swiftlint_baseline.txt` = 0 | аналог на Swift |
| Сложность функций под контролем | `check_complexity_gate.sh` | `cyclomatic_complexity` 8/10 в ратчете SwiftLint | аналог на Swift |
| Сообщения ошибок с контекстом | `check_grep_gate.sh --rule blind-error` | правило SwiftLint `empty_catch` | аналог на Swift |
| Логи структурные | `check_grep_gate.sh --rule unstructured-log` | правило SwiftLint `no_print`: `print`, `debugPrint`, `NSLog` | аналог на Swift |
| Зависимости без известных уязвимостей | `check_deps_audit.sh` | — | n/a: SPM не покрыт (F17) — названный остаток |
| Тесты действительно утверждают | `check_mutation_gate.sh` | тесты абляции пакета: выключенное правило обязано изменить ответ хотя бы одной своей пробы | частично: мутаций кода вне правил нет — названный остаток |
| Направление зависимостей | `check_layers_gate.sh` | — | n/a: направление задают таргеты SPM, обратная зависимость не соберётся |
| Покрытие изменённого кода | `check_diff_coverage.sh` | `check_swift_coverage.sh` в джобе `swift` CI: строки Sources ≥ 70%, отрицательный контроль порогом 101% | аналог на Swift (покрытие пакета, не диффа) |
| Ревью утверждений видит Swift (своё) | `assert_digest.sh` | `assert_digest_swift.py --check` в джобе `delivery` CI | своё: канонная сводка Swift-тестов не видит (`delivery/incidents/2026-10-18-assert-digest-swift.md`) |
| Снимки только вниз | `check_baseline_ratchet.sh` | pre-push + CI | как есть |
| Все гейты подключены | `check_gate_coverage.sh` | хук `gate-coverage` + CI | как есть |
| **Секреты не в git** | `detect-secrets-guard` | хук + `.secrets.baseline` | как есть |
| **Данные ребёнка не в git** (своё) | — | `check_child_data.py`, хук `child-data`, канарейка | своё: индекс + неигнорируемое дерево; каталог `local/`, расширение, сигнатура содержимого |
| **Объявления неприменимости «до кода» истекают с кодом** (своё) | — | `check_na_expiry.py`, хук `na-expiry`, условия `scripts/lint/na-expiry.json`, канарейка | своё: 17 из 19 объявлений решены на первом Swift-коде, два ждут кода приложения (`App/*.swift`) |

## Полнота, не только зелёность

- [x] `check_gate_coverage.sh` — OK: 17 канонных скриптов, подключено 7, осознанно нет 10 (причины печатаются); свои — ратчет SwiftLint, покрытие Swift, сводка утверждений Swift, child-data, na-expiry — подключены
- [x] `pre-commit run --all-files` — зелено (11 хуков и мета-гейт, toml — нет файлов; jscpd локально не установлен и пропускается с предупреждением, в CI ставится и проверяется шагом «инструменты на месте»)
- [x] `stack_selftest.py` — OK: 117 блоков, 0 ошибок (cqg@2.63, 2026-10-18)
- [x] Каждый подключённый гейт показал непустое число: child-data и na-expiry — 261 файл, file-length — 20 (`*.swift *.py`), ратчет SwiftLint — 8, покрытие — 5 файлов Sources (290 из 300 строк)
- [x] Пробы нарушителей (C6): `print(` и пустой `catch` в Sources — ратчет SwiftLint exit 1; файл 521 строка — `file-length` exit 1

## Замеры (строки measure §6)

| Что | Число |
|---|---|
| `contour_doctor.py` | AUTO 42 · WEAK 14 · ABSENT 4 · TOOL 3 · SKIP 2 · DEAD 0 (2026-10-18, с env Swift; SKIP названы: канарейка длины не закоммичена, канонный jscpd не печатает «просмотрено N») |
| pre-commit на коммите одного файла | ≈1 с со SwiftLint на Swift-файле (бюджет ≤ 5 с) |
| pre-commit `--all-files` | 5,44 с, из них detect-secrets 5,27 с — снимок канонов 1,6 МБ; это прогон CI, бюджет — минуты |
| `delivery_metrics.py` | 8 метрик в блоке (до первого коммита поставки: `files_touched 0`) |
| pre-push | 7,53 с вместе с отправкой по сети (бюджет ≤ 10 с): delivery-gate, baseline-ratchet, new-dependency плюс хуки коммит-стадии |
| Цена CI | прогон = gates 33 с + delivery 11 с; GitHub округляет каждую джобу до минуты → 2 мин Linux (множитель 1x). Оценка: ~13 прогонов в неделю (пуши в PR + мержи) ≈ 110 мин/мес + canon-freshness 4 мин ≈ 115 из 2000 бесплатных минут приватного репо (~6%). `timeout-minutes` стоит на каждой джобе |

## Остатки (не закрыто — и почему)

| Инвариант | Почему не закрыт | Компенсация |
|---|---|---|
| force-push / обход админом | бесплатный тариф GitHub: защиты ветки у приватного репозитория нет | правило «мерж только merge_guard.sh», `deny` на force-push в `.claude/settings.json`, workflow `main-guard` |
| Мутации кода вне правил ремонта | muter требует macOS-раннер (×10) | тесты абляции держат роль для правил; мутации кода — вручную при поставке (17 из 17 пойманы) |
| Сборка для iOS, async и списки без предела | в репозитории только пакет; кода приложения нет | `na-expiry` с условием `App/*.swift` краснеет на первом коде приложения |
| Аудит Swift-зависимостей | pip-audit и npm audit не видят SPM (F17) | ревью `new_dependency:` в STATUS; гейт `new-dependency` читает `Package.swift` |
| Канон OKF отстаёт от upstream #323 | метки времени ISO 8601 со смещением (2026-08-21); правка канона — за владельцем Prepare | bundle пишет метки по upstream, гейты канона их принимают |

## Разбор: где эта процедура подвела

### 2026-10-02 — шаблон CI роняет джобу гейтов на проекте без requirements.txt

- **Симптом:** первый прогон `quality` (36990914981) — `gates` красный за 7 с, упал `setup-python`: «No file matched to [**/requirements.txt or **/pyproject.toml]».
- **Причина:** охрана `cache:` в шаблоне CQG §8.3 включает pip-кэш по `**/requirements*.txt` (со звёздочкой), а `setup-python` по умолчанию ищет точное `**/requirements.txt`. Проект, где есть только `requirements-dev.txt`, проходит охрану и падает в действии — тот же класс «шаблон несёт питоновское допущение», что канон уже чинил для Astro.
- **Усиление:** `cache-dependency-path: requirements-dev.txt` в нашем workflow; адаптация объявлена в `adapted.json` и помечена кандидатом в апстрим канона.
- **Проверено воспроизведением:** без строки — прогон 36990914981 красный на `setup-python`; со строкой — 36991128518 зелёный, все шаги исполнены.

### 2026-10-02 — объявление зависимости по пакетам вместо манифеста

- **Симптом:** pre-push на первом push ветки: «новая зависимость не объявлена: requirements-dev.txt», хотя три пакета объявлены построчно.
- **Причина:** гейт `new-dependency` считает появление манифеста ОДНИМ решением и ждёт строку на путь, а шаблон STATUS показывает пример на пакет — форма записи зависит от того, новый ли манифест.
- **Усиление:** одна строка на манифест, пакеты и отвергнутые альтернативы — в `reason=`.
- **Проверено воспроизведением:** с построчными объявлениями push отклонён, с объявлением манифеста — прошёл.

### 2026-10-02 — подключённый гейт без предмета

- **Симптом:** `file-length` с маской `*.swift` подключён, pre-commit зелёный, а доктор — `DEAD 1`: «подключён и смотрит в ПУСТОТУ».
- **Причина:** на проекте без кода у Swift-гейта нет предмета, а одноправильный гейт, просмотревший ноль файлов, неотличим от гейта с шаблонной маской. Подключать «на вырост» нельзя.
- **Усиление:** гейт объявлен `n/a` с причиной и формой будущего хука; вернуть его — задача первой поставки с кодом.
- **Проверено воспроизведением:** с подключённым хуком доктор `DEAD 1`, без него и с объявлением — `DEAD 0`.

### 2026-10-18 — сводка утверждений не видит тестов на Swift

- **Симптом:** канонная `assert_digest.sh` печатает «утверждений нет» на диффе с Swift-тестами — `asserts_reviewed_by: n/a` проходил бы на пустоте.
- **Причина:** маска диффа `*test*.py|ts|tsx`, `*_test.go` — файлы `*Tests.swift` до разбора не доходят; шаблон `XCTAssert…` и блоки `func test` не берёт (`#expect(` берёт — поправка судьи).
- **Усиление:** свой `scripts/lint/assert_digest_swift.py` с режимом `--check` в джобе delivery; находка наверх — `delivery/incidents/2026-10-18-assert-digest-swift.md`.
- **Проверено воспроизведением:** временный репозиторий — Swift-утверждения 0 у канонной, 2 у своей; `n/a` над ними — exit 1, подпись — exit 0.

### 2026-10-18 — исключение контура не знает модулей delivery_*.py

- **Симптом:** `file-length` с маской `*.swift` — доктор `DEAD 1`: 11 модулей канона и генератор фикстур не видит ни один гейт.
- **Причина:** `exclude_contour` и `CONTOUR_RE` перечисляют `delivery_(check|metrics).py` случаями; модули после разреза `delivery@1.53` не исключены.
- **Усиление:** маска `*.swift *.py`; находка наверх — `delivery/incidents/2026-10-18-exclude-contour-delivery-modules.md`.
- **Проверено воспроизведением:** с маской `*.swift` — `DEAD 1`, с `*.swift *.py` — `DEAD 0`.
