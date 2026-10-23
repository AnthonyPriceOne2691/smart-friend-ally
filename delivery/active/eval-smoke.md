# Eval smoke — memory-guard

Оракул поставки — M29, подписанный родителем 2026-10-23 в спеке серии (коммит подписи 37bb5a9). Факт — по прогону тестов
пакетов и мутаций.

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| M29 | `MemoryGuardTests` + `SQLiteTests` (функция) + мутации «триггер снят», «проверка снята», «заражение снято» | записаны возраст 5 и «качели»; отброшено 17 по правилам (`surname` 2, `address` 2, `phone` 1, `institution` 2, `outside_adult` 1, `health` 1, `conflict` 1, `money` 1, `faith` 1, `incident` 2, `secret` 1, `password` 1, `birth_year` 1), значений в отчёте нет; в обход проверки — «forbidden value» на INSERT и UPDATE в `fact` и INSERT в `seen`, «no such function: forbidden» без функции; 0 вхождений «Петров», «Морковн», «ветрянк», «Ольг» в файлах базы | — |
