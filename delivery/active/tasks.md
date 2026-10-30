# Tasks

## Slice 0 — документы
- [x] T1: документы D3.2 первым коммитом ветки `feat/app-black-box`, до кода (L33): STATUS (исключение двух рисковых
  путей по ответу 8, поверхность стирания объявлена), spec (B13–B19 дословно из подписанной спеки серии), plan, tasks,
  decisions с шагами владельца
- [x] T2: `eval-smoke.md` — строки B13–B19 с оракулом и ожиданием, до кода; `phase: implement`

## Slice 1 — ядро и команда на Mac
- [x] T3: `BlackBox.held()` и общий подсчёт папок с `eraseAll`; тест `// B17`
- [x] T4: `scripts/blackbox.py` (черновик параллельного агента — сверить с планом), смоук S10 `blackbox_pull.sh` (B15,
  B16) со строкой в README и `run.sh`; мутации «сторож git снят», «стирание без сверки»

## Slice 2 — приложение
- [x] T5: `App/Sources/BlackBox/PhoneDisk.swift` — класс защиты, пометка «не в бэкап» с чтением обратно, `isPrivate`
- [x] T6: крючок в `Phrase.feed` и формат в строке готовности; `PhoneListener` отдаёт `Utterance` ящику
- [x] T7: `VoiceLoop` — ящик вторым приёмником, строка ящика и журнал; консоль — строка, кнопка «Стереть чёрный ящик» с
  подтверждением
- [x] T8: сборка для устройства без подписи (`xcodegen`, `xcodebuild … CODE_SIGNING_ALLOWED=NO`) и оракул артефакта;
  SwiftLint 0

## Slice 3 — знание
- [x] T9: `ops/black-box`, `engineering/voice-loop` (команды выгрузки и стирания), `ops/child-data`, `knowledge/log.md`

## Slice 4 — проверка и сдача
- [x] T10: verify-report, PR, CI; строгий `delivery_check`, `check_digest_report.py` до пуша (L43)
- [ ] T11 (отнесено в общую сессию теста постоянным решением родителя 2026-10-23, waiver в STATUS): телефон — B13–B19
  (сессия, `pull`, `erase`, кнопка консоли)
- [x] T13 (2026-10-27): слияние main `8ef99ea` сложением (VoiceLoop с двумя сессиями R/R2 и ящиком, PhoneListener с
  GigaAM и `keep`, смоук ящика — S10); стык с GigaAM — `BatchPhrase` отдаёт ящику те же 16 кГц Int16 (`onFed`), тест
  `// B14` на двойнике, мутация «хук снят» — красный
- [x] T14 (2026-10-30): слияние main `f9bcc32` сложением (child-open, memory-forget, design-demo, sim-app): консоль — в
  `ConsoleView` и `consoleActions`, проводка ящика — `BlackBox/BoxConsole.swift`, смоук ящика — S10; `allowed_signers`,
  `ChildMode`, `project.yml`, `child-mode`, `test-session` — без `child_mode.sh` и исключения
- [ ] T15: поправка B13, B18, B19 и всего, что опирается на замок, — после ответа родителя (текст и вопрос — у ведущего)
- [ ] T12: сдача — строка INDEX (уроки L83, L84, L85), `delivery/OBSERVATIONS.md`, waiver телефона — готовы; строка
  ключа родителя первой в `.github/allowed_signers`, без опций; подпись поверхности стирания — родитель сам
  (`bash scripts/sign_irreversible.sh`, касание), после неё — архив `2026-10-27-app-black-box`; мерж — ведущий
