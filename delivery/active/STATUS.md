# Active delivery status

- **slug:** memory-core
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)»: примеры M15–M25, ожидания M26–M42, ответы 1–9 по рекомендациям; вопрос ведущего — дословно в decisions.md)
  <!-- спека — коммиты 21d556c и 4a94261 (общий пакет SQLite по решению ведущего), подпись — этим отдельным коммитом до
       кода (L33), eval-smoke — следующим; второй вариант ответа «…но друзей и игрушки сразу» родитель не выбрал -->
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23, подписан вместе со спекой: четыре поставки, бюджет memory-core ≈ 605 строк в 17 файлах, стоп 780; исключение на два рисковых пути — только для memory-app (вопрос 9), его строка waiver живёт в её STATUS, не здесь)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M15–M21, M23, M24 — тесты пакета Packages/AllyMemory, M22 — тесты общего пакета Packages/AllySQLite, оба на Linux
       (CI, джоба swift) и на Mac; M25 — смоук S7 гейта данных ребёнка во временном репозитории -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет памяти на Linux судят его тесты в CI, сборка не оракул (§6.5a); приложение, файлы на телефоне и исполнение несёт memory-app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: D3.2 app-black-box (хранилище на
       телефоне, VoiceLoop), R child-lock (audience supervised), серия энциклопедии (SQLite FTS5 — общий пакет
       Packages/AllySQLite, решение ведущего 2026-10-23: вводит первый, кто сольётся), «оболочка», голос и речь (App); пакет памяти новый, AllyCore не трогается;
       конфликты в quality.yml, .swiftlint.yml, CLAUDE.md, INDEX.md, knowledge — сложением -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- стоп по предохранителю (net 1092 из 800) снят решением родителя 2026-10-23 — исключение ниже, ход — escalation.md -->
- **waivers:** max_loc_diff=1100 reason=вопрос ведущего родителю «Память, первая часть (база на телефоне), готова и проверена, но вышло ~1090 строк при пределе 800. Из них ~300 — тесты и ~180 — общая база, которую возьмёт и энциклопедия. Лишнего кода нет: каждое правило держит подписанный тобой пример. Как поступить?» — ответ родителя 2026-10-23: «Исключение для памяти до 1100 (Рекомендую)»; только для memory-core, на следующие поставки исключения нет by=human:anthony
- **new_dependency:** Packages/AllySQLite/Package.swift reason=новый манифест SwiftPM без внешних пакетов (общий SQLite приложения, решение ведущего 2026-10-23): системный модуль CSQLite — libsqlite3 из SDK Apple (3.54.0 на Mac), на Linux CI — libsqlite3-dev 3.45.1 образа ubuntu-24.04 (сверено по описанию образа и пробой в контейнере Swift 6.4.1), обёртка AllySQLite — Foundation, тесты — XCTest тулчейна; GRDB, SQLite.swift и свой исходник SQLite не берём (decisions.md); если пакет раньше введёт энциклопедия, строка уходит при слиянии main by=agent:claude-code
- **new_dependency:** Packages/AllyMemory/Package.swift reason=новый манифест SwiftPM без внешних пакетов: модуль Memory — Foundation и локальный ../AllySQLite, тесты — XCTest тулчейна by=agent:claude-code
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
- **observe_signal:** M15–M25 и покрытие AllySQLite и AllyMemory ≥ 70% зелёные в каждом PR; после memory-app в живых сессиях дочери при родителе — строка «память: N фактов» растёт после разбора, «Как зовут мою кошку?» в новой сессии — верный ответ, после «Стереть память» — не знает, блок ≤ 300 токенов по токенизатору
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
