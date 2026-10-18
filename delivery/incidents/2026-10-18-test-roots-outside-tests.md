# Инцидент: ссылки на примеры и порядок «пример раньше теста» не видят тестов вне `tests/`

- **Дата:** 2026-10-18 · **Нашедший:** agent:claude-code (сессия smart-frend-ally) · **Хозяин:** smart-friend-ally
- **Канон:** `delivery@2.04` — `scripts/delivery_evidence.py`, проверки §3.1d (ссылка на id примера) и «пример раньше
  теста» (`expectation_predates_tests`); в `delivery@2.06` (Prepare `153ae46`) код тот же

## Симптом

Поставка `turn-contract`, фаза implement: `delivery_check --diff-base origin/main` предупреждает «acceptance-примеры
без ссылки в тестах/eval-smoke: K1, K2, … K14», хотя у каждой тест-функции
`Packages/AllyDiscipline/Tests/DisciplineTests/ContractTests.swift` стоит метка `// K1` … `// K14`.

## Что видел нашедший

Обе проверки собирают тесты из трёх зашитых корней: `for root_dir in ("tests", "backend/tests", "src/tests")` и
`test_dirs = [d for d in ("tests", "backend/tests", "src/tests") ...]`. SwiftPM кладёт тесты в `Tests/` каждого пакета
(`Packages/<Пакет>/Tests/<Цель>Tests/*.swift`), и туда не смотрит ни одна. Расширение `.swift` в
`TEST_TEXT_SUFFIXES` есть — дыра не в маске файлов, а в корнях.

Последствия разные по весу:

- **ложная тревога** у §3.1d — её гасит `eval-smoke.md`, где id перечислены прозой; в поставке `swift-contour` так и
  вышло, и дыра не показалась;
- **молчаливый проход** у порядка «пример раньше теста»: `test_dirs` пуст, `expectation_predates_tests` судить нечего,
  и проверка зелёная без предмета на любой раскладке вне трёх корней. Это тот же класс, что у `assert_digest.sh`
  (`2026-10-18-assert-digest-swift.md`): маска канона не знает раскладку проекта, а гейт выглядит работающим.

## Воспроизведение хозяина

Ветка `feat/turn-contract` до `active/eval-smoke.md`: `python3 scripts/delivery_check.py --diff-base origin/main` —
предупреждение перечисляет K1–K14; `grep -c '// K' Packages/AllyDiscipline/Tests/DisciplineTests/ContractTests.swift`
— 16 меток. С `eval-smoke.md`, где K1–K14 названы, предупреждение уходит, а порядок так и не судится.

## Что сделано в Ally (канон не правился)

Ничего в каноне. `eval-smoke.md` перечисляет K1–K14 с фактом прогона; порядок показан историей ветки: спека с
примерами и тесты с метками вошли одним коммитом `01ea668`, ожидания проб сверены с эталоном на Python, а не с
реализацией.

## Предложение (решает судья)

Корни тестов брать оттуда же, откуда сводка утверждений после `cqg@2.69` (`LINT_TEST_GLOB`), или искать каталоги
`tests`/`Tests` на любой глубине вне `SKIP_DIR_PARTS`. Тест канона: раскладка SwiftPM
(`Packages/X/Tests/XTests/FooTests.swift` с `// K1`) — ни предупреждения §3.1d, ни молчания порядка.

## Куда уехало

- поставка `turn-contract` Ally; запись `kind: upstream-candidate` у `scripts/delivery_evidence.py` в
  `scripts/lint/adapted.json`;
- сообщение судье (сессия Prepare) после мержа поставки.

## Итог

Закрыто в каноне `delivery@2.07` (Prepare `1a46b2b`, обход флота `76c42c3`): `delivery_base.test_files()` берёт
тест-файлы по признаку имени (`test_*`, `*_test.*`, `*Tests.*`, `*Spec.*` …) и каталогу `__tests__/` из отслеживаемых и
новых неигнорируемых файлов; оба места — §3.1d и порядок «пример раньше теста» — берут тесты оттуда. Накат в Ally —
поставка `sync-cqg-2.70`: запись `upstream-candidate` у `scripts/delivery_evidence.py` снята. Проверено исполнением во
временном клоне: спека архивной `turn-contract` в `active/` без `eval-smoke.md` — до наката предупреждение
перечисляет K1–K14, после — только K11, и это правда: у K11 (живость по слепым судьям) метки в тестах нет, его
прогон записан в `eval-smoke.md` той поставки.
