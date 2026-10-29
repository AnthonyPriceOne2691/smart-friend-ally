# Verify report

**Date:** 2026-10-29
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к примерам спеки — дайджест ниже; Y1–Y11 подписаны родителем 2026-10-29)
**CI run:** _после пуша_
**Commit:** _после пуша_ (спека — 7057e53, подпись — 73eaa1e, eval-smoke до кода — fdac009)

## Shape oracles
- [x] PASS — SwiftLint 0.65 по всему дереву — 0 находок, ратчет 0 → 0; строки ≤ 120; правило `inline_prompt` — строки
  консоли короче 40 знаков после первой буквы (длинная собрана из двух, как «память выключена: …»)
- [x] PASS — `okf_validate.py`: 0 ошибок (52 файла); в том же диффе правлены `product/look-and-feel` (правило 14, раздел
  «Музыка», `implementation:`), `engineering/voice-loop` (музыка в приложении, `implementation:`), `ops/test-session`,
  `log.md`
- [ ] строгий `delivery_check --require-ci --diff-base origin/main` — после пуша

## Behavior oracles
- [x] PASS — `swift test --filter ShellCoreTests` на Mac (Xcode 27.1, `nice -n 10`) после слияния main (88e9920): 46 из 46;
  музыкальные после сжатия до предохранителя — 11 из 11 (Y1–Y10 и свойство на 100 сценариях); CI Linux — после пуша
- [x] PASS — мутации на окончательных тестах (L64 — по видимому эффекту), 12 из 12 убиты падением тестов, а не сборкой,
  файлы восстановлены:
  - «уход за 0 с» — Y2, Y5, Y6/Y7 и свойство; «„еле слышно“ = обычная громкость» — Y2, Y4, Y5;
  - «возврат без ожидания» — Y1, Y4, Y5, Y6/Y7, Y8; «консоль играет» — Y6/Y7; «Milena в сессии звучит» — Y8;
  - «граница громкости 0..<1» — Y9; «пауза — покой» — Y3;
  - «путь с конца прежнего, а не с уровня» — Y5 и свойство (скачок); «вверх до „еле слышно“ с ожиданием» — Y5;
  - шкатулка: «петля на кадр длиннее», «лево и право местами», «эхо без хвоста по кругу» — Y10 (sha256).
- [x] PASS — Y10: Swift-порт собирает петлю байт в байт как генератор страницы — sha256 WAV стенда
  `2d0ab760…` = файл страницы; sha256 отсчётов `d446a126…` — тест на Mac (CryptoKit не нужен: SHA-256 в тесте, Linux —
  CI). Сборка петли без оптимизации — 0,61 с (с итераторами было 42,7 с), с оптимизацией — 0,08 с
- [x] PASS — проверка типов `BackgroundMusic.swift` на SDK macOS 27 с собранным `ShellCore` — 0 ошибок и 0 предупреждений
  (вызовы iOS 27 `connectNode`, `playAudio`)
- [ ] сборка `Ally.app` без подписи и оракул артефакта — по слову ведущего (до 00:00 на Mac шёл отбор моделей)

## Product oracles
- [x] PASS — `human_ok_spec: yes` (родитель 2026-10-29, «Подписываю (Рекомендую)» через ведущего): покой 0,8, в разговоре
  −20 дБ, уход 0,4 с, возврат через 2 с за 3 с, строка `music.json`, мелодия кодом
- [x] PASS — трек выбран родителем на слух (№7 «Шкатулка Элли»; реплики дословно — `decisions.md`)
- [ ] Y11 — замер из колонок завтра (слово родителя: «Не, давай завтра лучше»). Без звука уже снято:
  - распознавание 30 чистых фраз `say` (Milena) — 5 из 135 слов, 3,7%;
  - те же фразы, смешанные с петлёй цифрой, совсем без эхоподавления: музыка на 16 дБ тише фразы — 3,7%, на 6 дБ — 4,4%
    (+0,7 п.п.);
  - Silero на одной приглушённой музыке (×0,08, всё время «поверх голоса») — 0 кадров речи, 0 перебиваний.

