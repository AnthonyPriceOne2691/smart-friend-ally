# Verify report

**Date:** 2026-10-25
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (все утверждения ведут к одобренным примерам Z19, Z20, Z29 — дайджест ниже; примеры подписаны родителем 2026-10-23 до кода)
**CI run:** проверки PR этой поставки (джобы quality: delivery со smoke S8, gates, swift)
**Commit:** спека — d825a5d; план — db4f91c; код — f5faacc; Z30 и OKF — 528b798; порог тремя точками — 3afe387; S8 — 51afcf4

## Shape oracles
- [x] PASS — pre-commit на коммитах поставки: `file-length` (`*.swift *.py *.c *.h`), jscpd, SwiftLint — 0 находок,
  секреты (строки `voice.json` с sha256 помечены для сканера, снимок секретов пуст), данные ребёнка, `gate-coverage`
- [x] PASS — `okf_validate.py` и `okf_sync_gate.py --base origin/main`: `voice-fx`, `voice-engine`, `voice-loop` сверены
- [x] PASS — `delivery_check --diff-base origin/main`: 0 ошибок. Предохранитель: 11 файлов кода, net 468 из 800, без
  исключений; уроки по путям диффа названы в `tasks.md`
- [x] PASS — покрытие `Packages/AllyVoiceFX` — 460 из 473 строк Sources/ вместе с C, 97%; `AllyCore` судит джоба
  `swift` (локально полный S5 не гоняем: Mac общий)

## Behavior oracles
- [x] PASS — `swift test --disable-keychain` на Mac (Xcode 27):
  - `AllyVoiceFX`, 7 тестов: Z29 — 10 точек ± 0,1 дБ, пик +g и −g — тождество, в цепочке «light» снимает 2,9 дБ на
    100 Гц; Z27, Z28, Z31 V4a — зелёные;
  - `AllyCore` `VoiceSettingsTests`, 5 тестов: Z19 — строка «Совсем малышка», правка высоты, порог скорости тремя
    точками (0,80 — строка консоли и 0,85; 0,85 — без строки; 0,9), чужая полоса — ошибка; Z20 — три строки `VoiceCheck`,
    группа `accent` приложением не проверяется.
- [x] PASS — Z20, команда: smoke S8 `voice_copy_check.sh` — верные файлы проходят, а значит, sha256 сверяется у
  распакованного словаря; подмена того же размера в файле и в словаре `.gz` — стоп с именем до первой копии. На
  настоящих файлах `copy_voice.py --check` сверил 21 файл, 501 МБ. Телефон не трогали: решение родителя 25.10 —
  закачка завтра.
- [x] PASS — Z30 полный, стенд `local/spike/voice-fx/scripts/port_vs_py.py --eq light` на Mac: PSOLA и «light» порта
  против одобренного p9f5 в одном прогоне. Итог — `results/z30_light_verdict.json`.

  | | HNR, дБ | джиттер, % | скачки | скрип | F0, Гц | форманты | UTMOS |
  |---|---|---|---|---|---|---|---|
  | порт | 12,07 | 1,62 | 0,02 | 0,03 | 343,4 | 4,8 | 1,89 |
  | p9f5 | 12,14 | 1,64 | 0,02 | 0,04 | 340,9 | 4,8 | 1,78 |

  Контроль `psola_c` не прошёл 5 замеров из 6.
- [x] PASS — мутации вручную, все убиты:
  - M1 «порог скорости `<` → `<=`» — случай ровно 0,85;
  - M2 «проверять и группу `accent`» — Z20;
  - M3 «знак полки» — Z29;
  - M4 «сверять сжатый `.gz`» — S8;
  - M5 «эквалайзер выпал из цепочки» — Z29 в цепочке;
  - M6 «сверять только байты» — выжил на первом смоке; S8 переписан на подмену того же размера, теперь убит.
- [x] PASS — Builder ≠ Verifier: код и тесты — агент-исполнитель; гейты и CI — механика; ожидания — примеры, подписанные
  родителем до кода

## Product oracles
- [x] PASS — `human_ok_spec: yes` (серия 2026-10-23, подпись V4a и ответ родителя о разрезе); код — после спеки d825a5d
  (L33)
- [x] PASS — Z19, Z20, Z29, Z30: факт по каждому — `eval-smoke.md`

## Spec coverage gaps
- **Вызывающий в приложении** — V4b2: голос, Milena при нехватке файлов (Z20, приложение), журнал, порт звука, стоп,
  паузы, слух (Z21–Z26). До неё ни `VoiceSettings`, ни эквалайзер приложение не зовёт (L50).
- **Имя после обработки.** GigaAM пишет «эли» на порте и с «light», «элли» — на p9f5: проверка слухом и замером на
  телефоне — Z26 V4b2.
- **Группа `accent`** — словари и модель омографов в манифесте. Остальные файлы RUAccent добавят V3b и V3c.
- **Реляционный оракул.** Предупреждение «нет реляционного оракула» остаётся: детектор знает только hypothesis и
  fast-check. Отношения здесь есть: пик +g и −g — тождество на случайных полосах и порог тремя точками.

## Ревью рисковых мест

