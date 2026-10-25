#!/usr/bin/env bash
# S8 (voice-config, Z20): команда копирования голоса сверяет sha256 до первой копии и стоит на расхождении с именем
# файла; словарь .gz распаковывается, и сверяется распакованный. Без телефона и без ~/models: временная папка и свой
# манифест в формате App/Resources/voice.json.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/models/voice" "$tmp/models/dict"
printf 'weights' >"$tmp/models/voice/a.weights"
printf '{"word": "wo+rd"}' | gzip -c >"$tmp/models/dict/b.json.gz"
python3 - "$tmp" <<'PY'
import gzip, hashlib, json, sys
from pathlib import Path
t = Path(sys.argv[1])
def entry(src, to, data):
    return {"from": src, "to": to, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(), "group": "voice"}
plain = (t / "models/voice/a.weights").read_bytes()
words = gzip.decompress((t / "models/dict/b.json.gz").read_bytes())
files = [entry("voice/a.weights", "supertonic/a.weights", plain), entry("dict/b.json.gz", "ruaccent/b.json", words)]
(t / "voice.json").write_text(json.dumps({"folder": "Voice", "files": files}))
PY
check() { python3 scripts/copy_voice.py --check --models "$tmp/models" --manifest "$tmp/voice.json"; }
# Верные файлы проходят — и это же доказывает, что сверяется распакованный словарь: в манифесте его sha256.
check >/dev/null || { echo "FAIL: сверка верных файлов не прошла"; exit 1; }
# Подмена того же размера: ловит только sha256, сверка одних байтов её пропустила бы.
printf 'weightz' >"$tmp/models/voice/a.weights"
if out=$(check 2>&1); then echo "FAIL: чужой файл прошёл сверку"; exit 1; fi
grep -q "supertonic/a.weights" <<<"$out" || { echo "FAIL: стоп без имени файла: $out"; exit 1; }
printf 'weights' >"$tmp/models/voice/a.weights"
printf '{"word": "w+ord"}' | gzip -c >"$tmp/models/dict/b.json.gz"
if out=$(check 2>&1); then echo "FAIL: чужой словарь прошёл сверку"; exit 1; fi
grep -q "ruaccent/b.json" <<<"$out" || { echo "FAIL: стоп без имени словаря: $out"; exit 1; }
echo "S8: верные файлы проходят, чужой файл и чужой словарь — стоп с именем до первой копии"
