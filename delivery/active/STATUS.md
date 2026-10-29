# Active delivery status

- **slug:** child-open
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- запуск и детский экран на телефоне судит родитель в общей сессии теста; на Mac — поставка sim-app; снимков
       экрана телефона нет (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, «Подписываю (Рекомендую)» через ведущего: примеры J1–J6 spec.md)
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app без подписи (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-child-open
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); параллельно идут sim-app (App/,
       скрипты) и design-demo (консоль вынесена в ConsoleView.swift) — правки минимальные, перед финальным пушем —
       свежий main -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/
  <!-- §12.6: запуск (экран загрузки, прогрев до Элли) и детский экран без замка — их отказ виден только исполнением
       на телефоне; доказательство — общая сессия теста, на Mac — поставка sim-app -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка снимает замок экрана на телефоне родителя и не добавляет ни отправки наружу, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- прогрев модели и префикса персоны — прежний путь загрузки; персона, реестр и пакет модели не меняются -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** заполняется на handoff
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
