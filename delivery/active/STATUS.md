# Active delivery status

- **slug:** memory-recall
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии и ответами 1–9: ожидания M36, M37, M39, M40 — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); разрез memory-app
       на memory-app и memory-recall — решение ведущего 2026-10-27, подписанное содержание прежнее; входы и строки
       «Здесь:» (с правилом суда M40) — вымышленный пример агента к подписанным ожиданиям, записан до прогона -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M36 — AllyMemory (системный ход) и AllyLlama на Mac с весами (префикс, токены); M39 — AllyMemory (строки консоли,
       стирание); M40 — стенд персоны на Mac вне git, правило суда — в spec.md до прогона; M37 и экран — сессия теста -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app без подписи (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory-recall
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: голос, слух, оболочка —
       конфликты в VoiceLoop.swift, AllyApp.swift, INDEX.md, OBSERVATIONS.md, knowledge — сложением; канон —
       вариант D, docs/canon копией под exclude -->
- **hooks:** not-deployed
- **blockers:** M40 не выдержан (быт 30 из 45 при 33, «почему» с подсказкой 37 из 48 при 43, детали D1 5 из 7, имя в D1 74%) — решение родителя через ведущего, escalation.md
- **waivers:** max_runtime_paths=2 reason=вопрос 9 спеки серии, подписан родителем 2026-10-23 «Подписываю (Рекомендую)»: «memory-app трогает два рисковых пути — пакет модели (разбор и пересборка префикса с блоком) и файлы памяти на телефоне (защита и бэкап): исключение max_runtime_paths=2 только для неё»; разрез ведущего 2026-10-27 его не расширяет — обе части берут те же пути Packages/AllyLlama/ и App/Sources/ (decisions.md поставки memory-app) by=human:anthony
- **waivers:** acceptance=M36,M37,M39 reason=постоянное решение родителя 2026-10-23 на вопрос ведущего о телефонных проверках — «Да, всё в общую сессию (Рекомендую)», и его слово 27.10 «сегодня добить всё, что нужно кодить, сборку; испытание на телефоне — потом»: чтение префикса из файла ≤ 0,1 с на телефоне (M36), «помнит на телефоне» целиком (M37), экран консоли памяти (M39) — в сессии теста; код, тесты M36, M39, прогон M40 на Mac, сборка без подписи и оракул артефакта — зелёные by=human:anthony
- **new_dependency:** none
- **runtime_paths:** Packages/AllyLlama/,App/Sources/
  <!-- §12.6: пересборка префикса с блоком (AllyLlama) и консоль памяти со стиранием (App) — их отказ виден только
       исполнением на телефоне; доказательство — сессия теста (waiver acceptance выше), на Mac — тест с весами -->
- **irreversible_surfaces:** none reason=«Стереть память» — кнопка родителя с подтверждением на его телефоне, стирает только файлы памяти этого телефона; у агента команды стирания на телефоне нет; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.json,Packages/AllyMemory/Sources/Memory/Resources/memory.json,Packages/AllyMemory/Sources/Memory/MemoryBlock.swift
  <!-- §14.1: блок памяти входит в системный ход разговора — шапка и слова блока (memory.json) и его сборка
       (MemoryBlock.swift) становятся поверхностью модели; дифференциальный прогон — M40 -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: шапка блока «не пересказывай и не перечисляй, вспоминай что-то одно» — правило промпта; исполнитель —
       advisory с замером M40 (вываливаний 0, имя ≤ трети) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M36, M39 и покрытие пакетов ≥ 70% зелёные в каждом PR; в сессии теста — «Как зовут мою кошку?» 3 из 3 и «не знает» после стирания; в живых сессиях дочери при родителе — Элли вспоминает одно, не перечисляет
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
