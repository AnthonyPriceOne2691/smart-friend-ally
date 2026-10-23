# Active delivery status

- **slug:** child-shell
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик судит родитель на глаз по снимкам вида на Mac (П32); снимков экрана телефона нет никогда (L46) -->
- **human_ok_spec:** yes (by=human:родитель, at=2026-10-22, «Подписываю (Рекомендую)» через ведущего: примеры V1–V10, облик со снимков зонда — эталон серии, вопросы 1–7 по рекомендациям)
  <!-- спека — коммит 2285571, подпись — этим отдельным коммитом до кода (L33); снимки зонда ведущий скопировал в local/checkpoint/shell-snapshots/ основного клона -->
- **human_ok_plan:** yes (by=human:родитель, at=2026-10-22, «Подписываю (Рекомендую)»: три поставки Ш1 → Ш2 → Ш3, пробы с дочкой — после Ш3; вопрос 1)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- план: ShellCore — тесты и покрытие ≥ 70% на Linux (джоба swift); ShellUI — снимки и пиксельные пробы на Mac (локально и ручная джоба ios.yml) -->
- **artifact_oracle:** n/a reason=Ш1 не собирает приложение: пакет SwiftPM судят его тесты (ядро — Linux CI, рисунок — снимки на Mac), сборка не оракул (§6.5a); экран в бандле iOS — Ш3
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-shell
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- предохранитель решён 2026-10-23: родитель выбрал вариант A escalation.md — исключение только для Ш1; Ш3 — после мержа R child-lock -->
- **waivers:** max_loc_diff=1000 reason=рисунок Элли и его пробы целиком в Ш1 — факт net 946 при плане 621, вариант A escalation.md; только для Ш1, на серию не распространяется by=human:anthony (2026-10-23 «Исключение для Ш1 до 1000 (Рекомендую)», через ведущего)
- **new_dependency:** Packages/AllyShell/Package.swift reason=новый манифест SwiftPM без внешних зависимостей: ShellCore — Foundation и локальный ../AllyCore (фазы сессии SessionState), ShellUI — SwiftUI из SDK Apple под #if canImport(SwiftUI), тесты — XCTest из тулчейна; Rive, Lottie и другие библиотеки не берём (решение родителя 2026-10-22: 2D в SwiftUI) by=agent:claude-code
- **runtime_paths:** none reason=Ш1 — пакет SwiftPM: позы, раскладка и палитра проверяются тестами на Linux, рисунок — снимками вида на Mac; экран в приложении на телефоне (App/) появится в Ш3 и будет объявлен там
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** n/a reason=оболочка не трогает поверхность модели: промпт, реестр с пином и сэмплингом и пакет модели объявлены D1.2; экран только рисует фазу сессии и ничего не говорит
- **rule_enforcers:** n/a reason=model_surface не объявлена списком; правил речи оболочка не исполняет — их держат контракт хода и сессия (knowledge/engineering/safety-below-model.md)
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** после Ш3 в тесте родителя на телефоне четыре позы (спит, слушает, думает, говорит) узнаются на глаз в каждой сессии, скорость модели с экраном Элли не ниже 95% от консоли, footprint выше консоли не больше чем на 10 МБ; до этого V1–V10 зелёные в каждом PR, покрытие ShellCore ≥ 70%
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
