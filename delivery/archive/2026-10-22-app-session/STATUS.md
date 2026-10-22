# Active delivery status

- **slug:** app-session
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-22 «Подписываю (Рекомендую)»; вопросы 1–9 decisions.md — по рекомендациям; разбиение D2.2 → R → R2 принято)
  <!-- одна подпись на обе поставки, как у D1 (D1.1 + D1.2): в таблице примеров только W — их гейт ищет в тестах D2.2;
       G — списком, R переносит их таблицей в свою спеку со ссылкой на коммит этой (L33, L51); спека — коммит 0ffd2df,
       подпись — отдельным коммитом до кода -->
- **human_ok_plan:** yes (родитель 2026-10-22 «Подписываю (Рекомендую)»; исключение R — касанием в Secretive на Mac, срок ≤ 7 дней)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- W1–W7 — тесты AllyCore на Linux (драйвер сессии, маршрутизатор, след); код App и переустановка — исполнение на
       телефоне родителя (W8–W11), не тесты -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный подписанный .app (сеть, ключи Info, права подписи); переустановка E4 гоняет его до установки на телефон
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-wiring
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением
       родителя. Параллельно: D1.2 app-voice-loop (сливается — код App), поставка голоса (VoiceOutput, VoiceLoop.swift),
       спеки D3 black-box и «оболочки» (детский экран) — их стык описан в spec.md, «Контракт слоя экрана» и «Стыки» -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- D1.2 влита слиянием main (ca2befe → 7276a0c); R child-lock — отдельной веткой после мержа D2.2 (завтра) -->
- **waivers:** acceptance=W8,W9,W10,W11 reason=решение родителя 2026-10-22 «Сливать, проверим потом»: телефонные примеры W8–W11 (сессия в консоли, маршрутизатор на телефоне, стоп, переустановка E4 на телефоне) отложены до первой сессии теста вместе с A10–A12 D1.2; код, тесты W1–W7, мутации, сборка без подписи, оракул артефакта и CI — зелёные; отрицательный путь E4 (чужой UDID) исполнен на Mac by=human:anthony at=2026-10-22
- **new_dependency:** none
- **runtime_paths:** scripts/reinstall_app.sh
  <!-- §12.6, один путь (E1: дальше — один рисковый путь на поставку): переустановка на телефон поверх со сверкой
       контейнера (E4). Рисковые пути D1.2 — App/Sources/Audio/, App/Sources/Speech/, Packages/AllyLlama/ — D2.2 не
       правит: сессия открывает микрофон через прежний API AudioIO (decisions.md, вопрос 8) -->
- **irreversible_surfaces:** none reason=продукт офлайн; переустановка ставит поверх и не удаляет контейнер, идёт отдельным решением родителя вне мержа; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность модели проекта объявила D1.2; D2.2 её не трогает — маршрутизатор решает до модели, сессия
       зовёт модель через прежний TurnRunner, промпт, реестр и пакет модели не меняются; блок «Изменение поверхности
       модели» в verify-report не нужен, пока дифф их не задел -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: реестр «правило персоны v2.4 → исполнитель → статус»; D2.2 вписывает туда маршрутизатор на живом ходе
       и правило forget (реплика с флагом к модели не идёт) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** W8–W11 в первой сессии теста (отложены словом родителя), затем в живых сессиях родителя: одна запись следа на ход, причина конца у последней, на «Дай мне спички» и её адрес — `script:matches` и `script:pii` с `forget`; p95 `speech_end_to_sound` ≤ 2,5 с (отложенная A10 D1.2); переустановка E4 раз в 7 дней без потери весов; до неё W1–W7 и покрытие AllyCore ≥ 70% зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
