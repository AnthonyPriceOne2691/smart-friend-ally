# CLAUDE.md — Smart Friend Ally

Голосовой «умный друг» для дочери пользователя (5 лет) на iPhone 17 Pro Max:
нативное iOS-приложение на Swift, полностью офлайн, по-русски, с памятью о
ребёнке между сессиями. Кода пока нет — идёт развёртывание контура, затем спайк
на телефоне (`KNOWLEDGE.md` §12).

## Сначала прочитай

- `KNOWLEDGE.md` — база исследования: железо, модели, речь, память, безопасность,
  принципы из опыта тренера (раздел 8, П1–П37), решения (раздел 13). Решение о
  продукте без него не принимается.
- `delivery/active/STATUS.md` — текущая поставка, фаза, класс.

## Canon stack / Agent Delivery Harness

- **Start here:** `docs/canon/AGENT_STACK.md` (order: Delivery → CQG → OKF).
- Process canon: `docs/canon/AGENT_DELIVERY_HARNESS.md`.
- Active delivery: `delivery/active/STATUS.md` — read before coding.
- **Order:** follow delivery phases. Do not oneshot large work.
- **Done:** only when verify oracles pass **and CI is green**; never declare done on red.
- Prefer git worktree for class M/L (Delivery §5.1).
- Smoke/evals: `delivery/evals/smoke/` + `active/eval-smoke.md` (Delivery §6).
- Metrics on handoff: Delivery §9 / A.10.
- Hooks if deployed: Delivery §10.
- Skills/prompts: `skills/README.md` (Delivery §11); no inline prompts (CQG).
- Do **not** duplicate code-quality rules here — use `docs/canon/CODE_QUALITY_GATES.md`.
- Do **not** invent domain canon — use `knowledge/` (OKF).
- Deploy order for missing layers: Delivery → CQG → OKF (see `AGENT_STACK.md`).

## OKF knowledge bundle

- **Stack map first:** `docs/canon/AGENT_STACK.md` (Delivery → CQG → OKF).
- Bundle root: `knowledge/` (Open Knowledge Format v0.2).
- **Before answering canonical questions** (policies, gate invariants,
  metrics definitions, ADR outcomes, runbooks): read
  `knowledge/index.md` and follow links. Do not invent from memory.
- **When changing invariants** in code: update the related OKF concept in
  the same change; refresh parent `index.md` and scope `log.md`.
  This is enforced, not advisory: `scripts/okf_sync_gate.py` fails CI when a path
  listed in a concept's `implementation:` changed but the concept did not.
  Declare that field on any concept that describes code behaviour.
- New durable knowledge goes into the bundle (YAML frontmatter with `type`),
  not into a new orphan markdown dump. `KNOWLEDGE.md` — legacy-база исследования:
  тронул тему — перенеси выжимку в concept (OKF §6).
- Bootstrap / format rules: `docs/canon/OKF_KNOWLEDGE_BUNDLE.md`.
- Upstream spec (check on OKF deploy/migrate):
  https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
  (из песочницы — через `gh api`, raw.githubusercontent.com недоступен).

## Неотменяемое (`delivery/CONSTITUTION.md`)

- **Данные ребёнка не попадают в git:** записи голоса, транскрипты, база памяти.
  Всё локальное — в `local/` (игнорируется); гейт контура отклоняет такие файлы
  даже через `git add -f`.
- **Продукт не ходит в сеть.** Облачные модели не предлагать — решение пользователя.

## Окружение

- Активный developer dir — Command Line Tools. Xcode 27 есть, но не выбран:
  команды Xcode запускать с `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- В пути проекта пробел (`Smart frend Ally`) — пути в скриптах всегда в кавычках.
- Пользователь пишет по-русски, часто диктовкой: искажённые названия сверять с контекстом.

## Синхронизация с каноном (Prepare)

Ally держится в полной синхронизации с каноном `~/Documents/Prepare`
(`agent-canon-stack`) — решение пользователя 2026-10-02.

- **Сверка в начале каждой сессии — по содержимому канона, а не по SHA:**
  `python3 ~/Documents/Prepare/field/fleet/plan_update.py "$PWD"`. «Сейчас» равно «станет»
  и «едет сам 0» — синхронизация не нужна: HEAD Prepare двигают правки BACKLOG и обход
  флота, а канон при этом не меняется. Отстали — первой работой сессии идёт поставка обновления.
- **Предусловие наката:** Prepare чистый и отправлен — `git -C ~/Documents/Prepare status -sb`
  показывает `## main...origin/main` без `ahead`, а `status --porcelain` пуст. Иначе канон в
  работе у судьи: накат привёз бы неопубликованное состояние, а провенанс снимка сослался бы
  на коммит, которого нет в upstream. Ждать.
