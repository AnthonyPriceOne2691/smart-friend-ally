# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; U16–U21 подписаны родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии «слух», подпись 3b68733)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40012440148
**Commit:** 2ecad69 (документы — e34ff15, активность — bcd0c46, слияние main с D7.1 — edba80b, реестр и sherpa — 82a1a9d, AllyHearing — 464daec, приложение — 567c644, знание — 20a2214, задачи — 97349ab, слияние main с memory-core — 2ecad69; эта сдача — следующим коммитом, PR #57)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint 0.65.0 — 0 находок (снимок 0;
  первая попытка коммита без `.build` AllyHearing в `excluded` дала 55 — L93 подтвердился, исключение вошло тем же
  коммитом); секреты — checksum с `pragma: allowlist secret`; данные ребёнка; `gate-coverage`
- [x] PASS — `check_single_ort.sh`: один ORT, пара sherpa 1.13.8 / ORT 1.28.0 запинована; локальная репетиция
  отрицательного контроля — копии с 1.13.9 и с 1.24.2 красные и называют `Packages/AllyOnnx/Package.swift`
- [x] PASS — `okf_validate.py`: 0 ошибок (47 файлов); `okf_sync_gate.py --base origin/main`: 14 концептов сверены
  (`turn-detector`, `onnx-runtime`, `voice-loop`, `safety-below-model`, `repo-map`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 21 файл, net 474
  из 800 (план 425, с поправкой +50% — 640, стоп 780). Предупреждение «нет реляционного оракула»: детектор знает
  hypothesis и fast-check, а отношения здесь — паритет флагов со спайком (U17, 100 фраз) и граница событий U18 (окно,
  где порог достигнут, и окно перед ним)
- [x] PASS — доктор контура в CI: `AUTO 46 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`; отрицательный контроль
  стража в джобе `swift`: пакеты со своим ORT — красный, `binaryTarget` sherpa — зелёный, чужая пара — красный

## Behavior oracles
- [x] PASS — AllyCore на Mac: 82 из 82 (новые — U16 б, U19 в `HearingTests`, U18 в `TurnDetectorTests`; A17, A25–A27 и
  тесты D7.1 без правок утверждений). CI на Linux, джоба `swift`: AllyCore — 24 файла `Sources/`, 1307 из 1360
  строк, 96%; отрицательный контроль порогом 101% покраснел. AllyHearing и AllyOnnx на Linux не собираются (двоичные
  xcframework) — Mac и ручная джоба `ios.yml`
- [x] PASS — AllyHearing на Mac: 2 из 2 — U16 (а): ORT 1.28.0, API 28 есть, 29 нет, sherpa 1.13.8, строка «слух: Silero ·
  sherpa 1.13.8 · ORT 1.28.0»; U17: флаги Silero на первых 100 фразах набора конца реплики = спайк, 100 из 100 (данные —
  `local/` основного клона, публичное и синтетическое аудио). AllyOnnx на Mac: 7 из 7 с восстановленной фикстурой
- [x] PASS — мутации в ту же сессию (П30), 9 из 9 убиты тестами, файлы восстановлены: запаздывание не вычитается (U18);
  активность игнорируется (U18); порог энергии +25 дБ и «без калибровки» (A17, U4, A26 — энергия после переезда та же);
  API не проверяется (U16 б); размер не сверяется (U19); порог Silero +0,1 и «сброс ничего не делает» (U17); API sherpa
  29 (U16 а). Сдвиг порога энергии на 1 дБ (+11) примеры A17–A27 не различают: их уровни −60 и −40 дБ — свойство
  примеров voice-core, не переезда
- [x] PASS — сборка приложения для устройства без подписи (`BUILD SUCCEEDED`) и оракул артефакта зелёные: sherpa и ORT в
  бинаре, сетевых символов нет, бинарей 6
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23, подпись серии 3b68733); U16–U21 перенесены таблицей дословно;
  документы и eval-smoke — первым коммитом ветки e34ff15, раньше кода bcd0c46 (L33)
- [x] PASS — U16–U19: факт по каждому — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — U20, U21 на телефоне: сессия теста с родителем после D7.3 (waiver в STATUS); модель Silero на
  телефон копирует родитель командой из runbook; без неё приложение слушает энергией и пишет это в консоли

## Исполнение рисковых путей

- `Packages/AllyHearing/` — исполнено на Mac: `SileroVAD` создаётся из файла модели через C API sherpa на ORT 1.28.0 и
  даёт флаги спайка (U17); `OnnxPair.current` читает настоящий рантайм (U16). На телефоне не исполнено: ресемплер
  буферов тапа, создание VAD из `Models` и время окна — U20, U21 в сессии теста (waiver в STATUS). at=2026-10-23

