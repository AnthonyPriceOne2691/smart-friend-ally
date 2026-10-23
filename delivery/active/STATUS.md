# Active delivery status

- **slug:** turn-detector
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23; «Подписываю (Рекомендую)» через ведущего — примеры U1–U28, вопросы 1–8 по рекомендациям decisions.md)
  <!-- подпись родителя под spec.md покрывает примеры всей серии «слух»: U1–U6 (таблица) — D7, их гейт ищет в тестах
       этой поставки; U7–U28 (список) — D7.1–D7.3, каждая переносит свои таблицей в свою спеку со ссылкой на коммит этой
       спеки (L51); подпись — отдельным коммитом до кода (L33) -->
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23; «Подписываю (Рекомендую)» — серия из четырёх поставок, бюджеты и порядок plan.md)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- U1–U5 — тесты AllyCore на Linux (тип хода, сессия, реестр слуха, «я всё», предел); проводка App — исполнение на
       телефоне родителя (U6), не тесты; поверхность модели (model.json) — A23 на Mac -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи); hearing.json едет ресурсом бандла
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-speechin
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением
       родителя. Параллельно 23.10: голос V1 voice-onnx (Packages/AllyOnnx; V4 правит PhoneListener.firstSound),
       R child-lock и «оболочка» (тап по Элли — done() из контракта экрана), D3.2 app-black-box (её звук у
       распознавателя), правки контракта, память — стыки в spec.md, «Стыки с параллельными поставками» -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- подпись родителя 2026-10-23 — отдельным коммитом до кода (L33); код — после eval-smoke.md, фаза implement -->
- **waivers:** acceptance=U6 reason=ответ 8 родителя в подписи серии 2026-10-23: проверки на телефоне — дважды, первая после D7.1 вместе с U14–U15; код, тесты U1–U5, мутации, A23, сборка без подписи и оракул артефакта — зелёные by=human:anthony at=2026-10-23
- **new_dependency:** none
- **runtime_paths:** none reason=звук и распознавание (App/Sources/Audio/, App/Sources/Speech/) и пакет модели не тронуты: хвост по типу хода — параметр определителя ядра, «я всё» — флаг определителя, оба с тестами на Linux; проводка PhoneListener, VoiceLoop и консоли проверяется на телефоне примером U6, как проводка D2.2
- **irreversible_surfaces:** none reason=продукт офлайн; D7 меняет код и реестр слуха; на телефон ставится отдельным решением родителя вне мержа; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность модели объявила D1.2; D7 убирает из model.json только ключи слуха (turn, listen_timeout) —
       модель их не читает; блок «Изменение поверхности модели» в verify-report и A23 на Mac (ответы модели те же) -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: D7 правил персоны не исполняет; спекуляция D7.1 впишет туда «к модели не идёт реплика, которую не пустил бы
       ход» -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** U6 в сессии теста: turn_kind в turns.jsonl совпадает с типом последней фразы Элли, пауза 1,2 с после открытого вопроса не обрывает фразу, «Я всё» кончает ход ≤ 0,1 с (turn_done); до неё U1–U5 и покрытие AllyCore ≥ 70% зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
