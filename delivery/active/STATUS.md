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
- **human_ok_spec:** yes (by=human:anthony at=2026-10-23 «Подписываю (Рекомендую)» через ведущего — серия D5 → D6.1 → D6.2, примеры X1–X17, решения 1–5 по рекомендациям; вариант «перебивать только тапом» не выбран)
  <!-- вопрос ведущего родителю дословно: «Живой разговор — 3 части. (1) В памяти модели остаётся только то, что Элли договорила вслух: оборванную фразу она не «помнит», готовые фразы защиты («нож сама не бери») помнит, адрес — никогда. (2) Микрофон слушает и во время речи Элли, с подавлением её же голоса (эха). (3) Дочка перебивает голосом (дольше четверти секунды, кашель не считается) или тапом — Элли замолкает за 0,3 с и слушает. Звонок или Siri — пауза, потом снова слушает. Автоусиление микрофона включим или нет — по замеру. Идёт после голоса и слуха. Подписываешь?» -->
  <!-- одна подпись на три поставки: в таблице примеров только X1–X8 (D5) — их гейт ищет в тестах этой поставки;
       X9–X17 — списком, D6.1 и D6.2 переносят их таблицей в свои спеки со ссылкой на коммит этой (L33, L51) -->
- **human_ok_plan:** yes (by=human:anthony at=2026-10-23 «Подписываю (Рекомендую)» — план D5 вместе со спекой; уроки L95–L97 — D5, L98–L99 — D6.1, L100 — D6.2)
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