## Spec coverage gaps
- **U20, U21** — телефон, сессия теста после D7.3 (ответ 8 серии), вместе с U28.
- **Ресемплер `AVAudioConverter`** — тестами Mac не судится: паритет U17 — на окнах 16 кГц из файлов; путь тапа — U21.
- **GigaAM, протокол распознавателя** — D7.3.

## Ревью рисковых мест

- **Публичный API:** `VoiceActivity`, `EnergyActivity`, `TurnDetector(…, activity:)`; `Hearing.vad`, `Hearing.listening
  (pair:fileBytes:)`, `OnnxPair`, `Listening` (AllyCore); `OnnxRuntime.serves(api:)`, `Sherpa` (AllyOnnx);
  `SileroVAD`, `SileroActivity`, `OnnxPair.current` (AllyHearing).
- **Безопасность ребёнка:** путь реплики не меняется — Silero решает только, где кончилась речь; при любой
  неисправности слуха (нет файла, не тот размер, нет API 28, VAD не открылся) — энергия, как до D7.2.
- **Конкурентность:** активность одна на слух; кормит её и спрашивает определитель один поток тапа; сброс — в начале
  каждого слушания, до установки тапа.
- **Данные:** модель Silero — вне git и вне приложения (копируется командой); данные U17 — публичные, в `local/`; в git —
  только фикстура `add.onnx` 97 байт (c = a + b).
- **Транзакция БД:** риска нет — базы в поставке нет; слова `Commit`, `pre-commit` в этом отчёте — шапка и метрики.
- **Производительность:** окно Silero на Mac 0,1–0,75 мс (спайк), время окон пишется в журнал; бюджет U20 — p95 ≤ 2 мс на
  телефоне. Ресемплер — один `AVAudioConverter` на слушание.
- **Цепочка гейтов:** `check_single_ort.sh` получил пин пары; джоба `swift` — отрицательный контроль пары; `ios.yml` —
  шаг тестов AllyHearing; `.swiftlint.yml` — исключение `.build`; `.gitignore` — исключение одной фикстуры.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 24 code (+12 process docs) / +538/−34 (net +504 по метрике; предохранитель без `.github/` и `scripts/lint/` — 21 файл, net 474 из 800; план 425) |
| commits | 9 до сдачи (документы, активность, слияние main с D7.1, реестр и sherpa, AllyHearing, приложение, знание, задачи, слияние main с memory-core); сдача — десятым |
| time_to_accepted_spec | 0h (подписана в серии «слух») |
| rework_after_done | 0 |
| harness_hardened | yes — `SileroTests.swift` (новый оракул), U18 в `TurnDetectorTests.swift`, U16 б и U19 в `HearingTests.swift`, пин пары в `check_single_ort.sh` с отрицательным контролем, шаг `ios.yml`, фикстура `add.onnx`, 9 мутаций |
| implement_retries | 3 — нет `import AllyOnnx` в `SileroVAD.swift` (сборка), устаревшая копия ресурсного бандла в `AllyCoreTests.xctest` (локальная сборка), коммит без `.build` в `excluded` SwiftLint (ратчет 0 → 55) |
| verify_fails_before_green | 0 — первый прогон CI 40012440148 зелёный во всех трёх джобах (swift, delivery, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **18**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
U16	XCTAssertEqual(hearing.listening(pair: { pair }, fileBytes: model), .silero(pair))
U16	XCTAssertEqual(hearing.listening(pair: { pair }, fileBytes: model).line,
U16	XCTAssertEqual(refused, .noApi(28))
U16	XCTAssertEqual(refused.line, "слух: ORT без API 28 — слушаю по энергии")
U19	XCTAssertEqual(choice, .noFile("silero_vad.onnx"))
U19	XCTAssertEqual(choice.line, "нет silero_vad.onnx — слушаю по энергии")
U18	XCTAssertEqual(out.map(\.name), ["started", "tentative", "ended"])
U18	XCTAssertEqual([out[1].time, out[2].time], [last - 0.128, last - 0.128])
U18	XCTAssertGreaterThanOrEqual(event.at - last, after - 1e-9)
U18	XCTAssertLessThan(event.at - window - last, after - 1e-9)
U16	XCTAssertEqual([pair.ort, pair.sherpa], ["1.28.0", "1.13.8"])
U16	XCTAssertEqual(pair.api, 28)
U16	XCTAssertTrue(pair.served)
U16	XCTAssertFalse(OnnxRuntime.serves(api: 29))
U16	XCTAssertEqual(choice.line, "слух: Silero · sherpa 1.13.8 · ORT 1.28.0")
U17	XCTAssertEqual([settings.threshold, settings.minSpeech, settings.minSilence], [0.5, 0.25, 0.1])
U17	XCTAssertEqual(phrases.count, 100)
U17	XCTAssertEqual(same, 100)
```

✅ **Каждое утверждение ведёт к примеру спеки** (U16 U17 U18 U19), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver на телефонные U20, U21)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
