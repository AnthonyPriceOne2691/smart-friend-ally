# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; G12–G18 — пороги таблицы, подписанной родителем 2026-10-22 «Подписываю (Рекомендую)», вопрос 9, на своих границах)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40002784926
**Commit:** e46d049 (документы — bb15e1c, ядро — 75ab6ad, приложение и знание — e3ba74d, слияние main с voice-text — 68cfc05, задачи и CLAUDE.md — e46d049; эта сдача — следующим коммитом, PR #49)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint 0.65.0 — 0 находок; секреты —
  фикстура подписи `ally-release` (base64 в многострочных литералах) проходит; данные ребёнка; `gate-coverage`
- [x] PASS — `okf_validate.py`: 0 ошибок (45 файлов); `okf_sync_gate.py --base origin/main`: 12 концептов сверены
  (`product/child-mode` — `ReleaseGate.swift`, `SSHSignature.swift`, `release.json`, `ChildMode.swift`; `ops/black-box` —
  `BlackBoxPorts.swift`; `safety-below-model` и `voice-loop` — `VoiceLoop.swift`, `AllyApp.swift`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 12 файлов, net 384
  из 800. Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а отношение здесь —
  граница каждой из девяти целей тремя точками (лучше порога и ровно на нём — открыт, на шаг хуже — закрыт), его держат
  мутации порогов и сравнений
- [x] PASS — доктор контура в CI: `AUTO 46 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0`

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): 66 из 66 (9 новых — G12–G17 в `AcceptanceTests`, G12 и G15 на Mac в
  `SignatureTests`, G18 в `TraceTests`; прежние тесты без правок). CI на Linux, джоба `swift`: AllyCore — 20 файлов `Sources/`, 987 из
  1022 строк, 96% (`SSHSignature.swift` под `#if canImport(CryptoKit)` на Linux не собирается; тесты подписи там — видимый
  пропуск, судит их Mac); отрицательный контроль порогом 101% покраснел
- [x] PASS — G12 и G15 на Mac против настоящих подписей OpenSSH 10.3: приёмка, подписанная третьим тестовым ключом ECDSA
  P-256 в `ally-release` (закрытый ключ удалён сразу), открывает `child`; подпись исключения (`ally-child-mode`)
  приёмкой не становится, подпись приёмки исключением — тоже; без подписи или без ключа — «не подписано», без файла — нет
- [x] PASS — мутации в ту же сессию (П30), 21 из 21 убиты тестами, файлы восстановлены: девять порогов на шаг мягче
  (G13); без безобидной части цели 2 (G13, G16); без сверки размера набора и «пустой замер проходит» (G14); `>=` и `<=`
  → `==` (G12, случай «лучше порога»); счёт вне набора читается, неподписанная приёмка, чужая сборка, без ключа (G15);
  замок не читает приёмку (G12, G17); пространство приёмки — опечатка (G12 на Mac); ящик пишет `child` (G18). Две
  мутации первым прогоном не собрались (дубль сырого значения `enum`, замыкание в условии `guard`) — переписаны и убиты
  тестами, а не компилятором
- [x] PASS — сборка приложения для устройства без подписи (`BUILD SUCCEEDED`) и оракул артефакта зелёные: Info, бинарей 4,
  сети нет; файла приёмки в бандле нет — консоль напишет «приёмка: нет файла приёмки»
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания — пороги,
  подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-22 «Подписываю (Рекомендую)», вопрос 9); пороги таблицы перенесены
  дословно; документы R2 и eval-smoke — первым коммитом ветки bb15e1c, раньше кода 75ab6ad (L33)
- [x] PASS — G12–G18: факт по каждому — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — телефон: строка приёмки в консоли, «Дочке, при мне» и детский экран без присмотра — общая сессия
  теста (waiver в STATUS, ответ родителя «Да, всё в общую сессию (Рекомендую)»); файла приёмки нет — без присмотра
  закрыт; ключа родителя в `.github/allowed_signers` нет (D3.2)

## Spec coverage gaps
- **Файл приёмки** — замер всех девяти целей на одной замороженной поверхности и подпись родителя (`ssh-keygen -Y sign
  -n ally-release`); не в R2: цели не достигнуты (справочный прогон 22.10 — 305 из 360, 12 из 90, G16).
- **Телефон** — общая сессия теста вместе с G8, G10, G11 R, W8–W11 D2.2 и A10–A12 D1.2.
- **Замок консоли** — значок стопа детского экрана ведёт в консоль взрослого и без присмотра; спека R2 его не меняет,
  записано в «чего это не даёт» `product/child-mode`.

## Ревью рисковых мест

- **Публичный API:** `ChildAccess.child`, `ChildAccess.open`; `ReleaseGate.access(release:exception:build:now:zone:)`
  (`release` по умолчанию nil — вызовы R не меняются), `accept(release:build:)`, `acceptanceLine(_:)`; `SignedFor` и
  `SignedFile.read(_:armored:signer:for:)` (только с CryptoKit); `Audience.child`.
- **Безопасность ребёнка:** закрыто на любом сомнении — нет ключа, нет файла, не читается, счёт вне набора, не подписано
  в `ally-release`, другая сборка, любая цель ниже порога (названы все); пороги — в коде, не в файле, который судят;
  подпись исключения на 7 дней приёмкой без срока не станет; сессия без присмотра чёрным ящиком не пишется.
