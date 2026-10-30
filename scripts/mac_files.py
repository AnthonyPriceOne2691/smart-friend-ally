#!/usr/bin/env python3
"""Папка файлов для Элли на Mac (sim-app): модель, слух, голос и ударения — в раскладке контейнера приложения.

    python3 scripts/mac_files.py            # сверка, затем раскладка в ~/models/ally-mac
    python3 scripts/mac_files.py --check    # только сверка источников

Приложение для iPhone на Mac запускает только Xcode, а в его контейнер macOS других не пускает — файлы забирает само
приложение: в консоли «Файлы с Mac…» → эта папка. Раскладка — как `Library/Application Support` контейнера: `Models/`
(веса из `App/Resources/model.json`, Silero из `hearing.json`), `Voice/` (файлы `voice.json`, словари `.gz`
распакованы) и `manifest.json` — путь, байты, sha256 каждого файла.

Сверка — до первой записи: веса — по пину `delivery/model_surface.txt`, Silero — по байтам `hearing.json`, голос —
функциями `copy_voice.py`. Файлы ложатся клонами APFS (`cp -c`) — место не тратится. В контейнер приложения
(`~/Library/Containers`) скрипт не пишет никогда; повтор пропускает неизменённое; ничего не удаляет и не скачивает.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import copy_voice

REPO = Path(__file__).resolve().parent.parent


def pinned(repo, model):
    """sha256 of the weights from the model surface's snapshot: the key `weights:<file>:<bytes>`."""
    key = f"weights:{model['file']}:{model['bytes']}"
    for line in (repo / "delivery/model_surface.txt").read_text().splitlines():
        if line.startswith(key + "\t"):
            return line.split("\t")[1]
    sys.exit(f"mac_files: нет пина {key} в delivery/model_surface.txt — стоп, ничего не записано")


def checked(path, rel, size, sha):
    """(path, rel, size, sha256) of a source that is there and the right one; else a stop with its name."""
    if not path.is_file():
        sys.exit(f"mac_files: нет файла {path} — стоп, ничего не записано")
    found, length = copy_voice.digest(path)
    if length != size or (sha and found != sha):
        sys.exit(f"mac_files: {rel} не тот (sha256 {found[:12]}…, {length} байт) — стоп, ничего не записано")
    return path, rel, size, found


def sources(repo, models, tts, work):
    """Every file of the folder, all checked before any write: the weights, Silero, the voice (`.gz` unpacked)."""
    resources = repo / "App/Resources"
    model = json.loads((resources / "model.json").read_text())["model"]
    vad = json.loads((resources / "hearing.json").read_text()).get("vad")
    voice = json.loads((resources / "voice.json").read_text())
    staged = [checked(models / model["file"], f"Models/{model['file']}", model["bytes"], pinned(repo, model))]
    if vad:
        staged.append(checked(models / vad["file"], f"Models/{vad['file']}", vad["bytes"], None))
    for path, entry in copy_voice.verify(voice["files"], tts, work):
        staged.append((path, f"{voice['folder']}/{entry['to']}", entry["bytes"], entry["sha256"]))
    return staged


def clone(source, target):
    """An APFS clone on the Mac (`cp -c`: no space spent), a plain copy elsewhere."""
    if sys.platform == "darwin" and subprocess.run(["cp", "-c", str(source), str(target)],
                                                   capture_output=True).returncode == 0:
        return
    shutil.copyfile(source, target)


def same(target, size, sha):
    return target.is_file() and target.stat().st_size == size and copy_voice.digest(target)[0] == sha


def lay_out(staged, out):
    """Changed files beside their place, then renamed into it; the list last. Returns how many files were written."""
    written = 0
    for path, rel, size, sha in staged:
        target = out / rel
        if same(target, size, sha):
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        part = target.with_name(target.name + ".part")
        clone(path, part)
        os.replace(part, target)
        written += 1
    listing = json.dumps({"files": [{"path": rel, "bytes": size, "sha256": sha} for _, rel, size, sha in staged]},
                         ensure_ascii=False, indent=1) + "\n"
    manifest = out / "manifest.json"
    if not manifest.is_file() or manifest.read_text() != listing:
        part = manifest.with_name("manifest.json.part")
        part.write_text(listing)
        os.replace(part, manifest)
        written += 1
    return written


def main():
    ap = argparse.ArgumentParser(description="папка файлов для Элли на Mac: сверка, затем раскладка")
    ap.add_argument("--check", action="store_true", help="только сверка источников")
    ap.add_argument("--models", type=Path, default=Path.home() / "models", help="веса и Silero")
    ap.add_argument("--tts", type=Path, default=Path.home() / "models/tts", help="голос и ударения")
    ap.add_argument("--out", type=Path, default=Path.home() / "models/ally-mac")
    ap.add_argument("--repo", type=Path, default=REPO)
    args = ap.parse_args()
    out = args.out.expanduser().resolve()
    containers = (Path.home() / "Library/Containers").resolve()
    if out == containers or containers in out.parents:
        sys.exit(f"mac_files: в контейнер приложения скрипт не пишет: {out} — стоп")
    with tempfile.TemporaryDirectory() as tmp:
        staged = sources(args.repo, args.models, args.tts, Path(tmp))
        total = sum(size for _, _, size, _ in staged)
        print(f"сверено: {len(staged)} файлов, {total} байт")
        if args.check:
            return
        written = lay_out(staged, out)
    if written == 0:
        print(f"без изменений: {len(staged)}")
        return
    gigabytes = f"{total / 1e9:.2f}".replace(".", ",")
    print(f"готово: {len(staged)} файлов, {gigabytes} ГБ в {out} — в консоли на Mac: «Файлы с Mac…» → эта папка")


if __name__ == "__main__":
    main()
