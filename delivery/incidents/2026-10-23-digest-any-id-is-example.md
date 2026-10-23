# Инцидент: сводка утверждений считает примером спеки любой токен вида «буква + цифры»

- **Дата:** 2026-10-23 · **Нашедший:** agent:claude-code (сессия smart-frend-ally, поставка `encyclopedia-core`) · **Хозяин:** smart-friend-ally
- **Канон:** `scripts/lint/assert_digest.sh` (классификатор awk: `match($0, /(^|[^A-Za-z0-9_])[A-Z][0-9]+([^A-Za-z0-9_]|$)/)`;
  `cqg@2.74`); `delivery@2.07` §3.1d уровень 3

## Симптом

Утверждение привязывается к первому токену вида «заглавная буква + цифры» на последней добавленной строке перед ним.
Токен не сверяется с таблицами примеров спеки, поэтому id урока, задачи или смоука проходит как «пример». Сводка
печатает «Каждое утверждение ведёт к примеру спеки» и `asserts_without_example: 0`. `delivery_check` после этого
принимает `asserts_reviewed_by: n/a`: ревью ожиданий снимается и над утверждениями, которых человек не подписывал.

## Воспроизведение (Ally, 2026-10-23, канонный код без правок)

Коммит 5c5ccec поставки `encyclopedia-core` добавил четыре утверждения под комментариями
`// «one may be missing» at three points (L90): …` и `// the limits at three points (L90): …`. L90 — урок архива, а не
пример спеки: таблица спеки — P1–P11. Прогон `BASE=origin/main bash scripts/lint/assert_digest.sh`:

```text
L90	XCTAssertEqual(decision("почему бурый медведь"), [nil, "knowledge.coverage"])
L90	XCTAssertEqual(decision("почему бурый медведь спит"), ["bear-winter", "knowledge.hint"])
L90	XCTAssertEqual(decision("почему бурый медведь спит зимой"), ["bear-winter", "knowledge.hint"])
L90	XCTAssertTrue(Encyclopedia(cards: atLimits, config: config).healthy)
✅ Каждое утверждение ведёт к примеру спеки (L90 P1 P10 P2 P3 P4 P5 P6 P7 P8 P9) …
asserts_without_example: 0
```

Свой гейт Ally `check_digest_report.py` пересчитывает тем же скриптом и тоже получает 0.

## Что сделано в Ally (канон не правился)

- Метки переставлены: id примера стоит первым токеном комментария (`// P6 at three points (L90): …`, коммит 19e247f).
  Теперь сводка относит утверждения к `P6` и `P9`.
- Урок L79.
- Запись `kind: upstream-candidate` у `scripts/lint/assert_digest.sh` в `scripts/lint/adapted.json`.

## Предложение (решает судья)

Сводке нужно множество id примеров из таблиц активной спеки — первая колонка строк `| <id> |`. Токен вне этого
множества считается «без примера», а если спеки нет — `unknown`. Проба: утверждение под `// L90` при спеке с примерами
P1–P11 даёт `asserts_without_example: 1`.

## Куда уехало

- поставка `encyclopedia-core` Ally (PR #56); запись в `scripts/lint/adapted.json`;
- доклад ведущему; сообщение судье (сессия Prepare) — через ведущего.
