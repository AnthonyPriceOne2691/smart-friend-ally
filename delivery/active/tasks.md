# Tasks

Уроки по путям диффа (§2.2a): L40, L41, L50, L51, L52, L59, L60, L61 (`Packages/AllyCore/`), L44, L45, L46 (`App/`), L10
(`scripts/`), L25, L33, L34, L35, L38, L47, L48, L49 (`knowledge/engineering/safety-below-model.md`), L7, L16
(`knowledge/product/`), L56, L57, L58 (`Packages/AllyCore/`, D3) — как применены, сказано в `plan.md`.

## Slice 0 — документы
- [x] T1: документы R первым коммитом ветки `feat/child-lock`, до кода (L33): STATUS, spec (G1–G11 таблицей дословно,
  подпись — ссылкой на спеку D2.2 + R в архиве), plan, tasks, decisions, eval-smoke — этот коммит
- [ ] T2: шаг владельца — ключ ECDSA P-256 в Secretive, открытая строка в `.github/allowed_signers` (пространство
  `ally-child-mode`); строку пришлёт ведущий, до неё — файл без ключа

## Slice 1 — замок (AllyCore, Linux)
- [ ] T3: `ReleaseGate.swift`, `Resources/release.json`; G1–G6 и свойство срока; мутации «без предела 7 дней», «без сверки
  поверхности», «без самопроверки», «неподписанное принято»

## Slice 2 — подпись (AllyCore, Mac)
- [ ] T4: `SSHSignature.swift` под `#if canImport(CryptoKit)`; фикстуры настоящим `ssh-keygen -Y sign` двумя тестовыми
  ключами (закрытые — не в git); G7 на Mac, видимый пропуск на Linux; мутации «без сверки пространства», «без сверки
  ключа»; шаг AllyCore в ручной macOS-джобе `ios.yml`

## Slice 3 — приложение
- [ ] T5: `ChildMode.swift` (с расширением `VoiceLoop`), `ChildScreen.swift` по стыку `ChildScreen(talk:until:onWake:onStop:)`,
  строки замка и кнопки консоли, `audience` в записи следа (G9; одно поле с D3), проверки доступа на границах; ключ в
  бандл через `project.yml`; сборка без подписи и оракул артефакта зелёные

## Slice 4 — скрипт подписи
- [ ] T6: `scripts/child_mode.sh` по образцу `sign_irreversible.sh`; без родителя — только `--dry` и отказ срока

## Slice 5 — телефон и Mac с родителем
- [ ] T7: сессия теста — G8, G10, G11 (решение ведущего: в общую сессию теста; агент окно подписи не вызывает)

## Slice 6 — знание
- [ ] T8: `product/child-mode.md`, `safety-below-model.md`, `engineering/session.md`, runbook `voice-loop.md`; все места E2 —
  поиском (L7, L16); индексы, `knowledge/log.md`; `okf_validate` и `okf_sync_gate` зелёные

## Slice 7 — сдача
- [ ] T9: verify-report (сводка утверждений, мутации, «Исполнение рисковых путей», CI, `mergeable`), строгий
  `delivery_check --require-ci --diff-base origin/main`, L43, архив в том же PR, строка INDEX с уроками L68–L70,
  `child-lock` в обязательствах CLAUDE.md; доклад ведущему «готово к мержу»; мерж — ведущий

## Перенесено (не эта поставка)
- R2 `release-gate`: пороги целей 18.10 и `release-gate.json` (подписанная серия, уроки L89–L91).
- Строка консоли «перерыв до …» — поставка, что придёт второй из R и Ш3; функция конца перерыва — одна.
- Тело детского экрана — Ш3 «оболочки»; Face ID — D8; слова и звук — D3.
