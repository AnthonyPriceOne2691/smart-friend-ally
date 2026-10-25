# Active delivery status

- **slug:** voice-config
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony — серия голоса, спека 68202f0, примеры Z19–Z26; подпись V4a того же дня покрыла правки Z19–Z22 и Z26; ответ родителя «Резать: эквалайзер — в следующую часть» перенёс сюда Z29 и полный Z30)
  <!-- V4b разбита на V4b1 voice-config (эта поставка: эквалайзер, полный Z30, строка пресета, реестр файлов, команда
       копирования) и V4b2 voice-app (телефон) по правилу ведущего 2026-10-23 «план +50%, стоп 780»; новых примеров нет -->
- **human_ok_plan:** yes (та же подпись серии 2026-10-23; разрез V4b — правило ведущего «план +50%, стоп 780»: план ≈ 410 строк, с запасом ≈ 610 — выше 780 escalation.md и к ведущему)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z19, Z20 — тесты AllyCore на Linux; Z20 (команда) — smoke voice_copy_check.sh в CI; Z29 — тесты AllyVoiceFX на
       Linux; Z30 — стенд Mac против одобренного p9f5 -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — в V4b1 приложение получает только ресурс voice.json; код приложения — V4b2
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice-app
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh. Параллельно: V3b accent-logic, V3c accent-onnx,
       чёрный ящик в приложении, оболочка, GigaAM, память, энциклопедия -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none reason=новых манифестов нет: эквалайзер — в существующем AllyVoiceFX, настройки — в AllyCore, команда — скрипт на stdlib Python
- **runtime_paths:** none reason=приложение в V4b1 не меняет код; команда копирования пишет в контейнер приложения только по решению родителя в общей сессии (manual-deploy)
- **irreversible_surfaces:** none reason=продукт офлайн; копирование в контейнер приложения обратимо и ничего не удаляет; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; V4b1 её не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: V4b1 правил персоны не исполняет -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z19, Z20, Z29 зелёные в каждом PR (Linux), smoke voice_copy_check.sh — в джобе delivery
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