- **Публичный API:** `EQBand`, `VoiceEQ`, `VoiceFX(pitch:formant:eq:)` — вызовы V4a не меняются;
  `VoiceSettings`, `VoicePresetLine`, `VoiceFile`, `VoiceCheck`. Вызывающих в приложении нет.
- **Сеть и телефон:** приложение ничего не скачивает. Команда копирует с Mac через `devicectl` только с UDID, ничего не
  удаляет, а `--remove-existing-content` не передаёт.
- **Данные:** в манифесте только имена файлов, байты и sha256 моделей; детских данных нет.
- **Цепочка гейтов:** smoke S8 добавлен в `run.sh` (S1–S8), README дополнен.
- **Безопасность:** команда пишет в контейнер приложения только с UDID и только после полной сверки sha256. Путь
  назначения — `to` из манифеста в git, внутри папки `Voice`; песочница контейнера — граница. Риск — `..` в `to`: его
  закрывает ревью манифеста в PR. Сети нет, удалений нет, sha256 моделей — не секрет.
- **Производительность:** риска для приложения нет, потому что эквалайзер — два биквада на отсчёт рядом с PSOLA
  (≈ 6 мс на секунду звука на Mac, не судится, L54). sha256 501 МБ на Mac — доли секунды, распаковка словарей —
  секунды.

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 11 code (+15 process docs) / +483/-15 (net +468) |
| commits | 7 |
| time_to_accepted_spec | 0.0h |
| rework_after_done | 0 (handoff not declared yet) |
| harness_hardened | yes — Packages/AllyCore/Tests/AllyCoreTests/VoiceSettingsTests.swift (новый оракул), Packages/AllyVoiceFX/Tests/AllyVoiceFXTests/VoiceEQTests.swift (новый оракул), delivery/evals/smoke/README.md, delivery/evals/smoke/run.sh |
| implement_retries | 2 — пометка сканера в JSON (голая фраза не сработала) и длинные строки до коммита |
| verify_fails_before_green | 0 — мутант M6 выжил, смок усилен до зелёного; CI — см. PR |
| est_token_or_cost | n/a |

MANUAL-поля заполняет агент/человек на handoff. Если `verify_fails_before_green >= 2` при `harness_hardened: no` — по §9.2 добавь oracle/breaker/hook в этой же поставке.

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

Новых/изменённых утверждений: **21**, из них без ссылки на пример спеки:
**0**. Вопрос к каждому непривязанному один: **откуда взято ожидаемое
значение — из спеки или придумано под реализацию?**

```
Z19	XCTAssertEqual([preset.style, "\(preset.speed)", "\(preset.steps)"], Self.chosen)
Z19	XCTAssertEqual([preset.pitch, preset.formant], [9, 5])
Z19	XCTAssertEqual(preset.eq.map(\.kind), ["lowshelf", "peak"])
Z19	XCTAssertEqual(preset.eq.map { [$0.frequency, $0.gainDB, $0.q] }, [[250, -3, 0.7], [4000, 2.5, 0.9]])
Z19	XCTAssertNil(voice.note)
Z19	XCTAssertEqual(voice.folder, "Voice")
Z19	XCTAssertEqual(Set(voice.files.map(\.group)), ["voice", "accent"])
Z19	XCTAssertEqual(edited.preset.pitch, 8)
Z19	XCTAssertEqual(try settings().preset.pitch, 9)
Z19	XCTAssertEqual(slow.note, "скорость 0,80 ниже 0,85 — взято 0,85")
Z19	XCTAssertEqual(slow.preset.speed, 0.85)
Z19	XCTAssertNil(floor.note)
Z19	XCTAssertEqual(floor.preset.speed, 0.85)
Z19	XCTAssertThrowsError(try settings(preset: line.replacingOccurrences(of: "lowshelf", with: "notch")))
Z20	XCTAssertEqual(VoiceCheck.check(voice, in: folder).message, "голоса нет: скопируй с Mac")
Z20	XCTAssertEqual(VoiceCheck.check(voice, in: folder).message, "голос не тот: 3 байт вместо 4")
Z20	XCTAssertEqual(VoiceCheck.check(voice, in: folder), .ready)
Z20	XCTAssertNil(VoiceCheck.check(voice, in: folder).message)
Z29	XCTAssertEqual(try gain(eq, at: freq), want, accuracy: 0.1, "\(freq) Hz")
Z29	XCTAssertLessThan(zip(x, y).map { abs($0 - $1) }.max() ?? 1, 1e-4, "\(freq) Hz \(gain) dB")
Z29	XCTAssertEqual(change(plain, shaped), -2.91, accuracy: 0.3)
```

✅ **Каждое утверждение ведёт к примеру спеки** (Z19 Z20 Z29), а примеры человек
подписал до кода (`human_ok_spec`). Подпись под дайджестом здесь
**не требуется**: она уже стоит, заранее и на числах. Пиши в verify-report
`asserts_reviewed_by: n/a (все утверждения ведут к одобренным примерам)`.

asserts_without_example: 0

## Verdict
- [x] READY FOR HANDOFF (Z19, Z20, Z29, Z30 зелёные; приложение и телефон — V4b2)
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED
