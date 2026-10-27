# Active delivery status

- **slug:** child-shell-mouth
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- рот судят тесты ядра; снимков экрана телефона нет никогда (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» через ведущего — одной подписью с Ш3 и Ш2б: пример V34, отнесённый к Ш2в разрезом перед кодом Ш2б по точке подписанной спеки)
  <!-- спека серии — коммит 4c61d3c, подпись — 48b39f7 (в main — сквош a868735); здесь пример таблицей (L51) -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=Ш2в не трогает приложение: пакет SwiftPM судят его тесты (ядро — Linux CI и Mac), сборка не оракул (§6.5a)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-shell-mouth
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон — в общую сессию теста -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=Ш2в — пакет SwiftPM: ритм рта — генератор с тестами на Linux и Mac; приложение не тронуто, экран на телефоне — общая сессия теста
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- оболочка поверхность модели не трогает: экран рисует фазу сессии и ничего не говорит -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в общей сессии теста рот Элли открывается по слогам и закрывается в паузах, пока она говорит, и не дёргается (на глаз родителя); до неё V34 зелёный в каждом PR, покрытие ShellCore ≥ 70%
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
