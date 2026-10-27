# Active delivery status

- **slug:** voice-out
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony — серия голоса, спека 68202f0, примеры Z19–Z26; подпись V4a того же дня покрыла правки Z20–Z22 и Z26)
  <!-- V4b2 разбита на V4b2a voice-out (эта поставка: ядро голоса хода в AllyCore) и V4b2b voice-app (приложение) по
       правилу ведущего «план +50%, стоп 780»; стык с D6.1 — SupertonicVoice(engine:), примеры не меняет (ведущий 25.10) -->
- **human_ok_plan:** yes (та же подпись серии 2026-10-23; разрез V4b2 — правило ведущего «план +50%, стоп 780»: план ≈ 380 строк, с запасом ≈ 570 — выше 780 escalation.md и к ведущему)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z21, Z23, Z24, Z25 — тесты AllyCore на Linux (двойники рендера, проигрывателя и часов); телефон — V4b2b, сессия теста -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — в V4b2a приложение не меняется; оракул нужен с V4b2b
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice-app2
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh. Параллельно: D6.1 duplex-audio, чёрный ящик в
       приложении, V3c accent-onnx -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none reason=новых манифестов нет: порты и голос хода — в AllyCore
- **runtime_paths:** none reason=ядро голоса — логика над протоколами, без платформы; AVAudioEngine и телефон — V4b2b
- **irreversible_surfaces:** none reason=продукт офлайн; V4b2a не трогает приложение и телефон; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; V4b2a её не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: V4b2a правил персоны не исполняет -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z21, Z23, Z24, Z25 зелёные в каждом PR (Linux); на телефоне — этапы voice_* в turns.jsonl с V4b2b
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
