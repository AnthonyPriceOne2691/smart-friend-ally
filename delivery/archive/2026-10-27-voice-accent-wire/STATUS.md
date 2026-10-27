# Active delivery status

- **slug:** voice-accent-wire
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony — серия голоса, спека 68202f0, примеры Z19–Z26; ведущий 25.10: проводка расстановщика примеров V4b2b не меняет)
- **human_ok_plan:** yes (та же подпись серии 2026-10-23; поставка — хвост серии по слову ведущего 25.10 и 27.10: план ≈ 90 строк, с запасом ≈ 135)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z20 — проверка групп в тестах AllyCore на Linux; звучание и строка консоли, Z26 — сессия теста -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice-accent
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh. Параллельно: D6.1–D6.2, Ш2в, энциклопедия, канон -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=Z20,Z26 reason=постоянное решение родителя 2026-10-23 «Да, всё в общую сессию (Рекомендую)» и его слово 27.10 «сегодня — расстановка ударений, проводка звука и перебивания… тесты — потом»: звучание без расстановщика и ударения RUAccent на телефоне — в сессии теста; проверка групп Z20 — тест на Linux, сборка без подписи, оракул артефакта и CI — зелёные by=human:anthony
- **new_dependency:** none reason=новых манифестов нет: App/project.yml подключает существующий пакет AllyAccent
- **runtime_paths:** App/Sources/Audio/*.swift
- **irreversible_surfaces:** none reason=продукт офлайн; установка и копирование на телефон — только в сессии теста по решению родителя (manual-deploy)
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; поставка её не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: расстановщик меняет только текст для движка, экран и журнал получают фразу как есть -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** на телефоне — строка консоли расстановщика и этап voice_text в turns.jsonl с сессии теста
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
