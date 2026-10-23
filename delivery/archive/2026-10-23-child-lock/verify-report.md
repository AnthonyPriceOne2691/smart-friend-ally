# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; G1–G11 подписаны родителем 2026-10-22 «Подписываю (Рекомендую)» в спеке D2.2 + R)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39992590788
**Commit:** 4220895 (документы — 5699424, код — 52c8eed, слияние main с D3 — 5ca9361, упрощение замка — c81f497, знание — 7671c59, джоба macOS — 4220895; эта сдача — следующим коммитом, PR #42)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint 0.65.0 — 56 файлов, 0 находок
  (снимок 0); секреты — фикстуры подписи (base64 без кавычек в многострочных литералах) проходят; данные ребёнка;
  `gate-coverage`
- [x] PASS — доктор контура в CI: `AUTO 45 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок (44 файла); `okf_sync_gate.py --base origin/main`: 9 концептов сверены (новый
  `product/child-mode`; `safety-below-model`, `voice-loop`, `repo-map` — правки `VoiceLoop.swift`, `AllyApp.swift`,
  `project.yml`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 15 файлов, net ≈ 769
  из 800 (с `CLAUDE.md`), порог стопа 780 не задет. Предупреждение «нет реляционного оракула»: детектор знает только
  hypothesis и fast-check, а реляционный оракул здесь — свойство G3 (на 42 точках вокруг концов срока и сроках 7 дней
  ± 1 с режим открыт ровно на `[from, until)` при сроке ≤ 7 дней)

## Behavior oracles
- [x] PASS — `swift test` на Mac (Xcode 27): 57 тестов из 57 (9 новых — G1–G7, G9 и свойство G3; тесты D1.1, D2, D2.2 и D3
  без правок). CI на Linux, джоба `swift`: AllyCore — 20 файлов `Sources/`, 936 из 969 строк, 96% (`SSHSignature.swift`
  под `#if canImport(CryptoKit)` на Linux не собирается; G7 там — видимый пропуск); отрицательный контроль порогом 101%
  покраснел
- [x] PASS — G7 на Mac против настоящих подписей OpenSSH 10.3 (`ssh-keygen -Y sign` двумя тестовыми ключами ECDSA P-256,
  закрытые ключи удалены): верная подпись принята; изменённый байт, пространство `irreversible`, чужое пространство в
  запросе, второй ключ, четыре вида мусора и строка без ключа — отклонены без падения
- [x] PASS — мутации в ту же сессию (П30), 9 из 9 убиты, файлы восстановлены: без предела 7 дней (G3 и свойство G3); без
  сверки поверхности (G5); без самопроверки (G6); неподписанное принято (G4); без сверки пространства (G7); без сверки
  ключа (G7); `audience` не доходит до записи (G9); обёртка `Conversation` теряет `audience` (G9, L58)
- [x] PASS — сборка приложения для устройства без подписи и оракул артефакта зелёные (CryptoKit — системный фреймворк,
  сети нет); `allowed_signers` лежит в бандле
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-22 «Подписываю (Рекомендую)»); таблица G1–G11 перенесена дословно;
  документы R и eval-smoke — первым коммитом ветки 5699424, раньше кода 52c8eed (L33)
- [x] PASS — G1–G7, G9: факт по каждому — `eval-smoke.md`; G11 без родителя — отказы срока до окна и `--dry` с
  исключением целиком (персона 329790cc…, вес 4977171584 байт; байты `contract.json` и `router.json` в бандле совпадают с
  файлами — хэши скрипта и приложения считаются от одного)
- [ ] НЕ ПРОВЕРЕНО — G8, G10 и подпись касанием G11: телефон и Mac с родителем — общая сессия теста (waiver в STATUS);
  ключа родителя в `.github/allowed_signers` ещё нет (T2) — до него детский режим закрыт с причиной «в сборке нет ключа
  родителя»

## Исполнение рисковых путей

