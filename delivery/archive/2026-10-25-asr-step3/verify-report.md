# Verify report

**Date:** 2026-10-25
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примеру спеки — дайджест ниже, asserts_without_example: 0; U27 подписан родителем 2026-10-23 «Подписываю (Рекомендую)» в спеке серии «слух», подпись 3b68733)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40215474963
**Commit:** 548aef8 (документы — a3c1336, ядро — 87bd055, слияние main с D7.3 — 20b4b4c, прогон и исполняемый — 16b8bf9, U27 на Mac против спайка — 6526db1, интервал — 906171d, verify — 548aef8, слияние main с memory-sense — fbdd348; эта сдача — следующим коммитом, PR #72)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd — рост 0; SwiftLint — 0 находок (длина функции и
  кортежи сразу разобраны: структура `Export` в тесте); секреты; данные ребёнка; `gate-coverage`. Хуки не обходились
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); `okf_sync_gate.py --base origin/main`: 18 концептов сверены
  (`turn-detector` с `StepThree.swift`, `step3.json`, `StepThreeRun.swift` в `implementation:`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 7 файлов, net 495
  из 800 (план 330, с поправкой +50% — 500, стоп 780). Предупреждение «нет реляционного оракула»: детектор знает
  hypothesis и fast-check, а отношения здесь — дифференциальное (суммы прогона = суммы `StepThree` по гипотезам спайка на
  тех же клипах) и повторяемость интервала с тем же зерном
- [x] PASS — CI: прогон 40215474963 на 548aef8 — `swift`, `delivery`, `gates` зелёные с первого раза; доктор контура
  `AUTO 47 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`; отрицательный контроль покрытия (порог 101%) покраснел

## Behavior oracles
- [x] PASS — AllyCore на Mac: 111 из 111 (новые — 5 тестов U27 в `StepThreeTests`). CI на Linux, джоба `swift` —
  AllyCore — 31 файл `Sources/`, 1898 из 1963 строк, 96%. AllyHearing на Linux не собирается (двоичные xcframework) — Mac
- [x] PASS — AllyHearing на Mac: 6 из 6 — U27 (`StepThreeRunTests`): синтетическая выгрузка из 20 клипов Common Voice с
  выдуманным `heard` и тремя пропусками — сравнено 20, пропуски 1 / 1 / 1, строки сумм равны строкам `StepThree` по
  гипотезам спайка, хэши моделей — как в runbook (02a443f4 fa9a4816 17cc5144), ни одной из 60 строк эталона и гипотез в
  выводе; GigaAM U22–U24 и Silero U16, U17 без правок. Данные — публичные, в `local/` основного клона
- [x] PASS — исполняемый `asr-step3` на публичной выгрузке из трёх клипов: выход 0 и шесть строк сумм; без весов — 2 и
  «GigaAM нет: нет файла model.int8.onnx — диктовка»; без эталонов — 1 и строка счёта; неверные аргументы — 2
- [x] PASS — мутации (П30), 14 из 14 убиты, файлы восстановлены: «ё» не сводится, числа остаются цифрами (нормализация);
  замена бесплатна (WER); порог строгий, однословная часть не судится (вердикт по трём точкам); зерно от часов
  (повторяемость); однословные GigaAM считаются по диктовке, пустые обоих перепутаны, пропуски перепутаны (строки);
  нижняя граница — медиана (интервал); живой GigaAM сравнивается, GigaAM не расшифровывает, эталон соседнего хода, хэш
  трёх байт (прогон на Mac). «Нижняя граница — медиана» сначала выжила: свойства интервала её не различают — процентили
  вынесены в функцию с прямой проверкой (L104)
- [x] PASS — сборка приложения для устройства без подписи (`BUILD SUCCEEDED`) и оракул артефакта — `app-artifact: OK`:
  новый исполняемый таргет `AllyHearing` приложение не линкует
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  пример, подписанный родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23, подпись серии 3b68733); U27 перенесён таблицей дословно;
  документы и eval-smoke — первым коммитом ветки a3c1336, раньше кода 87bd055 (L33)
- [x] PASS — U27: факт — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — шаг 3 на её записях: родитель после сессии теста (выгрузка D3.2, эталоны вслепую); исполнитель её
  записей не открывает и инструмент на них не запускает

## Исполнение рисковых путей

- `Packages/AllyHearing/` — исполнено на Mac, целевой среде инструмента: `StepThreeRun` читает записи и WAV выгрузки,
  открывает GigaAM через C API sherpa на ORT 1.28.0 из папки external data с размерами реестра и даёт суммы, равные
  суммам по гипотезам спайка (U27); исполняемый `asr-step3` отработал выходы 0, 1, 2 на публичной выгрузке. На телефоне
  инструмент не исполняется. at=2026-10-25

