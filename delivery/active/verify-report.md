# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; N1–N10 подписаны родителем 2026-10-29)
**CI run:** quality — https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40949719069; macOS-джоба по метке `macos` — https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40949732420 (на 02bcdff; первые прогоны — 40943703654 и 40944046395)
**Commit:** слияние main с child-open (88e9920) поверх 32bdcfa; до него memory-forget (02bcdff), card-fallback (832849c), design-demo (d6268d6); спека — e91d0bf, подпись — a3e6c1e, eval-smoke до кода — a99974b, код и знание — 677dbc6, уроки — 1571889, main с design-demo — d6268d6; macOS-джоба перезапущена меткой на каждом изменении кода приложения

**Статус: verify, N9 открыт.** Первый ход на Mac родитель перенёс на 2026-10-30 («Потом» — когда Mac не занят отбором
моделей на GPU): функциональный ход и чистый замер — одним заходом. До него поставка не сдаётся.

## Shape oracles
- [x] PASS — pre-commit на каждом коммите: `file-length`, jscpd — рост 0, SwiftLint — ратчет 0 (после выноса текстов
  импорта в `mac_import.json` по правилу `inline_prompt`), секреты (хэш «abc» FIPS 180-2 в тесте — с пометкой
  `pragma: allowlist secret`), данные ребёнка, `gate-coverage`
- [x] PASS — `okf_validate.py`: 0 ошибок (53 файла); `okf_sync_gate.py --staged`: 19 концептов сверены. В том же диффе
  правлены `engineering/voice-loop`, `engineering/voice-engine`, `engineering/safety-below-model` (пути в
  `implementation:`), новое решение `engineering/mac-run`, `ops/child-data`, `references/repo-map`, индекс, `log.md`
- [x] PASS — `delivery_check --diff-base origin/main`: 0 ошибок; предохранитель — 12 файлов, net 562 из 800 (план ≈ 600,
  с поправкой ≈ 750). Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а
  реляционные оракулы здесь — N2 (идемпотентность: повтор раскладки ничего не переписывает, ожидаемых значений нет) и
  N8 (две записи одного хода — файл и журнал — совпадают строка в строку)

## Behavior oracles
- [x] PASS — `swift test` `AllyCore` на Mac (Xcode 27.1, macOS 27.2, под `nice -n 10`): 143 из 143, после слияния main с
  card-fallback — 154 из 154; из них новые
  `MacImportTests` 5 (N4–N7, N6 — и подменный хэш, и CryptoKit) и `TraceLineTests` 1 (N8). CI на Linux, джоба `swift`
  (run 40943703654): `AllyCore` — 38 файлов `Sources/`, строк 2343 из 2420, 96% (порог 70%, свой каталог — L41);
  `gates` — pre-commit STRICT зелёный, smoke `PASS S9`; `delivery` — зелёный
- [x] PASS — мутации в ту же сессию (по видимому эффекту, L64), 7 из 7 убиты, файлы восстановлены:
  - N6 «копия без сверки хэша» — `XCTAssertThrowsError failed: did not throw`;
  - N7 «кнопка видна на телефоне» (`onMac && asleep` → `asleep`) — `XCTAssertFalse failed`;
  - N5 «чужой путь пропущен» и «размер не сверяется» — строки отказа не пришли;
  - N8 «приёмник пишет и слова» (свой `write(_:words:)` с услышанным) — строки журнала разошлись с файлом, кириллица;
  - S9 «запись в контейнер не остановлена» (под временным `HOME`) и «повтор переписывает всё» — FAIL N3 и FAIL N2
- [x] PASS — smoke S9 `delivery/evals/smoke/mac_files_check.sh` локально и в `run.sh` CI
- [x] PASS — сборки на Mac: «My Mac (Designed for iPhone)» с подписью Personal Team (Mac в профиле до 05.11 21:59 МСК,
  право `increased-memory-limit` на месте) и `generic/platform=iOS` без подписи — BUILD SUCCEEDED (и после слияния main
  с design-demo); оракул артефакта — OK

## Product oracles

| id | Факт |
|---|---|
| N1 | на Mac `mac_files.py`: 28 файлов, 5 501 485 523 байт за 5,12 с; `df` — минус 12 172 КБ (распакованные словари); sha256 весов = пин |
| N2 | повтор — «без изменений: 28», время изменения файлов то же |
| N3 | S9: стоп с именем до записи; в контейнер — отказ, каталог не создан |
| N4 | `MacImportTests` на настоящих реестрах: 28 = 26 + 2; настоящий импорт папки в контейнер — в первом ходе 2026-10-30 |
| N5 | все отказы строками спеки, ничего не скопировано |
| N6 | копия под временным именем, старый файл цел при несовпадении, `Memory/` не тронут |
| N7 | телефон — кнопки нет никогда, Mac — только пока спит |
| N8 | строка журнала = строка файла следа, без слов и кириллицы |
| N9 | **открыт** — первый ход на Mac 2026-10-30: родитель ⌘R, «Файлы с Mac…», «Разбудить»; синтетика `say`, `log show`, чистое окно без отбора моделей |
| N10 | телефон: сборка без подписи и оракул — OK; пакет модели, `model.json`, `reinstall_app.sh` не тронуты |