- **Конкурентность:** не меняется — слушатель детской сессии выбран один раз на запуск (приёмка в бандле без срока),
  очередь пробуждений R (`running` в `VoiceLoop.wake()`) та же.
- **Данные:** файла приёмки в git нет; в тестах — открытые тестовые ключи и подписи; закрытый ключ удалён.
- **Транзакция БД:** риска нет — базы в поставке нет; слова `Commit`, `pre-commit` в этом отчёте — шапка и метрики.
- **Производительность:** риска нет — приёмка читается один раз при запуске (бандл), замок — на передаче телефона, на тапе
  детского экрана и в конце детской сессии, не в горячем пути хода.
- **Цепочка гейтов:** гейты не меняются; правок `scripts/lint/` и `.github/workflows/` в поставке нет.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 12 code (+ process docs) / +435/−51, net 384 из 800 (с `CLAUDE.md`); план 295 (+30%, L91) |
| commits | 5 до сдачи (документы, ядро, приложение и знание, слияние main с voice-text, задачи); сдача — шестым |
| time_to_accepted_spec | 0h (пороги подписаны в D2.2 + R) |
| rework_after_done | 0 |
| harness_hardened | yes — `AcceptanceTests.swift` (новый оракул), G12 и G15 на Mac в `SignatureTests.swift`, G18 в `TraceTests.swift`, 21 мутация |
| implement_retries | 2 — `return` внутри выражения `switch` (ошибка сборки), находки SwiftLint (длина строк, кортеж из трёх) исправлены до коммита |
| verify_fails_before_green | 0 — первый прогон CI 40002784926 зелёный во всех трёх джобах (swift, delivery, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **33**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
G12	XCTAssertEqual(access, .child)
G12	XCTAssertNil(access.until)
G12	XCTAssertTrue(access.open)
G12	XCTAssertEqual(ReleaseGate.lines(access, zone: lock.zone),
G12	XCTAssertEqual(ReleaseGate.acceptanceLine(lock.reasons(file)), "приёмка: цели безопасности приняты")
G12	XCTAssertEqual(try lock.access(release: file, exception: try lock.file()), .child)
G12	XCTAssertEqual(try lock.access(release: try acceptance(better)), .child)
G13	XCTAssertEqual(lock.reasons(file), [reason], goal)
G13	XCTAssertEqual(ReleaseGate.acceptanceLine(lock.reasons(file)), "приёмка: " + reason, goal)
G13	XCTAssertEqual(try lock.access(release: file), .parentOnly(["нет исключения родителя"]), goal)
G13	XCTAssertEqual(try lock.access(release: file, exception: try lock.file()), .supervised(until: until), goal)
G14	XCTAssertEqual(lock.reasons(try acceptance(results)),
G14	XCTAssertEqual(lock.reasons(try acceptance(results)), ["быт: нет замера"])
G14	XCTAssertEqual(try lock.access(release: try acceptance(results)), .parentOnly(["нет исключения родителя"]))
G15	XCTAssertEqual(lock.reasons(file, signed: signed), [reason], reason)
G15	XCTAssertEqual(ReleaseGate.lines(access, zone: lock.zone), closed, reason)
G15	XCTAssertEqual(lock.reasons(try acceptance()), ["в сборке нет ключа родителя"])
G15	XCTAssertEqual(try lock.access(release: try acceptance()), .parentOnly(["в сборке нет ключа родителя"]))
G16	XCTAssertEqual(lock.reasons(file).joined(separator: "; "),
G16	XCTAssertFalse(try lock.access(release: file).open)
G17	XCTAssertEqual(try lock.access(release: try acceptance(results, extra: ["note": "прогон на телефоне"])), .child)
G17	XCTAssertEqual(lock.reasons(try acceptance(results)), [])
G12	XCTAssertEqual(read?.signed, true)
G12	XCTAssertEqual(ReleaseGate.access(release: read, exception: nil, build: build, now: Date(), zone: .current),
G15	XCTAssertEqual(SignedFile.read(message, armored: signed, signer: signer, for: .exception)?.signed, true)
G15	XCTAssertEqual(SignedFile.read(message, armored: signed, signer: signer, for: .acceptance)?.signed, false)
G15	XCTAssertEqual(SignedFile.read(accepted, armored: releaseSigned, signer: releaseSigner, for: .exception)?
G15	XCTAssertEqual(SignedFile.read(accepted, armored: nil, signer: releaseSigner, for: .acceptance)?.signed, false)
G15	XCTAssertEqual(SignedFile.read(accepted, armored: releaseSigned, signer: nil, for: .acceptance)?.signed, false)
G15	XCTAssertNil(SignedFile.read(nil, armored: releaseSigned, signer: releaseSigner, for: .acceptance))
G18	XCTAssertEqual(trace.records.map(\.audience), Array(repeating: "child", count: 4))
G18	XCTAssertTrue(line.contains("\"audience\":\"child\""), line)
G18	XCTAssertEqual(disk.paths, [])
```

✅ **Каждое утверждение ведёт к примеру спеки** (G12 G13 G14 G15 G16 G17 G18), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver на телефонные проверки — общая сессия теста)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
