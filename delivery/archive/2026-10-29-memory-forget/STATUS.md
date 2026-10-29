# Active delivery status

- **slug:** memory-forget
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии и ответами 1–9: ожидания M41, M42 — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); входы и строки
       «Здесь:» — вымышленный пример исполнителя к подписанным ожиданиям (поручение ведущего 2026-10-29) -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M41 — AllyMemory (байты базы, WAL, SHM, блок, надгробие); M42 — AllyCore через настоящую Session и Conversation
       с двойником модели; E4B на D2 × 3 seed — стенд на Mac вне git, по «можно» ведущего; экран «Забыть» — сессия теста -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app без подписи (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory-forget
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: memory-block-form (memory.json,
       BlockLines.swift, engineering/memory), card-fallback, sim-app — конфликты сложением; канон — вариант D,
       docs/canon копией под exclude -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=M41 reason=постоянное решение родителя 2026-10-23 на вопрос ведущего о телефонных проверках — «Да, всё в общую сессию (Рекомендую)»: экран «Забыть» на телефоне (список, подтверждение, исчезновение строки) — в сессии теста; код, тесты M41, сборка без подписи и оракул артефакта — зелёные by=human:anthony
- **new_dependency:** none
- **runtime_paths:** App/Sources/
  <!-- §12.6: экран «Забыть» в консоли родителя и имена из памяти в сессию — их отказ виден только исполнением на
       телефоне; доказательство — сессия теста (waiver выше), на Mac — сборка без подписи и тесты пакетов -->
- **irreversible_surfaces:** none reason=«Забыть» — кнопка родителя с подтверждением на его телефоне, удаляет только факты памяти этого телефона; у агента команды на телефоне нет; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.json,Packages/AllyMemory/Sources/Memory/Resources/memory.json,Packages/AllyMemory/Sources/Memory/MemoryBlock.swift
  <!-- §14.1: прежний список memory-recall; дифф трогает только memory.json — слова консоли «Забыть», модели они не
       идут; шапка и строки блока не меняются (M15, M23, M24 зелёные), блок выключен (in_conversation: false) -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: «спроси о брате не больше двух раз» и «по имени — только когда здороваешься» получают исполнителя ниже
       модели — окно сессии (TurnWindow); «хотя бы раз» остаётся за персоной, замер M42 на E4B -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M41, M42 и покрытие пакетов ≥ 70% зелёные в каждом PR; в сессии теста — «Забыть» на телефоне; в чёрном ящике — ответы, где окно срезало брата или имя (сырой текст модели против сказанного)
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
