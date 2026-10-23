# Active delivery status

- **slug:** app-black-box
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
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
  <!-- зависимость, а не остановка: телефонные B13–B19 — в общей сессии теста (waiver ниже); подпись поверхности стирания — касание родителя: строку ключа Secretive в .github/allowed_signers кладёт эта ветка (D3.2 — первая поставка, которой он нужен для мержа), затем родитель запускает sign_irreversible.sh; архив — после касания: скрипт подписывает строку из delivery/active/STATUS.md, подпись уезжает с поставкой (§2.3a) -->
- **waivers:** max_runtime_paths=2 reason=подписанная серия чёрного ящика (ответ 8 родителя 2026-10-22): крючок её буфера в Phrase.feed у распознавателя (App/Sources/Speech/) рядом с хранилищем на телефоне (App/Sources/BlackBox/); распознавание не меняется by=human:anthony at=2026-10-22; acceptance=B13,B14,B15,B16,B17,B18,B19 reason=родитель 2026-10-23 на вопрос ведущего: «Чтобы не дёргать тебя по каждой части: все проверки на телефоне относить в одну общую сессию теста с тобой, а сливать каждую часть по зелёным проверкам на Mac и GitHub, не спрашивая каждый раз? Подписи касанием (детский режим, стирание записей) всё равно остаются только за тобой.» — ответ «Да, всё в общую сессию (Рекомендую)»: телефонные части B13–B19 (сессия на телефоне, pull, erase, кнопка консоли) — в общую сессию теста; на Mac B15, B16 — смоук S7, B17 — тест, сборка без подписи, оракул артефакта и CI — зелёные; подпись поверхности стирания касанием — за родителем by=human:anthony at=2026-10-23
- **new_dependency:** none
- **runtime_paths:** App/Sources/BlackBox/,App/Sources/Speech/
  <!-- §12.6: хранилище на телефоне (защита файлов NSFileProtectionComplete, пометка «не в бэкап» с чтением обратно) и отвод её буфера у распознавателя; оба исполняются только на телефоне -->
- **irreversible_surfaces:** стирание чёрного ящика на телефоне — команда python3 scripts/blackbox.py erase и кнопка консоли «Стереть чёрный ящик»; записи её голоса и текста вне бэкапа — копия есть только в local/blackbox после выгрузки
- **model_surface:** n/a reason=поставка не трогает промпт, реестр модели и пакет модели: приложение лишь подключает чёрный ящик вторым приёмником следа и отводит её буфер у распознавателя
- **rule_enforcers:** n/a reason=model_surface не объявлена списком; правил персоны поставка не добавляет
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** B13–B19 в общей сессии теста с родителем (его решение 2026-10-23): файлы ящика под NSFileProtectionComplete вне бэкапа, записей ящика столько же, сколько строк следа, WAV у каждой услышанной реплики; выгрузка и стирание одной командой сверяют и стирают только выгруженное; до этого — смоук S7 и тесты AllyCore зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
