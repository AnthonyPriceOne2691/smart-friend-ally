# Active delivery status

- **slug:** accent-logic
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» — подпись серии голоса V1–V4, спека серии — коммит 68202f0; V3 разбита на V3a/V3b/V3c под той же подписью по варианту A эскалации d92e8c7; вопрос ведущего дословно: «Голос Элли: описание работы готово, это серия из 4 частей. (1) Движок голоса на телефоне и общая основа для голоса и слуха. (2) Произношение: ударения, «сево́дня», «но́вова», «Элли» — только для голоса, тексты не меняются. (3) Расстановщик ударений на телефоне. (4) Голос в приложении вместо Milena: «тоньше» (подъём высоты), первая фраза звучит не позже чем через 2,5 с после её речи. Сам голос и таблица произношения подставятся одной строкой после второго круга образцов. Пока файлов голоса на телефоне нет, звучит Milena, и в консоли видно, чего не хватает. Первая фраза — 8 шагов (качественнее), если укладываемся в 2,5 с, иначе 5 шагов. Подписываешь?»)
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23 — разбиение V3 на три поставки, вариант A эскалации d92e8c7, решение ведущего по подписи серии)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z14–Z16 (доля V3b) — повтор Python по записанным выходам моделей на Linux; полные Z14–Z18 — V3c на Mac -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет AllyAccent проверяют его тесты в CI на Linux; бинарь с расстановщиком — V4
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-accentlogic
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно — V3a accent-tokenizers (рабочее дерево voiceaccent), стыки — через ведущего -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=чистая логика текста над словарями и выходами моделей: без экрана, железа и ввода-вывода, кроме чтения файлов словарей
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не трогает приложение и телефон
- **model_surface:** n/a reason=языковая модель и промпт не меняются: расстановщик работает после контракта хода
- **rule_enforcers:** n/a reason=model_surface не объявлена списком
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z14–Z16 (повтор) зелёные в каждом PR; с V3c — полные Z14–Z18 на Mac; с V4 — ударения на слух родителя (Z26)
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
