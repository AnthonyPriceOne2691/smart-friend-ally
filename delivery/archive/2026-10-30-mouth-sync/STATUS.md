# Active delivery status

- **slug:** mouth-sync
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- рот по звуку судят тесты ядра на Linux и Mac; на телефоне — общая сессия теста; снимков экрана телефона нет (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-30, «Подписываю (Рекомендую)» через ведущего: рот только пока звучит голос, поза до звука, закрытие за десятые доли секунды — примеры N1–N6 spec.md)
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app без подписи (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-mouth-sync
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); параллельно идут voice-tuning,
       story-mode, музыка (#93) и Mac (#89) — правки минимальные, перед финальным пушем — свежий main -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/
  <!-- §12.6: признак «голос звучит» от проигрывателя к экрану — его отказ виден только исполнением; доказательство —
       демо в симуляторе (сценарий со звуком), сборка Ally.app и общая сессия теста -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка меняет движение рта Элли — ни отправки наружу, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- рот по звуку поверхность модели не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** N1–N5 и V12, V34 зелёные в каждом PR; в общей сессии теста на телефоне — N6: рот начинается со звуком первой фразы, между фразами и на стопе закрыт; после слияния родитель смотрит на Mac
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
