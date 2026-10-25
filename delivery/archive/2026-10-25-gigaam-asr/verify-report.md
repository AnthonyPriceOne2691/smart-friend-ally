# Verify report

**Date:** 2026-10-25
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; U22–U26, U28 подписаны родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии «слух», подпись 3b68733)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40211934087
**Commit:** 9a53593 (документы — 64a2303, ядро — f0fdf67, фраза приложения — 5e87dd7, крючок U12 и его откат — 8919b77, 9b5caa4, слияние main с D7.2 — 82ed294, распознаватель и знание — d9e3e5f, слияние main — 68162a0, тесты и точка остановки 23.10 — 59d2f3d, слияние main — c954f8f, уроки — 9a53593; сдача — 1c406d6; слияния main с memory-extract и test-session — 3ad5550, с kv-spoken и voice-config — 473047f; PR #67)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 0 находок; секреты; данные
  ребёнка; `gate-coverage`. Хуки не обходились
- [x] PASS — `okf_validate.py`: 0 ошибок (51 файл); `okf_sync_gate.py --base origin/main`: 18 концептов сверены
  (`turn-detector`, `voice-loop`, `safety-below-model`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 14 файлов, net 470
  из 800 (план 365, с поправкой +50% — 550, стоп 780). Предупреждение «нет реляционного оракула»: детектор знает
  hypothesis и fast-check, а отношения здесь — паритет гипотез со спайком (U23: 300 + 88 клипов, U24: external data
  против того же спайка) и предзапись относительно флага определителя (U25)
- [x] PASS — CI: прогон 40211934087 на 9a53593 — `swift`, `delivery`, `gates` зелёные с первого раза; доктор контура
  `AUTO 47 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`; отрицательный контроль покрытия (порог 101%) покраснел;
  страж «один ORT» и его отрицательный контроль зелёные

## Behavior oracles
- [x] PASS — AllyCore на Mac: 97 из 97 (новые — U22 в `HearingTests`, U25 и U26 в `RecognitionTests`; тесты D7, D7.1,
  D7.2 без правок утверждений); после слияния main с kv-spoken (473047f) — 106 из 106. CI на Linux, джоба `swift` — AllyCore — 29 файлов `Sources/`, 1708 из 1770 строк, 96%. AllyHearing на Linux не собирается (двоичные
  xcframework) — Mac
- [x] PASS — AllyHearing на Mac, 25.10 после слияния main: 5 из 5 — U23: 300 из 300 (Common Voice) и 88 из 88 (суррогат
  детского голоса с шумом) гипотез = спайк; U24: веса external data — те же 300 из 300, footprint после загрузки ≤ 450 МБ,
  пик ≤ 500 МБ; U22 из папки моделей: файлы external data — GigaAM открыт, `gigaam-v3-ctc:224757733`; пустая папка —
  «GigaAM нет: нет файла model.int8.onnx — диктовка»; U16 а, U17 (D7.2) без правок. Данные — публичные, в `local/`
  основного клона
- [x] PASS — мутации (П30), 11 из 11 убиты, файлы восстановлены: предзапись не вычитается, Int16 / 32767, определитель не
  сообщает о начале (U25); хвост расшифровывает всегда, продолжение не сбрасывает текст (U26); размер не сверяется, пара не
  сверяется, движок не спрашивается, метка — один файл (U22); метка GigaAM — диктовка (U22 на Mac); GigaAM слышит 8 кГц
  (U23, U24). Мутация «продолжение не сбрасывает текст» сначала выжила: пример U26 судил продолжение только новой паузой,
  а предел и «я всё» кончают ход после продолжения без паузы — случай добавлен в U26, мутация убита (L81)
- [x] PASS — сборка приложения для устройства без подписи (`BUILD SUCCEEDED`, 25.10 после слияний main — c954f8f и
  473047f) и оракул артефакта: бинарей 6, сетевых символов нет — `app-artifact: OK`
- [x] PASS — команда runbook перепаковки весов (onnx 1.23.2) дала те же байты и sha256, что в реестре слуха (L82)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  примеры, подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23, подпись серии 3b68733); U22–U26, U28 перенесены таблицей
  дословно; документы и eval-smoke — первым коммитом ветки 64a2303, раньше кода f0fdf67 (L33)
- [x] PASS — U22–U26: факт по каждому — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — U28 на телефоне: сессия теста с родителем (ответ 8 серии, waiver в STATUS; родитель 25.10:
  «сегодня механика: код, сборка; тесты и закачка на телефон — завтра»). По умолчанию слушает диктовка; GigaAM — только
  с `"engine": "gigaam"` в реестре и тремя файлами на телефоне (команда — runbook `voice-loop`)

## Исполнение рисковых путей

- `Packages/AllyHearing/` — исполнено на Mac: `GigaAMRecognizer` открывает модель через C API sherpa на ORT 1.28.0 из
  обычного файла (U23) и из external data (U24) и даёт гипотезы спайка; `GigaAMRecognizer.choose` читает размеры из папки
  моделей и открывает GigaAM или отказывает со строкой (U22 на Mac). На телефоне не исполнено: загрузка из
  `Library/Application Support/Models`, память и время расшифровки, путь тапа `GigaAMPhrase` — U28 в сессии теста (waiver
  в STATUS). at=2026-10-25

## Spec coverage gaps
- **U28** — телефон, сессия теста (ответ 8 серии), вместе с U20, U21 (D7.2).
- **U27** — инструмент шага 3, поставка D7.4.
- **`GigaAMPhrase`** (`AVAudioConverter` → 16 кГц Int16 → `BatchPhrase`) — тестами не судится: у `App` тестов нет; логика
  предзаписи и расшифровки — в `BatchPhrase` ядра (U25, U26), путь тапа — U28.
- **`TurnEnding`:** передачу «возможно, конец» и «продолжения» (D7.1) судят только двойники слуха; начало речи теперь
  судит U25 через настоящий определитель.

## Ревью рисковых мест

- **Публичный API:** `BatchPhrase`; `Hearing.asr`, `Recognition` (`choose`, `label`, `unopened`) (AllyCore);
  `GigaAMRecognizer` (`init`, `decode`, `Choice`, `choose`) (AllyHearing); `TurnEnding` передаёт и начало речи.
- **Безопасность ребёнка:** путь реплики не меняется — распознаватель решает только, каким текстом стал звук; текст идёт
  тем же маршрутизатором и контрактом. При любой неисправности GigaAM (нет файла, не тот размер, нет API 28, модель не
  открылась) — диктовка, как до D7.3.
- **Конкурентность:** `decode` под замком — одна реплика за раз; расшифровка — вне потока тапа (`Task.detached`); фраза
  создаётся на каждое слушание, поздняя расшифровка уходит фразе своего слушания.
- **Данные:** веса GigaAM — вне git и вне приложения (копируются командой); наборы U23, U24 — публичные, в `local/`;
  детских записей поставка не касается, текст в след не пишется.
- **Транзакция БД:** риска нет — базы в поставке нет; слова `Commit`, `pre-commit` в этом отчёте — шапка и метрики.
- **Производительность:** одна расшифровка на «возможно, конец», повтор — только после продолжения (U26); память GigaAM
  ≈ 0,4 ГБ (U24, снятие риска — 398 и 441 МБ); бюджет телефона — U28.
- **Цепочка гейтов:** без изменений.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 14 code (+11 process docs) / +502/−32 (net +470; предохранитель — 14 файлов, net 470 из 800; план 365) |
| commits | 11 до сдачи (документы, ядро, фраза приложения, крючок U12 и откат, три слияния main, распознаватель и знание, тесты и точка остановки, уроки); сдача — двенадцатым |
| time_to_accepted_spec | 0h (подписана в серии «слух») |
| rework_after_done | 0 |
| harness_hardened | yes — `GigaAMTests.swift` (новый оракул: U23, U24, U22 на Mac), `RecognitionTests.swift` (новый оракул: U25 через определитель, U26 с концом без паузы), U22 в `HearingTests.swift`, 11 мутаций |
| implement_retries | 2 — U12 (D7.1) мигал на этой ветке: крючок в ядре остановил гейт синхронизации знания, чинил PR #59 правкой теста; мутация M3 выжила — U26 дополнен |
| verify_fails_before_green | 0 — первый прогон CI 40211934087 зелёный во всех трёх джобах (swift, delivery, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **38**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
U22	XCTAssertEqual(asr.engine, "dictation")
U22	XCTAssertEqual(asr.choose(sizes: sizes, pairServes: true).engine, "dictation")
U22	XCTAssertEqual(gigaam.choose(sizes: sizes, pairServes: true).engine, "gigaam")
U22	XCTAssertNil(gigaam.choose(sizes: sizes, pairServes: true).line)
U22	XCTAssertEqual(gigaam.choose(sizes: missing, pairServes: true).engine, "dictation")
U22	XCTAssertEqual(gigaam.choose(sizes: missing, pairServes: true).line,
U22	XCTAssertEqual(gigaam.choose(sizes: small, pairServes: true).line,
U22	XCTAssertEqual(gigaam.choose(sizes: sizes, pairServes: false).line,
U22	XCTAssertEqual(gigaam.unopened, "GigaAM нет: модель не открылась — диктовка")
U22	XCTAssertEqual(asr.label("dictation"), "dictation")
U22	XCTAssertEqual(gigaam.label("gigaam"), "gigaam-v3-ctc:224757733")
U25	XCTAssertEqual(late.heard.count, Int(4.7 * 16_000))
U25	XCTAssertEqual(late.heard, Array(all[56_000...]))
U25	XCTAssertEqual(early.heard, quick)
U25	XCTAssertEqual(BatchPhrase.floats([-32_768, 16_384, 0, 32_767]), [-1, 0.5, 0, Float(32_767) / 32_768])
U25	XCTAssertEqual(heard.heard.count, all.count - ((try XCTUnwrap(flag) + 1) * 320 - 24_000))
U26	XCTAssertEqual(phrase.finish(), first)
U26	XCTAssertEqual(phrase.decodes, 1)
U26	XCTAssertNotEqual(second, first)
U26	XCTAssertEqual(phrase.finish(), second)
U26	XCTAssertEqual(phrase.decodes, 2)
U26	XCTAssertNotEqual(phrase.finish(), second)
U26	XCTAssertEqual(phrase.decodes, 3)
U26	XCTAssertEqual(untold.finish(), "тишина")
U26	XCTAssertEqual(untold.decodes, 1)
U26	XCTAssertEqual(count { $0 }, 3)
U23	XCTAssertEqual(cv.clips.count, 300)
U23	XCTAssertEqual(try same(recognizer, cv.clips, cv.expected, peak: &peak), 300)
U23	XCTAssertEqual(noisy.clips.count, 88)
U23	XCTAssertEqual(try same(recognizer, noisy.clips, noisy.expected, peak: &peak), 88)
U24	XCTAssertEqual(try same(recognizer, cv.clips, cv.expected, peak: &peak), 300)
U24	XCTAssertLessThanOrEqual(loaded, 450)
U24	XCTAssertLessThanOrEqual(peak - before, 500)
U22	XCTAssertNotNil(gigaam.decode)
U22	XCTAssertEqual([gigaam.label, gigaam.line ?? ""], ["gigaam-v3-ctc:224757733", ""])
U22	XCTAssertNil(empty.decode)
U22	XCTAssertEqual([empty.label, empty.line ?? ""],
U22	XCTAssertNil(GigaAMRecognizer.choose(hearing, models: external).decode)
```

✅ **Каждое утверждение ведёт к примеру спеки** (U22 U23 U24 U25 U26), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver на телефонную U28)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
