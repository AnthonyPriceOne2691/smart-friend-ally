# Tasks

Уроки (§2.2a) — в `plan.md`: L23, L37, L10, L33, L62, L7, L16, L70, L46, L45, L68, L80, L34, L52, L61, L64, L121,
L14; не применимы — L44, L59, L60, L69, L71, L72, L73, L81, L82, L89, L98, L99, L100, L105, L111, L112, L129, L130,
L134, L135, L136, L137, L138, L139 (причина там же).

## Slice 0 — разведка и спека
- [x] T1: зонд симулятора `local/spike/sim-probe/` (вне git): диктовка ru-RU и en-US на iOS 27.0 и 27.1 — «Model not
  available», Metal симулятора без apple7 и metal3; доклад ведущему, решение родителя «Приложение для iPhone прямо на Mac»
- [x] T2: подпись для «My Mac (Designed for iPhone)» — BUILD SUCCEEDED, Mac в профиле до 05.11; запуск вне Xcode убит
  Gatekeeper, контейнер закрыт для оболочки агентов (TCC) — доклад, решение родителя «Кнопка ▶ в Xcode + «Файлы с Mac…»»
- [x] T3: документы первым коммитом ветки `feat/sim-app`, до кода (L33, L62): STATUS, spec (N1–N10), plan, tasks,
  decisions; вопрос подписи под N1–N10 — ведущему

## Slice 1 — код (после подписи)
- [x] T4: `eval-smoke.md` — строки N1–N10 до кода; `phase: implement` (подпись родителя 2026-10-29, `a3e6c1e`)
- [ ] T5: `scripts/mac_files.py` и smoke S9 (N1–N3); прогон на Mac — `~/models/ally-mac`, `df` до и после
- [ ] T6: `MacImport` — план и отказы (N4, N5), копия (N6), видимость (N7); `VoiceFile.sha256`; sha256 потоком;
  мутации «копия без сверки хэша», «кнопка видна на телефоне», «чужой путь пропущен»
- [ ] T7: `TraceLine` (N8); мутация «приёмник пишет и слова»
- [ ] T8: приложение — `MacFilesButton`, импорт и прогрев в `VoiceLoop`, журнал `turn`, строка «модель: Metal — …»;
  `scripts/mac_app.sh`; сборка для Mac с подписью и для телефона без подписи, оракул артефакта (N10)
- [ ] T9: первый ход на Mac (N9): ведущему — шаги родителю и окно микрофона заранее; синтетика `say`, `log show`

## Slice 2 — знание и сдача
- [ ] T10: `engineering/mac-run` (новое решение), runbook `voice-loop`, `ops/child-data`, `repo-map`, `index.md`, `log.md`
- [ ] T11: слить свежий `origin/main` (child-open, design-demo, black-box — их строки дословно, L68); строгий
  `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI; метка `macos` — по слову ведущего
- [ ] T12: verify-report («Исполнение рисковых путей» — N9), уроки L158–L161, архив в том же PR, строка INDEX и
  OBSERVATIONS
