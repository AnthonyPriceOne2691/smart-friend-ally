# Active delivery status

- **slug:** encyclopedia-core
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)»: серия Э1–Э2, примеры P1–P11, ожидания P12–P20, вопросы 1–6 по рекомендациям; 100 карточек)
  <!-- одна подпись на серию, как у D3: гейт ищет в тестах поставки каждый id из таблиц её спеки, поэтому P12–P20 —
       списком; Э2 переносит их таблицей в свою спеку со ссылкой на коммит этой (L33, L51) -->
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23, подписан вместе со спекой)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- P1–P10 — тесты AllyCore на Linux (SQLite 3.45.1 с FTS5); P11 — encyclopedia-replay против эталона на Mac -->
- **artifact_oracle:** n/a reason=Э1 не собирает приложение: движок в пакете SwiftPM проверяют его тесты в CI на Linux, сборка не оракул (§6.5a); приложение собирает Э2 — scripts/lint/check_app_artifact.sh
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-encyclopedia
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: в main только через scripts/merge_guard.sh; на телефон — отдельным решением. Э1 трогает новые файлы AllyCore,
       Package.swift AllyCore, knowledge и CLAUDE.md — конфликты сложением, перед PR — слияние main -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: Э1 пишется против интерфейса Packages/AllySQLite из memory-core (пример M22 там);
       PR Э1 — после мержа memory-core (ответ ведущего на В1). Карточки Э2 агенты могут писать параллельно с Э1 -->
- **waivers:** none
- **new_dependency:** none
  <!-- Snowball — свой перенос (BSD-3, gh api 2026-10-23); SQLite — системный, через пакет проекта AllySQLite
       (.package(path:) гейт new-dependency не считает); NaturalLanguage не берётся -->
- **runtime_paths:** none reason=Э1 — функции над байтами карточек и текстом реплики и таблица FTS5 в памяти процесса, тесты на Linux и Mac; телефон, база из бандла и подсказка в промпте — Э2
- **irreversible_surfaces:** none reason=продукт офлайн; движок только читает данные: отправки, трат, стирания и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность проекта объявила D1.2; Э1 её не трогает — движок никто не зовёт, модель не видит ни подсказки,
       ни базы. Карточки, правило и рамка подсказки входят в поверхность в Э2 вместе с требованиями §14.4 -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: строку «на почему — настоящая причина» с частичным исполнителем вписывает Э2 -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** P1–P10 и покрытие AllyCore ≥ 70% зелёные в каждом PR; после Э2 — в живых сессиях подсказка только на ходах «почему» с карточкой, ни одной на «моё», деликатное и не-вопрос (след хода), поиск на телефоне p95 ≤ 10 мс
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
