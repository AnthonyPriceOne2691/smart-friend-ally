# Tasks

Уроки по путям диффа (§2.2a): `Packages/AllyMemory/`, `knowledge/engineering/memory.md` — L74, L75, L76, L95;
`knowledge/engineering/safety-below-model.md` — L25, L28, L29, L30, L33, L34, L35, L38, L39, L40, L41, L47, L48, L49,
L50, L51, L52, L59, L60, L61, L65, L66, L67, L68, L69, L70, L89, L90, L91 — как применены и почему нет, сказано в
`plan.md`.

- [x] T1: документы `memory-extract` первым коммитом ветки, до кода (L33): STATUS, spec (M26–M28 дословно таблицей,
  ссылка на спеку серии 21d556c и подпись 37bb5a9), plan, tasks, decisions, eval-smoke
- [x] T2: ресурсы разбора и `ExtractPrompt` (M26)
- [x] T3: `ModelAnswer`, `remember` с повтором и записью (M27)
- [x] T4: `Anchors` — опора и ответ → кандидаты (M28); мутации плана
- [x] T5: знание — `engineering/memory`, раздел реестра `safety-below-model`, `knowledge/log.md`; `okf_validate`,
  `okf_sync_gate`
- [ ] T6: слить main, PR, CI, verify-report, сдача: архив, строка INDEX с уроками L114, L115, L116, `memory-extract` в
  `delivery/OBSERVATIONS.md`

## Точка остановки 23.10

- **Сделано:** T1–T5 — документы (b3e5465), код и знание (cc1bf63), слияние main (b22b75e); PR #64, CI 40019214593
  зелёный (delivery, swift, gates; покрытие AllyMemory 90%); мутации 4 из 4 убиты; net 503 из 800; `verify-report.md`
  заполнен (дайджест 23 утверждения, 0 без примера; блоки поверхности модели и рисковых мест).
- **Следующий шаг (T6):** слить свежий origin/main (ушёл вперёд: 4307a08); фаза handoff — перенос в
  `delivery/archive/2026-10-23-memory-extract/`, строка INDEX (готовый текст ниже), `- \`memory-extract\`` в конец
  `delivery/OBSERVATIONS.md`; строгий `delivery_check --require-ci --diff-base origin/main` и `check_digest_report.py`;
  пуш, зелёный CI, доклад ведущему «готово к мержу». Затем `memory-sense` (M30, M31; уроки L117–L118).
- **Бриф составителя свежего набора (M32): есть** — `local/research/memory/fresh/brief-author.md` и скрипт заморозки
  `local/research/memory/fresh/freeze.py` (проверен на синтетике), ведущему ещё не доложен.
- Строка INDEX для сдачи:

| 2026-10-23 | `2026-10-23-memory-extract` | `Packages/AllyMemory/`, `knowledge/engineering/memory.md`, `knowledge/engineering/safety-below-model.md` | **L114:** утверждение с индексом после проверки длины роняет под мутацией весь процесс XCTest («Index out of range», сигнал 5): мутация числится убитой, но остальные тесты прогона молчат — структуру сверяют целиком или срезом, а не `[2]`. **L115:** опора по доле слов значения ловит общие глаголы шаблона: «любит морковку» из чужого примера прошла бы как «согласилась» по «любишь» в вопросе Элли — глаголы формы («любит», «умеет», «нравится») — служебные слова опоры. **L116:** правила и разбор над готовой базой второй раз вышли в план (memory-guard 258 из 280, memory-extract 503 из 520): занижение переноса L34 (+17–43%) — про движки с состоянием, а не про правила. |
