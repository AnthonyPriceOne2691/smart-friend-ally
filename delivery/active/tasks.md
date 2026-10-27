# Tasks

Уроки (§2.2a) — в `plan.md`: L33, L52, L63, L88, L107, L110, L50, L51, L64, L19, L86, L87, L46, L16, L70, L62, L35, L14,
L43, L34, L91, L37, L105; не применимы — L106, L108, L109, L1, L12, L36 (причины там же). Номера уроков этой поставки —
у ведущего.

## Slice 0 — документы
- [x] T1: документы Ш2в первым коммитом ветки `feat/child-shell-mouth`, до кода (L33): STATUS, spec (V34 таблицей со
  ссылкой на 4c61d3c и подпись 48b39f7), plan (≈ 140, с поправкой ≈ 210), tasks, decisions
- [x] T2: `eval-smoke.md` — строка V34 до кода; `phase: implement`

## Slice 1 — ритм
- [x] T3: `Syllables` — слоги, слова, фразы, следование; V34 (генератор); мутации «без следования», «пауза фразы как
  пауза слова» — обе красные
- [x] T4: `Motion` — `voiceLevel`, ритм в позе «говорит», переданный уровень как есть; V34 (`Motion`); мутации «ритм и
  в других фазах», «переданный уровень заменён ритмом» — красные; V12 Ш2а зелёный с ритмом в половине сценариев,
  мутация «сброс вместо гашения» краснит его

## Slice 2 — знание и сдача
- [x] T5: ADR `character-rendering`, `product/look-and-feel`, `knowledge/log.md`
- [ ] T6: слить `origin/main`; строгий `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI
- [ ] T7: verify-report, `check_digest_report.py` до пуша сдачи; архив в том же PR, строка INDEX с уроками, slug — в
  конец `delivery/OBSERVATIONS.md`; доклад ведущему
