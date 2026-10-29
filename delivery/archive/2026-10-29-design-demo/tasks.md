# Tasks

Уроки (§2.2a) — в `plan.md`: L33, L62, L46, L105, L106, L137, L138, L139, L130, L63, L107, L64, L80, L7, L16, L70,
L44, L45, L34, L52; не применимы — L1, L2, L3, L4, L6, L11, L12, L13, L14, L21, L26, L27, L31, L32, L37, L40, L41,
L42, L43, L50, L53, L56, L57, L58, L59, L60, L61, L68, L69, L71, L72, L73, L74, L75, L76, L77, L78, L79, L81, L82,
L86, L87, L88, L89, L90, L91, L92, L93, L94, L98, L99, L100, L101, L104, L108, L109, L110, L111, L112, L113, L125,
L127, L128, L129, L131, L132, L133, L134, L135, L136 (причина там же).

## Slice 0 — спека
- [x] T1: документы первым коммитом ветки `feat/design-demo`, до кода (L33, L62): STATUS, spec (Y1–Y7), plan, tasks
- [x] T2: вопрос родителю через ведущего — подпись под Y1–Y7: ответ «Подписываю (Рекомендую)» 2026-10-29, строку STATUS вписал ведущий

## Slice 1 — показ
- [x] T3: `eval-smoke.md` — строки Y1–Y7 до кода; `phase: implement`
- [x] T4: `ConsoleView` из `AllyApp.swift` (модель и действия), обёртка приложения
- [x] T5: цель `AllyDemo` (`project.yml`), `App/Demo/` — вход, тур, плашка, вымышленная консоль, превью
- [x] T6: `scripts/run_demo.sh`; сборка под симулятор; как встанет рантайм — запуск на iPhone 17 Pro Max, доклад
  ведущему «демо в симуляторе открыто» (21:50)
- [x] T6a: поправка Y4 по слову родителя после показа 2026-10-29: демо открывается детским режимом, поведение — её
  собственное по сценарию (`DemoScript`), знак стопа — консоль без Face ID, переключатель — только `-demo-panel YES`;
  `spec.md`, `eval-smoke.md`, `decisions.md`; перезапуск на том же устройстве, доклад ведущему

## Slice 2 — токены, оракул, CI
- [x] T7: `Look.swift`, числа облика из `AdultZone`, `GlassCapsule`, `glassCard`, `ConsoleView`; пробы `ShellUITests`
  на Mac; мутация «высота 36» (Y6)
- [x] T8: `check_demo_boundary.sh` (Y1, Y2, Y3, Y5), pre-commit; мутации «Demo в Ally», «AllyLlama у демо»
- [x] T9: `ios.yml` — сборка демо под симулятор и оракул границы; jscpd — `App/Demo`

## Slice 3 — знание и сдача
- [x] T10: runbook демо, `look-and-feel`, ADR `character-rendering`, `voice-loop`, `repo-map`, `log.md`, индексы
- [x] T11: свежий main; строгий `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI, метка `macos`
- [x] T12: verify-report, архив в том же PR, строка INDEX (уроки L154–L157), `OBSERVATIONS.md`; доклад ведущему
