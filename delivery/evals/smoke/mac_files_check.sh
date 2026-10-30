#!/usr/bin/env bash
# S9 (sim-app, N1–N3): папка файлов для Элли на Mac. Скрипт сверяет всё до первой записи, кладёт раскладку контейнера
# (`Models/`, `Voice/`, словарь `.gz` распакован) и `manifest.json`, повтор ничего не переписывает, не тот источник —
# стоп с именем и без записи, а в `~/Library/Containers` скрипт не пишет вовсе. Без ~/models: временный репозиторий
# с реестрами в формате App/Resources и пином в формате delivery/model_surface.txt. Шаги судятся кодом возврата (L10).
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/repo/App/Resources" "$tmp/repo/delivery" "$tmp/models/tts/voice" "$tmp/models/tts/dict"
printf 'weights' >"$tmp/models/w.gguf"
printf 'silero' >"$tmp/models/vad.onnx"
printf 'voice' >"$tmp/models/tts/voice/a.weights"
printf '{"word": "wo+rd"}' | gzip -c >"$tmp/models/tts/dict/b.json.gz"
python3 - "$tmp" <<'PY'
import gzip, hashlib, json, sys
from pathlib import Path
t = Path(sys.argv[1])
res = t / "repo/App/Resources"
sha = lambda data: hashlib.sha256(data).hexdigest()
weights = (t / "models/w.gguf").read_bytes()
(res / "model.json").write_text(json.dumps({"model": {"file": "w.gguf", "bytes": len(weights)}}))
(res / "hearing.json").write_text(json.dumps({"vad": {"file": "vad.onnx", "bytes": 6}}))
plain, words = (t / "models/tts/voice/a.weights").read_bytes(), gzip.decompress((t / "models/tts/dict/b.json.gz").read_bytes())
files = [{"from": "voice/a.weights", "to": "supertonic/a.weights", "bytes": len(plain), "sha256": sha(plain), "group": "voice"},
         {"from": "dict/b.json.gz", "to": "ruaccent/b.json", "bytes": len(words), "sha256": sha(words), "group": "accent"}]
(res / "voice.json").write_text(json.dumps({"folder": "Voice", "files": files}))
(t / "repo/delivery/model_surface.txt").write_text(f"# пин\nweights:w.gguf:{len(weights)}\t{sha(weights)}\n")
PY
lay() { python3 scripts/mac_files.py --repo "$tmp/repo" --models "$tmp/models" --tts "$tmp/models/tts" --out "$1"; }
state() { python3 -c 'import os, sys; [print(p, os.stat(p).st_size, os.stat(p).st_mtime_ns) for p in sorted(str(q) for q in __import__("pathlib").Path(sys.argv[1]).rglob("*") if q.is_file())]' "$tmp/out"; }
out="$tmp/out"
# N1: раскладка контейнера, словарь распакован, список с байтами и sha256 каждого файла.
first=$(lay "$out") || { echo "FAIL N1: раскладка не прошла: $first"; exit 1; }
for f in Models/w.gguf Models/vad.onnx Voice/supertonic/a.weights Voice/ruaccent/b.json manifest.json; do
  [ -f "$out/$f" ] || { echo "FAIL N1: нет $f"; exit 1; }
done
grep -q '"wo+rd"' "$out/Voice/ruaccent/b.json" || { echo "FAIL N1: словарь не распакован"; exit 1; }
python3 - "$out" <<'PY' || exit 1
import hashlib, json, sys
from pathlib import Path
out = Path(sys.argv[1])
files = json.loads((out / "manifest.json").read_text())["files"]
paths = [f["path"] for f in files]
if paths != ["Models/w.gguf", "Models/vad.onnx", "Voice/supertonic/a.weights", "Voice/ruaccent/b.json"]:
    sys.exit(f"FAIL N1: список не тот: {paths}")
for f in files:
    data = (out / f["path"]).read_bytes()
    if len(data) != f["bytes"] or hashlib.sha256(data).hexdigest() != f["sha256"]:
        sys.exit(f"FAIL N1: в списке не те байты или sha256: {f['path']}")
PY
tail -1 <<<"$first" | grep -q '^готово: 4 файлов' || { echo "FAIL N1: нет строки «готово»: $first"; exit 1; }
# N2: повтор — ни одного переписанного файла.
before=$(state)
again=$(lay "$out") || { echo "FAIL N2: повтор не прошёл: $again"; exit 1; }
grep -q 'без изменений: 4' <<<"$again" || { echo "FAIL N2: повтор что-то переписал: $again"; exit 1; }
[ "$(state)" = "$before" ] || { echo "FAIL N2: файлы переписаны повтором"; exit 1; }
# N3: не тот источник того же размера — стоп с именем до первой записи, папка та же.
printf 'voicX' >"$tmp/models/tts/voice/a.weights"
if bad=$(lay "$out" 2>&1); then echo "FAIL N3: чужой файл голоса прошёл"; exit 1; fi
grep -q 'supertonic/a.weights' <<<"$bad" || { echo "FAIL N3: стоп без имени файла: $bad"; exit 1; }
printf 'voice' >"$tmp/models/tts/voice/a.weights"
printf 'weightz' >"$tmp/models/w.gguf"
if bad=$(lay "$out" 2>&1); then echo "FAIL N3: веса мимо пина прошли"; exit 1; fi
grep -q 'Models/w.gguf' <<<"$bad" || { echo "FAIL N3: стоп без имени весов: $bad"; exit 1; }
[ "$(state)" = "$before" ] || { echo "FAIL N3: после стопа папка изменилась"; exit 1; }
printf 'weights' >"$tmp/models/w.gguf"
# N3: в контейнер приложения — отказ до сверки, каталог не создан.
box="$HOME/Library/Containers/com.anthonypriceone.ally.smoke-$$/Data"
if bad=$(lay "$box" 2>&1); then echo "FAIL N3: запись в контейнер не остановлена"; exit 1; fi
grep -q 'в контейнер приложения скрипт не пишет' <<<"$bad" || { echo "FAIL N3: отказ без причины: $bad"; exit 1; }
[ ! -e "$HOME/Library/Containers/com.anthonypriceone.ally.smoke-$$" ] || { echo "FAIL N3: каталог в контейнерах создан"; exit 1; }
echo "S9: раскладка с распакованным словарём и списком, повтор без записи, чужой источник и контейнер — стоп"
