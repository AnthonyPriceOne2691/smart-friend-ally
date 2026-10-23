# Active delivery status

- **slug:** kv-spoken
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** plan
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** deferred (reason=спека серии D5 → D6.1 → D6.2 и примеры X1–X17 у ведущего на подпись родителю 2026-10-23; до подписи — стоп)
  <!-- одна подпись на три поставки: в таблице примеров только X1–X8 (D5) — их гейт ищет в тестах этой поставки;
       X9–X17 — списком, D6.1 и D6.2 переносят их таблицей в свои спеки со ссылкой на коммит этой (L33, L51) -->
- **human_ok_plan:** deferred (reason=план D5 — вместе со спекой на подпись родителю 2026-10-23)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- X2–X5, X7 — тесты AllyCore и AllyLlama без весов (Linux, Mac); X1, X6 — AllyLlama на Mac с весами, без весов —
       видимый пропуск (П34); X8 — телефон, сессия с родителем -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-duplex
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением
       родителя. D5 — после D7.1 turn-speculation (ветка feat/turn-detector), D6.1 — после V4 voice-app -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** Packages/AllyLlama/
  <!-- §12.6, один рисковый путь на поставку (E1): память модели — seq_rm и дописывание сказанного в LlamaModel -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни выкатки
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: D5 меняет пакет модели — блок «Изменение поверхности модели» в verify-report -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в сессиях с родителем память модели держит только прозвучавшее: следующий ответ не опирается на несказанное (оценка родителя на слух); в следе — `spec_retracted` вместо `spec_stale`; первая фраза не медленнее main более чем на 0,1 с p95 (X8); до неё X1–X7 зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
