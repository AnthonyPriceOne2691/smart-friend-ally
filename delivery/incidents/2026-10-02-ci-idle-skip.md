# Инцидент: шаблон CI в простое пропускает delivery_check

- **Дата:** 2026-10-02 · **Нашедший:** agent:claude-code (сессия smart-frend-ally) · **Хозяин:** smart-friend-ally
- **Канон:** `cqg@2.43`, `.github/workflows/quality.yml` (§8.3), джоба `delivery`, шаг `Delivery phase gate + circuit breakers`

## Симптом

Прогон на `main` после архива bootstrap (36992656769, `e0d2056`): шаг зелёный,
но по ветке `else` — «no active delivery — skip». В этот момент у проекта
открыто окно наблюдения (`observe_until: 2026-10-16`), и просрочку CI бы не увидел.

## Что видел нашедший

Шаблон: `else echo "no active delivery — skip"`. У `voice-interview-coach` тот же
шаг давно исправлен (уроки тренера L7, L15, L18): в простое гейт зовётся без
флагов, потому что именно в простое он ловит просроченное наблюдение (§13.1) и
пропавший `delivery/active/` (§2.3a). В шаблон канона исправление не попало.

## Воспроизведение хозяина

- Регрессия `delivery/evals/smoke/idle_overdue.sh` (S4 в smoke): красная на шаблонной
  форме шага («в простое шаг не зовёт delivery_check»), зелёная после правки (PR #3, `376e4c4`).
- Поведенческая половина той же регрессии: во временном репозитории в простое
  `delivery_check` с просроченным `observe_until` и без `observed.md` — exit 1, с `observed.md` — exit 0.

## Вердикт хозяина

Дефект шаблона: урок, купленный другим проектом флота, не вошёл в канон —
рецидив L18 тренера (урок Ally L5).

## Предложение (решает судья)

В шаблоне ветка `else` — `python scripts/delivery_check.py` без `--require-ci` и
`--diff-base` (без активной поставки у них нет предмета), с комментарием о причине.

## Куда уехало

- `scripts/lint/adapted.json` → `.github/workflows/quality.yml`, `kind: upstream-candidate`;
- сообщение судье (сессия Prepare) после мержа поставки `canon-sync-loop`.
