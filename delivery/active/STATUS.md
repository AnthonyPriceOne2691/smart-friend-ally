# Active delivery status

- **slug:** gigaam-asr
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23; «Подписываю (Рекомендую)» через ведущего — примеры U22–U28 в спеке серии «слух», подпись 3b68733, спека 74ada91)
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23; план серии «слух» с бюджетом D7.3 и запасным вариантом «инструмент шага 3 — отдельной поставкой», подпись 3b68733)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-gigaam
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция только через scripts/merge_guard.sh; на телефон — решением родителя. Код — после мержа D7.2
       (f0d62ef: AllyHearing, sherpa в AllyOnnx); main слит сложением -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=U28 reason=ответ 8 родителя в подписи серии «слух» 2026-10-23 на вопрос ведущего («… Проверки на телефоне — дважды: после части 2 и после части 4. Подписываешь?» — «Подписываю (Рекомендую)»): Silero и GigaAM (U20, U21, U28) — после D7.3, в сессии теста; постоянное решение родителя 2026-10-23 — все проверки на телефоне в общую сессию теста, сливаем по зелёным Mac и GitHub («Да, всё в общую сессию (Рекомендую)»); код, тесты U22–U26 на Mac и Linux, мутации, сборка без подписи и оракул артефакта — зелёные; по умолчанию слушает диктовка, GigaAM — только с `engine: gigaam` в реестре и файлами на телефоне by=human:anthony at=2026-10-23
- **new_dependency:** none
- **runtime_paths:** Packages/AllyHearing/
  <!-- §12.6, один путь: GigaAM на устройстве — загрузка весов external data, память, время расшифровки -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка меняет код слуха; на телефон — отдельным решением родителя; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели не трогается: распознаватель — не она -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** U28 в сессии теста: с asr: gigaam прирост footprint ≤ 450 МБ, recognize p95 ≤ 0,5 с на 20 ходах; до неё U22–U26 зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
