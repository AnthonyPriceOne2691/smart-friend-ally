# Verify report

**Date:** 2026-10-30
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все новые утверждения ведут к примерам спеки — дайджест ниже, asserts_without_example: 0; N1–N6 подписаны родителем 2026-10-30 до кода)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/41101726059 (gates, delivery, swift — зелёные на d660731)
**Commit:** d660731 (спека — 903e8c4, подпись — 00f0102, вопрос в спеке — 239405e, план и eval-smoke до кода — 1161b7c, код — e09947b, знание — c85f20a, уровень без скачка — 64247cc; main влит до f9bcc32); macOS-джоба по метке на образе `xcode-27` — https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/41101731000; сдача — следующим коммитом, PR #94

## Shape oracles
- [x] PASS — pre-commit на всех файлах локально и в CI: `file-length`, jscpd — рост 0; SwiftLint — 0 находок (ратчет 0),
  `child_screen_text` и `child_screen_gestures` без новых исключений; секреты, данные ребёнка, граница демо,
  `gate-coverage`. Класс `VoiceLoop` уткнулся в предел 300 строк: помощники `memory`, `uptime`, `line` стоят в расширении
  того же файла.
- [x] PASS — `okf_validate.py`: 0 ошибок; `okf_sync_gate.py --base origin/main`: концепты сверены. В том же диффе правлены
  `engineering/character-rendering`, `product/look-and-feel`, `engineering/voice-loop`, `engineering/design-demo`,
  `product/child-mode`, `engineering/safety-below-model`, `ops/test-session`.
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main`: 0 ошибок. Предохранитель — 15 файлов, net 208 из 800
  (план ≈ 215). Предупреждение «нет реляционного оракула»: детектор знает только hypothesis и fast-check; реляционный
  оракул здесь — V34: уровень `Motion` совпадает с `Syllables` того же зерна кадр в кадр (L128).

## Behavior oracles
- [x] PASS — `swift test --disable-keychain --package-path Packages/AllyShell` на Mac под `nice -n 10`: `ShellCoreTests` — 37, из них
  покраснел V12 (разбор ниже); после правки V12, V34 и N1–N5 — 8 из 8. Весь пакет со снимками и настоящим стеклом — в
  macOS-джобе.
- [x] PASS — CI Linux, джоба `swift`: зелёная; покрытие AllyShell — 12 файлов `Sources/`, строк 703 из 706, 99%
  (порог 70%).
- [x] PASS — macOS-джоба `ios.yml` по метке (https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/41101731000, образ `xcode-27`): AllyShell — 37 из 37 со снимками и стеклом; `Ally.app` —
  BUILD SUCCEEDED (проводка `VoiceLoop`, `SystemVoice`, `AllyApp`, `ChildScreen`), оракул артефакта — OK; `AllyDemo.app` —
  BUILD SUCCEEDED; граница демо — OK на обоих.
- [x] PASS — мутации в ту же сессию (П30, L64 — по видимому эффекту), 7 из 7 убиты, файлы восстановлены:
  - «рот от состояния» (`talking` без `sound`): N1 и N4 — уровень 0,056 при пороге 0,02; N5 — сценарий 0, 0,054 при 0,05;
    N2 — 0,75, N3 — 0,16;
  - «поза от состояния» (без удержания): N1 — вес «думает» 0,88 при 0,9, N4 — вес взмаха 0,116 при 0,1;
  - «рот гаснет втрое медленнее» (`closing` 3): N3 — 0,54, N2 — 0,136;
  - «рот закрывается скачком» (`closing` 1000): V12, сценарий 0 — 1,76 границы;
  - «пауза сбрасывает позу»: N2 — вес «говорит» 0,59 при 0,9;
  - «из сна — без пробуждения»: N4 — вес «слушает» 0;
  - «генератор и `Motion` врозь» (16 вместо `closing` в `Syllables`): V34 — 0,235 против 0,185 (L128).
- [x] PASS — красное по делу, пороги не менялись: первый прогон V12 краснел на сценарии 1 (1,92 границы). Переданный уровень
  «как есть» был безопасен только при постоянном входе, а со звуком он появляется и исчезает. Теперь он приходит и уходит
  со скоростью закрытия рта (`Motion.eased`), V34 «уровень идёт как есть» верен (L186).
- [x] PASS — Builder ≠ Verifier: код писал агент-исполнитель; мутации, гейты и CI — механика; ожидания — примеры,
  подписанные родителем до кода.

## Product oracles
- [x] PASS — `human_ok_spec: yes`: родитель 2026-10-30 через ведущего, строку вписал ведущий (коммит 00f0102). Вопрос и
  ответ дословно — раздел «Подпись» в `spec.md`.
- [x] PASS — примеры спеки: факт по каждому — `eval-smoke.md` (N1–N6).
- [x] PASS — вид: видео симулятора `local/frames/talk.mp4` (вне git), кадры через 0,5 с от пробуждения. Снимков экрана
  телефона нет (L46).

## Исполнение рисковых путей

- `App/Sources/` — признак «звучит» от проигрывателя до детского экрана. Демо-цель в симуляторе командой `bash
  scripts/run_demo.sh` (окно симулятора не открывалось, сборка и запуск теми же шагами): видео 17,7 с — после пробуждения
  глаза открыты, поза «слушает», ни взмаха, ни рта; со звуком пошли взмах и рот; после «думает» рука у подбородка держится
  до звука; в паузе между фразами рот закрыт, поза «говорит» остаётся. Проводка `VoiceLoop`, `SystemVoice`, `AllyApp`, `ChildScreen` собрана в `Ally.app`
  macOS-джобой (`xcodebuild -scheme Ally -destination 'generic/platform=iOS'`). С настоящим голосом — общая сессия теста
  (`ops/test-session` 3.5: N6), решение родителя 2026-10-30: на телефон всё идёт одной сборкой. at=2026-10-30

## Spec coverage gaps
- **Точность рта и обрезка тишины.** Точность рта зависит от обрезки тишины: сейчас `SupertonicRenderer` не режет её края, в файле фразы перед первым
  слышимым звуком 0,4–0,64 с, а в конце ≈ 0,7 с, и `began`/`ended` идут на границах файла, а не слышимого звука.
  Обрезку делает поставка голоса (замер и решение ведущего 2026-10-30), сигнал и N1–N6 не меняются; обе поставки
  едут в одной сборке, проверка на слух и на глаз — общая сессия теста.
- **Milena.** Ветка `SystemVoice` (делегат `didStart`, `done`) проверена сборкой и чтением: Milena — запасной голос.

## Ревью рисковых мест

- **`Motion.step`.** Новый вход `sound` по умолчанию `false`: забытый вход даёт Элли без рта, а не рот без звука. Прежние
  вызовы в тестах идут через `film`, где без явного звука голос звучит всю фазу речи, поэтому V11–V17 и V34 верны как были.
- **Группы пружин (L86).** Удержание позы — смена группы, `voiced` живёт в пределах фазы. Паузы между фразами группу не
  меняют; `held` переводит сон и дрёму в «слушает».
- **`Syllables`.** Вне речи уровень падает линейно, 10 в секунду, вместо прежнего 16/с по экспоненте. В речи числа Ш2в те
  же: V34 сверяет генератор кадр в кадр.
- **`VoiceLoop`.** Новое только свойство `sounding` и замыкание `sounds`: в `makeVoice` им пользуются `SoundingPlayer` и
  `SystemVoice`. Ход, контракт, маршрутизатор и слушание его не читают. Порядок `began` → `ended` держит один поток задачи
  `speak`.
- **Безопасность ребёнка:** на детском экране ни слов, ни кнопок не прибавилось; правила ниже модели не тронуты.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main; MANUAL-поля заполнены на сдаче -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 15 кода под предохранителем (+13 документов и знания) / +271/−63, net 208 из 800; план ≈ 215 |
| commits | 10 до сдачи; сдача — следующим |
| time_to_accepted_spec | 19,4 ч (спека 903e8c4 вечером 2026-10-29, родитель спал; подпись 00f0102 — 2026-10-30) |
| rework_after_done | 0 |
| harness_hardened | yes — `MouthTests` (N1–N5), генератор `Talk` в свойствах V12 и V35 |
| implement_retries | 3 — ратчет SwiftLint (строки и класс `VoiceLoop` на пределе 300), V12 на переданном уровне (L186), N5 с 30 с на 15 с (под load 170 — девять минут) |
| verify_fails_before_green | 0 в CI (quality 41101726059, ios 41101731000); локально — V12 до правки уровня |
| est_token_or_cost | n/a |

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **22**, из них без ссылки на пример спеки: **0**.

```
N1	XCTAssertLessThanOrEqual(shot.level, 0.02, "\(shot.time)")
N1	XCTAssertLessThanOrEqual(shot.frame.pose.mouthOpen, 0.02, "\(shot.time)")
N1	XCTAssertGreaterThanOrEqual(shot.weights[thinks], 0.9, "\(shot.time)")
N1	XCTAssertGreaterThanOrEqual(peak(shots, from: 2.9, to: 3.4), 0.6)
N1	XCTAssertGreaterThanOrEqual(shot(shots, at: 3.5).weights[talks], 0.9)
N2	XCTAssertLessThanOrEqual(shot.level, 0.05, "\(shot.time)")
N2	XCTAssertGreaterThanOrEqual(shot.weights[talks], 0.9, "\(shot.time)")
N2	XCTAssertGreaterThanOrEqual(peak(shots, from: 4.85, to: 5.35), 0.6)
N3	XCTAssertGreaterThanOrEqual(level, 0.6)
N3	XCTAssertEqual(shot(shots, at: cut).level, level, accuracy: 0.11)
N3	XCTAssertLessThanOrEqual(shot(shots, at: cut + 0.12).level, 0.05)
N4	XCTAssertLessThanOrEqual(shot.level, 0.02, "\(shot.time)")
N4	XCTAssertLessThanOrEqual(shot.weights[waves], 0.1, "\(shot.time)")
N4	XCTAssertGreaterThanOrEqual(shot(shots, at: 3.05).weights[listens], 0.9)
N4	XCTAssertGreaterThanOrEqual(shot(shots, at: 3.05).frame.eyeOpen, 0.95)
N4	XCTAssertGreaterThanOrEqual(shot(shots, at: 3.7).weights[waves], 0.9)
N4	XCTAssertGreaterThanOrEqual(peak(shots, from: 3.1, to: 3.6), 0.6)
N5	XCTAssertLessThanOrEqual(motion.voiceLevel, 0.05, "scenario \(scenario) at \(time)")
N5	XCTAssertLessThanOrEqual(pose.mouthOpen, 0.1, "scenario \(scenario) at \(time)")
N5	XCTAssertGreaterThanOrEqual(widest, 0.6)
N5	XCTAssertEqual(held.pose.mouthOpen, 0.335, accuracy: 0.01)
N5	XCTAssertNotNil(ImageRenderer(content: LiveScene(phase: .asleep, sounding: false)
```

Каждое утверждение ведёт к примеру спеки (N1–N5), подписанному родителем до кода. Две последние строки — прежние
проверки V34 и V8, переписанные под новую подпись вызова; к N5 их приписала последняя метка дайджеста (L113).

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
