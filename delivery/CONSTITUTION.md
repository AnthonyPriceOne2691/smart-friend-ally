# Delivery constitution — Smart Friend Ally

**Version:** 1.0
**Ratified:** 2026-10-02
**Canon stack:** delivery@1.98 · cqg@2.43 · okf@1.19
<!-- версии из шапок соответствующих *.md; absent = слой не развёрнут -->
**CI:** not-deployed   <!-- §10.4; после первого зелёного прогона: deployed (github-actions) merge-gate: tooling -->

## Non-negotiables

- Done закрывается **зелёным CI-прогоном** (§10.4), не локальным «у меня прошло».
- `STRICT=0` / `git commit -n` — аварийная локальная мера, видимая в PR; в CI запрещены.
- **Данные ребёнка не попадают в git никогда:** записи голоса, транскрипты, база
  памяти, журналы с её репликами. Держат это `.gitignore` и гейт контура, а не
  внимательность.
- **Продукт не ходит в сеть:** облачных моделей, телеметрии и синхронизации нет
  (решение пользователя 2026-10-01; канон — `knowledge/`).

## Process principles

1. Spec before broad implementation (class M/L).
2. Vertical slices; no oneshot of the whole plan.
3. Done = oracles (shape + behavior + product), never self-declaration alone.
4. Builder ≠ Verifier.
5. Agent mistake → strengthen harness (oracle / breaker / hook), not only prompts.
6. One `delivery/active` at a time.
7. Путь, который проверяется только исполнением (микрофон, права, аудиосессия,
   лимит памяти, прерывания), исполняется на iPhone до «готово» (§12.6). Одна
   установка на телефон — одна рисковая правка.

## Coding-agent contract (thin ABC)

### Preconditions
- STATUS.md read; class S/M/L known; branch/worktree set.
- Before implement: artifacts per harness §2.2 (S: tasks; M/L: spec+plan+tasks + human_ok_spec).
- Перед решением о продукте прочитан `KNOWLEDGE.md` (исследование и принципы П1–П37).

### Invariants
- No secrets in git; no child data in git; no force-push to main; no done-on-red; no silent scope creep.

### Governance
- Human OK on spec (M/L). Human OK on plan (L / risky).
- HITL: правила детской безопасности, смена модели или голоса, миграции базы
  памяти на телефоне, всё, что меняет обращение с данными ребёнка.

### Recovery
- On oracle red: fix ≤ retry budget, else escalate in STATUS.md.

## Agent permissions (§4.5)

Источник истины по **действиям**. Строки ниже обязаны совпадать с
`.claude/settings.json` (`permissions.deny` / `permissions.ask`) — сверяет
`delivery_check` в обе стороны. Правило здесь и не в настройках = запрет,
который не работает; в настройках и не здесь = граница, сдвинутая без ревью.

`allow` тут не перечисляется: это накопительный список конкретных команд,
его место — только в настройках (§4.5, почему).

```text
agent-permissions
# Необратимое: подтверждение здесь не защита, а соучастие.
deny: Bash(git push --force:*)
deny: Bash(git push:* --force-with-lease)
deny: Bash(rm -rf /:*)
deny: Read(./.env)
deny: Read(./**/.env)
# Обратимо, но платит человек своим временем.
ask: Bash(git push:*)
ask: Bash(gh pr merge:*)
ask: Bash(gh repo create:*)
ask: Bash(pip install:*)
ask: Bash(npm install:*)
ask: Bash(brew install:*)
ask: WebFetch
```

<!-- psql/mysql из шаблона сняты: серверных баз в проекте нет. Добавлены
     `gh repo create` (действие наружу) и `brew install` (установка инструментов
     мимо манифеста). Строку в настройки — и сюда, одним коммитом. -->

## Pointers to sibling layers (fill if deployed)

- Code shape oracles: see `docs/canon/CODE_QUALITY_GATES.md` — [ ] not deployed / [x] deployed (Swift-роли ждут первого кода: `scripts/lint/not-applicable.json`)
- Domain canon: see `knowledge/` per `docs/canon/OKF_KNOWLEDGE_BUNDLE.md` — [ ] not deployed / [x] deployed
- Agent hooks (§10): [x] not deployed / [ ] deployed
- CI oracles (§10.4, workflow per CQG §8): [x] not deployed / [ ] deployed
- Skills catalog: `skills/README.md` — [x] absent / [ ] present
- Research base (не канон контура): `KNOWLEDGE.md` в корне — факты, решения, принципы П1–П37.
