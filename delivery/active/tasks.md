# Tasks

## Slice 0 — подпись и предпосылка
- [ ] T0: родитель подтверждает список имён E5 (только «Элли») и подписывает спеку и план — `human_ok_spec`, `human_ok_plan`
- [ ] T1: D1.1 `voice-core` — ветка `feat/voice-core` от main, документы из раздела «Предпосылка» (примеры — таблицей,
  подпись — ссылкой на коммит этой спеки); `Packages/AllyCore`, тесты A1–A6 и A14–A18 с метками `// A<n>`; шаг сверки
  дайджеста A19 в `quality.yml` и запись в `adapted.json`; `LINT_SWIFT_PACKAGES` и jscpd видят `AllyCore`; CI зелёный; `merge_guard`
- [ ] T2: ребейз этой ветки на main с D1.1; `eval-smoke.md` — строки A7–A13, A20–A23 с командой и ожиданием, до кода

## Slice 1 — модель
- [ ] T3: `Packages/AllyLlama`: `binaryTarget` b10809 (checksum с `pragma: allowlist secret`), `LlamaModel` за `LanguageModel` —
  порт `LlamaEngine`, актор на своей очереди, поток `bufferingNewest(1)`, отмена на токене
- [ ] T4: `StandParityTests` (A23) на Mac: 37 из 37 при n_ctx 4096; число совпавших при 8192; без весов — пропуск видим

## Slice 2 — приложение
- [ ] T5: `App/project.yml`, `App/Ally.entitlements`, игнорируемый `App/Local.xcconfig` (`DEVELOPMENT_TEAM`), `.gitignore`
- [ ] T6: `App/Sources/Audio/` — сессия, разрешение микрофона, тап, полудуплекс, голос Milena по идентификатору (A12)
- [ ] T7: `App/Sources/Speech/` — `DictationTranscriber` ru-RU без загрузки ассета, строка готовности (A11)
- [ ] T8: `VoiceLoop` и консоль: готовность, срок подписи (A21), журнал хода без слов в `Caches/turns.jsonl` (A20)
- [ ] T9: ресурсы — персона v2.4 дословно (только после T0), `model.json`; снимок `delivery/model_surface.txt` (A22)

## Slice 3 — гейты
- [ ] T10: `.swiftlint.yml` — `included: App`, `no_network`, `blocking_wait`, `unbounded_stream`; роли `cpu-in-async` и
  `unbounded-list` в `not-applicable.json` словами разборщика карты ролей (L32); канарейки; jscpd и счётчик ратчета
  SwiftLint видят `App` и `AllyLlama`; доктор DEAD 0 (A7 — правило, A13)
- [ ] T11: `scripts/lint/check_app_artifact.sh` с канарейкой; `.github/workflows/ios.yml` — `workflow_dispatch`, macOS,
  `timeout-minutes`; запись в `adapted.json`; цена прогона в минутах (CQG §8.7) (A7, A8)

## Slice 4 — телефон
- [ ] T12: установка; шаги владельца — доверие сертификату (L15), лимит бесплатной подписи (зонды); веса командой концепта
- [ ] T13: прогоны A9, A10, A20 (20 ходов на динамике), A11 (авиарежим, 5 ходов), A12 (снимки экрана), A21; журнал и
  снимки — в `local/`, в отчёт — числа и команды

## Slice 5 — канон и сдача
- [ ] T14: концепт `engineering/voice-loop.md` с `implementation:`, ADR `engineering/app-architecture.md` (отказы плана),
  карта репозитория, реестр в `safety-below-model.md`, `knowledge/log.md` и индексы
- [ ] T15: инциденты наверх с `kind: upstream-candidate`: `.binaryTarget` в существующем манифесте гейт `new-dependency`
  не видит; `BUILD_MARKERS` не знает XcodeGen и Xcode — правило §6.5a у iOS-проекта молчит
- [ ] T16: verify-report — «Исполнение рисковых путей», «Изменение поверхности модели», дайджест, ссылка на CI и на ручную
  macOS-джобу; строгий `delivery_check --require-ci --diff-base origin/main` (L14)
- [ ] T17: сдача — архив, урок в INDEX, CLAUDE.md (снять устаревшую строку про `assert_digest_swift.py`); `merge_guard` — ведущий
