# Stack acceptance

**Date:** 2026-10-02 · повторная приёмка 2026-10-18 — первый Swift-код (поставка `swift-contour`) · сверка при накате `cqg@2.70` 2026-10-18 (поставка `sync-cqg-2.70`): свои обходы впитанных каноном находок сняты, карта ролей — статусы канона
**Stack:** delivery@2.07 · cqg@2.70 · okf@1.21 · stack-map@1.54
**Где лежат каноны:** снимок в `docs/canon/` (вариант C, коммитится), провенанс — `docs/canon/VENDORED.json` (`agent-canon-stack` @ `76c42c3`, `dirty: false`, значения с префиксами `git:`/`sha256:`; обновляется через `apply_update.py` — `4c3caa1` → `859152d` → `9323136` → `b5241ac` → `2eff5ed` → `c5585a5` → `76c42c3` (оба последних — из чистого клона), замок `scripts/lint/payload.lock.json`)

checked_at: 2026-10-18
stale_after: 2026-12-31

stack-selftest: ci (vendored)

## Что развёрнуто

| Слой | Состояние | Примечание |
|---|---|---|
| ① delivery/ | deployed | `delivery_check`, метрики, пара подписи необратимого, права агента в `.claude/settings.json` |
| ② гейты | deployed | хуков на коммите: 10 (гигиена конфигов ×5, secrets, child-data, ратчет SwiftLint, file-length, jscpd) + мета-гейт (он же судит истечение n/a «до кода», `until`); на pre-push: 3; джоба CI `swift` — тесты и покрытие пакета. Роли Python и TS на Swift держат свои конфиги и гейты (карта ниже) |
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
| Доступ к настройкам только типизированно | `check_grep_gate.sh --rule config-access` | правило SwiftLint `env_access` в ратчете `check_swiftlint_ratchet.sh` | адаптирован (`check_swiftlint_ratchet.sh`) |
| DI вместо importlib-магии | `check_grep_gate.sh --rule di-indirection` | — | n/a: в Swift нет `importlib`; зависимости таргетов фиксирует SPM |
| Сервис не знает про web | `check_grep_gate.sh --rule service-no-web` | — | n/a: веб-слоя нет, продукт офлайн |
| Нет модулей-помоек | `check_grep_gate.sh --rule no-grab-bag-module` | имена `utils/misc/common/helpers.swift` в ратчете `check_swiftlint_ratchet.sh` | адаптирован (`check_swiftlint_ratchet.sh`) |
| Ошибки не молчат | `check_ast_gate.py --rule silent-except` | правило SwiftLint `empty_catch` в ратчете `check_swiftlint_ratchet.sh` | адаптирован (`check_swiftlint_ratchet.sh`) |
| Длинные промпты — в файлы | `check_ast_gate.py --rule inline-prompt` | правило SwiftLint `inline_prompt` в ратчете `check_swiftlint_ratchet.sh`: русский литерал длиннее 40 знаков в Sources | адаптирован (`check_swiftlint_ratchet.sh`) |
| Event loop не голодает | `check_ast_gate.py --rule cpu-in-async` | — | n/a до кода приложения: в пакете нет `async`; `until: "App/*.swift"` — мета-гейт краснеет с первым файлом приложения (`cqg@2.66`) |
| Список-эндпоинт имеет границу | `check_ast_gate.py --rule unbounded-list` | — | n/a до кода приложения: функции над одной репликой; `until: "App/*.swift"` (`cqg@2.66`) |
| Длина файлов под контролем | `check_file_length.sh` | хук `file-length`, `LINT_LENGTH_GLOBS="*.swift *.py"` (`*.py` — генератор фикстур пакета; механику контура гейт исключает сам, `cqg@2.67`) | как есть, маска Swift |
| Копипаст не растёт | `check_jscpd_gate.sh` | хук `jscpd-dry-gate`, формат `swift` по `Packages/AllyDiscipline/Sources` | как есть, формат Swift |
| Warnings линтера не растут | `check_eslint_warnings.sh` | ратчет SwiftLint `check_swiftlint_ratchet.sh`, снимок `swiftlint_baseline.txt` = 0 | адаптирован (`check_swiftlint_ratchet.sh`) |
| Сложность функций под контролем | `check_complexity_gate.sh` | правило SwiftLint `cyclomatic_complexity` 8/10 в ратчете `check_swiftlint_ratchet.sh` | адаптирован (`check_swiftlint_ratchet.sh`) |
| Сообщения ошибок с контекстом | `check_grep_gate.sh --rule blind-error` | правило SwiftLint `empty_catch` в ратчете `check_swiftlint_ratchet.sh` | адаптирован (`check_swiftlint_ratchet.sh`) |
| Логи структурные | `check_grep_gate.sh --rule unstructured-log` | правило SwiftLint `no_print` в ратчете `check_swiftlint_ratchet.sh`: `print`, `debugPrint`, `NSLog` | адаптирован (`check_swiftlint_ratchet.sh`) |
| Зависимости без известных уязвимостей | `check_deps_audit.sh` | — | n/a: SPM не покрыт (F17) — названный остаток |
| Тесты действительно утверждают | `check_mutation_gate.sh` | тесты абляции пакета: выключенное правило обязано изменить ответ хотя бы одной своей пробы | n/a: mutmut и Stryker — для python и ts, muter требует macOS-раннер (×10); роль для правил держат тесты абляции, мутаций кода вне правил нет — названный остаток. Часть комплекта `mutation_shard.sh` не развёрнута и объявлена n/a: накат `76c42c3` её не привёз (`delivery/incidents/2026-10-18-plan-misses-sourced-part.md`) |
| Направление зависимостей | `check_layers_gate.sh` | — | n/a: направление задают таргеты SPM, обратная зависимость не соберётся |
| Покрытие изменённого кода | `check_diff_coverage.sh` | `check_swift_coverage.sh` в джобе `swift` CI: строки Sources ≥ 70%, отрицательный контроль порогом 101% | адаптирован (`check_swift_coverage.sh`): покрытие пакета, не диффа |
| Ревью утверждений видит Swift | `assert_digest.sh` | канонная сводка (`cqg@2.68`): маски по умолчанию берут `*Tests.swift` и `*Test.swift`, тест-файл вне масок — `asserts_without_example: unknown`, и `delivery_check` не принимает над ним `n/a` | как есть (своя сводка Swift снята при накате `cqg@2.70`) |
| Снимки только вниз | `check_baseline_ratchet.sh` | pre-push + CI | как есть |
| Все гейты подключены | `check_gate_coverage.sh` | хук `gate-coverage` + CI | как есть |
| **Секреты не в git** | `detect-secrets-guard` | хук + `.secrets.baseline` | как есть |
| **Данные ребёнка не в git** (своё) | — | `check_child_data.py`, хук `child-data`, канарейка | своё: индекс + неигнорируемое дерево; каталог `local/`, расширение, сигнатура содержимого |
| **Объявления неприменимости «до кода» истекают с кодом** | `check_gate_coverage.sh` | `until` у объявлений в `scripts/lint/not-applicable.json` (`cqg@2.66`, образец — бывший свой гейт Ally): два ключа ждут кода приложения — `App/*.swift` | как есть (свой гейт na-expiry снят при накате `cqg@2.70`) |

