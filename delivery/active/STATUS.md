# Active delivery status

- **slug:** test-session
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** S
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** n/a
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** weak — поставка документная: один runbook по подписанным спекам; сверка механикой — каждый id runbook'а найден в своём источнике, каждый телефонный waiver архива есть в runbook'е (verify-report)
- **artifact_oracle:** n/a reason=поставка не собирает приложение и не трогает его код — только документ в knowledge/ops и указатели
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-testsession
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон — решением родителя -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=документ: команды runbook'а — существующие (reinstall_app.sh, child_mode.sh, devicectl, blackbox.py после D3.2), новых скриптов нет
- **irreversible_surfaces:** none reason=продукт офлайн; документ ничего не ставит и не стирает — стирание ящика объявлено и подписано в своей поставке (D3.2)
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность модели не трогаем -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** первая общая сессия теста проходит по runbook'у за раз: подготовка, шаг владельца, проверки по порядку без лишних переустановок; итоги записаны в observed.md поставок, расхождения runbook'а с телефоном — правкой runbook'а
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
