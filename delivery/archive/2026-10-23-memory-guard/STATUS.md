# Active delivery status

- **slug:** memory-guard
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии: ожидание M29 — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); разбиение
       memory-extract на memory-guard (M29) и memory-extract (M26–M28, M30–M32) — решение ведущего 2026-10-23,
       «подписанное содержание то же, разбито мельче»; входы M29 и строка «Здесь:» — вымышленный пример агента к
       подписанному ожиданию, новых ожиданий не вводят -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M29 — тесты пакета Packages/AllyMemory (MemoryGuardTests) и общего Packages/AllySQLite (функция), на Linux (CI,
       джоба swift) и на Mac -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакеты памяти и SQLite на Linux судят их тесты в CI, сборка не оракул (§6.5a); приложение и файлы на телефоне несёт memory-app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: серия энциклопедии (общий пакет
       Packages/AllySQLite — добавляется только метод function, остальное не трогается), голос, речь, оболочка,
       child-lock; AllyCore не трогается; конфликты в CLAUDE.md, INDEX.md, OBSERVATIONS.md, knowledge — сложением -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=пакеты памяти и SQLite на Linux и Mac (база во временном каталоге теста); файлы памяти на телефоне и разбор моделью — memory-app, там пути объявляются (вопрос 9 спеки серии)
- **irreversible_surfaces:** none reason=запрет только отбрасывает значение до записи и отвергает его триггером; стирания, отправки наружу, трат, выкатки и публикации нет, продукт офлайн
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность не меняется — до модели память ещё не доходит (вызывающего нет, L50); промпт разбора и его
       правило «не извлекай запрещённое» вводит memory-extract, туда же — строка реестра «запрет хранить — исполняется
       кодом и триггером» -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: memory-guard правил промпта не вводит; запрет — правило кода ниже будущего промпта разбора -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M29 и покрытие AllySQLite и AllyMemory ≥ 70% зелёные в каждом PR; после memory-app в живых сессиях дочери при родителе — в журнале записи «отброшено по правилам» растёт без значений, в консоли родителя нет адресов, телефонов, фамилий
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
