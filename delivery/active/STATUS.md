# Active delivery status

- **slug:** encyclopedia-core
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** specify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** pending (спека серии Э1–Э3 у родителя через ведущего: примеры P1–P12 Э1 таблицей, ожидания Э2 P13–P19 и Э3 P20–P25 списком, вопросы 1–8 в decisions.md)
  <!-- одна подпись на серию, как у D3 (B1–B12 + B13–B22): гейт ищет в тестах поставки каждый id из таблиц её спеки,
       поэтому P13–P25 — списком; Э2 и Э3 переносят их таблицей в свои спеки со ссылкой на коммит этой (L33, L51) -->
- **human_ok_plan:** pending (подписывается вместе со спекой: в плане — порядок серии, бюджет Э1 и правило выбора формата подсказки Э3)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- P1–P10 — тесты AllyCore на Linux (основы слов, поиск FTS5 на системном SQLite 3.45.1, решение, отказ закрытый,
       запись без слов); P11–P12 — прогон encyclopedia-replay против эталона на Python на открытых наборах стенда, на Mac -->
- **artifact_oracle:** n/a reason=Э1 не собирает приложение: движок энциклопедии в пакете SwiftPM проверяют его тесты в CI на Linux, сборка не оракул (§6.5a); приложение собирает Э3, там — scripts/lint/check_app_artifact.sh
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-encyclopedia
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением.
       Параллельно 2026-10-23 работают ещё восемь исполнителей: Э1 трогает только новые файлы AllyCore, Package.swift
       AllyCore (цель encyclopedia-replay), knowledge и CLAUDE.md — конфликты решаются сложением, перед PR — слияние main -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: implement — после подписи родителя и когда в main есть общий пакет Packages/AllySQLite
       (вводит memory-core; если Э1 готова раньше — поставка sqlite-core по решению ведущего, вопрос В1). Э2 (карточки) —
       после мержа Э1, писать карточки агенты могут параллельно с Э1 по подписанной схеме; Э3 — после мержа Э2 -->
- **waivers:** none
- **new_dependency:** none
  <!-- основы слов — свой перенос алгоритма Snowball (BSD-3, сверено gh api 2026-10-23); SQLite — системный, через общий
       пакет проекта Packages/AllySQLite (.package(path:), гейт new-dependency считает только name:/url:); NaturalLanguage
       не берётся (decisions.md) -->
- **runtime_paths:** none reason=Э1 — функции над байтами карточек и текстом реплики в AllyCore и таблица FTS5 в памяти процесса, тесты на Linux и Mac; телефон (FTS5 системного SQLite iOS), загрузка базы из бандла и формат подсказки в промпте — Э3
- **irreversible_surfaces:** none reason=продукт офлайн; движок только читает данные: отправки наружу, трат, стирания и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность модели проекта объявила D1.2; Э1 её не трогает — движок не зовёт ни сессия, ни приложение,
       модель не видит ни подсказки, ни базы. Карточки, правило решения и рамка подсказки войдут в поверхность в Э3
       (§14.1 п.1 и п.5), вместе с тремя требованиями §14.4 -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: реестр «правило персоны v2.4 → исполнитель»; строку «на почему — настоящая причина, уверенно и правильно»
       (частичный исполнитель — подсказка энциклопедии) вписывает Э3, когда подсказка доходит до модели -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** P1–P10 и покрытие AllyCore ≥ 70% зелёные в каждом PR; после Э3 — в живых сессиях: подсказка только на ходах «почему» с карточкой, ни одной на «моё», деликатное и не-вопрос (след хода, правило knowledge.*), поиск на телефоне p95 ≤ 10 мс
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
