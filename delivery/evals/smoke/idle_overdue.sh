#!/usr/bin/env bash
# Регрессия поставки ci-idle-delivery-check (S4 в smoke, Delivery §3.1c).
#
# Простой — штатное состояние (§2.3a), и как раз в нём delivery_check ловит
# просроченное наблюдение (§13.1). Утверждений два, и нужны оба:
#   1) поведение — в простое просроченный observe_until без observed.md даёт
#      красный гейт, а с observed.md — зелёный;
#   2) проводка — шаг «Delivery phase gate» в quality.yml в простое ЗОВЁТ
#      delivery_check, а не печатает skip. Шаблон CQG §8.3 печатал skip; тот же
#      дефект тренер закрыл уроками L7, L15, L18.
# Первое без второго проверяет гейт, которого CI не зовёт; второе без первого —
# вызов, который ничего не ловит.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)" || exit 1
PY=python3

overdue_observation_is_red() {
  local tmp rc=0
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts" "$tmp/.claude" "$tmp/delivery/active" \
           "$tmp/delivery/archive/2026-01-01-probe"
  cp "$ROOT"/scripts/delivery_*.py "$tmp/scripts/"
  cp "$ROOT/delivery/CONSTITUTION.md" "$tmp/delivery/"
  cp "$ROOT/.claude/settings.json" "$tmp/.claude/"
  touch "$tmp/delivery/active/.gitkeep"
  printf '| Дата | Поставка (каталог) | Пути | Урок |\n|---|---|---|---|\n| 2026-01-01 | `2026-01-01-probe` | `x/` | — |\n' \
    > "$tmp/delivery/archive/INDEX.md"
  printf -- '- **observe_until:** 2026-01-02\n' > "$tmp/delivery/archive/2026-01-01-probe/STATUS.md"
  commit() { git -C "$tmp" add -A && git -C "$tmp" -c user.name=probe -c user.email=probe@local commit -qm "$1"; }
  git -C "$tmp" init -q && commit probe
  if (cd "$tmp" && "$PY" scripts/delivery_check.py >/dev/null 2>&1); then
    echo "FAIL: в простое просроченное наблюдение не поймано"; rc=1
  fi
  printf '# Observed\n' > "$tmp/delivery/archive/2026-01-01-probe/observed.md"
  commit observed
  if ! (cd "$tmp" && "$PY" scripts/delivery_check.py >/dev/null 2>&1); then
    echo "FAIL: с observed.md гейт в простое всё равно красный — проба судит не то"; rc=1
  fi
  rm -rf "$tmp"
  return "$rc"
}

idle_branch_calls_delivery_check() {
  "$PY" - "$ROOT/.github/workflows/quality.yml" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"- name: Delivery phase gate.*?\n(?=      - name:|\Z)", text, re.S)
if not m:
    sys.exit("FAIL: шага «Delivery phase gate» в quality.yml нет")
step = m.group(0)
idle = step.split("else", 1)[1] if "else" in step else ""
idle = "\n".join(l for l in idle.splitlines() if not l.strip().startswith("#"))
if "scripts/delivery_check.py" not in idle:
    sys.exit("FAIL: в простое шаг не зовёт delivery_check (skip вместо проверки — L18 тренера)")
PY
}

overdue_observation_is_red && idle_branch_calls_delivery_check && echo "idle-overdue: PASS"
