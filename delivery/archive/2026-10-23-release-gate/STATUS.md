# Active delivery status

- **slug:** release-gate
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-22 «Подписываю (Рекомендую)»: таблица «Пороги R2» и ответ на вопрос 9 — delivery/archive/2026-10-22-app-session/spec.md и decisions.md; примеры G12–G18 — пороги таблицы на своих границах)
  <!-- числа подписаны; примеры — те же числа «на пороге — открыт, на шаг хуже — закрыт», без новых чисел -->
- **human_ok_plan:** yes (родитель 2026-10-22 «Подписываю (Рекомендую)» — разбиение D2.2 → R → R2; решение родителя 2026-10-23 «сейчас собираем, оптимизировать потом»)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-releasegate
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция только через scripts/merge_guard.sh; параллельно — D3.2 (ключ родителя в .github/allowed_signers),
       поставка голоса (VoiceLoop.swift), оболочка Ш2–Ш3; слияние main — сложением -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** phone=строка приёмки в консоли,«Дочке, при мне» и детский экран без присмотра reason=постоянное решение родителя 2026-10-23: все проверки на телефоне — в общую сессию теста, сливаем по зелёным Mac и GitHub; ответ родителя «Да, всё в общую сессию (Рекомендую)»; файла приёмки в сборке нет — без присмотра закрыт, консоль пишет «приёмка: нет файла приёмки»; ключ родителя в .github/allowed_signers кладёт D3.2 by=human:anthony at=2026-10-23
- **new_dependency:** none
- **runtime_paths:** none reason=приёмка — чистая функция ядра над файлом из бандла и сборкой; пути к телефону и подписи (`scripts/child_mode.sh`) поставка не трогает; приложение берёт файл из бандла, как ключ родителя в R
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни выкатки; файла приёмки в сборке нет — без присмотра закрыто
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- поверхность модели не меняется: приёмка читает хэши для сверки сборки -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** G12–G18 и покрытие AllyCore ≥ 70% зелёные в каждом PR; консоль пишет строку «приёмка: …» с причиной; режим без присмотра открывается только подписанным файлом приёмки с целями на порогах (первый такой файл — по замеру целей 18.10)
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
