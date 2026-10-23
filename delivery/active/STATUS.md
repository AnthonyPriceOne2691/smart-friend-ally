# Active delivery status

- **slug:** voice-onnx
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** L
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-23 «Подписываю (Рекомендую)», by=human:anthony; вопрос ведущего дословно: «Голос Элли: описание работы готово, это серия из 4 частей. (1) Движок голоса на телефоне и общая основа для голоса и слуха. (2) Произношение: ударения, «сево́дня», «но́вова», «Элли» — только для голоса, тексты не меняются. (3) Расстановщик ударений на телефоне. (4) Голос в приложении вместо Milena: «тоньше» (подъём высоты), первая фраза звучит не позже чем через 2,5 с после её речи. Сам голос и таблица произношения подставятся одной строкой после второго круга образцов. Пока файлов голоса на телефоне нет, звучит Milena, и в консоли видно, чего не хватает. Первая фраза — 8 шагов (качественнее), если укладываемся в 2,5 с, иначе 5 шагов. Подписываешь?»; вопросы спеки 3–5 — по рекомендациям, 1–2 ждут второй круг образцов)
  <!-- подпись покрывает примеры всей серии (Z1–Z26, спека — коммит 68202f0). V1 вышла 903 строки против плана 720 —
       ведущий 2026-10-23 разрезал её на V1a voice-onnx (эта поставка, AllyOnnx и страж, пример Z1) и V1b voice-engine
       (движок, Z2–Z7) по готовым коммитам, вариант A escalation.md: содержание подписанного то же, разбито мельче.
       V2 voice-text ведёт отдельный исполнитель (ветка feat/voice-text); каждая поставка переносит свои примеры таблицей
       в свою спеку со ссылкой на 68202f0 (L51) -->
- **human_ok_plan:** yes (та же подпись 2026-10-23; ведущий: строки V1 — вариант (а), план ≈ 720, стоп-линия 780 — выше escalation.md и к ведущему, не исключение)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- Z1 — страж в Linux-джобе swift с отрицательным контролем; тесты AllyOnnx — на Mac (ручная джоба ios и локально):
       двоичный ORT на Linux не собирается, как у AllyLlama -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — в V1a приложение не меняется; оракул нужен с V4, когда ORT войдёт в бинарь Ally.app
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
- **new_dependency:** Packages/AllyOnnx/Package.swift reason=новый манифест SwiftPM: binaryTarget onnxruntime — официальный pod Microsoft onnxruntime-c 1.28.0 (download.onnxruntime.ai/pod-archive-onnxruntime-c-1.28.0.zip, sha256 b503cf59…a327; статический xcframework iOS, симулятор, macOS; ORT_API_VERSION 28 — как заголовки sherpa-onnx 1.13.8; бинаря в git нет); один ORT на приложение — решение ведущего 2026-10-23 by=agent:claude-code
- **new_dependency:** onnxruntime-1.28.0 reason=рантайм синтеза Supertonic и RUAccent на телефоне (стенд local/spike/tts-swift: паритет с Python −82,6 дБ на 1.24.2, RTF 0,21 на 2 потоках); лицензия MIT (gh api repos/microsoft/onnxruntime/license, 2026-10-23, L36), релиз v1.28.0 от 2026-07-25; строка дублирует путь манифеста, потому что гейт new-dependency .binaryTarget не разбирает by=agent:claude-code
- **runtime_paths:** Packages/AllyOnnx/
  <!-- §12.6, один путь: нативный рантайм вывода на устройстве — потоки, spin, отображение весов из файла, память.
       Вызывающий AllyOnnx появится в V1b — движок Supertonic (L50); слух подключит его своей поставкой. Приложение и
       рисковые пути D1.2 (App/Sources/Audio/, App/Sources/Speech/, Packages/AllyLlama/) V1a не правит -->
- **irreversible_surfaces:** none reason=продукт офлайн; V1a не трогает приложение и телефон; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность языковой модели объявила D1.2; V1a промпт, реестр и пакет модели не меняет -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: V1a правил персоны не исполняет; правила произношения и знаки ударения — V2, они войдут в реестр с V4,
       когда голос подключится к живому ходу (L50) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** страж Z1 зелёный в каждом PR, в том числе в поставке слуха, которая добавит binaryTarget sherpa в AllyOnnx; тесты AllyOnnx в ручной джобе ios на каждом бампе ORT
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
