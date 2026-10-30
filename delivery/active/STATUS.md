# Active delivery status

- **slug:** voice-tuning
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** spec
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- голос судит родитель на слух на странице local/checkpoint/voice-tuning/ (вне git); темп и чёткость — стенд local/spike/voice-tuning/ -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-30, «Голос понравился медленнее и выразительнее, где ты написал «рекомендую», короче. Вот он, да, можно его пока оставить, он нравится больше всех» и «Около секунды (Рекомендую)» через ведущего: вариант 6, обрезка тишины, пауза около секунды — вопрос и ответы дословно в spec.md)
  <!-- подпись вписывает ведущий после выбора родителя на странице; агент by=human не пишет -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app: строка voice.json доезжает в бандл
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice-tuning
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон — общая сессия теста.
       Рядом работают background-music, story-mode, mouth-sync: правки минимальные, перед пушем сдачи слить свежий main -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- в main и в пресет voice.json — только после выбора родителя: «сначала нужно прослушать и выбрать» (2026-10-30);
       обрезку и паузу ведущий поручил готовить в ветке, подпись — вместе с выбором варианта -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/Audio/,App/Sources/PhoneListener.swift
  <!-- §12.6: обрезка и ожидание тихой комнаты на настоящем звуке; ветка не вливается до выбора родителя, живая проверка —
       Mac кнопкой родителя и общая сессия теста -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- настройка голоса поверхность языковой модели не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в общей сессии теста родитель и дочь слышат выбранный голос; темп и чёткость выбранного варианта записаны на стенде и в концепте voice-fx
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
