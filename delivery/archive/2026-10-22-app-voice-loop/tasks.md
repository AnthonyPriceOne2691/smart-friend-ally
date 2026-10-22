# Tasks

## Slice 0 — подпись и предпосылка
- [x] T0: родитель подтверждает список имён E5 (только «Элли») и подписывает спеку и план — `human_ok_spec`, `human_ok_plan`
  (родитель 2026-10-20 «Подписываю», коммит `3a5f8af`)
- [x] T1: D1.1 `voice-core` — ветка `feat/voice-core` от main, документы из раздела «Предпосылка» (примеры — таблицей,
  подпись — ссылкой на коммит этой спеки); `Packages/AllyCore`, тесты A1–A6 и A14–A18 с метками `// A<n>`; шаг сверки
  дайджеста A19 в `quality.yml` и запись в `adapted.json`; `LINT_SWIFT_PACKAGES` и jscpd видят `AllyCore`; CI зелёный; `merge_guard`
  (PR #33, сквош `bc5447c` 2026-10-22)
- [x] T2: ребейз этой ветки на main с D1.1; `eval-smoke.md` — строки A7–A13, A20–A24 с командой и ожиданием, до кода
  (не ребейз, а мерж `origin/main` — ветка уже на origin, без force-push; решение ведущего 2026-10-22)

## Slice 1 — модель
- [x] T3: `Packages/AllyLlama`: `binaryTarget` b10809 (checksum с `pragma: allowlist secret`), `LlamaModel` за `LanguageModel` —
  порт `LlamaEngine`, `swa_full`, 4 последовательности с общим KV, мастер-префикс и копия, файл состояния с ключом,
  актор на своей очереди, поток `bufferingNewest(1)`, отмена на токене; размеры KV в журнале llama.cpp сверены (448 МиБ)
  (2026-10-22: KV 128 + 320 = 448 МиБ при 8192, 64 + 160 при 4096; файл состояния 49,9 МБ)
- [x] T4: `StandParityTests` (A23) на Mac: токены промпта 37 из 37, ответы ≥ 35 из 37 при n_ctx 4096; число при 8192;
  без весов — пропуск видим (2026-10-22: токены 37 из 37; ответы 35 из 37 со сборкой префикса и 37 из 37 с префиксом
  из файла, при 4096 и 8192)

## Slice 2 — приложение
- [x] T5: `App/project.yml`, `App/Ally.entitlements`, игнорируемый `App/Local.xcconfig` (`DEVELOPMENT_TEAM`), `.gitignore`
- [x] T6: `App/Sources/Audio/` — сессия, разрешение микрофона, тап, полудуплекс, голос Milena по идентификатору (A12)
- [x] T7: `App/Sources/Speech/` — `DictationTranscriber` ru-RU без загрузки ассета, строка готовности (A11)
- [x] T8: `VoiceLoop` и консоль: готовность, срок подписи (A21), журнал хода без слов в `Caches/turns.jsonl` (A20)
- [x] T9: ресурсы — персона v2.4 дословно (только после T0), `model.json`; снимок `delivery/model_surface.txt` (A22)

## Slice 3 — гейты
- [x] T10: `.swiftlint.yml` — `included: App`, `no_network`, `blocking_wait`, `unbounded_stream`; роли `cpu-in-async` и
  `unbounded-list` в `not-applicable.json` словами разборщика карты ролей (L32); канарейки; jscpd и счётчик ратчета
  SwiftLint видят `App` и `AllyLlama`; доктор DEAD 0 (A7 — правило, A13)
- [x] T11: `scripts/lint/check_app_artifact.sh` с канарейкой; `.github/workflows/ios.yml` — `workflow_dispatch`, macOS,
  `timeout-minutes`; запись в `adapted.json`; цена прогона в минутах (CQG §8.7) (A7, A8)
  (2026-10-22: прогон 39831715919 по метке `macos` — зелёный за 67 с на macos-26, Xcode 26.6: A23 пропущен видимо,
  `.app` для устройства собран, оракул артефакта OK; цена — 2 мин macOS ×10 = 20 из 2000 бесплатных минут, раз на поставку)

## Slice 4 — телефон
- [x] T12: установка; шаги владельца — доверие сертификату (L15), лимит бесплатной подписи (зонды); веса командой концепта
  (2026-10-22: подпись Personal Team без новых окон доверия, занята 1 из 3 подписей — зонды не удалялись; веса 4,64 ГБ
  за 427 с; разрешение микрофона — родитель)
- [x] T13: прогоны A9, A10, A20 (20 ходов на динамике), A11 (авиарежим, 5 ходов), A12 (снимки экрана), A21, A24 (первый и
  второй запуск); журнал и снимки — в `local/`, в отчёт — числа и команды
  (2026-10-22: A9, A20, A21, A24 — пройдены; A10 — FAIL первого замера (p95 2,65 с), правка кадров 20 мс внесена;
  перемер A10, A11 и A12 — в первую сессию теста по решению родителя, waiver в STATUS)

## Slice 5 — канон и сдача
- [x] T14: концепт `engineering/voice-loop.md` с `implementation:`, ADR `engineering/app-architecture.md` (отказы плана),
  карта репозитория, реестр в `safety-below-model.md`, `knowledge/log.md` и индексы
- [x] T15: инциденты наверх с `kind: upstream-candidate`: `.binaryTarget` в существующем манифесте гейт `new-dependency`
  не видит; `BUILD_MARKERS` не знает XcodeGen и Xcode — правило §6.5a у iOS-проекта молчит
- [x] T16: verify-report — «Исполнение рисковых путей», «Изменение поверхности модели», дайджест, ссылка на CI и на ручную
  macOS-джобу; строгий `delivery_check --require-ci --diff-base origin/main` (L14)
  (2026-10-22: verify-report с блоками рисковых путей, поверхности модели, наблюдений родителя на слух; дайджест 3 из 3
  с примером)
- [x] T17: сдача — архив, урок в INDEX, CLAUDE.md (снять устаревшую строку про `assert_digest_swift.py`); `merge_guard` — ведущий
  (2026-10-22: архив `2026-10-22-app-voice-loop`, уроки L44, L45, L46 — поимённо (§2.2a), CLAUDE.md без новых строк)
