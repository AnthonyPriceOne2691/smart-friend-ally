# Active delivery status

- **slug:** voice-engine
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** L
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony; вопрос ведущего дословно: «Голос Элли: описание работы готово, это серия из 4 частей. (1) Движок голоса на телефоне и общая основа для голоса и слуха. (2) Произношение: ударения, «сево́дня», «но́вова», «Элли» — только для голоса, тексты не меняются. (3) Расстановщик ударений на телефоне. (4) Голос в приложении вместо Milena: «тоньше» (подъём высоты), первая фраза звучит не позже чем через 2,5 с после её речи. Сам голос и таблица произношения подставятся одной строкой после второго круга образцов. Пока файлов голоса на телефоне нет, звучит Milena, и в консоли видно, чего не хватает. Первая фраза — 8 шагов (качественнее), если укладываемся в 2,5 с, иначе 5 шагов. Подписываешь?»; вопросы спеки 3–5 — по рекомендациям, 1–2 ждут второй круг образцов)
  <!-- подпись покрывает примеры всей серии (Z1–Z26, спека — коммит 68202f0). V1 вышла 903 строки против плана 720 —
       ведущий 2026-10-23 разрезал её на V1a voice-onnx (сдана, AllyOnnx и страж, Z1) и V1b voice-engine (эта поставка,
       движок, Z2–Z7) по готовым коммитам, вариант A escalation.md: содержание подписанного то же, разбито мельче.
       V2 voice-text ведёт отдельный исполнитель (ветка feat/voice-text); каждая поставка переносит свои примеры таблицей
       в свою спеку со ссылкой на 68202f0 (L51) -->
- **human_ok_plan:** yes (та же подпись 2026-10-23; ведущий: строки V1 — вариант (а), план ≈ 720, стоп-линия 780 — выше escalation.md и к ведущему, не исключение)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z2–Z7 — тесты AllyVoice на Mac (ручная джоба ios и локально; без весов и эталонов в ~/models — пропуск, П34):
       двоичный ORT на Linux не собирается, как у AllyLlama; Z6 — в тихое окно Mac, которое устраивает ведущий -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — в V1b приложение не меняется; оракул нужен с V4, когда движок войдёт в бинарь Ally.app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением.
       Параллельно 23.10: слух (Silero VAD и GigaAM через sherpa-onnx — делит Packages/AllyOnnx, добавит туда sherpa и
       проверку пары версий своей поставкой), D3 black-box (порт VoiceTape — D3.3 возьмёт порт проигранного звука V4),
       R child-lock, оболочка, правки контракта, второй круг образцов голоса (local/spike/voice-samples-2) -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- подпись — отдельным коммитом до кода (L33); спека 68202f0, план bbcd6b3 -->
- **waivers:** none
- **new_dependency:** Packages/AllyVoice/Package.swift reason=новый манифест SwiftPM: движок синтеза за протоколом SpeechEngine, зависимость — локальный путь ../AllyOnnx (один ORT, V1a); веса Supertonic не в git (~/models на Mac, папка голоса на телефоне — V4); модель Supertonic 3 — OpenRAIL-M (карточка HF, 2026-10-23), код supertonic-py, по которому сверен разбор текста, — MIT by=agent:claude-code
- **runtime_paths:** none reason=движок — логика над AllyOnnx; рантайм, потоки, spin и отображение весов — рисковый путь V1a (Packages/AllyOnnx/), приложение V1b не правит
  <!-- §12.6: V1b — логика движка над AllyOnnx (рантайм, потоки, spin и отображение весов — рисковый путь V1a). Приложение
       и рисковые пути D1.2 V1b не правит; движок войдёт в приложение с V4 — до того у него нет вызывающего (L50) -->
- **irreversible_surfaces:** none reason=продукт офлайн; V1b не трогает приложение и телефон; веса — копии файлов на Mac вне git; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; синтез речи — не она, V1b промпт, реестр и пакет модели не меняет -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: V1b правил персоны не исполняет; знаки ударения и правила чтения — V2, они войдут в реестр с V4, когда голос
       подключится к живому ходу (L50) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z2 (паритет ≥ 60 дБ) и Z6 (медиана ≤ 1,3 с) повторяются в ручной джобе ios и локально на каждом бампе ORT; с V4 — p95 speech_end_to_sound ≤ 2,5 с и прирост отпечатка ≤ 0,4 ГБ в живых сессиях родителя
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
