# Tasks

- [x] T1: документы первым коммитом ветки `feat/asr-step3`: spec (U27 таблицей дословно), plan, tasks, decisions,
  STATUS
- [x] T2: `eval-smoke.md` до кода
- [x] T3: слить main после мержа D7.3 (`GigaAMRecognizer`)
- [x] T4: `StepThree` в AllyCore и `step3.json`; `StepThreeTests` (Linux)
- [x] T5: `StepThreeRun` и исполняемый `asr-step3` в AllyHearing; `StepThreeRunTests` (Mac)
- [x] T6: знание, verify, PR, CI; сдача — архив, INDEX (L104), строка `asr-step3` в `delivery/OBSERVATIONS.md`

Уроки по путям диффа, найденные гейтом на verify: **L7, L16, L70** — место шага 3 искал поиском по смыслу («шаг 3»,
«step3», «D7.4»): кроме `turn-detector` и `ops/black-box` нашлась справка `asr-child-speech` со скриптами исследования —
ей дописана строка о `asr-step3`; граница данных не сдвигается: выгрузка на Mac — решение D3, инструмент только читает
`local/`; **L50** — у инструмента есть вызывающий: команда runbook `ops/black-box`; **L68** — поля записи (`heard`,
`child_audio.file`, `versions.asr`) взяты дословно из ядра ящика и раскладки D3.2; **L73** — GigaAM вошёл через
готовый шов `GigaAMRecognizer.choose`; **L77** — правило меряется на базе, которую увидит продукт: её записи ящика, а не
корпус исследования. Не применимы: **L28, L40, L78** — списков слов, нарезки и базы справки нет; **L58, L59, L60, L69,
L71, L72, L112** — инструмент синхронный, без обёрток протоколов, отмены, сессий и памяти модели.
