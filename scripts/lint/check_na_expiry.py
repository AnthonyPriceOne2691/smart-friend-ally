#!/usr/bin/env python3
"""Объявления n/a «до первого кода» истекают с первым кодом.

Свой гейт проекта, строки в каталоге CQG §3 у него нет. Канон держит
устаревшее объявление `not-applicable.json` видимостью — причина печатается на
каждом прогоне (`cqg@1.67`). На проекте, развёрнутом ДО кода, этого мало: роли
Swift объявлены n/a с причиной «кода ещё нет», и проба 2026-10-03 показала, что
первый закоммиченный `.swift` проходит и мета-гейт (OK), и доктора (о Swift ни
строки). Код поехал бы мимо всех гейтов, а вернуть их держалось бы на памяти.

Условия истечения живут в отдельном файле проекта `scripts/lint/na-expiry.json`
— формат `not-applicable.json` читают канонные скрипты, и чужое поле в нём было
бы правкой канона из проекта:

    {"*.swift": ["check_file_length.sh", "check_grep_gate.sh:config-access", ...]}

Ключ — маска `git ls-files`, значение — ключи `not-applicable.json`, чья причина
обещает действие «первой поставкой с кодом». Ключ с `_` в начале — комментарий.

Правила:
  expired  по маске есть хоть один файл (индекс или неигнорируемое дерево), а
           список не пуст — каждое объявление ждёт решения: подключить гейт
           (убрать ключ из not-applicable.json) или переобъявить n/a с причиной,
           верной при коде; в обоих случаях — убрать ключ из na-expiry.json;
  stale    ключ списка уже не объявлен в not-applicable.json — решение принято,
           а условие осталось: убрать его отсюда.

Снимка нет: это не ратчет, нарушений-легаси не бывает. `STRICT=0` — локальная
аварийная мера (предупреждение и exit 0), в CI запрещена. Мягкий режим здесь
законен, а у гейта детских данных нет: пропущенное решение о ролях обратимо.

Выход: 0 — чисто, печатает числа; 1 — нарушение; 2 — конфиг не читается или
неизвестный аргумент.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

EXPIRY = Path("scripts/lint/na-expiry.json")
NA = Path("scripts/lint/not-applicable.json")


def load(root: Path, rel: Path) -> dict:
    data = json.loads((root / rel).read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{rel}: ожидался объект JSON")
    return {k: v for k, v in data.items() if not str(k).startswith("_")}


def matching_files(root: Path, *mask: str) -> list[str]:
    """Индекс и неигнорируемое дерево; без маски — все файлы, их и сверяет маска."""
    out = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", *mask],
        cwd=root, capture_output=True, check=True,
    ).stdout
    return sorted({p for p in out.decode("utf-8", "surrogateescape").split("\0") if p})


def judge(root: Path, expiry: dict, declared: dict) -> tuple[list[str], int, int]:
    """→ (нарушения, сколько файлов нашлось по маскам, сколько объявлений в силе)."""
    problems: list[str] = []
    seen = pending_total = 0
    for mask, keys in expiry.items():
        if not isinstance(keys, list):
            problems.append(f"{EXPIRY}: «{mask}» — ожидался список ключей")
            continue
        files = matching_files(root, mask)
        seen += len(files)
        for key in keys:
            if key not in declared:
                problems.append(f"stale — «{key}» уже не объявлен в {NA}, а условие "
                                f"«{mask}» о нём осталось: убери ключ из {EXPIRY}")
            elif files:
                problems.append(f"expired — «{key}»: по маске «{mask}» есть код "
                                f"({len(files)}, первый: {files[0]}), а объявление n/a "
                                f"«до кода» в силе")
            else:
                pending_total += 1
    return problems, seen, pending_total


def main(argv: list[str]) -> int:
    if argv:
        print(f"na-expiry — неизвестный аргумент {argv[0]!r}; гейт без параметров",
              file=sys.stderr)
        return 2
    try:
        root = Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True, check=True).stdout.strip())
        expiry, declared = load(root, EXPIRY), load(root, NA)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"na-expiry — не могу прочитать условия: {exc}", file=sys.stderr)
        return 2
    problems, seen, pending = judge(root, expiry, declared)
    if not problems:
        # «просмотрено N файл(ов)» — форма CQG §6: доктор сверяет N с деревом.
        # N — все пути индекса и неигнорируемого дерева: их и сверяет маска.
        print(f"na-expiry — просмотрено {len(matching_files(root))} файл(ов), по маскам "
              f"{seen}; условий {len(expiry)}, объявлений n/a «до кода» в силе {pending}")
        return 0
    strict = os.environ.get("STRICT", "1") != "0"
    head = "\033[31mna-expiry" if strict else "\033[33mWARNING na-expiry (STRICT=0)"
    print(f"{head} — объявления n/a ждут решения ({len(problems)}):\033[0m", file=sys.stderr)
    for line in problems:
        print(f"  {line}", file=sys.stderr)
    print("Решение на каждый ключ: подключить гейт или переобъявить n/a с причиной, верной "
          f"при коде, — и убрать ключ из {EXPIRY}. Карта ролей — delivery/STACK-ACCEPTANCE.md.",
          file=sys.stderr)
    return 1 if strict else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
