# Tasks

Уроки (§2.2a) — в `plan.md`: L18, L46, L62, L63, L88, L107, L110, L64, L105, L106, L108, L109, L127, L128, L80, L130,
L7, L70, L34, L52, L37, L79, L113; не применимы — L17, L41, L44, L45, L58–L61, L68, L69, L71–L73, L81, L82, L86, L87,
L89–L91, L98–L100, L111, L112, L129 (причина там же).

## Slice 0 — спека и мок-снимки
- [x] T1: документы первым коммитом ветки `feat/app-glass`, до кода (L33, L62): STATUS, spec (F1–F5), plan (≈ 250,
  с поправкой ≈ 375), tasks, decisions
- [x] T2: мок-снимки на стенде `local/spike/glass/` (вне git): детский экран — день, ночь, «слушает», «думает»;
  консоль и зона взрослых крупно; «было / стало» рядом — PNG и страничка в `local/checkpoint/glass-mockups/`;
  доклад ведущему — подпись под примерами и видом, вопрос об образе macOS-джобы

## Slice 1 — код (после подписи)
- [x] T3: `eval-smoke.md` — строки F1–F5 до кода; `phase: implement`
- [x] T4: палитра и небо (`Palette`, `SkyArt`, `AdultSky`); F1, F2; мутации «обод на небе бледнее 3:1», «небо без
  голубизны»
- [x] T5: стекло в зоне взрослых, снимок окна (`GlassSnapshotTests`); F3; мутации «плашка без белой подложки», «знак
  без сливы»
- [x] T6: `GlassCapsule` и консоль; F4; мутации «недоступная не бледнеет», «высота 36»
- [x] T7: цель iOS 27.0 (`project.yml`, `Package.swift`), F5 в `check_app_artifact.sh`; образ `ios.yml` — по слову
  ведущего (решение 2026-10-27 — `xcode-27`); сборка `.app` на Mac — BUILD SUCCEEDED, `MinimumOSVersion` 27.0
- [x] T7a: порог дня V36 0,85 → 0,75 под подписанное небо (замер 0,773, ночь 0,277) — мерж после слова родителя
  (поправка в `spec.md`, `decisions.md`)

## Slice 2 — знание и сдача
- [x] T8: `product/look-and-feel`, ADR `character-rendering`, `knowledge/log.md`
- [ ] T9: слить `origin/main`; строгий `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI; метку
  `macos` — моя (слово ведущего 2026-10-27)
- [ ] T10: verify-report, `check_digest_report.py` до пуша сдачи; архив в том же PR, строка INDEX, slug — в конец
  `delivery/OBSERVATIONS.md`; доклад ведущему. Уроки этой поставки — с L137 (номера дал ведущий)