## Исполнение рисковых путей

- `App/Sources/Audio/` — без звука at=2026-10-29: Swift-петля стенда (`MusicAEC render`) — байт в байт WAV страницы;
  распознавание и Silero стенда на файлах; проверка типов `BackgroundMusic.swift` на SDK macOS 27 — 0 предупреждений;
  сборка `Ally.app` и оракул артефакта — macOS-джоба CI по метке `macos`. Граф с voice processing из колонок — Y11
  завтра (слово родителя); приложение целиком на телефоне — сессия теста

## Spec coverage gaps
- **Телефон:** эхоподавление динамика телефона, громкость `.voiceChat` в покое, провал еле слышной музыки на запуске
  движка — общая сессия теста (`ops/test-session`, 3.6).
- **Звонок посреди разговора:** после конца прерывания узел музыки может остаться молчащим до конца сессии (движок
  перезапускает `AudioIO`, узел не перезапускается) — редкий случай, в покое проигрыватель продолжает.

## Ревью рисковых мест

- **Микрофон и эхо (безопасность распознавания).** В разговоре звучит музыка 0,08 через движок голоса. Если
  эхоподавление телефона вычтет её хуже, чем на Mac, распознавание дочки ухудшится, а Silero может поднять ложное
  перебивание. Без эхоподавления, цифрой: +0,0 п.п. при музыке на 16 дБ тише фразы, +0,7 п.п. на 6 дБ, 0 кадров речи у
  Silero. Из колонок — Y11. Откат без кода: `"duck_db": -60` (почти тишина) или `"on": false` в `music.json`.
- **Правило 4 (микрофон закрыт во сне).** В покое музыка идёт мимо движка (`AVAudioPlayer`), движок с voice processing
  запускается только в `wake()` после `duck()`. Музыка не держит движок и не запускает его.
- **Порядок пробуждения.** `wake()` теперь ждёт `duck()` (≤ 0,4 с) до `audio.start()`. Окно двойного тапа выросло с
  миллисекунд до 0,4 с — второй тап раньше поставил бы вторую сессию сразу после первой (L69); теперь его не берёт сторож
  `waking`. Консоль музыку не ждёт: `duck()` у консоли возвращается сразу.
- **Аудиосессия.** Музыка категорию не трогает (L130, L144); до конца прогрева её нет (экран загрузки — тишина).
- **Двоичное в git.** Звука в git нет: петлю собирает код, хэш закреплён тестом (`pragma: allowlist secret` у sha256 —
  это хэш, не секрет).

