# Active delivery status

- **slug:** card-fallback
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-29, через ведущего: «Подписываю: фраза + карточка (Рекомендую)» под примером P21–P23 спеки card-fallback; вопрос дословно — spec.md, раздел «Подпись»)
  <!-- спека — коммит 901e5ae до кода (L33); вопрос ушёл с двумя правками ведущего, они — в spec.md и decisions.md -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- P21–P24 — тесты AllyCore на Linux; P18 — стенд формата на Mac вне git, перегон на свежих seed -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-card-fallback
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: в main только через scripts/merge_guard.sh; на телефон — отдельным решением родителя. Общие файлы с
       параллельными поставками: Session.swift, TurnRunner.swift, TurnTrace.swift, knowledge — конфликты сложением,
       перед PR — слияние main -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=меняется только ядро AllyCore (судится на Linux в CI); приложение и его рисковый путь VoiceLoop.swift не трогаю — текст карточки звучит тем же голосом через TurnRunner
- **irreversible_surfaces:** none reason=продукт офлайн; откат на карточку только читает базу из бандла: отправки, трат, стирания, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyCore/Sources/AllyCore/Resources/encyclopedia.ru.jsonl,Packages/AllyCore/Sources/AllyCore/Resources/encyclopedia.json,Packages/AllyCore/Sources/AllyCore/Knowledge.swift,Packages/AllyCore/Sources/AllyCore/Encyclopedia.swift
  <!-- §14.1: правка — только Encyclopedia.swift (движок читает ключ карточки и проверяет его при загрузке); вход
       модели не меняется — решения поиска и подсказка те же (P17, P23) -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** P21–P24 и покрытие AllyCore ≥ 70% зелёные в каждом PR; в живых сессиях при родителе — доля ходов с `knowledge.fallback` среди ходов с `knowledge.hint` (след, чёрный ящик) и ни одного `knowledge.fallback` без `knowledge.hint`
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
