# Active delivery status

- **slug:** turn-speculation
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23; «Подписываю (Рекомендую)» через ведущего — примеры U7–U15 в спеке серии «слух», подпись 3b68733, спека 74ada91)
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23; план серии «слух» с бюджетом D7.1, подпись 3b68733)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-speechin
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон — решением родителя. Параллельно:
       D5 kv-spoken (spec_stale), голос V3/V4 (PhoneListener), D7.2 после V1 -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/Speech/
  <!-- §12.6, один путь: текст диктовки на «возможно, конец» (finalize(through:) без конца ввода) — поведение
       распознавателя на телефоне; App/Sources/Audio/ и Packages/AllyLlama/ не тронуты -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка меняет код ядра и слух приложения; на телефон — отдельным решением родителя; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: D7.1 поверхность модели не трогает — модель получает ту же реплику, что получила бы на хвосте -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** U14, U15 в сессии теста: p95 speech_end_to_sound ≤ 2,5 с на открытых и закрытых ходах, текст на «возможно, конец» = итог на хвосте ≥ 18 из 20; до неё U7–U13 и покрытие AllyCore ≥ 70% зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
