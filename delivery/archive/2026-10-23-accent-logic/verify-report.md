# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; Z14–Z16 подписаны родителем 2026-10-23 «Подписываю (Рекомендую)», подпись серии голоса V1–V4)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40017621354
**Commit:** 0403aa6 (документы — 297e1e6 и abce206, слияние V3a — 652d5cf, код и тесты — 1071844, пробы — 1f0b002 и c7a29d5, знание и документы — 9cd072d, 615b9a3, 3caa47e, cb7c39c, правки — 70de9fa (хвост предложений) и c8c89ab (id в строке теста), слияния main — d339945, 3d97898 (V3a f416f21) и 0403aa6 (silero-vad); сдача — следующим коммитом, PR #63)

## Shape oracles
- [x] PASS — pre-commit на всех файлах (STRICT=1, локально и в CI): `file-length` по маске `*.swift *.py *.c *.h`;
  jscpd 4.0.5, пятый прогон — Sources `AllyAccent`, 12 файлов, 0 пар; SwiftLint 0.65.0 — 0 находок (снимок 0; `.build`
  пакета в `excluded` — от V3a, L93); секреты (sha256 в фикстуре — с префиксом `sha256:`, L38); данные ребёнка;
  `gate-coverage`. Доктор контура в CI — `AUTO 46 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений; `okf_sync_gate.py --base origin/main`: concept
  `engineering/accent-placer` — `implementation:` дополнен исходниками логики
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main` после слияния main с V3a: 0 ошибок; предохранитель — 11 файлов, net 684 из 800, рисковых путей 0. Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check, а оракул здесь дифференциальный — повтор Python на 182 текстах
- [x] PASS — запись адаптации и env (L94): пакет в `LINT_SWIFT_PACKAGES`, пятый прогон jscpd, `adapted.json`, карта
  ролей — от V3a, сверены на каждом слиянии main; своих правок CI у поставки нет

## Behavior oracles
- [x] PASS — `swift test --disable-keychain` на Mac (Xcode 27, Swift 6.4): `RuAccentReplayTests` 12 из 12 (Z14 — 163 из
  163 и 9 фраз страницы, Z15 — 8 из 8, Z16 — «аксол+отлик», 9 проб причуд, адаптер токенизаторов V3a), `TokenizerParity`
  V3a — 2 из 2. Двойник: чужих входов 0, несделанных записанных вызовов 0 на всех 182 текстах. Покрытие на Mac —
  `AllyAccent` 556 из 586 строк, 94%. CI на Linux, джоба `swift`: прогон 40017621354 на 0403aa6 (swift-6.4-RELEASE): `swift test` пакета зелёный — все 12 тестов повтора и токенизаторы V3a (настоящие файлы на Linux пропущены видимо); `AllyAccent` — 12 файлов `Sources/`, 555 из 587 строк, 94%; отрицательный контроль порогом 101% покраснел; джобы gates и delivery зелёные, доктор контура в CI — `AUTO 46 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`
- [x] PASS — ожидания — из эталона, а не от автора (§3.1d): тексты Z14–Z16 вернул Python в записи V3a (sha256
  `pipeline.jsonl` сверен с `manifest.json`); пробы — тексты того же конвейера Python (RUAccent 1.5.8.3, int8, tiny,
  «поняла») с настоящими токенизаторами и заданными логитами; генератор пишет фикстуру, только если Python сам
  повторяет по ней все 182 текста — самопроверка поймала пробы без добавки «о» → «+о»
- [x] PASS — запас решений на записи: ближайшая оценка модели слов — в 0,0033 от порога 0,55, ближайшая пара омографов —
  0,033 по логиту, токены модели «ё» — 0,011 по вероятности; разница `expf` Linux и Mac (ulp) решений не переворачивает
- [x] PASS — мутации после коммита (П30, по механизму — L59; каждая меняет то, что судит оракул — L64), 25 из 25 убиты,
  файлы восстановлены из git: фильтр не снимает знаков; двойная кавычка остаётся в фильтре; фраза не режется на
  предложения; хвост из пробельных — отдельное предложение; « - » не становится « ~ »; склейка без
  `delete_spaces_before_punc`; `fix_capital` без сверки длины; метка YO — индекс PUNCT; подслово не склеивается со
  словом; неизвестный токен считается подсловом; модель «ё» без условия «е»; среднее логитов вместо среднего
  вероятностей; всегда пакетный путь; особое слово не режется тройками; чётная группа больше трёх не режется парами;
  ответы ложатся с конца; омограф ищется строчными; без «поняла»; без «о» → «+о»; словарь не перебивает модель; порог
  0,55 не держится; знак на букве позиции; позиция 0 без знака; STRESS_SECONDARY ставит знак; второй «+» без сдвига.
  На одной записи стенда первые 23 дали 21: склейка подслов и среднее логитов выжили — данные стенда эти ветки не
  ходят; их закрыла проба «ё» (L102)
- [x] PASS — эквивалентные мутации названы и в счёт не идут: softmax по паре вместо всего пакета (меняет решение только
  при равенстве до ulp) и «фраза группы — своя» вместо фразы первой гипотезы (различимо только там, где Python падает)
- [x] PASS — Builder ≠ Verifier: код и тесты писал агент-исполнитель; мутации, гейты и CI — механика; ожидания —
  тексты Python, примеры подписаны родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23 «Подписываю (Рекомендую)», подпись серии голоса V1–V4, разбиение
  V3 — вариант A d92e8c7); спека с примерами — коммитами `297e1e6` и `abce206` раньше кода `1071844` (L33)
- [x] PASS — примеры Z14–Z16 (доля V3b): факт по каждому — `eval-smoke.md`

## Исполнение рисковых путей

