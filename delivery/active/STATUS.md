# Active delivery status

- **slug:** duplex-audio
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony at=2026-10-25 «Подписываю (Рекомендую)» через ведущего — X18, X19; X9–X12 подписаны серией 2026-10-23, спека b7ef7b0, подпись e5c86ac)
  <!-- вопрос ведущего — черновик исполнителя: «Живой разговор, часть 2 (звук). Микрофон открыт, пока Элли говорит, её собственный голос вычитается. Что дочка сказала поверх Элли (последние 1,5 с), попадает в распознавание с первого слога. Перебиваний пока нет — только считаем, сколько раз она говорила поверх; в тихой комнате на 50 ответах ложных должно быть 0. Запасной голос Milena — по-старому. Подписываешь?» -->
  <!-- в таблице примеров X9–X12 перенесены из спеки серии без изменения смысла (L51); X13–X17 — D6.2 -->
- **human_ok_plan:** yes (by=human:anthony at=2026-10-25 «Подписываю (Рекомендую)» — план D6.1 вместе со спекой; ядро — до V4b2, телефонная часть — после мержа V4b2 voice-app и D7.3 gigaam-asr)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- X11, X18, X19 — тесты AllyCore на Linux (виртуальное время, синтетические кадры); X9, X10, X12 и телефонная
       часть X11 — телефон, общая сессия теста (постоянное решение родителя) -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-duplexaudio
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон — отдельным решением родителя.
       Код D6.1 — после мержа V4b2 voice-app (player голоса) и D7.3 gigaam-asr (PhoneListener); D6.2 — после D6.1 и D5 -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- порядок, а не затор: код — после мержа V4b2 voice-app (player голоса) и D7.3 gigaam-asr; до них — документы (T1) -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** App/Sources/Audio/
  <!-- §12.6, один рисковый путь на поставку (E1): движок звука — voice processing, аудиосессия .voiceChat, тап на сессию -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка меняет звук приложения; на телефон — отдельным решением родителя; отправки, трат и выкатки нет
- **model_surface:** n/a reason=языковая модель, промпт и реестр модели не меняются: поставка меняет только звук
- **rule_enforcers:** n/a reason=model_surface не объявлена списком
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в сессии теста: 0 наложений на 50 ответах в тихой комнате (X10), p95 «конец её речи → первый звук» ≤ 2,5 с и выбор AGC (X12), её речь поверх голоса — в распознавателе с первого слога (X11); в следе — этап `overlap` и версия `audio`; до неё X11, X18, X19 зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