## Spec coverage gaps
- **Её записи** — шаг 3 родителя; раскладка выгрузки — D3.2 (PR #43): судится по раскладке её ядра и по ведущему
  («менять никто не собирается»), настоящей выгрузки ещё нет.
- **Кавычки в `refs.csv`** — снимаются только по краям эталона; запятая внутри эталона — его часть (после второй).
- **Звук не 16 кГц** — отказ с именем файла; ящик пишет только 16 кГц, тестом путь не судится.

## Ревью рисковых мест

- **Публичный API:** `StepThree` (`Pair`, `Skipped`, `Summary`, `normalize`, `summary`, `lines`) в AllyCore; исполняемый
  `asr-step3` (таргет `StepThreeTool`) в AllyHearing — библиотека `AllyHearing` не меняется.
- **Безопасность ребёнка и данные:** инструмент печатает только суммы и ничего не пишет на диск; тексты строк — ресурс,
  в них нет полей записи; хэши — файлов GigaAM и версии iOS, не записей. Вход — `local/` (выгрузка и `refs.csv` с её
  словами вне git). Ошибки — на stderr с именами файлов, без текстов.
- **Конкурентность:** нет — прогон синхронный, распознаватель под своим замком.
- **Транзакция БД:** риска нет — базы в поставке нет; слова `Commit`, `pre-commit` в этом отчёте — шапка и метрики.
- **Производительность:** GigaAM ≈ 0,25 с на клип на Mac; 50 реплик — меньше минуты; бутстрэп 2000 × N — мгновенно.
- **Цепочка гейтов:** без изменений.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 7 code (+11 process docs) / +497/−2 (net +495; план 330, с поправкой +50% — 500) |
| commits | 7 до сдачи (документы, ядро, слияние main с D7.3, прогон и исполняемый, U27 против спайка, интервал, verify); сдача — восьмым |
| time_to_accepted_spec | 0h (подписана в серии «слух») |
| rework_after_done | 0 |
| harness_hardened | yes — `StepThreeTests.swift` и `StepThreeRunTests.swift` (новые оракулы U27: три точки правила, дифференциальная сверка со спайком, «ни одной строки»), 14 мутаций |
| implement_retries | 2 — затенение параметра в помощнике теста (сборка); мутация «нижняя граница — медиана» выжила — интервал вынесен |
| verify_fails_before_green | 0 — первый прогон CI 40215474963 зелёный во всех трёх джобах (swift, delivery, gates) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **33**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
U27	XCTAssertEqual(StepThree.normalize("Ёжик, 5 котят! 21 и 101-й; 100%"),
U27	XCTAssertEqual(StepThree.normalize("Мурка  спит."), StepThree.normalize("мурка спит"))
U27	XCTAssertEqual([StepThree.normalize("0"), StepThree.normalize("40"), StepThree.normalize("99")],
U27	XCTAssertEqual([summary.count, summary.oneWord, summary.exactDictation, summary.exactGigaAM], [4, 2, 1, 1])
U27	XCTAssertEqual([summary.emptyDictation, summary.emptyGigaAM], [0, 1])
U27	XCTAssertEqual([summary.werDictation, summary.werGigaAM, summary.gain], [25, 25, 0])
U27	XCTAssertFalse(summary.gigaamWins)
U27	XCTAssertEqual(summary, StepThree.summary(pairs))
U27	XCTAssertLessThanOrEqual(summary.low, summary.gain)
U27	XCTAssertGreaterThanOrEqual(summary.high, summary.gain)
U27	XCTAssertLessThan(summary.low, summary.high)
U27	XCTAssertEqual([bounds.low, bounds.high], [50, 1949])
U27	XCTAssertEqual([same.low, same.gain, same.high], [0, 0, 0])
U27	XCTAssertEqual(atWer.gain, 10, accuracy: 1e-9)
U27	XCTAssertTrue(atWer.gigaamWins)
U27	XCTAssertEqual(belowWer.gain, 100.0 / 11, accuracy: 1e-9)
U27	XCTAssertFalse(belowWer.gigaamWins)
U27	XCTAssertTrue(StepThree.summary(wer(5, last: 2, dictation: 3, gigaam: 1)).gigaamWins)
U27	XCTAssertEqual([atWord.gain, atWord.oneWordGain], [0, 10])
U27	XCTAssertTrue(atWord.gigaamWins)
U27	XCTAssertEqual([belowWord.gain, belowWord.oneWordGain], [0, 5])
U27	XCTAssertFalse(belowWord.gigaamWins)
U27	XCTAssertTrue(StepThree.summary(oneWord(20, missed: 3) + [long(20, gigaamMissed: 3)]).gigaamWins)
U27	XCTAssertEqual(lines.count, 6)
U27	XCTAssertEqual(lines.first, "шаг 3: реплик 2; пропущено — без эталона 3, без звука 1, с живым GigaAM 2")
U27	XCTAssertEqual(lines.last, "вердикт: GigaAM основным (≥ 10 п.п. по WER или по однословным)")
U27	XCTAssertEqual(words.filter { word in lines.contains { $0.lowercased().contains(word) } }, [])
U27	XCTAssertEqual([run.compared, run.lines.count], [20, 6])
U27	XCTAssertEqual(run.lines.first, "шаг 3: реплик 20; пропущено — без эталона 1, без звука 1, с живым GigaAM 1")
U27	XCTAssertEqual(run.lines[4], "модели: GigaAM gigaam-v3-ctc:224757733 sha256 02a443f4 fa9a4816 17cc5144; "
U27	XCTAssertEqual(Array(run.lines[1...3]) + [run.lines[5]],
U27	XCTAssertEqual(texts.count, 60)
U27	XCTAssertEqual(texts.filter { text in
```

✅ **Каждое утверждение ведёт к примеру спеки** (U27), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
