# Tasks

Уроки (§2.2a) — в `plan.md`: L23, L37, L10, L33, L62, L7, L16, L70, L46, L45, L68, L80, L34, L52, L61, L64, L121,
L14, L41, L50, L51, L58, L79, L113, L91, L107, L131, L140, L141, L143, L154, L155; не применимы — L28, L40, L44, L56, L57, L59, L60, L69, L71,
L72, L73, L77, L78, L81, L82, L89, L90, L98, L99, L100, L104, L105, L106, L111, L112, L129, L130, L132, L133, L134,
L135, L136, L137, L138, L139, L142, L144, L145, L146, L147, L156, L157 (причина там же).

## Slice 0 — разведка и спека
- [x] T1: зонд симулятора `local/spike/sim-probe/` (вне git): диктовка ru-RU и en-US на iOS 27.0 и 27.1 — «Model not
  available», Metal симулятора без apple7 и metal3; доклад ведущему, решение родителя «Приложение для iPhone прямо на Mac»
- [x] T2: подпись для «My Mac (Designed for iPhone)» — BUILD SUCCEEDED, Mac в профиле до 05.11; запуск вне Xcode убит
  Gatekeeper, контейнер закрыт для оболочки агентов (TCC) — доклад, решение родителя «Кнопка ▶ в Xcode + «Файлы с Mac…»»
- [x] T3: документы первым коммитом ветки `feat/sim-app`, до кода (L33, L62): STATUS, spec (N1–N10), plan, tasks,
  decisions; вопрос подписи под N1–N10 — ведущему

## Slice 1 — код (после подписи)
- [x] T4: `eval-smoke.md` — строки N1–N10 до кода; `phase: implement` (подпись родителя 2026-10-29, `a3e6c1e`)
- [x] T5: `scripts/mac_files.py` и smoke S9 (N1–N3); прогон на Mac — `~/models/ally-mac`, `df` до и после: 28 файлов,
  5,50 ГБ за 5,1 с, место −11,9 МБ; повтор — «без изменений: 28»; мутации S9 «запись в контейнер», «повтор переписывает» —
  убиты
- [x] T6: `MacImport` — план и отказы (N4, N5), копия (N6), видимость (N7); `VoiceFile.sha256`; sha256 потоком;
  тексты — `mac_import.json` (правило `inline_prompt`); мутации «копия без сверки хэша», «кнопка видна на телефоне»,
  «чужой путь пропущен», «размер не сверяется» — убиты
- [x] T7: `TraceLine` (N8); мутация «приёмник пишет и слова» — убита
- [x] T8: приложение — `MacFilesButton`, импорт и прогрев в `VoiceLoop`, журнал `turn`, строка «модель: Metal — …»;
  `scripts/mac_app.sh`; сборка для Mac с подписью и для телефона без подписи — BUILD SUCCEEDED, оракул артефакта OK
  (N10); после design-demo кнопка — вставкой снизу у `ConsoleView` (общий вид демо не тронут)
- [ ] T9: первый ход на Mac (N9): ведущему — шаги родителю и окно микрофона заранее; синтетика `say`, `log show`

## Slice 2 — знание и сдача
- [x] T10: `engineering/mac-run` (новое решение), runbook `voice-loop`, `ops/child-data`, `repo-map`, `index.md`, `log.md`;
  `voice-engine`, `safety-below-model` (пути в `implementation:`); `okf_validate`, `okf_sync_gate` — зелёные
- [ ] T11: слить свежий `origin/main` (child-open, design-demo, black-box — их строки дословно, L68); строгий
  `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI; метка `macos` — по слову ведущего
- [ ] T12: verify-report («Исполнение рисковых путей» — N9), уроки L158–L161, архив в том же PR, строка INDEX и
  OBSERVATIONS
