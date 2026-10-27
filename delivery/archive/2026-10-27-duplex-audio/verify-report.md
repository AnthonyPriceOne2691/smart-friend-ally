# Verify report

**Date:** 2026-10-27
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам — дайджест ниже, asserts_without_example: 0; X11, X18, X19 подписаны: X11 — серией 2026-10-23, X18 и X19 — родителем 2026-10-25)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40564235954 (49a357a: delivery, gates, swift — зелёные со второй попытки; первая попытка `swift` упала падением раннера тестов — `Segmentation fault` в прогоне покрытия AllyVoiceFX, пакета вне диффа)
**Commit:** 49a357a (ядро — e0eb2cb, обёртка проигрывателя — ecebe46, проводка — 49a357a; документы — dbd4f4e, подпись — 17d329f и b768cff; слияния main — 5a6a6c8, be604ca, 4711548, e5754f5; эта сдача — следующим коммитом, PR #79)

## Shape oracles
- [x] PASS — pre-commit и pre-push на коммитах поставки: `file-length`, jscpd, секреты, данные ребёнка, SwiftLint 0 находок
  (длинные строки исправлены до коммита), `gate-coverage`, фазовый гейт
- [x] PASS — `okf_validate.py` 0/0; `okf_sync_gate.py`: 18 концептов с `implementation:` сверены
- [x] PASS — `delivery_check --diff-base origin/main`: 0 ошибок; предохранитель — 7 файлов кода, net 424 (+475/−51) из
  800 (план 355, +19%), рисковый путь — 1 (`App/Sources/Audio/`). Предупреждение «нет реляционного оракула»: детектор
  знает только hypothesis и fast-check

## Behavior oracles
- [x] PASS — `swift test` AllyCore на Mac: 121 тест из 121 (новые — X11, X18 дважды, X19). CI, джоба `swift`: AllyCore —
  34 файла `Sources/`, 2107 из 2178 строк, 96%
- [x] PASS — мутации ядра, каждая краснит свой пример, файлы восстановлены. Счётчик и кольцо: «окно не судится», «окно
  после голоса не судится», «минимум не судится», «свой минимум флага не учтён», «кольцо без речи отдаётся», «без
  запаса», «очистка не чистит». Обёртка проигрывателя: «конец — возврат `play`», «начало не сообщается», «кадры не
  учтены»
- [x] PASS — сборка Ally.app для устройства без подписи (xcodegen, `xcodebuild … generic/platform=iOS
  CODE_SIGNING_ALLOWED=NO`) без предупреждений в файлах поставки; оракул артефакта `check_app_artifact.sh` — OK

## Product oracles
- [x] PASS — `human_ok_spec: yes`: X9–X12 — подпись серии e5c86ac раньше кода; X18, X19 и план — подпись 17d329f до
  кода e0eb2cb (L33)
- [x] PASS — X11 (ядро), X18, X19: факты — `eval-smoke.md`
- [ ] НЕ ПРОВЕРЕНО — X9, X10, X12 и телефонная часть X11 — общая сессия теста по постоянному решению родителя
  2026-10-23; waiver в STATUS (`by=human:anthony at=2026-10-23`)

## Исполнение рисковых путей
- `App/Sources/Audio/` — собран для устройства и проверен оракулом артефакта (сеть, ключи Info, бинарники — 6). На
  телефоне не исполнялся: 27.10 родитель — «сегодня проводка, тесты на телефоне — потом»; X9, X10, X12 — в сессии теста
  (waiver). at=2026-10-27

## Spec coverage gaps
- X9, X10, X12 и телефонная часть X11 — сессия теста.
- Её речь дольше 1,5 с поверх голоса доходит только последними 1,5 с — целиком её возьмёт перебивание D6.2.
- С Milena — полудуплекс (решение поставки): её голос мимо движка, эхоподавлению не опора.

## Ревью рисковых мест
- **Конкурентность:** тап, голос, слушание и стоп приходят с разных потоков — всё состояние микрофона живёт на одной
  последовательной очереди `AudioIO`; буфер тапа копируется до очереди. Слушание отвечает ровно один раз: `finish`
  снимает его до ответа.
- **Отмена:** стоп сессии кончает слушание в полёте сразу ответом «никто не говорил» — прежний предел «микрофон гаснет к
  концу слушания (≤ 8 с)» снят (L60). Следующая сессия запускает движок только после останова прежней — в той же
  задаче пробуждения (L69).
- **Порядок графа:** узел голоса подключается в `makeVoice` до `goDuplex`, где включается voice processing (X9); движок в
  этот момент не запущен.
- **Приватность и данные:** микрофон открыт всю сессию, и пока Элли говорит, — это подписанное поведение (X9–X11). Кольцо
  — 1,5 с в памяти, чистится при сне, на диск ничего не пишется. В журнале — числа (`overlap`, `started_over_voice`) и
  версия `audio`, слов нет.
- **Публичный API ядра:** `OverlapCounter`, `VoiceRing`, `SoundingPlayer`, поля `Hearing.overlap` и
  `Hearing.voiceProcessing` (необязательные — реестр без них остаётся полудуплексом).

## Harness metrics (this shipment)

| Metric | Value |
|---|---|
| files_touched / loc_diff | 7 code (+ process docs, knowledge) / +475/−51 (net +424) из 800 |
| commits | 13 до сдачи (документы, подписи, ядро, обёртка, проводка, четыре слияния main, уроки путей, сверка T1); сдача — следующим |
| time_to_accepted_spec | 0h — X9–X12 подписаны серией, X18 и X19 — в тот же день пачкой |
| rework_after_done | 0 |
| harness_hardened | yes — `OverlapTests.swift` (X11, X18, X19), двойник `LatePlayer` |
| implement_retries | 2 — запас кольца 0,8 с вместо 0,3 (правка после подписи, рассмотрена ведущим); предупреждение о захвате детектора |
| verify_fails_before_green | 1 — первая попытка `swift` упала падением раннера вне диффа, перезапуск зелёный |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **20**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
X18	XCTAssertEqual(counter.take(), 1)
X18	XCTAssertEqual(counter.take(), 0)
X18	XCTAssertEqual(counter.take(), 1)
X18	XCTAssertEqual(counter.take(), 0)
X18	XCTAssertEqual(silero.take(), 1)
X18	XCTAssertEqual(counter { $0.take() }, 1)
X18	XCTAssertEqual(ends { $0 }.first ?? -1, 1.05, accuracy: 1e-9)
X18	XCTAssertEqual(counter { $0.take() }, 1)
X18	XCTAssertEqual(counter { $0.take() }, 0)
X18	XCTAssertTrue(cut.cut)
X18	XCTAssertEqual(ends { $0 }.last ?? -1, 2.5, accuracy: 0.002)  // whole frames played: within one at 1 kHz
X18	XCTAssertEqual(ends { $0 }.last ?? -1, 2.5 + 1.0, accuracy: 1e-9)
X11	XCTAssertEqual(pieces.count, 70)  // from 9.4 − 0.8 = 8.6 s to the voice's end
X11	XCTAssertTrue(ring.handOver().isEmpty)
X11	XCTAssertEqual(started ?? -1, 9.04, accuracy: 1e-9)
X11	XCTAssertEqual(pieces.firstIndex(where: loud), 20)  // 8.6 s + 20 frames = 9.0 s, her first syllable
X11	XCTAssertEqual(detector.preRoll.count, 23)  // 8.6 … 9.04 s: the detector's pre-roll holds it too
X11	XCTAssertEqual(detector.preRoll.firstIndex(where: loud), 20)
X19	XCTAssertTrue(ring.handOver().isEmpty)
X19	XCTAssertTrue(loud.handOver().isEmpty)
```

✅ **Каждое утверждение ведёт к примеру спеки** (X11 X18 X19), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver родителя на телефонные X9, X10, X12)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
