# Active delivery status

- **slug:** background-music
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- музыку судят тесты автомата и шкатулки (Linux CI и Mac), стенд эхоподавления на Mac (Y11) и уши родителя -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, «Подписываю (Рекомендую)» через ведущего: покой 0,8, в разговоре −20 дБ, уход 0,4 с, возврат через 2 с за 3 с, строка music.json, мелодия собирается кодом — примеры Y1–Y11 spec.md)
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=файла музыки нет: шкатулку собирает код при запуске, её байты судит тест Y10 (sha256 PCM на Linux и Mac)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-background-music
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон — общая сессия теста.
       Рядом в App/Sources: sim-app (Элли на Mac) и child-open (экран загрузки) — правки минимальные, перед пушем сдачи
       слить свежий main -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/Audio/
  <!-- §12.6, один рисковый путь: музыка на движке голоса с voice processing и проигрыватель покоя на аудиосессии
       .playAndRecord — отказ платформы виден только исполнением -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка добавляет звук в приложение; отправки, трат, выкатки и публикации нет
- **model_surface:** n/a reason=модель, промпт и реестр модели не меняются: поставка меняет только звук
- **rule_enforcers:** n/a reason=model_surface не объявлена списком
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** —
- **observe_until:** —
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
