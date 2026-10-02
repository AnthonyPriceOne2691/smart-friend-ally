# Spec: развернуть канон-контур в Smart Friend Ally

> Решение пользователя 2026-10-02: «контур обязательно нужно развернуть в этом
> проекте». Цель согласована устно; примеры приёмки ниже пользователь ещё не
> видел, поэтому `human_ok_spec: deferred` до его подписи.

## Problem

Ally начинается с нуля: кода нет, есть исследование `KNOWLEDGE.md`. Опыт тренера
(раздел 8 KNOWLEDGE.md, П29–П37) показывает, что дефекты, невидимые сборке и
тестам, ловила механика контура: мёртвые настройки, слепые гейты, правила промпта
без исполнителя. Развернуть её потом, поверх кода, дороже: каждый гейт придётся
вводить ратчетом от снимка нарушений, а не от нуля.

## Users / stakeholders

- Агент, который будет писать Ally: работает по фазам и не может закрыть работу без оракулов.
- Пользователь (родитель): подписывает спеки, решает за канон, видит честное состояние контура.

## In scope

- ① Delivery: дерево `delivery/`, конституция Ally, права агента, hook в `CLAUDE.md`,
  `scripts/delivery_*.py` и пара подписи необратимого.
- ② CQG: все скрипты Приложения A, конфиги Приложения B, адаптация под Swift по
  блоку «Применимость» (маски `*.swift`, роль линтера — SwiftLint), объявленные
  `n/a` с причинами, гейт «данные ребёнка не попадают в git», baseline'ы,
  pre-commit и pre-push.
- ③ OKF: bundle `knowledge/` с концептами Ally, `okf_validate.py`, `okf_sync_gate.py`.
- ④ CI и гейт мержа: приватный репозиторий `smart-friend-ally` на GitHub
  (согласие пользователя 2026-10-02), `quality.yml`, `main-guard.yml`,
  `merge_guard.sh`, `check_ci_status.sh`.
- Снимок канонов (вариант C): `docs/canon/` + самопроверка + `VENDORED.json`.
- Приёмка по `AGENT_STACK.md` §6 с честными `weak`.

## Out of scope

- Код продукта и Xcode-проект — первая продуктовая поставка (спайк, KNOWLEDGE.md §12).
- Оживление Swift-гейтов на настоящем коде: пока кода нет, они смотрят ноль файлов,
  и это записывается как `weak`, а не прячется.
- Серверная защита ветки — бесплатный тариф GitHub её не даёт.
- Агентские hooks §10 (A.11) — отдельной поставкой, если понадобятся.

## Acceptance (observable)

- [ ] `delivery_check` на ветке bootstrap без ошибок.
- [ ] Каждый гейт таблицы CQG §3 подключён или объявлен `n/a` с причиной.
- [ ] Коммит аудиофайла или базы отклоняется гейтом даже через `git add -f`.
- [ ] CI зелёный по ссылке на прогон, мерж — только через `merge_guard.sh`.
- [ ] `STACK-ACCEPTANCE.md` называет каждое `weak` и его причину.

## Acceptance examples

| # | Вход | Ожидаемый выход |
|---|---|---|
| A1 | `python3 scripts/delivery_check.py` на ветке bootstrap | `0 error(s)`; каждое предупреждение названо в STATUS или STACK-ACCEPTANCE |
| A2 | `bash scripts/lint/check_gate_coverage.sh` | exit 0: каждая роль §3 подключена или стоит в `scripts/lint/not-applicable.json` с причиной, причина печатается |
| A3 | `git add -f local/rec.wav && git commit` (граничный случай: обход `.gitignore`) | коммит отклонён гейтом детских данных, сообщение называет файл и правило |
| A4 | `python3 scripts/lint/contour_doctor.py` | `DEAD 0`; гейты, которым нечего смотреть, — `WEAK` или `SKIP` с названной причиной |
| A5 | `python3 docs/canon/stack_selftest.py docs/canon` | OK: блоки payload парсятся, версии в шапках совпадают с `VENDORED.json` |
| A6 | `python3 scripts/okf_validate.py` и `python3 scripts/okf_sync_gate.py` | оба exit 0; хотя бы у одного концепта заполнен `implementation:` |
| A7 | PR ветки bootstrap в `smart-friend-ally` (ошибочный путь: `git merge` руками) | `quality` зелёный на последнем коммите; мерж идёт только через `merge_guard.sh`, ручной `git merge` в main не используется |

## Non-functional

- Ни один файл контура не правится «по смыслу»: канонные скрипты байт-в-байт,
  адаптация — через env, `not-applicable.json`, `adapted.json` и свои гейты.
- Гейты на коммите укладываются в бюджет времени хуков (CQG §8.6).

## Open questions

- Нет.
