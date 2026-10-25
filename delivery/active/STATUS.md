# Active delivery status

- **slug:** barge-in
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** plan
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** deferred (reason=X13–X17 подписаны серией 2026-10-23 (спека b7ef7b0, подпись e5c86ac); вопрос 1 — откуда считать 0,3 с в X13 — у ведущего на подпись родителю пачкой 2026-10-25; до подписи — без кода)
  <!-- в таблице примеров X13–X17 перенесены из спеки серии без изменения смысла (L51) -->
- **human_ok_plan:** deferred (reason=план D6.2 — у ведущего на подпись родителю пачкой 2026-10-25; код — после мержа D6.1 duplex-audio и V4b2 voice-app)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- политика X13–X16 — тесты AllyCore на Linux (двойники, виртуальное время); время X13, тап X14, кашель X15,
       настоящие прерывания X16 и порт звука X17 — телефон, общая сессия теста (постоянное решение родителя) -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-bargein
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон — отдельным решением родителя.
       Код D6.2 — после мержа D6.1 duplex-audio (движок, кольцо, счётчик) и V4b2 voice-app (стоп голоса, порт звука) -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- порядок, а не затор: код — после мержа D6.1 и V4b2; до них — документы -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/Audio/
  <!-- §12.6, один рисковый путь на поставку (E1): прерывания аудиосессии и перезапуск движка звука -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка меняет поведение разговора в приложении; на телефон — отдельным решением родителя; отправки, трат и выкатки нет
- **model_surface:** n/a reason=языковая модель, промпт и реестр модели не меняются: отмена хода и память — путь D5
- **rule_enforcers:** n/a reason=model_surface не объявлена списком
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в сессии теста: голос замолкает в срок X13 (по ответу на вопрос 1), тап и кашель — как X14, X15, звонок и Siri — пауза и слушание после (X16); в следе — `barge_in` и `interrupted`; до неё X13–X16 (политика ядра) зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
