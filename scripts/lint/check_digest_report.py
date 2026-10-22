#!/usr/bin/env python3
"""Дайджест утверждений в verify-report совпадает с пересчётом (свой гейт проекта, CQG §5.5).

Зачем. `delivery_check` читает строку `asserts_without_example: N` из verify-report, а вставляет её исполнитель:
устаревший дайджест (тесты поменялись после вставки) или поправленный руками пропускал бы
`asserts_reviewed_by: n/a` над утверждениями, которых не подписывал никто (Delivery §3.1d уровень 3; урок L26).
Здесь дайджест пересчитывается канонным `assert_digest.sh` от той же базы и сверяется с отчётом. Шаг возвращён
поставкой voice-core (решение ведущего 2026-10-19); адаптация записана в `scripts/lint/adapted.json`.

Отчёт — активной поставки либо той, что архивируется этим же диффом (так судит и `delivery_check --diff-base`).
Отчёта нет — фаза до verify: сверять не с чем, выход 0 с причиной. Выход 1: дайджест не посчитан, в отчёте нет
строки, числа расходятся, `n/a` при пересчёте не 0 или `unknown`.

Настройка (env): BASE (дефолт origin/main).
Запуск: python3 scripts/lint/check_digest_report.py
"""

from __future__ import annotations

import os
import re
import subprocess
import sys

MARK = re.compile(r"asserts_without_example:\s*(\d+|unknown)")
WAIVED = re.compile(r"(?im)^\W*asserts_reviewed_by\W*n/a")
ARCHIVED = re.compile(r"^delivery/archive/[^/]+/verify-report\.md$")


def git(*args: str) -> str:
    out = subprocess.run(["git", *args], capture_output=True, text=True, check=False)
    return out.stdout if out.returncode == 0 else ""


def report(base: str) -> str | None:
    """Путь отчёта: активной поставки или архивируемой в окне `merge-base..HEAD`."""
    if os.path.isfile("delivery/active/verify-report.md"):
        return "delivery/active/verify-report.md"
    window = (git("merge-base", base, "HEAD").strip() or base) + "..HEAD"
    added = git("diff", "--name-only", "--diff-filter=A", window).splitlines()
    return next((p for p in added if ARCHIVED.match(p) and os.path.isfile(p)), None)


def verdict(path: str, fresh: str, text: str, base: str) -> list[str]:
    """Ошибки сверки; пусто — отчёт честен."""
    claimed = MARK.findall(text)
    if not claimed:
        return [f"в {path} нет строки asserts_without_example — дайджест не вставлен (bash scripts/lint/assert_digest.sh)"]
    errors = []
    if claimed[-1] != fresh:
        errors.append(f"{path}: asserts_without_example {claimed[-1]}, пересчёт от {base}: {fresh} — "
                      "дайджест устарел или поправлен руками; вставь свежий")
    if WAIVED.search(text) and fresh != "0":
        errors.append(f"{path}: asserts_reviewed_by: n/a при пересчёте {fresh} — n/a законен только при нуле "
                      "(§3.1d уровень 3): нужна подпись human:… at=…")
    return errors


def main() -> int:
    os.chdir(git("rev-parse", "--show-toplevel").strip() or ".")
    base = os.environ.get("BASE", "origin/main")
    path = report(base)
    if path is None:
        print("digest-report: verify-report нет — сверять не с чем (фаза до verify)")
        return 0
    digest = subprocess.run(["bash", "scripts/lint/assert_digest.sh"], capture_output=True, text=True,
                            env={**os.environ, "BASE": base}, check=False).stdout
    fresh = MARK.findall(digest)
    if not fresh:
        print(f"ERROR: digest-report — дайджест от {base} не посчитан (нет строки asserts_without_example)",
              file=sys.stderr)
        return 1
    with open(path, encoding="utf-8") as fh:
        errors = verdict(path, fresh[-1], fh.read(), base)
    for error in errors:
        print(f"ERROR: digest-report — {error}", file=sys.stderr)
    if not errors:
        print(f"digest-report: {path} — asserts_without_example {fresh[-1]}, совпадает с пересчётом от {base}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