## Исполнение рисковых путей

- `App/Sources/` — исполнено до кода и в сборке: `xcodebuild … -destination 'platform=macOS,arch=arm64,id=…'
  -allowProvisioningUpdates build` — подпись прошла, Mac внесён в профиль; запуск обёртки `open …/Wrapper/Ally.app` и
  прямой запуск бинаря — убиты Gatekeeper (`Terminating process due to Gatekeeper rejection`, `Code did not match any
  currently allowed policy`), процесс жил 3,7 с с пределом памяти 16 ГБ; оболочке агентов контейнер закрыт (TCC
  `SystemPolicyAppDataDetailed`, `authValue=0`). Сам первый ход из Xcode (выбор папки, копия, микрофон, диктовка, Metal,
  звук) — **не исполнен**: перенесён родителем на 2026-10-30, строка допишется на сдаче. at=2026-10-29

## Spec coverage gaps
- **N9 и настоящий импорт N4 на Mac** — 2026-10-30, одним заходом с чистым замером (слово ведущего: до 00:00 на GPU
  идёт отбор моделей).
- **macOS-джоба CI** проверяет пакеты и сборку `.app` без подписи; подпись и запуск на Mac — только кнопкой родителя в
  Xcode (Gatekeeper), CI этого не видит по построению.

## Ревью рисковых мест

- **Безопасность** (маячок — слово `secret`): это пометка детектора секретов у известного хэша «abc» FIPS 180-2 в
  тесте `FileDigest`; секретов нет. По сути безопасности: скрипт не пишет в `~/Library/Containers` (N3, мутация),
  импорт пускает только пути реестров и не трогает `Memory/`, `Caches/`, `Ally/` (N5, N6), журнал без слов (N8);
  контейнер с данными дочки закрыт для агентов самой macOS.
- **Производительность** (маячок — `json.dumps`/`json.loads` в `mac_files.py`): это три реестра и список из 28 строк;
  время уходит на sha256 5,5 ГБ (5,12 с на Mac вместе с клонами), повтор — та же сверка. В приложении копия клонами,
  sha256 потоком по 8 МиБ — замер копии в первом ходе.
- **Новый модуль** `scripts/mac_files.py`: переиспользует сверку `copy_voice.py` (`digest`, `verify`), а не копирует её;
  запись — `.part` и `os.replace`; клон `cp -c` на macOS, иначе обычная копия (Linux CI).
- **Слияние с design-demo:** консоль переехала в общий `ConsoleView`; кнопка «Файлы с Mac…» стоит вставкой снизу у
  `Console` приложения — общий вид и демо не тронуты; в проекте две схемы, в подсказке `mac_app.sh` — «схема Ally».
- **Слияние с child-open:** прогрев запуска идёт один раз за экраном загрузки (`started`); после успешной копии
  «Файлы с Mac…» сбрасывает его и прогревает заново под тем же экраном, отказ копии прогрев не трогает. Строка Metal —
  в одной строке с прогревом, приёмник журнала — в списках следа: тело `VoiceLoop` и `warmUp` в пределах SwiftLint
  (300 и 50), свой код — в расширении того же файла. Синтетика — только консольной сессией: детский экран открыт
  всегда, а его сессия пишет память и чёрный ящик.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на verify -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 12 кода (+17 документов, знания и smoke) / net 562 из 800; план ≈ 600, с поправкой ≈ 750 |
| commits | 7 до verify (спека, подпись, eval-smoke, код и знание, уроки, слияние main, схема); сдача — после N9 |
| time_to_accepted_spec | 0,3 ч (спека e91d0bf → подпись a3e6c1e) |
| rework_after_done | 0 (сдача не объявлена) |
| harness_hardened | yes — `MacImportTests`, `TraceLineTests` (новые оракулы), smoke S9 `mac_files_check.sh` |
| implement_retries | 4 — `@Published` на двух переменных одной строкой; правило `inline_prompt` (тексты импорта — в ресурс) и длина строк; детектор секретов на хэше «abc»; импорт с `Task.detached` на свою очередь по L143 после слияния card-fallback |
| verify_fails_before_green | 0 — все прогоны CI зелёные (quality 40943703654, 40944844520, 40946391728, 40947702920, 40949719069; macOS 40944046395, 40947743060, 40949732420); локально — два отказа pre-commit до коммита (SwiftLint, секреты) и длина тела `VoiceLoop` 301 после слияния memory-forget — свой код вынесен в расширение того же файла |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **34**, из них без ссылки на пример спеки: **0**. Все утверждения ведут к примерам N4 N5
N6 N7 N8, подписанным до кода (`human_ok_spec`).

asserts_without_example: 0

## Verdict

**Не сдано: N9 открыт** (первый ход на Mac — 2026-10-30 по слову родителя). Остальное зелёное: N1–N8 и N10, мутации
7 из 7, сборки и оракул артефакта.
