#!/usr/bin/env python3
"""Команда копирования файлов голоса на телефон (серия голоса, V4b1).

    python3 scripts/copy_voice.py <UDID>     # сверка на Mac, затем копирование в контейнер приложения
    python3 scripts/copy_voice.py --check    # только сверка, без телефона

Манифест — App/Resources/voice.json. У каждого файла есть:
- `from` — источник под ~/models/tts (или --models);
- `to` — путь в папке голоса;
- байты и sha256.

Словарь `.gz` распаковывается во временную папку, и sha256 сверяется у распакованного. Всё сверяется до первой копии,
на расхождении — стоп с именем файла. Ничего не удаляет и не скачивает. На телефон ставит только решение родителя
(manual-deploy). Флаги devicectl — как у reinstall_app.sh (Xcode 27, L23).
"""
import argparse
import gzip
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BUNDLE = "com.anthonypriceone.ally"
CHUNK = 1 << 20


def digest(path):
    sha, size = hashlib.sha256(), 0
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(CHUNK), b""):
            sha.update(block)
            size += len(block)
    return sha.hexdigest(), size


def stage(entry, models, work):
    """The file as it goes to the phone: the source itself, or the `.gz` unpacked into `work`."""
    src = models / entry["from"]
    if not src.is_file():
        sys.exit(f"copy_voice: нет файла {src} — стоп, ничего не скопировано")
    if src.suffix != ".gz":
        return src
    out = work / entry["to"]
    out.parent.mkdir(parents=True, exist_ok=True)
    with gzip.open(src, "rb") as packed, open(out, "wb") as plain:
        shutil.copyfileobj(packed, plain, CHUNK)
    return out


def verify(files, models, work):
    """Every file before any copy: (staged path, entry); the first mismatch stops it all."""
    staged = []
    for entry in files:
        path = stage(entry, models, work)
        sha, size = digest(path)
        if sha != entry["sha256"] or size != entry["bytes"]:
            sys.exit(f"copy_voice: {entry['to']} не тот (sha256 {sha[:12]}…, {size} байт) — стоп, ничего не скопировано")
        staged.append((path, entry))
    return staged


def devicectl(*args):
    return subprocess.run(["xcrun", "devicectl", *args], capture_output=True, text=True)


def container(udid):
    return ["--device", udid, "--domain-type", "appDataContainer", "--domain-identifier", BUNDLE]


def copy(udid, folder, staged):
    for path, entry in staged:
        dest = f"Library/Application Support/{folder}/{entry['to']}"
        done = devicectl("device", "copy", "to", *container(udid), "--source", str(path), "--destination", dest)
        if done.returncode != 0:
            sys.exit(f"copy_voice: {entry['to']} не скопирован: {done.stderr.strip()[-300:]}")
        print(f"скопирован: {entry['to']} ({entry['bytes']} байт)")


def on_phone(udid, folder, work):
    """Bytes of every file under the voice folder on the phone, by name; empty when the listing fails."""
    out = work / "files.json"
    devicectl("device", "info", "files", *container(udid), "--subdirectory", f"Library/Application Support/{folder}",
              "--json-output", str(out))
    try:
        files = json.loads(out.read_text()).get("result", {}).get("files", [])
    except (OSError, ValueError):
        return {}
    return {f.get("name"): f.get("metadata", {}).get("size") for f in files}


def main():
    ap = argparse.ArgumentParser(description="файлы голоса на телефон: сверка на Mac, затем копирование")
    ap.add_argument("udid", nargs="?", help="UDID телефона; без него — только --check")
    ap.add_argument("--check", action="store_true", help="только сверка на Mac, без телефона")
    ap.add_argument("--models", type=Path, default=Path.home() / "models/tts")
    ap.add_argument("--manifest", type=Path, default=REPO / "App/Resources/voice.json")
    args = ap.parse_args()
    if not args.check and not args.udid:
        sys.exit("copy_voice: нужен UDID телефона или --check")
    manifest = json.loads(args.manifest.read_text())
    with tempfile.TemporaryDirectory() as tmp:
        work = Path(tmp)
        staged = verify(manifest["files"], args.models, work)
        print(f"сверено: {len(staged)} файлов, {sum(e['bytes'] for _, e in staged)} байт")
        if args.check:
            return
        if devicectl("device", "info", "details", "--device", args.udid, "--timeout", "30").returncode != 0:
            sys.exit(f"copy_voice: телефон {args.udid} не найден — ничего не скопировано")
        copy(args.udid, manifest["folder"], staged)
        sizes = on_phone(args.udid, manifest["folder"], work)
        wrong = [e["to"] for _, e in staged if sizes.get(Path(e["to"]).name) != e["bytes"]]
        if wrong:
            sys.exit(f"copy_voice: на телефоне не тот размер или нет файла: {', '.join(wrong)}")
        print("на телефоне всё на месте")


if __name__ == "__main__":
    main()
