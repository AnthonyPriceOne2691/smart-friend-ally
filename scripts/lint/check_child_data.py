#!/usr/bin/env python3
"""Данные ребёнка не попадают в git (delivery/CONSTITUTION.md, Non-negotiables).

Свой гейт проекта, строки в каталоге CQG §3 у него нет. Зачем он, если есть
.gitignore: игнор обходится `git add -f` молча, а запись голоса в истории —
необратимая утечка: из git её убирает только переписывание истории, с GitHub —
ещё и обращение в поддержку. Поэтому правило держит механика, а не внимание.

Что смотрит:
  индекс        `git ls-files --cached` — отслеживаемое и уже добавленное,
                в том числе через `add -f`;
  дерево        `git ls-files --others --exclude-standard` — неигнорируемые
                файлы: до коммита их отделяет один `git add -A`.

Три правила:
  local-dir    файл из `local/` в индексе: каталог только для локальных данных;
  data-ext     расширение аудио, базы, её спутников или чёрного ящика в индексе
               (.wav, .m4a, .sqlite, .sqlite-wal, .db-journal, .allybox, …);
  data-magic   файл начинается сигнатурой аудио, видео, HEIC, SQLite, WAL или
               журнала SQLite, записи чёрного ящика (`ALLY-BLACKBOX/`), как бы он
               ни назывался: переименованную запись (`voice.bin`, `case.json`)
               правило расширений пропускает.

Спутники базы (поставка memory-core): в режиме WAL свежие записи — имена из памяти
о ребёнке — лежат в `-wal` до чекпойнта, журнал отката держит прежние страницы;
проба 2026-10-23 — WAL с записью под тремя именами проходил гейт с выходом 0.

Текст разговора узнаётся только по заголовку записи чёрного ящика (поставка
black-box): фразу, перепечатанную руками, гейт не видит — по кириллице в тексте
он краснел бы на знании и фикстурах. Заголовок обязан стоять первой строкой в
каждом текстовом файле ящика, и в производных на Mac тоже.

⚠ Сигнатура читается из РАБОЧЕГО дерева, а не из индекса: файл, добавленный в
индекс и потом подменённый на диске, проверяется по подмене. Расширение и путь
судятся по индексу, поэтому `add -f запись.wav` ловится в любом случае.

Снимка нет и не будет: допуск ноль. Ратчет «только вниз» тут не про что —
одна запись в истории уже утечка. Мягкого режима (`STRICT=0`) тоже нет.

Выход: 0 — чисто, печатает число просмотренных; 1 — нарушение, каждое с файлом
и правилом; 2 — не git-репозиторий или неизвестный аргумент.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

DATA_EXT = {
    ".wav", ".m4a", ".caf", ".aif", ".aiff", ".mp3", ".flac", ".ogg", ".opus",
    ".sqlite", ".sqlite3", ".db", ".realm", ".allybox",
    ".sqlite-wal", ".sqlite-shm", ".sqlite-journal", ".db-wal", ".db-shm", ".db-journal",
}
SQLITE_WAL = (b"\x37\x7f\x06\x82", b"\x37\x7f\x06\x83")   # магия WAL: две схемы контрольной суммы
SQLITE_JOURNAL = bytes.fromhex("d9d505f920a163d7")             # магия журнала отката
LOCAL_DIR = "local/"
HEAD_BYTES = 16


def magic_kind(head: bytes) -> str | None:
    """Что это за данные по первым байтам; None — не аудио и не база."""
    if head[:4] == b"RIFF" and head[8:12] == b"WAVE":
        return "WAV"
    if head[:4] == b"caff":
        return "CAF"
    if head[4:8] == b"ftyp":            # m4a, mp4, mov, heic — всё контейнер ISO
        return "ISO-контейнер (m4a/mp4/mov/heic)"
    if head[:4] == b"FORM" and head[8:12] in (b"AIFF", b"AIFC"):
        return "AIFF"
    if head[:4] == b"fLaC":
        return "FLAC"
    if head[:4] == b"OggS":
        return "Ogg/Opus"
    if head[:3] == b"ID3" or head[:2] in (b"\xff\xfb", b"\xff\xf3", b"\xff\xf2"):
        return "MP3"
    if head[:16] == b"SQLite format 3\x00":
        return "SQLite"
    if head[:4] in SQLITE_WAL:          # WAL базы: свежие записи до чекпойнта
        return "SQLite WAL"
    if head[:8] == SQLITE_JOURNAL:      # журнал отката: прежние страницы
        return "журнал SQLite"
    if head.startswith(b"ALLY-BLACKBOX/"):  # запись чёрного ящика: её слова и ответ Элли
        return "чёрный ящик Ally"
    return None


def git_list(root: Path, *args: str) -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "-z", *args], cwd=root, capture_output=True, check=True
    ).stdout
    return [p for p in out.decode("utf-8", "surrogateescape").split("\0") if p]


def read_head(path: Path) -> bytes:
    try:
        with path.open("rb") as fh:
            return fh.read(HEAD_BYTES)
    except OSError:                     # удалён с диска, но ещё в индексе
        return b""


def violations(root: Path, cached: list[str], others: list[str]) -> list[str]:
    found: list[str] = []
    for rel in cached:
        if rel.startswith(LOCAL_DIR):
            found.append(f"{rel}: local-dir — каталог local/ только для локальных данных")
        elif Path(rel).suffix.lower() in DATA_EXT:
            found.append(f"{rel}: data-ext — расширение аудио, базы или чёрного ящика в индексе")
    flagged = {f.split(":", 1)[0] for f in found}
    for rel in dict.fromkeys(cached + others):
        if rel in flagged:
            continue
        kind = magic_kind(read_head(root / rel))
        if kind:
            where = "в индексе" if rel in cached else "в дереве, не игнорируется"
            found.append(f"{rel}: data-magic — содержимое {kind}, {where}")
    return found


def main(argv: list[str]) -> int:
    if argv:
        print(f"child-data — неизвестный аргумент {argv[0]!r}; гейт без параметров",
              file=sys.stderr)
        return 2
    try:
        top = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        print("child-data — не git-репозиторий, судить нечего", file=sys.stderr)
        return 2
    root = Path(top)
    cached = git_list(root, "--cached")
    others = git_list(root, "--others", "--exclude-standard")
    found = violations(root, cached, others)
    seen = len(set(cached) | set(others))
    if found:
        print(f"\033[31mchild-data — данные ребёнка на пути в git ({len(found)}):\033[0m",
              file=sys.stderr)
        for line in found:
            print(f"  {line}", file=sys.stderr)
        print("Убери из индекса (git rm --cached <файл>), а сами данные держи в "
              "local/ — он игнорируется. Обхода у гейта нет намеренно.", file=sys.stderr)
        return 1
    print(f"child-data — просмотрено {seen} файл(ов), данных ребёнка нет")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
