# Active delivery status

- **slug:** app-black-box
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-22, «Подписываю (Рекомендую)» под спекой серии чёрного ящика: ожидания D3.2 B13–B19 и ответы 1–8, delivery/archive/2026-10-23-black-box/spec.md)
  <!-- как D1.1 у D1.2: примеры D3.2 переезжают таблицей дословно из подписанной спеки серии, подпись — ссылкой на неё; документы — первым коммитом ветки, до кода (L33) -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- логика ящика — тесты AllyCore на Linux (D3), новая функция held() — там же; команда выгрузки и стирания — смоук S7 на двойнике devicectl; код App — сборка для устройства и оракул артефакта на Mac, поведение — исполнение на телефоне (B13–B19) -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи); сборка для устройства без подписи на Mac
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-appbox
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением родителя. Параллельно: R child-lock (VoiceLoop, консоль, audience, .github/allowed_signers), поставка голоса, оболочка -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: телефонные B13–B19 исполняются после мержа R (детская сессия supervised открывается исключением родителя) и при родителе; подпись поверхности стирания — палец родителя (ключ Secretive в .github/allowed_signers заводит R) -->
- **waivers:** max_runtime_paths=2 reason=подписанная серия чёрного ящика (ответ 8 родителя 2026-10-22): крючок её буфера в Phrase.feed у распознавателя (App/Sources/Speech/) рядом с хранилищем на телефоне (App/Sources/BlackBox/); распознавание не меняется by=human:anthony at=2026-10-22
- **new_dependency:** none
- **runtime_paths:** App/Sources/BlackBox/,App/Sources/Speech/
  <!-- §12.6: хранилище на телефоне (защита файлов NSFileProtectionComplete, пометка «не в бэкап» с чтением обратно) и отвод её буфера у распознавателя; оба исполняются только на телефоне -->
- **irreversible_surfaces:** стирание чёрного ящика на телефоне — команда python3 scripts/blackbox.py erase и кнопка консоли «Стереть чёрный ящик»; записи её голоса и текста вне бэкапа — копия есть только в local/blackbox после выгрузки
- **model_surface:** n/a reason=поставка не трогает промпт, реестр модели и пакет модели: приложение лишь подключает чёрный ящик вторым приёмником следа и отводит её буфер у распознавателя
- **rule_enforcers:** n/a reason=model_surface не объявлена списком; правил персоны поставка не добавляет
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** B13–B19 на телефоне родителя в первой детской сессии при родителе: файлы ящика под NSFileProtectionComplete вне бэкапа, записей ящика столько же, сколько строк следа, WAV у каждой услышанной реплики; выгрузка и стирание одной командой сверяют и стирают только выгруженное; до этого — смоук S7 и тесты AllyCore зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
