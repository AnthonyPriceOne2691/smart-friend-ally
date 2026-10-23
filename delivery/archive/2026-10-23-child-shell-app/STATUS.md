# Active delivery status

- **slug:** child-shell-app
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик судит родитель на глаз по снимкам на Mac (П32); снимков экрана телефона нет никогда (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» через ведущего: Ш3 и Ш2б одной подписью — примеры V19–V36, вопрос 1 по рекомендации, «венок контрастнее» не выбран; перерыв после лимита — «Без перерыва»: ключ по умолчанию 0)
  <!-- спека — коммит 4c61d3c, подпись — этим отдельным коммитом до кода (L33); вопросы ведущего дословно — в decisions.md -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи); Ш3 добавляет ключ 120 Гц
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-shell-app
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон приложение ставится
       отдельным решением родителя в общей сессии теста -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=V29 reason=постоянное решение родителя 2026-10-23 на вопрос ведущего о телефонных проверках — «Да, всё в общую сессию (Рекомендую)»: экран в приложении, тап, «я всё», стоп, перерыв по ключу, системные полоски, 120 Гц и замер бюджета проверяются в общей сессии теста; код, тесты V19–V26, мутации, канарейки, сборка без подписи и оракул артефакта — зелёные by=human:anthony at=2026-10-23
- **new_dependency:** none
- **runtime_paths:** App/Sources/*.swift
  <!-- §12.6, один путь: экран в приложении — тело ChildScreen, перерыв в VoiceLoop, строка консоли; звук Audio/ и
       распознавание Speech/ не тронуты; исполняется на телефоне в общей сессии теста (решение родителя) -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- оболочка поверхность модели не трогает: экран рисует фазу сессии и ничего не говорит -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в общей сессии теста дочка с родителем видит Элли с венком на своём экране: тап будит, «я всё» кончает реплику, стоп возвращает консоль, после прощания по лимиту тап не будит до конца перерыва; до неё V19–V28 зелёные в каждом PR, покрытие ShellCore ≥ 70%
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