## Assertion digest (ревью ожиданий, не кода)

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **44**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
Y10	XCTAssertEqual([MusicBox.frames, Self.loop.count], [1_924_364, 2 * 1_924_364])
Y10	XCTAssertEqual(sha256(bytes), wave)
Y10	XCTAssertLessThanOrEqual(seam, inside[channel], "channel \(channel)")
Y10	XCTAssertGreaterThan(seam, 0, "channel \(channel): a seam of silence would hide a gap")
Y10	XCTAssertEqual(peak, Int(0.70 * 32767), "the generator scales the loudest sample to 0,70")
Y1	XCTAssertEqual(MusicCue.of(idle, line: line), .full)
Y1	XCTAssertEqual(levels([(.full, 0)], at: [0, 2, 3.5, 5, 60]), [0, 0, 0.4, 0.8, 0.8])
Y2	XCTAssertEqual(MusicCue.of(scene, line: line), .quiet)
Y2	XCTAssertEqual(line.quiet, 0.08, accuracy: 1e-9)
Y2	XCTAssertEqual(levels([(.full, 0), (.quiet, 10)], at: [10, 10.2, 10.4, 30]), [0.8, 0.44, 0.08, 0.08])
Y2	XCTAssertEqual(fader([(.full, 0), (.quiet, 10)]).end, 10.4, accuracy: 1e-9)
Y3	XCTAssertEqual(MusicCue.of(scene, line: line), .quiet, "\(phase)")
Y3	XCTAssertEqual(MusicCue.of(idle, line: line), .full)
Y4	XCTAssertEqual(levels(cues, at: [101, 102, 103.5, 105]), [0.08, 0.08, 0.44, 0.8])
Y5	XCTAssertEqual(waiting.end, 101, accuracy: 1e-9)
Y5	XCTAssertEqual(waiting.level(at: 101), 0.08, accuracy: 1e-9)
Y5	XCTAssertEqual(rising.end, 103.9, accuracy: 1e-9)
Y5	XCTAssertEqual(rising.level(at: 103.7), 0.26, accuracy: 1e-9)
Y5	XCTAssertNil(rising.cue(.quiet, line: line, at: 104), "the same level — no new way")
Y5	XCTAssertEqual(early.end, 1, accuracy: 1e-9, "a tap before the music rose does not wait for it")
Y5	XCTAssertEqual(early.level(at: 1.5), 0.08, accuracy: 1e-9)
Y6	XCTAssertEqual(MusicCue.of(scene, line: line), .off, "case \(index)")
Y6	XCTAssertEqual(levels([(.full, 0), (.off, 10)], at: [10.2, 10.4, 20]), [0.4, 0, 0])
Y6	XCTAssertEqual(levels([(.full, 0), (.off, 10), (.full, 20)], at: [22, 23.5, 25]), [0, 0.4, 0.8])
Y8	XCTAssertEqual(MusicCue.of(milena, line: line), .off)
Y8	XCTAssertEqual(MusicCue.of(milena, line: line), .full)
Y8	XCTAssertEqual(levels([(.full, 0), (.off, 10), (.full, 100)], at: [10.4, 101, 103.5, 105]), [0, 0, 0.4, 0.8])
Y9	XCTAssertEqual(decode("{}"), .standard)
Y9	XCTAssertEqual(MusicLine.standard.console, "музыка: «Шкатулка Элли» · 0,80 · -20,00 дБ")
Y9	XCTAssertEqual(decode("{\"volume\": \(raw)}").volume, volume, raw)
Y9	XCTAssertEqual(decode("{\"volume\": \(raw)}").notes, [], raw)
Y9	XCTAssertEqual(refused.volume, 0.8, raw)
Y9	XCTAssertEqual(refused.notes, ["музыка: громкость вне 0–1 — взято 0,80"], raw)
Y9	XCTAssertEqual([edges.duckDB, edges.fadeOut, edges.delay, edges.fadeIn], [-60, 5, 60, 30])
Y9	XCTAssertEqual([past.duckDB, past.fadeOut, past.delay, past.fadeIn], [-20, 0.4, 2, 3])
Y9	XCTAssertEqual(past.notes.count, 5)
Y9	XCTAssertEqual(decode("[1]").notes, ["музыка: music.json не читается"])
Y9	XCTAssertEqual([MusicCue.of(idle, line: silent), MusicCue.of(idle, line: .standard)], [.off, .full], raw)
Y9	XCTAssertEqual(silent.console, "музыка: выключена", raw)
Y9	XCTAssertNil(fader.cue(.off, line: silent, at: 5), raw)
Y2	XCTAssertEqual(fader.level(at: time), before, accuracy: 1e-9, "scenario \(scenario): a jump")
Y2	XCTAssertTrue((0...0.8).contains(ramp.to), "scenario \(scenario)")
Y2	if ramp.to < before { XCTAssertLessThanOrEqual(fader.end, time + 0.4 + 1e-9, "scenario \(scenario)") }
Y2	XCTAssertLessThanOrEqual(change, max(0.8 / 0.4 * step, line.quiet) + 1e-9, "scenario \(scenario)")
```

✅ **Каждое утверждение ведёт к примеру спеки** (Y1 Y10 Y2 Y3 Y4 Y5 Y6 Y8 Y9), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [ ] READY FOR HANDOFF
- [x] NEED CONVERGE (Y11 из колонок — завтра, по слову родителя)
- [ ] BLOCKED