## Полнота, не только зелёность

- [x] `check_gate_coverage.sh` — OK: 18 скриптов, подключено 8, осознанно нет 10 (причины печатаются); свои — ратчет SwiftLint, покрытие Swift (джоба `swift`), child-data — подключены; карта ролей: заявлений со статусом канона 25 строк из 45 (было 13 — «аналог на Swift» разборщик `cqg@2.65` не читает), противоречий нет
- [x] `pre-commit run --all-files` — зелено (10 хуков и мета-гейт, toml — нет файлов; jscpd локально не установлен и пропускается с предупреждением, в CI ставится и проверяется шагом «инструменты на месте»)
- [x] `stack_selftest.py` — OK: 119 блоков, 0 ошибок (cqg@2.70, 2026-10-18)
- [x] Каждый подключённый гейт показал непустое число: child-data — 280 файлов, file-length — 15 (`*.swift *.py`; модули `delivery_*.py` гейт исключает сам с `cqg@2.67`), ратчет SwiftLint — 14, secrets — 28 на пачку, покрытие — 9 файлов Sources (659 из 683 строк, 96%)
- [x] Пробы нарушителей (C6): `print(` и пустой `catch` в Sources — ратчет SwiftLint exit 1; файл 521 строка — `file-length` exit 1; `App/Probe.swift` — мета-гейт exit 1 «объявления n/a истекли» (оба ключа), без него — 0; `XCTAssertEqual(2 + 2, 5)` на временной ветке — канонная сводка `asserts_without_example: 1` (накат `cqg@2.70`)

