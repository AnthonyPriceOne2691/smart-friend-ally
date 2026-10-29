# Tasks

Уроки (§2.2a) — в `plan.md`: L18, L46, L62, L63, L88, L107, L110, L64, L80, L105, L106, L108, L109, L128, L137, L138;
не применимы — L17, L44, L45, L59, L60, L61, L68, L69, L70, L71, L72, L73, L81, L82, L86, L87, L89, L90, L91, L98, L99,
L100, L111, L112, L129, L130, L131, L132, L133, L134, L135, L136, L139 (причина там же).

## Slice 0 — спека и страница выбора
- [x] T1: стенд `local/spike/app-icon/stand/` (вне git): копия `ShellCore` и `ShellUI` из origin/main и `IconScene`,
  рендер четырёх вариантов днём и ночью, малые размеры со скруглением iOS, замер проб и размера PNG
- [x] T2: страница `local/checkpoint/app-icon/index.html`: варианты крупно, домашний экран светлый и тёмный, 60, 40 и
  29 pt; путь и вопрос — ведущему
- [ ] T3: документы первым коммитом ветки `feat/app-icon`, до кода (L33, L62): STATUS, spec (I1–I7), plan, tasks,
  decisions

## Slice 1 — код (после выбора родителя)
- [ ] T4: подпись под выбором в STATUS вписывает ведущий; `eval-smoke.md` — строки I1–I7 до кода; `phase: implement`
- [ ] T5: `IconScene` выбранного варианта; `IconTests` I1, I4; мутации «без глаз», «прозрачный угол»
- [ ] T6: `render_app_icon.sh`, каталог `AppIcon.appiconset` с днём и ночью; I2, I3, I5, I7; мутации «Элли мельче»
  (I3), «без ночной пары» (I2), «без снятия дизеринга» (I5)
- [ ] T7: `check_app_artifact.sh` — значок в `.app` (I6), мутант на поддельном бандле; `xcodegen generate` и `actool` на
  каталоге; сборка `.app` — macOS-джоба по слову ведущего
- [ ] T8: демо-каталог с пометкой «демо», если `design-demo` в main

## Slice 2 — знание и сдача
- [ ] T9: `product/look-and-feel`, ADR `character-rendering`, `knowledge/log.md`
- [ ] T10: слить свежий `origin/main`; строгий `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI
- [ ] T11: verify-report, `check_digest_report.py` до пуша сдачи; архив в том же PR, строка INDEX (уроки L174–L176),
  slug — в конец `delivery/OBSERVATIONS.md`; доклад ведущему «готово к мержу»
