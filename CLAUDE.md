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

## Состояние (2026-10-02)

- **Контур развёрнут и слит** (squash `520cfa3`, PR #1 закрыт): `delivery@1.98 · cqg@2.43 · okf@1.19 · stack-map@1.52`,
  снимок `docs/canon/` с провенансом. Репозиторий — приватный `AnthonyPriceOne2691/smart-friend-ally`;
  `ci-oracles: tooling` (защиты ветки нет на бесплатном тарифе). Мерж — только
  `PATH="$PWD/.venv/bin:$PATH" bash scripts/merge_guard.sh <ветка> main` из основного клона, затем
  `git push origin main` и закрыть PR со ссылкой на сквош.
- Разбор и уроки L1–L4 — `delivery/archive/2026-10-02-contour-bootstrap/`, `delivery/archive/INDEX.md`.
- **Обязательство:** до **2026-10-16** записать `delivery/archive/2026-10-02-contour-bootstrap/observed.md`
  (сигнал — в STATUS архива), иначе `delivery_check` покраснеет на следующей поставке.
- **Первая поставка с кодом** подключает Swift-роли, объявленные `n/a`: `file-length` с маской `*.swift`
  (форма — комментарием в `.pre-commit-config.yaml`), ратчет SwiftLint (роли линтера и сложности),
  покрытие через `swift test --enable-code-coverage`; объявляет `runtime_paths` и `model_surface`, повторяет приёмку.
- **Находки для канона (Prepare):** шаблон CI роняет джобу без `requirements.txt` (L3); OKF отстаёт от upstream #323
  (метки времени ISO 8601 со смещением). Решение о правке канона — за пользователем.

