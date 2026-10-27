# Active delivery status

- **slug:** memory-app
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии и ответами 1–9: ожидания M33, M34, M35, M38 — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); разрез memory-app
       на memory-app (M33–M35, M38) и memory-recall (M36, M39, M37, M40) — решение ведущего 2026-10-27, подписанное
       содержание прежнее; входы и строки «Здесь:» — вымышленный пример агента к подписанным ожиданиям -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M33 — AllyCore (MemoryTapTests), M34, M35 (отмена), M38 — AllyMemory на Linux и Mac; M35 (E4B) — AllyLlama на Mac
       с весами, без весов — видимый пропуск (П34); телефонные части — waiver ниже -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app без подписи (сеть, ключи Info, права подписи); приложение получает пакет AllyMemory
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory-app
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится вручную в общей
       сессии теста; параллельно: голос, слух, оболочка, энциклопедия — конфликты в VoiceLoop.swift, project.yml,
       INDEX.md, OBSERVATIONS.md, knowledge — сложением; канон — вариант D, docs/canon копией под exclude -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** max_runtime_paths=2 reason=вопрос 9 спеки серии, подписан родителем 2026-10-23 «Подписываю (Рекомендую)»: «memory-app трогает два рисковых пути — пакет модели (разбор и пересборка префикса с блоком) и файлы памяти на телефоне (защита и бэкап): исключение max_runtime_paths=2 только для неё»; разрез ведущего 2026-10-27 его не расширяет — обе части берут те же пути Packages/AllyLlama/ и App/Sources/ by=human:anthony
- **waivers:** acceptance=M35,M38 reason=постоянное решение родителя 2026-10-23 на вопрос ведущего о телефонных проверках — «Да, всё в общую сессию (Рекомендую)», и его слово 27.10 «сегодня добить всё, что нужно кодить, сборку; испытание на телефоне — потом»: p95 разбора после 10-минутной сессии, экран во время разбора, тап, фон и убийство во время разбора, класс защиты файлов памяти на телефоне — в сессии теста; код, тесты M33–M35, M38, сборка без подписи и оракул артефакта — зелёные by=human:anthony
- **new_dependency:** none
  <!-- AllyMemory — локальный пакет репозитория; в project.yml приложения — строка пакета, внешних нет -->
- **runtime_paths:** Packages/AllyLlama/,App/Sources/
  <!-- §12.6: разбор моделью в последовательности 2 с грамматикой (AllyLlama) и проводка памяти в VoiceLoop — их отказ
       виден только исполнением на телефоне; доказательство — сессия теста (waiver acceptance выше) -->
- **irreversible_surfaces:** none reason=память пишет и стирает только свои файлы на телефоне; отправки наружу, трат, выкатки и публикации нет, продукт офлайн; «стереть всё» — memory-recall (M39)
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.json
  <!-- §14.1: новый проход модели — разбор в последовательности 2 с JSON-грамматикой (`AllyLlama`, ресурс json.gbnf);
       персона и сэмплирование разговора не меняются -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M33–M35, M38 и покрытие пакетов ≥ 70% зелёные в каждом PR; в сессии теста — строка `Caches/memory.jsonl` после каждой детской сессии при родителе (время, токены, факты), «память: …» в консоли при запуске
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
