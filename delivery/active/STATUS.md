# Active delivery status

- **slug:** voice-app
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** specify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony — серия голоса, спека 68202f0, примеры Z19–Z26; подпись V4a того же дня покрыла правки Z20–Z22 и Z26)
  <!-- V4b2b — приложение поверх ядра V4b2a; стык с D6.1 — SupertonicVoice(engine:), примеры не меняет (ведущий 25.10) -->
- **human_ok_plan:** yes (та же подпись серии 2026-10-23; разрез V4b2 — правило ведущего «план +50%, стоп 780»: план ≈ 230 строк, с запасом ≈ 345)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- поведение голоса судят тесты ядра V4b2a (Z21, Z23–Z25 на двойниках) и сессия теста; здесь — сборка и оракул артефакта -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice-app3
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh. Параллельно: D6.1 duplex-audio, чёрный ящик в
       приложении, V3c accent-onnx -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=Z20,Z21,Z22,Z23,Z24,Z25,Z26 reason=постоянное решение родителя 2026-10-23 на вопрос ведущего о телефонных проверках — «Да, всё в общую сессию (Рекомендую)», и его слово 25.10 «сегодня механика: код, сборка; тесты и закачка на телефон — завтра»: голос на телефоне, Milena без файлов, журнал, бюджет, порт, стоп, паузы и слух — в сессии теста 26.10; код, сборка без подписи, оракул артефакта и CI — зелёные by=human:anthony
- **new_dependency:** none reason=новых манифестов нет: App/project.yml подключает существующие пакеты AllyVoice, AllyVoiceFX, AllySpeechText
- **runtime_paths:** App/Sources/Audio/*.swift
- **irreversible_surfaces:** none reason=продукт офлайн; установка на телефон — только в сессии теста по решению родителя (manual-deploy); отправки наружу, трат и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; V4b2b её не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: голос говорит только фразы, которые ему отдал ход после контракта -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** на телефоне — этапы voice_* и версия voice в turns.jsonl с первой сессии теста; p95 speech_end_to_sound
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
