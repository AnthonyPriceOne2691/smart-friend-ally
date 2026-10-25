# Active delivery status

- **slug:** canon-variant-d
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
- **behavior-oracles:** weak — дёшево: ничего сверх сделанного; перевод раскладки канона на вариант D, код продукта не меняется — доказательство пробами исполнением в чистом checkout ветки без `docs/canon/` и в свежем клоне (verify-report), тесты пакетов — джоба swift
- **artifact_oracle:** n/a reason=поставка не собирает приложение и не трогает его код — раскладка канона, конфиг хуков и smoke контура
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-variantd
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением, а не следствием мержа -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=раскладка канона и механика контура; код продукта не меняется
- **irreversible_surfaces:** none reason=продукт офлайн; поставка ничего не публикует сверх уже открытого — репозиторий открыт решением родителя 23.10, тексты канона уходят из индекса, а не в него, история не переписывается
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность модели не трогаем -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** —
- **observe_until:** —
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
