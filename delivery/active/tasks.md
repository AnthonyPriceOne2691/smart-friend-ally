# Tasks

Уроки (§2.2a) — в `plan.md`: L33, L62, L7, L16, L70, L58, L68, L71, L59, L60, L69, L89, L90, L121, L130, L131, L46,
L154, L155, L156, L157, L34, L52, L61, L91, L113; не применимы — L9, L10, L17, L18, L25, L28, L29, L30, L35, L37, L38, L39, L40,
L41, L44, L45, L47, L48, L49, L50, L51, L56, L57, L63, L64, L65, L66, L67, L72, L73, L77, L78, L79, L80, L81, L82, L86,
L87, L88, L98, L99, L100, L104, L105, L106, L107, L108, L109, L110, L111, L112, L114, L115, L116, L117, L118, L119,
L120, L125, L126, L127, L128, L129, L132, L133, L134, L135, L136, L137, L138, L139, L140, L141, L142, L143, L144, L145, L146, L147 (причина там же). Уроки этой
поставки — с L171.

## Slice 0 — спека
- [ ] T1: документы первым коммитом ветки `feat/child-open`, до кода (L33, L62): STATUS, spec (J1–J6), plan, tasks
- [ ] T2: вопрос родителю через ведущего — подпись под J1–J6

## Slice 1 — ядро
- [ ] T3: свежий main (`design-demo`); `eval-smoke.md` — строки J1–J6 до кода; `phase: implement`
- [ ] T4: `Launch` (экран после прогрева, строка загрузки), `ReleaseGate.audience`; тесты J2, J3, J4, J6 на Linux

## Slice 2 — приложение
- [ ] T5: `VoiceLoop` — флаг прогрева, замер этапов, фраза голоса без звука, Элли после прогрева; без сверки доступа
- [ ] T6: `AllyApp` — загрузка → Элли или консоль; `ChildScreen` без надписи; `LoadingScreen`
- [ ] T7: `scripts/child_mode.sh` — решение (`decisions.md`); сборка `.app` без подписи и оракул артефакта

## Slice 3 — знание и сдача
- [ ] T8: Policy `child-mode`, `look-and-feel`, `voice-loop`, `black-box`, `test-session`, `session`,
  `safety-below-model`, `session-limit`, `child-data`, `repo-map`, индексы, `log.md`
- [ ] T9: свежий main; строгий `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI, метка `macos`
- [ ] T10: verify-report, архив в том же PR, строка INDEX (уроки L171, L172, L173), `OBSERVATIONS.md`; доклад ведущему
