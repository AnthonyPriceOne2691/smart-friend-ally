# Инцидент: исключение контура в `file-length` и у доктора не знает 11 модулей `delivery_*.py`

- **Дата:** 2026-10-18 · **Нашедший:** agent:claude-code (сессия smart-frend-ally) · **Хозяин:** smart-friend-ally
- **Канон:** `cqg@2.63` — `scripts/lint/check_file_length.sh::exclude_contour` и его зеркало `CONTOUR_RE` у доктора

## Симптом

Ally подключил `file-length` с маской `*.swift` (первый код — пакет на Swift). Доктор: `DEAD 1` — «маска гейта не
покрывает 12 файл(ов) области: …make_fixtures.py, scripts/delivery_artifact.py, scripts/delivery_base.py …; этих
файлов не видит НИ ОДИН подключённый гейт, а роль объявлена закрытой».

## Что видел нашедший

`exclude_contour` перечисляет механику контура случаями: `scripts/delivery_(check|metrics)\.py$`. С `delivery@1.53`
`delivery_check.py` разрезан на модули, и 11 из них (`delivery_artifact`, `_base`, `_decisions`, `_diff`, `_evidence`,
`_history`, `_journals`, `_limits`, `_risk`, `_runtime`, `_status`) в исключение не попали. Это тот же рецидив, что
канон закрыл в `BREAKER_EXCLUDE` (`delivery_base.py`: «ПРЕФИКСЫ, а не четыре точных пути»), но в зеркале гейта
длины и доктора правка не повторена. На проекте с маской `*.py` молчит (модули короче 500 строк и проходят как
продуктовый код), на Swift-проекте доктор зовёт роль мёртвой.

## Воспроизведение хозяина

Ветка `feat/swift-contour`: `LINT_LENGTH_GLOBS="*.swift"` — доктор `DEAD 1` (12 файлов, из них 11 — модули канона);
`LINT_LENGTH_GLOBS="*.swift *.py"` — `DEAD 0`, гейт смотрит 20 файлов.

## Что сделано в Ally (канон не правился)

Маска `*.swift *.py` в хуке и в env джобы gates: генератор фикстур пакета мерить и так надо, а модули канона короче
500 строк. Цена обхода — модули канона судятся как продуктовый код: вырастет модуль выше 500 строк — гейт Ally
покраснеет на каноне.

## Предложение (решает судья)

Исключать механику контура префиксом, как в `BREAKER_EXCLUDE`: `scripts/delivery_[a-z_]+\.py$` в `exclude_contour` и в
`CONTOUR_RE`, и тест, где канонная раскладка с маской `*.swift` даёт доктору `DEAD 0`.

## Куда уехало

- поставка `swift-contour` Ally; запись `kind: upstream-candidate` у `check_file_length.sh` в `scripts/lint/adapted.json`;
- сообщение судье (сессия Prepare) после мержа поставки.

## Итог

Судья `prepare-ae` записал находку в BACKLOG канона (Prepare `0c642c2`, 2026-10-18) и сверил с кодом; правка канона —
следующей партией.

Канон впитал находку в `cqg@2.67` (Prepare `8f8e99a`: префикс `scripts/delivery_[a-z_]+\.py`, скрипты §3.4a и едущие
файлы в `exclude_contour` и `CONTOUR_RE`) и `delivery@2.05` (`7b0a160`, третье зеркало — `BREAKER_EXCLUDE`). Накат в
Ally — поставка `sync-cqg-2.70` (Prepare `76c42c3`): запись `upstream-candidate` снята. Проверено исполнением во
временном клоне: маска хука `*.swift` — доктор `DEAD` на 1 файле области (генератор фикстур) вместо 12 до наката;
маска `*.swift *.py` остаётся ради генератора фикстур — `DEAD 0`, `file-length` «просмотрено 15 из 15».
