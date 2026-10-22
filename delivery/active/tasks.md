# Tasks — contract-fixes

- [ ] T1: тесты-воспроизведения H1, H4, H6, H7, H9–H11 — красные на коде main; факт в `decisions.md`
- [ ] T2: эталон — `TAIL_LINK_RE`, `QWORD_RE`, `VERB_RE`, `elliptic()`, `narrow()`, выключатель `elliptic_tail`, пробы;
  самотест и каждый выключатель краснит самотест
- [ ] T3: `contract.json` — `tail_link`, `qword`, `verb`; генератор сверяет; фикстуры заново
- [ ] T4: Swift — `extraQuestions()` (H9–H13), `pointed()` (H1–H5), `fallback()` и указатель к заготовке (H6–H8);
  выключатели `elliptic_tail`, `pointer_spares_safety`, `danger_over_topic`; тесты зелёные, абляция, шум
- [ ] T5: паритет Swift = эталон на всём открытом корпусе в трёх режимах (H14)
- [ ] T6: замер — H14 (срабатывания и изменения), H15 (цели 3–4, пары Q7, слепые судьи на 9 парах в обоих порядках),
  H16 (2706 ответов под стражем страха)
- [ ] T7: знания — раздел поставки в `safety-below-model`, E4B отложен (реестр), пункт об указателе страха исправлен,
  `knowledge/log.md`
- [ ] T8: eval-smoke, verify-report (дайджест, L43), строгий `delivery_check`, CI; handoff в том же PR: архив, INDEX
  с уроками L65, L66, L67, `contract-fixes` в список наблюдений CLAUDE.md; PR из черновика в готовый; мерж — ведущий

## Где остановился (2026-10-22, вечер — стоп по слову ведущего: родитель закругляется)

- Сделано: спека подписана родителем (H1–H16, решения H4 и H8), план с отброшенными вариантами и задачи — в git.
  Кода и тестов нет; эталон `output_filter.py` и `contract.json` не тронуты. Слепых судей не запускал.
- Прототипы замера — вне git, в `local/spike/contract-fixes/`: `sim.py` (правка 3 на эталоне, H14), `ellip.py`
  (признак обрывка), `lastq.py`, `qclass.py`, `fear_pointer.py` (H16 — 2706 ответов под стражем страха).
- **Следующий шаг — T1:** тесты-воспроизведения H1, H4 (`ContentTests.testPointerSparesTheLastProhibition`), H6, H7
  (`ContentTests.testDangerScriptOutranksABareTopicFallback`), H9–H11 (пробы `elliptic_tail` в `ContractTests` и
  `testEllipticTailYieldsToTheFullQuestion`). Прогнать на коде main — красные, факт в `decisions.md`. Потом T2–T4 одним
  шагом (эталон, `contract.json`, Swift), чтобы ветка не стояла с красным CI. Слепые судьи (T6) — завтра.