- `runtime_paths: none` — чистая логика текста над словарями и выходами моделей: без экрана, прав, звука, железа и
  файлов платформы, кроме чтения JSON словарей. Исполнение — `swift test --package-path Packages/AllyAccent` на Mac
  (macOS 27) и в CI на Linux. at=2026-10-23

## Spec coverage gaps
- **Полные Z14–Z18** — настоящие модели через `AllyOnnx` и паритет текста с Python от фразы до фразы — V3c на Mac; здесь —
  логика по записанным выходам моделей.
- **Вызывающего нет до V4 (L50):** `RuAccentPlacer` готов, `SpeechTextPipeline` приложения его не зовёт; словари в
  приложение копирует команда V4 (распаковка `.gz` в четыре JSON).
- **Где Python падает** (омографов больше, чем ответов: «поняла» дважды; знак модели слов на [eos]) — эталона нет; Swift
  не падает: остаток омографов без знака, знак за концом слова пропущен (`decisions.md`).
- **razdel:** правила сокращений не перенесены (спека); на 173 позициях простое разбиение совпало с razdel во всех.

## Ревью рисковых мест
- **Публичный API:** `RuAccentPlacer` (`StressPlacer`), `AccentDictionaries` (`init(accents:omographs:yoWords:yoHomographs:)`,
  `init(directory:)`), `AccentModels` (стык ведущего), `AccentTokenizers`, `RuAccentTokenizers`, `AccentError`. Пакет
  `AllySpeechText` и приложение не менялись; зависимость — локальный `../AllySpeechText` (не новое имя для гейта).
- **Данные ребёнка:** в фикстуре — фразы стенда без имён (категория P снята записью), фразы страницы образцов и пробы;
  единственное имя — вымышленный «Тёма»; детских записей нет. Лицензия данных RUAccent — MIT.
- **Падения:** индексы логики под защитой — выход модели не той формы даёт `AccentError.shape`, а не ловушку.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 11 code (+9 process docs) / +686/−2 (net +684); предохранитель — 11 файлов, net 684 из 800 (план ≈ 490, с поправкой +50% ≈ 735) |
| commits | 15 своих до сдачи (первый родитель): документы прежнего исполнителя — 2, код и тесты — 1, пробы — 2, документы и знание — 4, правки — 2 (70de9fa, c8c89ab), слияния — 4 (V3a 652d5cf, main d339945, 3d97898, 0403aa6); генератор метрик считает 20 — с коммитами ветки V3a, пришедшими слиянием; сдача — следующим |
| time_to_accepted_spec | 0.0h — подпись родителя под серией стояла до спеки V3b |
| rework_after_done | 0 |
| harness_hardened | yes — `RuAccentReplayTests.swift` (повтор Python по записи, 9 проб причуд), двойник `ReplayTwin` с отказом на чужом входе, 25 мутаций; генератор фикстуры с самопроверкой Python (стенд, вне git) |
| implement_retries | 2 — переносы строк длиннее 120 знаков (SwiftLint) до первого коммита; генератор: пробы без добавки «о» → «+о» — поймала самопроверка Python до записи фикстуры |
| verify_fails_before_green | 0 — красных прогонов CI нет; мутации: на записи стенда 2 из 23 выжили (склейка подслов, среднее логитов) → проба «ё», 25 из 25; дайджест привязывал утверждения стенда к Z16 → литерал убран (c8c89ab) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **29**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
Z14	XCTAssertEqual(stand.count, 163)
Z14	XCTAssertEqual(try mismatches(stand), [])
Z14	XCTAssertEqual(page.count, 9)
Z14	XCTAssertEqual(try mismatches(page), [])
Z15	XCTAssertEqual(group.count, 8)
Z15	XCTAssertEqual(try mismatches(group), [])
Z16	XCTAssertEqual(item.textOut, "аксол+отлик")
Z16	XCTAssertEqual(try mismatches([item]), [])
Z14	XCTAssertEqual(odd.python, "Мы уж+е начал+а.")
Z14	XCTAssertEqual(odd.mismatches, [])
Z14	XCTAssertEqual(triples.python, "Я начал+а, ты начал+а.")
Z14	XCTAssertEqual(triples.mismatches, [])
Z14	XCTAssertEqual(pairs.python, "Там мук+а и мук+а начал+а.")
Z14	XCTAssertEqual(pairs.mismatches, [])
Z14	XCTAssertEqual(four.python, "Там йод+атович и йодатов+ич.")
Z14	XCTAssertEqual(four.mismatches, [])
Z14	XCTAssertEqual(capital.python, "ёжик и Ёжик спят.")
Z14	XCTAssertEqual(capital.mismatches, [])
Z14	XCTAssertEqual(transfer.python, "М+оло+ко.")
Z14	XCTAssertEqual(transfer.mismatches, [])
Z14	XCTAssertEqual(mark.python, "Кошк+а.")
Z14	XCTAssertEqual(mark.mismatches, [])
Z14	XCTAssertEqual(text.python, "Мама сказала привет - и ушла +о море, а 5 кот+ов  спят.  ")
Z14	XCTAssertEqual(text.mismatches, [])
Z14	XCTAssertEqual(yo.python, "Вёсла е+е \(long) е+е.")
Z14	XCTAssertEqual(yo.mismatches, [])
Z14	XCTAssertEqual(tokenizers.yo("ты мне её покажешь?"), wordPiece.encode("ты мне её покажешь?"))
Z14	XCTAssertEqual(tokenizers.omograph(text, "понял+а"), bpe.encode(text, pair: "понял+а"))
Z14	XCTAssertEqual(tokenizers.accent("Кошка"), char.encode("Кошка"))
```

✅ **Каждое утверждение ведёт к примеру спеки** (Z14 Z15 Z16), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
