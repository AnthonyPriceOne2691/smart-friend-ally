# Verify report

**Date:** 2026-10-23
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; U1–U5 подписаны родителем 2026-10-23 «Подписываю (Рекомендую)»)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40001339477
**Commit:** 0fde01f (код — 35ca564, слияния main: с R и Ш1 — aa6a36a, с V2 — 0fde01f; спека — 74ada91, подпись — 3b68733, eval-smoke — b640552; эта сдача — следующим коммитом, PR #46 `MERGEABLE`)

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length`, jscpd, секреты, данные ребёнка, SwiftLint 0.65.0 — 0 находок,
  `gate-coverage`; pre-push — фазовый гейт, ратчет снимков, `new-dependency`
- [x] PASS — `okf_validate.py`: 0 ошибок, 0 предупреждений; `okf_sync_gate.py --base origin/main`: 8 концептов с
  `implementation:` сверены (`engineering/turn-detector`, `session`, `voice-loop`, `safety-below-model`)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок; предохранитель — 19 файлов, net 261
  из 800 (план 371). Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check; свойство на
  200 ходах из плана снято словом родителя 2026-10-23 «сейчас собираем, оптимизировать будем потом» — только подписанные
  примеры

## Behavior oracles
- [x] PASS — `swift test` AllyCore на Mac (Xcode 27): 63 теста из 63, из них 6 новых (U1–U5); S1–S12, W1–W7, B1–B12,
  G-тесты R и A17, A25–A27 — без правок утверждений. CI на Linux, джоба `swift`: AllyCore — 22 файла `Sources/`, 1010 из
  1049 строк, 96% (по своему `Sources/`, L41); отрицательный контроль порогом 101% покраснел
- [x] PASS — мутации в ту же сессию (П30), 4 из 4 убиты, файлы восстановлены: вопросительное слово раньше «или» (U1, (к) →
  `open`); счёт только в последней фразе (U1, (о) → `open`); «не расслышала» сбрасывает тип (U2, типы `…, counting,
  open`); `done()` без сверки слушания (U4, `endTurn()` 3 раза)
- [x] PASS — сборка приложения для устройства без подписи (`xcodebuild … CODE_SIGNING_ALLOWED=NO`) после слияния main с R
  и Ш1 и оракул артефакта `scripts/lint/check_app_artifact.sh` — зелёные
- [x] PASS — Builder ≠ Verifier: код и тесты — агент-исполнитель; мутации, гейты и CI — механика; ожидания — примеры,
  подписанные родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-23); подпись — коммит 3b68733 раньше кода 35ca564, eval-smoke —
  b640552 до кода (L33)
- [x] PASS — примеры U1–U5: факт по каждому — `eval-smoke.md` (тесты, мутации, A23)
- [ ] НЕ ПРОВЕРЕНО — U6 (телефон: пауза 1,2 с после открытого вопроса, «Да», «Я всё», `turn_kind` в `turns.jsonl`):
  по ответу 8 родителя в подписи серии — телефон после D7.1, waiver в STATUS (`by=human:anthony at=2026-10-23`). На
  телефон в этой поставке ничего не ставилось

## Изменение поверхности модели
- элемент: `App/Resources/model.json` (sha256 `b6fc9e78…` → `5240c360…`, снимок `delivery/model_surface.txt` обновлён)
- почему: ключи слуха `turn` и `listen_timeout` переехали в реестр слуха `App/Resources/hearing.json`; рантайм,
  сэмплинг, персона, голос, вес и тайм-аут первой фразы — прежние, `LlamaSettings` их читает как раньше
- оракулы: A23 (`StandParityTests`) на Mac — токены 37 из 37, ответы 37 из 37 при n_ctx 4096 и 37 при 8192: ответы модели
  равны стенду v2.4 (дифференциальный прогон против прежней поверхности — не хуже ни в одном случае)
- порча промпта: n/a — промпт персоны не тронут
- провайдер: llama.cpp b10809 (macOS-срез того же xcframework), Gemma 4 E4B Q4_K_M, веса `~/models`
- цена: 193 с одного прогона, машина под нагрузкой параллельных сессий
- at=2026-10-23

## Spec coverage gaps
- **U6 на телефоне** — в сессии теста после D7.1 вместе с U14–U15 (ответ 8 родителя).
- **Тап по Элли во время слушания** на детском экране — сейчас тап по кругу заглушки R (`VoiceLoop.childWake`); Ш3
  подключит его при замене тела `ChildScreen` (решение ведущего 2026-10-23).
- **Спекуляция** — D7.1; до неё открытые ходы отвечают на ≈ 1 с позже: на телефон D7 без D7.1 не ставится.

## Ревью рисковых мест
- **Публичный API:** `Listener.listen(_ kind:)` и `endTurn()` — новая форма протокола слуха (двойник и `PhoneListener`
  обновлены); `Conversation.done()`; `Session.expect`; `TurnKinds`; `Hearing`; `TurnEnding`; `TurnDetector(kind:timing:
  ending:)` — новый параметр со значением по умолчанию; `TurnTrace.turnKind`; `ModelRegistry` без `turn` и
  `listenTimeout`.
- **Конкурентность:** `done()` входит в актор драйвера и зовёт слух только при `session.state.listens`; просьба конца —
  флаг под замком, его берёт определитель на кадре тапа; с R две сессии на одном слухе — `done()` зовёт показанную.
- **Безопасность ребёнка:** тип хода меняет только то, сколько слух ждёт тишины: маршрутизатор, `forget` и контракт хода не
  тронуты (`safety-below-model.md`).
- **Данные:** в следе нет слов (U2 — кириллицы 0); `turn_kind` — латиницей.
- **Цепочка гейтов:** гейты, `merge_guard.sh` и `.pre-commit-config.yaml` поставка не меняет.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 19 code (+ process docs) / +310/−49 (net +261) из 800 |
| commits | 8 до сдачи (спека, вёрстка плана, подпись, eval-smoke, код, слияние main, факты verify); сдача — следующим |
| time_to_accepted_spec | 0.4h |
| rework_after_done | 0 |
| harness_hardened | yes — `TurnKindTests.swift`, `HearingTests.swift` (новые оракулы), U2, U4, U5 и 4 мутации |
| implement_retries | 1 — после слияния R `done()` переадресован показанной сессии |
| verify_fails_before_green | 0 — прогоны CI 40000764754 (0a52392) и 40001339477 (0fde01f, после слияния main с V2) зелёные во всех трёх джобах (swift, delivery, gates); PR #46 `MERGEABLE` (L35) |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **23**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
U2	XCTAssertEqual(talk.ear.kinds, [.open, .closed, .counting, .counting])
U2	XCTAssertEqual(talk.sink.records.map(\.turnKind), [nil, "open", "closed", "counting", "counting"])
U2	XCTAssertEqual(talk.sink.records.map(\.source),
U2	XCTAssertEqual(talk.sink.records.last?.end, "rest")
U2	XCTAssertEqual(talk.model.calls, 2)
U2	XCTAssertNil(line.range(of: "[А-Яа-яЁё]", options: .regularExpression), line)
U4	XCTAssertEqual(talk.ear.ended, 1)
U4	XCTAssertEqual(talk.voice.sentences, greeting + [misheard] + restPhrase)
U3	XCTAssertEqual(TurnKind.allCases.map { hearing.turn.tail($0) }, [1.8, 1.2, 2.5])
U3	XCTAssertEqual([hearing.turn.tentative, hearing.turn.preRoll, hearing.turn.maxTurn, hearing.listenTimeout],
U3	XCTAssertEqual(Set(keys), ["model", "runtime", "sampling", "persona", "voice", "voice_rate",
U3	XCTAssertEqual(try ModelRegistry.decode(model).model.bytes, 4_977_171_584)
U3	XCTAssertEqual(partial.tail(.counting), 1.8)
U4	XCTAssertEqual(done.map(\.name), ["ended"])
U4	XCTAssertEqual(done.first?.at ?? -1, 1.90, accuracy: 1e-6)
U4	XCTAssertEqual(done.first?.time ?? -1, 1.48, accuracy: 1e-6)
U4	XCTAssertEqual(tail.first?.at ?? -1, 3.28, accuracy: 1e-6)
U4	XCTAssertEqual(early.map(\.name), ["ended"])
U4	XCTAssertEqual(early.first?.at ?? -1, 0.30, accuracy: 1e-6)
U5	XCTAssertEqual(long.prefix(2).map(\.name), ["started", "limit"])
U5	XCTAssertEqual(long.first?.at ?? -1, 0.54, accuracy: 1e-6)
U5	XCTAssertEqual(long.count > 1 ? long[1].at - long[0].at : 0, 30, accuracy: frameSeconds)
U1	XCTAssertEqual(TurnKinds.shared.kind(after: sentences), kind, sentences.joined(separator: " "))
```

✅ **Каждое утверждение ведёт к примеру спеки** (U1 U2 U3 U4 U5), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (с waiver родителя на телефонный U6)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
