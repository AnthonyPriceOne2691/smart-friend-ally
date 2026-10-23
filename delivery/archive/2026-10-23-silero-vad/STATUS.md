# Active delivery status

- **slug:** silero-vad
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23; «Подписываю (Рекомендую)» через ведущего — примеры U16–U21 в спеке серии «слух», подпись 3b68733, спека 74ada91)
- **human_ok_plan:** yes (by=human:anthony, at=2026-10-23; план серии «слух» с бюджетом D7.2 ≈ 380, подпись 3b68733; поправка +50% и стоп 780 — поручение ведущего 2026-10-23)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-silero
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция только через scripts/merge_guard.sh; на телефон — решением родителя. Параллельно: D7.1
       (TurnDetector, PhoneListener — стыки согласованы через ведущего 2026-10-23), D3.2 (PhoneListener, VoiceLoop),
       серия голоса (AllyOnnx); слияние main — сложением, после мержа D7.1 -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** acceptance=U20,U21 reason=ответ 8 родителя в подписи серии «слух» 2026-10-23 на вопрос ведущего («… Проверки на телефоне — дважды: после части 2 и после части 4. Подписываешь?» — «Подписываю (Рекомендую)»): Silero и GigaAM (U20, U21, U28) — после D7.3, в сессии теста; постоянное решение родителя 2026-10-23 — все проверки на телефоне в общую сессию теста, сливаем по зелёным Mac и GitHub («Да, всё в общую сессию (Рекомендую)»); код, тесты U16–U19 на Mac и Linux, 9 мутаций, сборка без подписи и оракул артефакта — зелёные; без модели Silero на телефоне слух — энергия со строкой в консоли by=human:anthony at=2026-10-23
- **new_dependency:** Packages/AllyHearing/Package.swift reason=новый манифест SwiftPM без внешних пакетов: AllyHearing — Silero VAD через C API sherpa-onnx (библиотека AllySherpa из ../AllyOnnx) и активность для определителя ../AllyCore; AVFoundation — из SDK; сторонних библиотек не берём by=agent:claude-code
- **new_dependency:** sherpa-onnx-1.13.8 reason=Silero VAD на телефоне (решение ведущего 2026-10-23, снятие риска local/spike/speech-in-ort: флаги спайка 1434 из 1434 на официальном ORT 1.28.0); статические xcframework релиза k2-fsa iOS и macOS по url и checksum (6b8e769c…, 93f7a064…), ORT внутри нет — линкуется рантайм AllyOnnx; лицензия Apache-2.0 (gh api repos/k2-fsa/sherpa-onnx/license, 2026-10-23, L36), релиз v1.13.8 от 2026-09-10; строка дублирует путь манифеста, потому что гейт new-dependency .binaryTarget не разбирает by=agent:claude-code
- **runtime_paths:** Packages/AllyHearing/
  <!-- §12.6, один путь (решение ведущего): Silero через C API sherpa на устройстве, ресемплер буферов тапа, создание
       VAD из файла моделей — исполнение на телефоне (U20, U21); binaryTarget в AllyOnnx судят сборка iOS и U16 на Mac;
       App/Sources/Audio/ и App/Sources/Speech/ не тронуты -->
- **irreversible_surfaces:** none reason=продукт офлайн; поставка меняет слух ядра и приложения; модель Silero копируется на телефон командой родителя; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: D7.2 поверхность модели не трогает — модель получает ту же реплику; меняется только, кто решает конец речи -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** U20, U21 в сессии теста: прирост footprint от Silero ≤ 40 МБ, окно p95 ≤ 2 мс, 0 из 10 обрывов в тишине; до неё U16–U19 зелёные на Mac и в CI, строка консоли «слух: …» при каждом запуске
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
