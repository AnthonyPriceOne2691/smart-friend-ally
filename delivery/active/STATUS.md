# Active delivery status

- **slug:** router-guard-load
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** S
- **kind:** bugfix
- **repro_test:** Packages/AllyDiscipline/Tests/DisciplineTests/RouterTests.swift::testDecisionIsFast
  <!-- падал под нагрузкой общего Mac: merge_guard #69 (load ≈ 25) и #71 (load 36–39) на S5; локально под nice -n 10 при
       load 63–67 — p95 0,063 с против порога 0,050 с дважды подряд, при load ≈ 7 — зелёный (разбор V3c, 2026-10-25) -->
- **diagnosis:** n/a reason=причина найдена прогонами 2026-10-25 — сторож меряет процессорное время на экономичных ядрах занятого Mac (nice и нагрузка выше числа P-ядер), а не решение маршрутизатора; R12 (p95 5 мс) судит release-реплей
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** n/a (класс S; поручение ведущего 2026-10-25 — сторож скорости отладочной сборки, R12 не меняется)
- **human_ok_plan:** n/a (класс S)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=поставка не собирает приложение: правка теста пакета SwiftPM
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-routerguard
- **parallel_sessions:** merge-guard,manual-deploy
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=правка только теста: продуктовый код маршрутизатора не меняется
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не трогает приложение и телефон
- **model_surface:** n/a reason=промпт и модель не меняются
- **rule_enforcers:** n/a reason=model_surface не объявлена списком
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** S5 в merge_guard не краснеет на `testDecisionIsFast` при занятом Mac (пропуск с причиной в логе); на CI сторож судит каждый PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
