# Active delivery status

- **slug:** app-encyclopedia
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии «энциклопедия почему»: Э1–Э2, ожидания P12–P20 — дословно в колонке ожидания spec.md; 100 карточек)
  <!-- спека серии — коммит ffc8523, подпись — 8bc7a1a (archive/2026-10-23-encyclopedia-core), Э1 слита 2ca2c30;
       вопрос ведущего родителю дословно — в archive/2026-10-23-encyclopedia-core/decisions.md -->
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23, план серии с разбиением Э1 → Э2 и бюджетом Э2, подписан вместе со спекой)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- P12, P13, P17 — тесты AllyCore на Linux; P14–P16, P18, P19 — стенд вне git; P20 — телефон с ведущим -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-app-encyclopedia
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: в main только через scripts/merge_guard.sh; на телефон — отдельным решением родителя (25.10: «тесты и
       закачка на телефон — завтра»). Общие файлы с параллельными поставками: Session.swift, TurnTrace.swift,
       Conversation.swift, VoiceLoop.swift, knowledge — конфликты сложением, перед PR — слияние main -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- escalation.md решён: разделы 1 и 2 — решения родителя 2026-10-27 -->
  <!-- зависимость, а не остановка: финальную базу (два прохода фактов, судьи) доводит ведущий; код, сборка и тесты
       на фикстурах идут на черновике той же схемы, финальный файл подставляется до verify -->
- **waivers:** acceptance=P16,P18,P20 reason=P18 — решение родителя 2026-10-27 «Слить, чинить сразу после (Рекомендую)»: формат B, исправленный судья, seed 45–47 — 38 из 48 при пороге 43, артефактов 0, все промахи — переспросы; карточка при ответе без сути — поставка card-fallback; P16 — решение родителя 2026-10-27 «Принять строгий (Рекомендую)» на v4 (с карточкой верных 26 из 40 при пороге 28, чужих 0 из 40 с карточкой и без, не-вопросы 0 из 20): строгое правило остаётся, добор попаданий — формулировками из чёрного ящика; P20 — постоянное решение родителя 2026-10-23 «Да, всё в общую сессию (Рекомендую)»: телефонные проверки — в общую сессию теста (`knowledge/ops/test-session.md`); код, тесты P12, P13, P17, сборка без подписи и оракул артефакта — зелёные by=human:anthony at=2026-10-27
- **new_dependency:** none
- **runtime_paths:** App/Sources/VoiceLoop.swift
  <!-- прогрев грузит базу из ресурсов AllyCore и строит FTS5 на телефоне: SQLite iOS с FTS5 не проверен (Э1), отказ
       виден только исполнением — самопроверкой и строкой консоли (P20, с ведущим) -->
- **irreversible_surfaces:** none reason=продукт офлайн; поиск только читает базу из бандла: отправки, трат, стирания, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyCore/Sources/AllyCore/Resources/encyclopedia.ru.jsonl,Packages/AllyCore/Sources/AllyCore/Resources/encyclopedia.json,Packages/AllyCore/Sources/AllyCore/Knowledge.swift,Packages/AllyCore/Sources/AllyCore/Encyclopedia.swift
  <!-- §14.1 п.1 и п.5: подсказка — часть входа модели; база, конфиг и правило решения (`Encyclopedia.swift`) — конфиг
       извлечения; сборка входа — `Knowledge.swift`, P19 -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** P12, P13, P17 и покрытие AllyCore ≥ 70% зелёные в каждом PR; в живых сессиях при родителе — подсказка только на ходах «почему» с карточкой, ни одной на «моё», деликатное и не-вопрос (поле `knowledge` следа), поиск на телефоне p95 ≤ 10 мс
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
