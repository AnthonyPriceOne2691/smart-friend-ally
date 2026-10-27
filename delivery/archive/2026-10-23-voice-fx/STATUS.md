# Active delivery status

- **slug:** voice-fx
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony; вопрос ведущего дословно: «Голос «Совсем малышка» в приложении. Исполнитель проверил: быстрая черновая версия обработки даёт лёгкий дребезг. Он делает свой следящий за высотой голоса — тогда на телефоне голос звучит так же чисто, как образец, который ты выбрал (по замерам один в один). Дальше голос встаёт в приложение вместо Milena с «Э́льли» и «сево́дня», а в сессии теста ты слушаешь: нет ли металла и «бурундука». Подписываешь?»; вариант «брать черновую обработку как есть» не выбран)
  <!-- серия голоса подписана родителем 2026-10-23 (спека 68202f0); после третьего круга образцов V4 разбита на V4a
       voice-fx (обработка PSOLA + эквалайзер, эта поставка) и V4b voice-app (приложение). Эта подпись покрывает
       примеры Z27–Z31 и правки V4b Z19–Z22, Z26 (спека — коммиты bf827a4, 24d1cec). Правка после подписи —
       ответом родителя 2026-10-23 «Резать: эквалайзер — в следующую часть»: Z29 и полный Z30 уехали в V4b,
       Z30 здесь — PSOLA против выхода стенда без эквалайзера -->
- **human_ok_plan:** yes (та же подпись 2026-10-23; план ≈ 640 строк, стоп-линия 780 — выше escalation.md и к ведущему)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z27, Z28, Z31 — тесты AllyVoiceFX на Linux (джоба swift, покрытие ≥ 70%); Z30 — замеры дребезга на стенде Mac против выхода стенда без эквалайзера -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — в V4a приложение не меняется; оракул нужен с V4b
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice-fx
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh. Параллельно: V3 voice-accent (RUAccent, исполнитель V2),
       слух, память и другие поставки ведущего -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- предохранитель 824 > 800 снят разрезом: родитель 2026-10-23 «Резать: эквалайзер — в следующую часть»
       (escalation.md, вариант B); эквалайзер и Z29 — в V4b -->
- **waivers:** none
- **new_dependency:** Packages/AllyVoiceFX/Package.swift reason=новый манифест SwiftPM: обработка голоса после синтеза — своё TD-PSOLA (порт алгоритма стенда dsp.py на C со своим автокорреляционным трекером), эквалайзер — V4b; только Foundation и C, внешних зависимостей нет by=agent:claude-code
- **runtime_paths:** none reason=обработка — чистая функция над отсчётами, без платформы, прав и железа; воспроизведение и тракт звука — V4b
- **irreversible_surfaces:** none reason=продукт офлайн; V4a не трогает приложение и телефон; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; V4a её не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: V4a правил персоны не исполняет -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z27, Z28, Z31 зелёные в каждом PR (Linux); цена обработки на телефоне — этап voice_fx в журнале хода с V4b
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
