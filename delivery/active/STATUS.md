# Active delivery status

- **slug:** memory-core
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** tasks
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** no (ждёт подписи родителя через ведущего: примеры M15–M25, ожидания M26–M42, вопросы 1–9 decisions.md)
  <!-- спека серии — первым коммитом ветки, до кода (L33); подпись — отдельным коммитом до кода, eval-smoke — после неё -->
- **human_ok_plan:** no (ждёт подписи вместе со спекой: разбиение серии на четыре поставки, бюджет memory-core ≈ 598 строк)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M15–M24 — тесты пакета Packages/AllyMemory на Linux (CI, джоба swift) и на Mac; M25 — смоук S7 гейта данных
       ребёнка во временном репозитории -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет памяти на Linux судят его тесты в CI, сборка не оракул (§6.5a); приложение, файлы на телефоне и исполнение несёт memory-app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: D3.2 app-black-box (хранилище на
       телефоне, VoiceLoop), R child-lock (audience supervised), серия энциклопедии (SQLite FTS5 — один системный модуль
       SQLite на приложение, вопрос ведущему), «оболочка», голос и речь (App); пакет памяти новый, AllyCore не трогается;
       конфликты в quality.yml, .swiftlint.yml, CLAUDE.md, INDEX.md, knowledge — сложением -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- остановка по процессу, а не блокер: после коммита спеки и плана исполнитель ждёт подписи родителя (ведущий) -->
- **waivers:** none
- **new_dependency:** Packages/AllyMemory/Package.swift reason=новый манифест SwiftPM без внешних пакетов: модуль Memory — Foundation и системный SQLite через модуль CSQLite (SDK Apple: libsqlite3, 3.54.0 на Mac; Linux CI — libsqlite3-dev 3.45.1 образа ubuntu-24.04, сверено по описанию образа и пробой в контейнере Swift 6.4.1), тесты — XCTest тулчейна; GRDB, SQLite.swift и свой исходник SQLite не берём (решение ниже, decisions.md) by=agent:claude-code
- **runtime_paths:** none reason=пакет памяти на Linux и Mac (база во временном каталоге теста, блок — текст); файлы памяти на телефоне (защита, бэкап), разбор моделью и префикс с блоком — memory-app, там пути объявляются (вопрос 9)
- **irreversible_surfaces:** none reason=«стереть всё» — функция ядра без вызывающего; кнопку в консоли родителя с подтверждением добавит memory-app, нажимает её родитель, команды стирания на телефоне у агента нет; продукт офлайн, отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность проекта не меняется — блок памяти в memory-core не доходит ни до одной модели (вызывающего нет,
       L50); memory-app допишет его к системному ходу персоны и внесёт MemoryBlock.swift и memory.json в поверхность со
       снимком и дифференциальным прогоном (M40) -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: memory-core правил промпта не вводит; строку «блок памяти: не пересказывать, не вываливать — advisory с
       замером» и «реплика с forget в память не идёт — исполняется» внесут memory-extract и memory-app -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M15–M25 и покрытие AllyMemory ≥ 70% зелёные в каждом PR; после memory-app в живых сессиях дочери при родителе — строка «память: N фактов» растёт после разбора, «Как зовут мою кошку?» в новой сессии — верный ответ, после «Стереть память» — не знает, блок ≤ 300 токенов по токенизатору
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
