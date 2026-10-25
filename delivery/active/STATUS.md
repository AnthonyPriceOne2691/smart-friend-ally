# Active delivery status

- **slug:** asr-step3
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23; «Подписываю (Рекомендую)» через ведущего — пример U27 в спеке серии «слух», подпись 3b68733, спека 74ada91; отдельная поставка — запасной вариант подписанного плана серии)
- **human_ok_plan:** n/a
  <!-- класс M: подпись плана не требуется (§2.2); отличие от плана серии — Swift вместо скрипта Python — в decisions.md -->
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=инструмент Mac для родителя; приложение и его бандл не меняются
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-step3
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция только через scripts/merge_guard.sh; на телефон поставка не ставится. Код — после мержа D7.3
       (GigaAMRecognizer); раскладка выгрузки — D3.2 (PR #43) -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** Packages/AllyHearing/
  <!-- §12.6, один путь: GigaAM через C API sherpa на Mac по WAV выгрузки, чтение записей ящика — исполнение на Mac -->
- **irreversible_surfaces:** none reason=инструмент только читает выгрузку на Mac и печатает суммы; отправки наружу, трат, выкатки, публикации и стирания нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели не трогается: распознаватель и его сравнение — не она -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** первый шаг 3 родителя на её записях: вывод — только суммы и вердикт, ни одного её слова; до него U27 зелёный в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
