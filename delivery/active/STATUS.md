# Active delivery status

- **slug:** sim-app
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- первый ход на Mac исполняет родитель кнопками (⌘R, «Разбудить»), агент говорит синтетикой и снимает строки журнала -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, «Подписываю (Рекомендую)» через ведущего: примеры N1–N10 spec.md)
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app для устройства без подписи (сеть, ключи Info, iOS 27.0); на Mac идёт тот же iOS-бинарь
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-sim-app
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); запуск на Mac — кнопкой родителя в Xcode -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/
  <!-- §12.6: приложение для iPhone на Mac — выбор папки, копия в контейнер, микрофон, диктовка, Metal, звук; исполняется первым ходом N9 -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не отправляет наружу, не тратит и не публикует; Mac в бесплатную команду внесла автоматическая подпись Xcode под входом родителя по его решению 2026-10-29
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- поставка поверхность модели не трогает: Metal — строка приложения, а не пакета модели -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** заполняется на handoff
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
