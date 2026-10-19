# Active delivery status

- **slug:** app-voice-loop
- **stack:** delivery@2.07, cqg@2.70, okf@1.21
- **class:** L
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** specify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** pending (спека D1.1 + D1.2 и список имён E5 — у родителя; подпись до первого кода)
- **human_ok_plan:** pending (класс L: родитель подписывает план вместе со спекой)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- логика хода — тесты AllyCore на Linux (предпосылка D1.1 voice-core); AllyLlama — паритет со стендом v2.4 на Mac (A23); код App — исполнение на телефоне (A9–A12, A20), не тесты -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app: сеть (nm -u, otool -L), ключи Info, права подписи; локально на подписанной сборке и в ручной macOS-джобе (E3)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-app
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением, а не следствием мержа -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: implement D1.2 начинается после подписи и после мержа предпосылки D1.1 voice-core (spec.md, «Предпосылка») -->
- **waivers:** max_runtime_paths=3 reason=решение родителя E1 2026-10-19 (AskUserQuestion ведущего): только для D1 — перенос в продукт настроек звука, распознавания и модели, исполненных зондом 17.10 на этом телефоне (local/spike/phone, knowledge/engineering/model-on-phone.md); пути App/Sources/Audio/, App/Sources/Speech/, Packages/AllyLlama/; предел 800 строк и 25 файлов не поднимается; дальше — один рисковый путь на поставку by=human:anthony at=2026-10-19
- **new_dependency:** Packages/AllyLlama/Package.swift reason=новый манифест SwiftPM: binaryTarget llama.cpp b10809 (xcframework релиза по url и checksum d6813b3b…, бинаря в git нет; тот же рантайм, что у зонда и стенда v2.4; iOS-срез линкует Foundation, Metal, Accelerate, сетевых символов в nm -u нет — проверено 2026-10-19); зависимость от ../AllyCore — локальный путь by=agent:claude-code
- **new_dependency:** llama.cpp-b10809 reason=рантайм модели на телефоне (решение 2026-10-17, knowledge/engineering/model-on-phone.md): E4B — 0,4–0,5 ГБ footprint из 6 ГБ, p95 до первого звука 1,9 с; LiteRT-LM отклонён — GPU-делегат закрыт, Swift API — превью; лицензия MIT (gh api repos/ggml-org/llama.cpp/license, L36), релиз 2026-09-04, sha256 ассета в API совпадает с файлом зонда; строка дублирует путь манифеста, потому что гейт new-dependency .binaryTarget не разбирает (dependency_manifests.py:252-262) by=agent:claude-code
- **runtime_paths:** App/Sources/Audio/,App/Sources/Speech/,Packages/AllyLlama/
  <!-- §12.6, три пути E1: звук (аудиосессия, права микрофона, голос), распознавание (DictationTranscriber), модель (Metal, mmap весов, лимит памяти). Ключи Info и entitlements судит оракул артефакта на хосте (plutil, codesign), консоль — исполняется A12 на каждом запуске -->
- **irreversible_surfaces:** none reason=продукт офлайн; установка на телефон родителя и копирование весов обратимы (удаление приложения) и идут отдельным решением вне мержа; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: промпт — персона v2.4 (sha256 329790cc…); пин и сэмплинг — реестр model.json (вес и его размер, n_ctx, сэмплинг 0,7/0,95/40/0,05, 256 токенов, seed 42, thinking выкл.); версия рантайма — binaryTarget b10809 в Package.swift; формат хода Gemma 4 и цепочка сэмплера — код AllyLlama. Схем инструментов, извлечения и схемы выхода нет; судьи — слепые агенты стенда вне git. Снимок — delivery/model_surface.txt -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: таблица «правило персоны v2.4 → исполнитель → статус»; D1.2 обновляет её: контракт зовётся на каждом ответе цикла, режим хода в D1 всегда talk (прощание задаст D2) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** A9, A10, A20 подтверждены в живых сессиях родителя за неделю после установки: доступно на старте ≥ 6000 МБ, пик footprint ≤ 700 МБ, p95 до первого звука ≤ 2,5 с, у каждого хода запись контракта без слов; до неё — паритет A23 и тесты ядра зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
