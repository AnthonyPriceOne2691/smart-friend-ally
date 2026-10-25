# Active delivery status

- **slug:** accent-onnx
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» — подпись серии голоса V1–V4, спека серии — коммит 68202f0; V3 разрезана на V3a–V3c решением ведущего 2026-10-23 без изменения подписанного; Z18 переподписан родителем 2026-10-23 «Да, принять (Рекомендую)» — вариант A escalation; Z17 по отпечатку переподписан родителем 2026-10-25 «170 МБ, сжать потом (Рекомендую)»; вопрос ведущего дословно: «Голос Элли: описание работы готово, это серия из 4 частей. (1) Движок голоса на телефоне и общая основа для голоса и слуха. (2) Произношение: ударения, «сево́дня», «но́вова», «Элли» — только для голоса, тексты не меняются. (3) Расстановщик ударений на телефоне. (4) Голос в приложении вместо Milena: «тоньше» (подъём высоты), первая фраза звучит не позже чем через 2,5 с после её речи. Сам голос и таблица произношения подставятся одной строкой после второго круга образцов. Пока файлов голоса на телефоне нет, звучит Milena, и в консоли видно, чего не хватает. Первая фраза — 8 шагов (качественнее), если укладываемся в 2,5 с, иначе 5 шагов. Подписываешь?»)
- **human_ok_plan:** n/a (класс M; разбиение V3 — решение ведущего 2026-10-23)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z14–Z18 — тесты AllyVoice на Mac (ручная джоба ios и локально): двоичный ORT на Linux не собирается, как у V1 -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет SwiftPM проверяют его тесты на Mac; бинарь с расстановщиком — V4
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-accentonnx
- **parallel_sessions:** merge-guard,manual-deploy
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: Z14–Z17 ждут мержа V3b accent-logic (RuAccentPlacer, AccentModels); Z18 — без неё -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** Packages/AllyOnnx/
  <!-- V3c не правит AllyOnnx, но три модели — новый вызывающий нативного рантайма: потоки, spin, отображение весов из файла, память (Z17) -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не трогает приложение и телефон
- **model_surface:** n/a reason=языковая модель и промпт не меняются: модели ударений работают после контракта хода
- **rule_enforcers:** n/a reason=model_surface не объявлена списком
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z14–Z18 в ручной джобе ios на каждом бампе ORT и смене файлов RUAccent; с V4 — ударения на слух родителя в сессии (Z26)
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
