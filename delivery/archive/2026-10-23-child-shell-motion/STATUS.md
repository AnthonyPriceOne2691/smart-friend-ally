# Active delivery status

- **slug:** child-shell-motion
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик движения судит родитель на глаз по полосам кадров на Mac (П32); снимков экрана телефона нет никогда (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» через ведущего: примеры V11–V18 как есть)
  <!-- спека — коммит aae5951, подпись — этим отдельным коммитом до кода (L33); Ш2б и Ш3 подписываются как обычно -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=Ш2а не собирает приложение: пакет SwiftPM судят его тесты (ядро — Linux CI, кадры — Mac), сборка не оракул (§6.5a); экран в приложении — Ш3
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-shell-motion
- **parallel_sessions:** merge-guard,manual-deploy
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=Ш2а — пакет SwiftPM: движение — чистые функции и аниматор с тестами на Linux, кадры — снимки на Mac; экран на телефоне — Ш3
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** n/a reason=оболочка не трогает поверхность модели: экран рисует фазу сессии и ничего не говорит
- **rule_enforcers:** n/a reason=model_surface не объявлена списком; правил речи оболочка не исполняет
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** после Ш3 в тесте родителя на телефоне переходы между позами плавные (без рывков на глаз), моргание и зевок видны; до этого V1–V18 зелёные в каждом PR, покрытие ShellCore ≥ 70%
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