- `scripts/child_mode.sh` — исполнено без подписи: `bash scripts/child_mode.sh 0000 --until 2026-11-30T21:00:00+03:00` →
  «дальше 7 дней — окна не будет», выход 1; `--until 2026-10-20T21:00:00+03:00` → «уже прошёл», выход 1; без смещения →
  «нет смещения часового пояса», выход 1; `bash scripts/child_mode.sh 0000 --until 2026-10-29T21:00:00+03:00 --dry` —
  окно с исключением целиком и поверхностью сборки. Подпись касанием, сверка и копия на телефон не исполнены: подписывает
  только родитель, сессия теста (waiver в STATUS). at=2026-10-23

## Spec coverage gaps
- **G8, G10, G11 на телефоне и Mac** — общая сессия теста с родителем; там же W8–W11 D2.2 и A10–A12 D1.2.
- **Ключ родителя (T2)** — строку пришлёт ведущий; до неё режим закрыт (G4) — безопасное умолчание.
- **Пороги без присмотра и `release-gate.json`** — R2 (подписанная серия).
- **Строка консоли «перерыв до …»** — добавит та поставка из R и Ш3, что придёт второй; функция конца перерыва — одна.
- **Тело детского экрана** — Ш3 «оболочки»; здесь заглушка по стыку `ChildScreen(talk:until:onWake:onStop:)`.

## Ревью рисковых мест

- **Публичный API:** `ChildAccess` (`supervised(until:)`, `parentOnly`, `until`); `ReleaseSurface` с `build(…)`;
  `SignedFile`; `ReleaseGate.Build` с `current(…)`, `access(exception:build:now:zone:)`, `lines`, `when`, `longest`;
  `SSHSignature.verify` (только на платформах с CryptoKit); `Audience` и `SessionParts.audience` — из D3.
- **Безопасность ребёнка:** отказ закрытый на любом сомнении — нет ключа, нет файла, не читается, не подписан, не тот срок,
  не та сборка, отказ самопроверки; пути к режиму без присмотра нет; срок проверяется на границах сессии; подпись — только
  касанием родителя, агент окна не вызывает.
- **Конкурентность:** две сессии на одном слухе; новая будится после конца прежней (`running` в `VoiceLoop.wake()`), иначе
  слушание встало бы на занятую шину (L60).
- **Данные:** исключение и подпись — вне git, в контейнере телефона; в git — только место ключа родителя и тестовые
  открытые ключи; закрытые тестовые ключи удалены.
- **Транзакция БД:** риска нет — базы в поставке нет; слова `Commit`, `pre-commit` в этом отчёте — шапка и метрики.
- **Производительность:** риска нет — `json.loads` и `json.dumps` в `scripts/child_mode.sh` разбирают один реестр и пишут
  одну строку исключения на Mac перед подписью; на телефоне замок читает один файл при запуске, на передаче телефона, на
  тапе детского экрана и в конце детской сессии — не в горячем пути хода.
- **Цепочка гейтов:** гейты не меняются; `scripts/lint/adapted.json` — запись о шаге ручной джобы `ios.yml` (тесты подписи
  на macOS), `.github/workflows/ios.yml` — один шаг.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 15 code (+ process docs) / net ≈ 769 из 800 (с `CLAUDE.md`); до упрощения замка — 778 |
