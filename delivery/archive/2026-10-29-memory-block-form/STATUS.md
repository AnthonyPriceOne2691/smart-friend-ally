# Active delivery status

- **slug:** memory-block-form
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, «Подписываю (Рекомендую)» через ведущего: шапка блока, бюджет 200, пример на вымышленных фактах)
  <!-- вопрос ведущего ушёл с шапкой исполнителя слово в слово, бюджет 200, порядок отсева подписанный, пример — M43;
       добавка ведущего к вопросу: «Старые проверки текста блока поменяются под эти слова, порядок и потолки — прежние»
       (M15, M23, M24 новыми словами); ожидание M40 — спека серии памяти, подпись 2026-10-23 (коммит 37bb5a9); правило
       суда M40 и устройство стенда — строка «Здесь:» исполнителя, записана до прогона; формат подсказки стенда (B) —
       решение ведущего 2026-10-29 -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M43, M15, M23, M24 — AllyMemory на Linux и Mac; M40 — стенд персоны на Mac вне git, правило — spec.md до прогона -->
- **artifact_oracle:** n/a reason=дифф не трогает приложение и его сборку: слова и сборка блока живут в пакете AllyMemory, их судят тесты пакета; включение блока — строка ресурса пакета, приложение и его ключи не меняются
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory-block-form
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: memory-forget (memory.json —
       слова консоли, BlockLines.swift — Words.Console, engineering/memory), card-fallback — конфликты сложением; канон —
       вариант D, docs/canon копией под exclude -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=M40 reason=решение родителя 2026-10-29 на вопрос ведущего о втором замере M40 — «Включить: имя держит код»: правило не выдержано по имени (D1 74% при 16% у персоны и пороге 33%), вываливанию (1 из 221 при 0) и живости (38% за блок у слепых судей при пороге 45%); быт 34 из 45 при 33, «почему» 31 и 38 из 48 при 26 и 36, детали D1 7 из 7 — не хуже; имя в продукте держит окно сессии memory-forget (D1 через окно — 10 из 31) by=human:anthony
- **waivers:** acceptance=M36,M37 reason=постоянное решение родителя 2026-10-23 на вопрос ведущего о телефонных проверках — «Да, всё в общую сессию (Рекомендую)»: чтение префикса с блоком на телефоне (M36) и «помнит на телефоне» (M37) — в сессии теста после включения блока; код, тесты и M40 на Mac — до слияния by=human:anthony
- **new_dependency:** none
- **runtime_paths:** none reason=дифф трогает только слова и сборку блока в пакете AllyMemory (Linux и Mac, тесты); путь пересборки префикса с блоком исполнен на Mac с весами в memory-recall (PrefixTests M36), на телефоне — сессия теста (waiver M36, M37)
- **irreversible_surfaces:** none reason=слова и сборка блока памяти на телефоне родителя; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/memory.json,Packages/AllyMemory/Sources/Memory/MemoryBlock.swift,Packages/AllyMemory/Sources/Memory/BlockLines.swift
  <!-- §14.1: шапка, бюджет и строки блока (memory.json, BlockLines.swift) и его сборка (MemoryBlock.swift) — поверхность
       модели, когда блок включён; дифференциальный прогон — M40 -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: правила шапки — «не пересказывай», «верь ей», «правила безопасности и подсказка важнее» — правила промпта;
       ниже модели их держат маршрутизатор и контракт (опасное), энциклопедия (подсказка), окно сессии (имя, брат);
       замер — M40 -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M43, M15, M23, M24, M40 (блок новой формы в системном ходе, окно держит имя на D1 — 10 из 31) и покрытие пакетов ≥ 70% зелёные в каждом PR; в сессии теста — «помнит на телефоне» (M37) и префикс с блоком из файла (M36); в чёрном ящике — вываливания фактов и обращения по имени
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