- **Вниз (канон → Ally):** `python3 ~/Documents/Prepare/field/fleet/plan_update.py "$PWD"`
  (план, без записи) → `python3 ~/Documents/Prepare/field/fleet/apply_update.py "$PWD"`
  (механика; требует закоммиченными файлы, которые перепишет; сам не коммитит) → ручные
  порты по плану → гейты, доктор, приёмка → PR → `merge_guard.sh`. Обновление контура —
  не развёртывание: CQG §5.5.
- **Наверх (Ally → канон):** канон сами не правим — протокол сети (BACKLOG Prepare):
  нашедший заявляет, хозяин воспроизводит, вносит судья. Артефакты —
  `delivery/incidents/<дата>-<имя>.md` и `kind: upstream-candidate` в
  `scripts/lint/adapted.json` (их собирает обход флота). Транспорт — сообщение сессии в
  репозитории канона (`ListAgents` → `prepare-*`); разговор не носитель: нет артефакта —
  нет находки.
- **Флот:** Ally стоит в реестре `field/fleet/registry.json` Prepare — тогда суточный
  обход (10:00) и обход после каждого бампа версии видят его отставание и кандидатов.

## Состояние (2026-10-22)

- **Контур развёрнут и слит** (squash `520cfa3`, PR #1 закрыт) и синхронизирован с каноном до
  `delivery@2.07 · cqg@2.74 · okf@1.21 · stack-map@1.54` (Prepare `1f64dd7`, накат из чистого клона), снимок `docs/canon/` с провенансом и замком. Репозиторий — приватный `AnthonyPriceOne2691/smart-friend-ally`;
  `ci-oracles: tooling` (защиты ветки нет на бесплатном тарифе). Мерж — только
  `PATH="$PWD/.venv/bin:$PATH" bash scripts/merge_guard.sh <ветка> main` из основного клона, затем
  `git push origin main` и закрыть PR со ссылкой на сквош.
- Разбор и уроки L1–L42 — `delivery/archive/`, указатель — `delivery/archive/INDEX.md`. Ally стоит в реестре флота
  Prepare. Находки наверх: три инцидента 02.10 — в очереди судьи (BACKLOG Prepare, п.6–8). Из находок 17.10 судья
  внёс в канон: недельный `delivery_check` (`okf@1.21`), разборщик карты ролей (`cqg@2.60`), маячок «деньги» на «счёт»
  (`delivery@2.03`) — итог дописан в инцидентах; механизм истечения n/a «до кода» внесён в `cqg@2.66`. Четыре находки 18.10 (сводка Swift, исключение контура,
  корни тестов, истечение n/a) канон впитал — свои обходы сняты накатом `sync-cqg-2.70`; новая — накат не привозит
  часть комплекта (`2026-10-18-plan-misses-sourced-part`); 22.10 она повторилась на частях стражей исполнения
  (`cqg@2.72`) — доказательства дописаны в тот же инцидент, части доложены из payload'а. Находка 17.10 о поставке, уехавшей
  в архив тем же коммитом (`2026-10-17-archived-handoff-signature`), закрыта судьёй в `delivery@2.04`: строгий
  `delivery_check` с `--diff-base` судит такую поставку сам, обход L24 больше не нужен.
- **Обязательства наблюдения:** до **2026-11-30** — `persona-session-blackbox` (сдвинуто: сигнал наступит со спайком),
  `na-expiry-stopper`, `sync-cqg-2.55`, `state-refresh`, `spike-memory-limit`, `look-and-feel`, `look-and-feel-research`, `snout-instead-of-trunk`, `flower-crown`, `crown-centered`, `character-axolotl`, `spike-model-bakeoff`, `visual-approved`, `sync-cqg-2.63`, `spike-phone-llm`, `incident-archived-handoff`, `persona-v2`, `swift-contour`, `turn-contract`, `sync-cqg-2.70`, `closing-question`, `router-core`, `router-people`, `voice-core`, `sync-cqg-2.74`, `session-core`, `app-session`, `router-events`, `app-voice-loop`, `black-box`, `child-shell`, `child-lock`, `voice-text`, `release-gate`. Остальные закрыты `observed.md` 17.10. Недельный
  `canon-freshness` гоняет `delivery_check` (Delivery §13.1): просрочку видно и без поставок.
- **Спайк на телефоне** (`KNOWLEDGE.md` §12): шаг 1 сделан — лимит памяти приложения ≈3,3 ГБ без entitlement и
  ≈6,0 ГБ с `increased-memory-limit`, бесплатная Personal Team его выдаёт (`knowledge/engineering/memory-limit.md`).
  Шаг 2 на Mac сделан (`knowledge/engineering/model-bakeoff.md`): в замер на телефоне идут Gemma 4 E4B и E2B (E2B —
  только с маршрутизацией «скажи маме» до модели), оба Bonsai отклонены; стенд — `local/spike/bakeoff/`. Шаг 2 на телефоне
  сделан (`knowledge/engineering/model-on-phone.md`): в llama.cpp E4B и E2B держат 0,3–0,5 ГБ из 6 ГБ (веса из файла в лимит
  не идут), до первого звука p95 1,9 и 1,3 с, детали длинного разговора 7 из 7; русский распознаёт DictationTranscriber
  (у SpeechTranscriber его нет); E4B — основной кандидат; зонд — `local/spike/phone/`, живой режим — иконка «Ally Probe».
  Первый запуск новой подписи требует доверия сертификату на самом телефоне — это шаг владельца (L15).
- **Как она разговаривает** — `knowledge/product/persona.md` (пожелания родителя 2026-10-17): естественность фраз — главное,
  не терять деталей разговора, спрашивать про брата (имена и подробности — только в памяти на телефоне, не в git); ударения —
  критерий выбора голоса (временный Milena ставит их неправильно). **Персона v2.4 принята на слух родителя 2026-10-17**
  (лист вслепую: живее в 21 паре из 24; `knowledge/engineering/persona-eval.md`). Обращение — только по имени: «моя
  хорошая», «солнышко» снимает фильтр перед голосом (решение родителя). Очевидные листы судят слепые судьи-агенты по
  критериям родителя: безопасность с запретом, ум, живость. Частоту («иногда») и гарантии промпт E4B не держит — их
  держит код (L25). Дисциплина: контракт хода сдан 18.10, «вопрос в конце» — 19.10 (цель 4 уточнена родителем,
  живость 71%), дальше маршрутизатор; цели — `knowledge/engineering/safety-below-model.md`, судья — слепые агенты (L30).
- **Облик** — `knowledge/product/look-and-feel.md` (draft, пожелания родителя 2026-10-17): пузырьки, нежно-розовый,
  максимально плавные анимации, персонаж в круге — аксолотлик, выбор дочери 2026-10-17; визуал утверждён родителем — прототип v3
  (`local/prototype/ally-main-screen-v3.html`, вне git), венок из роз, гвоздик и лизиантусов включён; правила экрана для пятилетки
  и этика — там же. Способ показа — ADR `engineering/character-rendering`: первая версия — 2D-вектор в SwiftUI по
  прототипу v3 (решение родителя 2026-10-22, серия «оболочка» Ш1–Ш3, спека Ш1 — `feat/child-shell`); Rive «2.5D», 3D и
  художник — позже, по замеру рядом с моделью. Открыто за родителем: установка инструмента концепт-арта, бюджет на
  исполнителя; образ и имя — с дочерью. Отчёты исследований — `knowledge/references/research/`.
- **Пакет `Packages/AllyDiscipline`** (поставки `swift-contour`, `turn-contract`, `closing-question`, 18–19.10): ремонт текста `Repair` и
  контракт хода `TurnContract` до голоса; ратчет SwiftLint, `file-length` с маской `*.swift *.py`, jscpd `swift`, джоба
  CI `swift` с покрытием ≥ 70%. Приложение `App/` и модель `AllyLlama` — D1.2 `app-voice-loop` (runbook
  `engineering/voice-loop`; A10, A11, A12 — в первую сессию теста). Сводку утверждений сверяет CI с отчётом (voice-core).
- **Сессия в приложении** (D2.2 `app-session`, 22.10): тап «Разбудить», слух по состоянию сессии (`Conversation`),
  маршрутизатор на каждой реплике, след `TurnTrace` в `Caches/turns.jsonl`, переустановка одной командой
  `bash scripts/reinstall_app.sh <UDID>` (E4). Телефонные W8–W11 отложены родителем до первой сессии теста вместе с
  A10–A12. **Замок «при родителе»** (R `child-lock`, 23.10): детский экран — только по подписанному исключению родителя
  до 7 дней на эту сборку (`bash scripts/child_mode.sh <UDID> --until <дата>`, подпись — касанием в Secretive, проверяет
  телефон). **Без присмотра** (R2 `release-gate`, 23.10) — только подписанная родителем приёмка `release-gate.json` в
  бандле (пространство `ally-release`): девять порогов целей 18.10 — в коде, в файле — замер; файла нет, консоль пишет
  «приёмка: нет файла приёмки». Ключ родителя в `.github/allowed_signers` (D3.2) и телефонные проверки — сессия теста.
- **Исследования 18.10** (поставка `research-reports`, наблюдение до 2026-11-30) — справки в `knowledge/references/research/`:
  ударения синтеза (знак U+0301 у Supertonic 3 работает: 55 из 60 против 33 из 60), распознавание речи пятилетки (GigaAM-v3
  точнее диктовки; правило шага 3 «≥10 п.п.» и протокол записи), память-портрет (приёмка M1–M14), энциклопедия «почему»
  (BM25 в FTS5 хватает; приёмка E1–E11). Лицензии сверены при записи: OpenStax — CC BY-NC-SA, не CC BY.
- **STATUS поставки** несёт `parallel_sessions: merge-guard,manual-deploy` (обязательно с `delivery@2.01`). После
  синхронизации канона сразу гонять строгий `delivery_check --require-ci --diff-base origin/main` (урок L14).

