# Active delivery status

- **slug:** voice-onnx
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** L
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** specify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** no
  <!-- подпись родителя под spec.md покрывает примеры всей серии V1–V4 (Z1–Z26); в таблице — только V1 (Z1–Z7), их гейт
       ищет в тестах этой поставки; V2–V4 переносят свои примеры таблицей в свои спеки со ссылкой на коммит спеки (L51) -->
- **human_ok_plan:** no
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z1 — страж в Linux-джобе quality; Z2–Z7 — тесты AllyOnnx и AllyVoice на Mac (ручная джоба ios и локально):
       двоичный ORT на Linux не собирается, как у AllyLlama -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — в V1 приложение не меняется; оракул нужен с V4, когда ORT войдёт в бинарь Ally.app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-voice
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением.
       Параллельно 23.10: слух (Silero VAD и GigaAM через sherpa-onnx — делит Packages/AllyOnnx, добавит туда sherpa и
       проверку пары версий своей поставкой), D3 black-box (порт VoiceTape — D3.3 возьмёт порт проигранного звука V4),
       R child-lock, оболочка, правки контракта, второй круг образцов голоса (local/spike/voice-samples-2) -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- код — после подписи родителя под spec.md и plan.md (L33: спека отдельным коммитом до кода); до неё фаза — specify -->
- **waivers:** none
- **new_dependency:** Packages/AllyOnnx/Package.swift reason=новый манифест SwiftPM: binaryTarget onnxruntime — официальный pod Microsoft onnxruntime-c 1.28.0 (download.onnxruntime.ai/pod-archive-onnxruntime-c-1.28.0.zip, sha256 b503cf59…a327; статический xcframework iOS, симулятор, macOS; ORT_API_VERSION 28 — как заголовки sherpa-onnx 1.13.8; бинаря в git нет); один ORT на приложение — решение ведущего 2026-10-23 by=agent:claude-code
- **new_dependency:** onnxruntime-1.28.0 reason=рантайм синтеза Supertonic и RUAccent на телефоне (стенд local/spike/tts-swift: паритет с Python −82,6 дБ на 1.24.2, RTF 0,21 на 2 потоках); лицензия MIT (gh api repos/microsoft/onnxruntime/license, 2026-10-23, L36), релиз v1.28.0 от 2026-07-25; строка дублирует путь манифеста, потому что гейт new-dependency .binaryTarget не разбирает by=agent:claude-code
- **new_dependency:** Packages/AllyVoice/Package.swift reason=новый манифест SwiftPM: движок синтеза за протоколом SpeechEngine, зависимость — локальный путь ../AllyOnnx by=agent:claude-code
- **runtime_paths:** Packages/AllyOnnx/
  <!-- §12.6, один путь: нативный рантайм вывода на устройстве — потоки, spin, отображение весов из файла, память. Движок
       AllyVoice — логика над ним; приложение и рисковые пути D1.2 (App/Sources/Audio/, App/Sources/Speech/,
       Packages/AllyLlama/) V1 не правит -->
- **irreversible_surfaces:** none reason=продукт офлайн; V1 не трогает приложение и телефон; веса — копии файлов на Mac вне git; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; синтез речи — не она, V1 промпт, реестр и пакет модели не меняет -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: V1 правил персоны не исполняет; правила произношения и знаки ударения — V2, они живут ниже модели, на входе
       движка, и войдут в реестр с V4, когда голос подключится к живому ходу (L50) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** Z2 (паритет ≥ 60 дБ) и Z6 (медиана ≤ 1,3 с) повторяются в ручной джобе ios на каждом бампе ORT; с V4 — p95 speech_end_to_sound ≤ 2,5 с и прирост отпечатка ≤ 0,4 ГБ в живых сессиях родителя
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
