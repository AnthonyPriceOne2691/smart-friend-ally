# Active delivery status

- **slug:** design-demo
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик судит родитель на глаз в симуляторе и канвасе Xcode на Mac; снимков экрана телефона нет (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, «Подписываю (Рекомендую)» через ведущего: примеры Y1–Y7 spec.md)
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_demo_boundary.sh — проект и собранные Ally.app и AllyDemo.app: демо не в релизе, в демо нет модели, микрофона и голоса
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-design-demo
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); параллельно идёт sim-app — тоже
       App/project.yml и ios.yml: правки здесь минимальные, перед финальным пушем — свежий main -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=демо идёт только в симуляторе без модели, микрофона и голоса; консоль приложения — тот же вид, вынесенный в общий файл с прежними условиями кнопок (чтение loop.* один в один); вид на телефоне — общая сессия теста
- **irreversible_surfaces:** none reason=продукт офлайн; поставка добавляет демо-цель для симулятора и скрипт запуска на Mac — ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- демо и токены облика поверхность модели не трогают -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Y1–Y3 и Y5 зелёные в каждом PR (проект — хук demo-boundary, собранное — macOS-джоба по метке); Y6 — пробы AllyShell с прежними порогами; на Mac `bash scripts/run_demo.sh` поднимает демо в детском режиме за ≤ 30 с повторно, правка Look.swift или Palette.swift видна в канвасе и симуляторе
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