## Замеры (строки measure §6)

| Что | Число |
|---|---|
| `contour_doctor.py` | AUTO 39 · WEAK 13 · ABSENT 4 · TOOL 3 · SKIP 2 · DEAD 0 (2026-10-18, после наката `cqg@2.70`, без активной поставки, с env Swift; до наката на том же стенде — AUTO 41 · WEAK 16: −2 AUTO — снят свой гейт na-expiry (канарейка и область), −3 WEAK — сняты записи впитанных находок; SKIP названы: канарейка длины не закоммичена, канонный jscpd не печатает «просмотрено N») |
| pre-commit на коммите одного файла | ≈1 с со SwiftLint на Swift-файле (бюджет ≤ 5 с) |
| pre-commit `--all-files` | 5,44 с, из них detect-secrets 5,27 с — снимок канонов 1,6 МБ; это прогон CI, бюджет — минуты (2026-10-18 при накате не перемерялось: load average машины ≈100 от параллельных сессий, тот же прогон на состоянии `main` — 83 с) |
| `delivery_metrics.py` | 8 метрик в блоке (до первого коммита поставки: `files_touched 0`) |
| pre-push | 7,53 с вместе с отправкой по сети (бюджет ≤ 10 с): delivery-gate, baseline-ratchet, new-dependency плюс хуки коммит-стадии |
| Цена CI | прогон = gates 33 с + delivery 11 с; GitHub округляет каждую джобу до минуты → 2 мин Linux (множитель 1x). Оценка: ~13 прогонов в неделю (пуши в PR + мержи) ≈ 110 мин/мес + canon-freshness 4 мин ≈ 115 из 2000 бесплатных минут приватного репо (~6%). `timeout-minutes` стоит на каждой джобе |

## Остатки (не закрыто — и почему)

| Инвариант | Почему не закрыт | Компенсация |
|---|---|---|
| force-push / обход админом | бесплатный тариф GitHub: защиты ветки у приватного репозитория нет | правило «мерж только merge_guard.sh», `deny` на force-push в `.claude/settings.json`, workflow `main-guard` |
| Мутации кода вне правил ремонта | muter требует macOS-раннер (×10) | тесты абляции держат роль для правил; мутации кода — вручную при поставке (17 из 17 пойманы) |
| Сборка для iOS, async и списки без предела | в репозитории только пакет; кода приложения нет | мета-гейт: `until: "App/*.swift"` у двух объявлений n/a краснеет на первом коде приложения (`cqg@2.66`) |
| Пересчёт сводки утверждений в CI | `delivery_check` судит строку `asserts_without_example`, вставленную в verify-report; свой `--check`, пересчитывавший сводку Swift в CI, снят при накате `cqg@2.70` | ревью verify-report на мерже; вернуть ли шаг пересчёта канонной сводкой — решение человека |
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

Итог 2026-10-18: канон впитал обе находки выше (`cqg@2.68`, `cqg@2.67`); свой `assert_digest_swift.py` снят при накате
`cqg@2.70`, маска `*.py` осталась ради генератора фикстур (с `*.swift` доктор теперь видит один непокрытый файл, а не 12).

### 2026-10-18 — накат не привёз часть комплекта мутационного гейта

- **Симптом:** сразу после `apply_update.py` (Prepare `76c42c3`) доктор — `DEAD`: «развёрнуто 53 из 54, НЕ ОБЪЯВЛЕНО 1: mutation_shard.sh», хотя план сказал «новый файл 0, нужен приезжающим 0».
- **Причина:** приехавший `check_mutation_gate.sh` подключает новую часть `mutation_shard.sh` через `.`; план строит старый payload манифестом нового извлекателя (часть есть в обоих — «не развёрнуто»), а обход «нужен приезжающим» читает только импорты python.
- **Усиление:** часть объявлена n/a в `not-applicable.json` (мутационный гейт у Ally n/a целиком, вход выходит на объявлении до подключения частей); находка наверх — `delivery/incidents/2026-10-18-plan-misses-sourced-part.md`, запись `upstream-candidate`.
- **Проверено воспроизведением:** без объявления — доктор `DEAD 1`, с ним — `AUTO` «53 из 54, 1 объявлены неприменимыми». Во временном клоне с живой TS-половиной (Stryker-заглушка): без части — `ts_shard: command not found` и exit 0 без вердикта, с частью — `not_judged`, exit 1.
