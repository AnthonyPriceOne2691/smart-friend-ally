# Active delivery status

- **slug:** session-core
- **stack:** delivery@2.07, cqg@2.70, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** specify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** pending
  <!-- спека с примерами S1–S14 и три текста сессии ждут подписи родителя до кода (L33); итог передаёт ведущий -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет SwiftPM проверяют его тесты в CI на Linux, сборка не оракул (§6.5a); проводку в App и сборку несёт D2.2
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-session
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением, а не следствием мержа -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: ядро D2 от D1.2 не зависит; проводка сессии в App и переустановка одной командой (E4) — поставка D2.2 после мержа D1.2 app-voice-loop -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=ядро сессии — актор и чистые функции над протоколами модели, голоса и маршрутизатора: без экрана, прав, звука, железа и ввода-вывода; рисковый путь (переустановка на телефон) несёт D2.2
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни выкатки
- **model_surface:** n/a reason=поставка не трогает поверхность модели: промпт, реестр с пином и сэмплингом и пакет модели объявляет D1.2; тексты сессии — заготовки кода, в промпт не идут, подсказок модели нет
- **rule_enforcers:** n/a reason=model_surface не объявлена списком; реестр «правило персоны v2.4 → исполнитель» — таблица в knowledge/engineering/safety-below-model.md, D2 вписывает туда сессию: прощание кодом и режим goodbye
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** S1–S14 и покрытие AllyCore ≥ 70% зелёные в каждом PR; после D2.2 в живых сессиях родителя у каждой сессии одна запись следа на ход и причина конца (limit, goodbye_word, rest, parent), прощание по лимиту звучит не позже первого хода после 600 с
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
