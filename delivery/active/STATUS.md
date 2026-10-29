# Active delivery status

- **slug:** app-icon
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик значка судит родитель на глаз на странице local/checkpoint/app-icon/ (L18); снимков экрана телефона нет (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, «В» через ведущего: вариант значка — мордочка крупно, ночная пара остаётся; вопрос и варианты дословно в spec.md)
  <!-- подпись под выбором вписывает ведущий: агент by=human не пишет -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** check_app_artifact.sh
  <!-- I6: CFBundleIcons и Assets.car в собранном .app — ручная macOS-джоба по метке -->
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-app-icon
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон — в общую сессию теста -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
  <!-- pngcrush — из Xcode (xcrun), не новый пакет -->
- **runtime_paths:** none reason=значок — ресурс каталога: в собранном .app его судит оракул артефакта (I6), вид на домашнем экране — общая сессия теста; отказ не роняет процесс
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- значок поверхность модели не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в общей сессии теста родитель видит значок Элли на домашнем экране днём и ночную пару в тёмной теме; до неё I1–I4 зелёные на Mac и в macOS-джобе, I6 — на собранном .app
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