| commits | 7 до сдачи (документы, код, слияние main с D3, упрощение, знание, джоба macOS); сдача — восьмым |
| time_to_accepted_spec | 0h (подписана в D2.2 + R) |
| rework_after_done | 0 |
| harness_hardened | yes — `ReleaseGateTests.swift`, `SignatureTests.swift` (новые оракулы), G9 в `TraceTests.swift`, свойство G3 и 9 мутаций |
| implement_retries | 2 — `@Published` на трёх переменных в одном объявлении (ошибка сборки), находки SwiftLint (длина строк, шесть параметров, `String(decoding:)`) исправлены до коммита |
| verify_fails_before_green | 0 — первый прогон CI 39992590788 зелёный во всех трёх джобах (swift, delivery, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **34**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
G1	XCTAssertEqual(access, .parentOnly(["нет исключения родителя"]))
G1	XCTAssertNil(access.until)
G1	XCTAssertEqual(ReleaseGate.lines(access, zone: lock.zone),
G2	XCTAssertEqual(access, .supervised(until: try lock.at("2026-10-29T21:00:00+03:00")))
G2	XCTAssertEqual(ReleaseGate.lines(access, zone: lock.zone).first, "при родителе: до 29.10 в 21:00")
G2	XCTAssertEqual(current.surface.contract, "fnv1a:" + TurnContract(mode: .talk).finish("").record.contractHash)
G2	XCTAssertEqual(current.surface.router, "fnv1a:" + Router.shared.route("").record.dataHash)
G2	XCTAssertEqual([current.surface.persona, current.surface.model], ["sha256:329790cc", "w.gguf:1"])
G2	XCTAssertEqual([current.router, current.contract, current.key], [true, true, true])
G3	XCTAssertNotNil(try lock.access(file, now: "2026-10-29T20:59:59+03:00").until)
G3	XCTAssertEqual(try lock.access(file, now: "2026-10-29T21:00:00+03:00"),
G3	XCTAssertEqual(try lock.access(file, now: "2026-10-23T08:59:59+03:00"),
G3	XCTAssertNotNil(try lock.access(try lock.file(until: "2026-10-30T09:00:00+03:00")).until)
G3	XCTAssertEqual(try lock.access(try lock.file(until: "2026-10-30T09:00:01+03:00")),
G3	XCTAssertEqual(open, span <= ReleaseGate.longest && now >= from && now < until, "\(span) \(now)")
G7	XCTAssertEqual(try lock.access(try lock.file(), signed: false), .parentOnly(["подпись исключения не сходится"]))
G7	XCTAssertEqual(try lock.access(Data("{не json".utf8)), .parentOnly(["исключение не читается"]))
G7	XCTAssertEqual(try lock.access(try lock.file()), .parentOnly(["в сборке нет ключа родителя"]))
G7	XCTAssertEqual(try lock.access(nil), .parentOnly(["в сборке нет ключа родителя"]))
G5	XCTAssertEqual(try lock.access(try lock.file(surface: surface)),
G5	XCTAssertEqual(try lock.access(try lock.file(surface: two)),
G6	XCTAssertEqual(try lock.access(try lock.file()), .parentOnly(["маршрутизатор не прошёл самопроверку"]))
G6	XCTAssertEqual(try lock.access(try lock.file()), .parentOnly(["контракт не прошёл самопроверку"]))
G7	XCTAssertTrue(SSHSignature.verify(message, armored: signed, signer: signer, namespace: "ally-child-mode"))
G7	XCTAssertFalse(SSHSignature.verify(changed, armored: signed, signer: signer, namespace: "ally-child-mode"))
G7	XCTAssertFalse(SSHSignature.verify(message, armored: forIrreversible, signer: signer,
G7	XCTAssertFalse(SSHSignature.verify(message, armored: signed, signer: signer, namespace: "irreversible"))
G7	XCTAssertFalse(SSHSignature.verify(message, armored: byAnotherKey, signer: signer,
G7	XCTAssertFalse(SSHSignature.verify(message, armored: garbage, signer: signer, namespace: "ally-child-mode"))
G7	XCTAssertFalse(SSHSignature.verify(message, armored: signed, signer: "нет ключа", namespace: "ally-child-mode"))
G9	XCTAssertEqual(sink.records.map(\.audience), Array(repeating: audience.rawValue, count: 3))
G9	XCTAssertTrue(line.contains("\"audience\":\"\(audience.rawValue)\""), line)
G9	XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
L58	XCTAssertEqual(sink.records.map(\.audience), ["supervised", "supervised", "supervised"])
```

✅ **Каждое утверждение ведёт к примеру спеки** (G1 G2 G3 G5 G6 G7 G9 L58), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver на телефонные G8, G10, G11; ключ родителя — T2)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
