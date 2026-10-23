# Plan: запрет на любом пути записи в память (`memory-guard`)

Уроки архива. **L74**: движок памяти — с поправкой ×1,8, а не ×1,25 (**L61**): план ≈ 280, ожидание ≈ 505, стоп 780. **L75**: метка примера —
`// M29` в строке `func test`. **L76**: правило данных держит все файлы хранилища — проверка байтов идёт по базе, WAL и
SHM. **L33**: документы и eval-smoke — первым коммитом, до кода; подпись — спека серии (37bb5a9). **L41**: покрытие —
по своему `Sources/` у `AllySQLite` и `AllyMemory`. **L45**: числа JSON — явными типами. **L50**: у проверки ещё нет
писателя-разбора (`memory-extract`) — знание так и пишет. **L26, L43**: новый тест-файл — в сводке утверждений; сверка
дайджеста — до пуша сдачи. **L35, L14**: перед ссылкой на CI — `mergeable`; после слияния main — строгий
`delivery_check`. **L28**: список слов видит только виденное — правила словарные, вторая линия — маршрутизатор
(`memory-app`). Не применимы: **L1, L2, L12** — объявлений n/a и новых манифестов нет; **L19, L47, L48, L49** — замеров на
модели нет.

## Approach

1. **`AllySQLite`:** `SQLiteConnection.function(_ name:, _ body: (String) -> Bool)` — скалярная функция одного текста,
   детерминированная; замыкание живёт в user data соединения (`Unmanaged`), освобождается деструктором SQLite.
2. **`Forbidden.swift` + `Resources/forbidden.json`:** группы правил по порядку ресурса; `rule(_ value:)` — id первого
   сработавшего правила по тексту без регистра и с «е» вместо «ё»; `Taint(heard:)` — слово после «фамили…», до двух
   слов после «улиц…» (служебные пропущены) и прилагательное перед ней, числа после «садик … номер» (цифрами и словами;
   сложное число словами — каждое слово отдельно, с запасом); значение заражено, если его слово совпадает со словом
   заражения или делит с ним начало не короче max(4, длина − 2), или несёт заражённое число.
   `install(on:)` регистрирует `forbidden(text)` = есть правило.
3. **`Schema.swift`:** триггеры у `fact` (BEFORE INSERT, BEFORE UPDATE OF value, value_key — по `value` и `value_key`)
   и у `seen` (BEFORE INSERT): `WHEN forbidden(…) BEGIN SELECT RAISE(ABORT, 'forbidden value'); END`. Функция —
   `SQLITE_DETERMINISTIC | SQLITE_INNOCUOUS`: схема зовёт её из триггера и при `trusted_schema = OFF`.
4. **`MemoryStore`:** функция ставится при открытии до схемы; `write` — кандидат с правилом или заражением не пишется,
   `report.refused[id] += 1`; `MemorySession.heard` (по умолчанию пусто), `WriteReport.refused`.
5. **Знание:** `engineering/memory.md` — запрет и заражение исполняются (`implementation:` += `Forbidden.swift`,
   `forbidden.json`), `knowledge/log.md`.

## Budget (800 строк, 25 файлов; ожидание ×1,8)

| Файл | строк |
|---|---|
| `Packages/AllySQLite/Sources/AllySQLite/SQLite.swift` (+ функция) | 22 |
| `Packages/AllySQLite/Tests/AllySQLiteTests/SQLiteTests.swift` (+ функция, M29) | 14 |
| `Packages/AllyMemory/Sources/Memory/Forbidden.swift` | 60 |
| `Packages/AllyMemory/Sources/Memory/Resources/forbidden.json` | 30 |
| `Packages/AllyMemory/Sources/Memory/Schema.swift` (триггеры) | 9 |
| `Packages/AllyMemory/Sources/Memory/MemoryStore.swift`, `Facts.swift` | 25 |
| `Packages/AllyMemory/Tests/MemoryTests/MemoryGuardTests.swift` (M29) | 110 |
| `Packages/AllyMemory/Tests/MemoryTests/Support.swift` | 10 |
| **итого, 8 файлов** | **≈ 280** |

Ожидание ≈ 505. Выше 780 — стоп и `escalation.md`; вариант — заражение (≈ 60 строк с тестом) в `memory-extract`.

## Rejected alternatives

- **Маршрутизатор как детектор значений** — отклонено: зависимость пакета от `AllyDiscipline` ради флага, который
  `memory-app` и так держит до разбора (реплика с `forget` в разбор не идёт).
- **Только триггер без проверки** — отклонено: триггер отвечает «forbidden value» без id правила, а отчёт обязан
  назвать правило, и вся сессия не должна падать из-за одного значения.
- **Порог числа «≥ 10», как у справки** — отклонено: подписано «числа … не сохраняются ни в одном поле».

## Test / eval strategy

- `MemoryGuardTests` — M29 одним тестом с метками; `SQLiteTests` — функция (`// M29`). Мутации: триггер снят (сырой
  INSERT проходит), проверка снята (записалось запрещённое), заражение снято («Петрова» записана).
