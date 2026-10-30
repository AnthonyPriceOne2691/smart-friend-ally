#!/usr/bin/env bash
# B15–B16 (поставка app-black-box, S10 в smoke): команда родителя scripts/blackbox.py выгружает чёрный ящик с «телефона»
# в local/blackbox/<дата>/<сессия>/ и стирает на нём только сверенное. Телефона нет: фальшивый xcrun на PATH играет
# devicectl над временным каталогом-контейнером (info details; info files --json-output — result.files[].name и
# .metadata.size; copy from; copy to --remove-existing-content true; FAKE_LOCKED — «device is locked»), фальшивый mdls —
# признак iCloud. Настоящий xcrun не зовётся: без фальшивого первым на PATH — стоп. Всё — во временных каталогах с
# пробелами в путях; синтетика — WAV PCM16 16 кГц, m4a с заголовком ftyp, записи с bytes и FNV-1a.
# Случаи: 1 — две сверяемые сессии (1b — имена в листинге без каталога сессии); 2 — испорчен байт WAV (2b — чужой
# заголовок записи и звук другого размера); 3 — .gitignore без local/; 4 — iCloud по mdls (4b — путь под Mobile
# Documents); 5 — телефон заперт (5b — заперли посреди копирования); 6 — erase после 2 (6b — devicectl ответил 0 и не
# стёр); 7 — повторный pull (7b — сессия выросла после выгрузки). 7 и 7b идут за 1, 6 — за 2: им нужно их состояние.
set -uo pipefail
TOOL="${BLACKBOX_TOOL:-}"  # черновик вне клона — путь к команде; иначе scripts/blackbox.py репозитория
if [ -z "$TOOL" ]; then ROOT="$(git rev-parse --show-toplevel)" || exit 1; TOOL="$ROOT/scripts/blackbox.py"; fi
PY=python3
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
rc=0 cases=0 name="" out="" code=0
BOX="Library/Application Support/BlackBox"
UDID=00008150-SMOKE00000000000
DAY=2026-10-25
S1=2026-10-25T09-00-00Z-AAAA1111
S2=2026-10-25T10-30-00Z-BBBB2222
PHONE="$tmp/phone container"
R="$tmp/repo with space"
mkdir -p "$tmp/bin"
export FAKE_PHONE="$PHONE" FAKE_UDID="$UDID" FAKE_LOG="$tmp/devicectl.log" PATH="$tmp/bin:$PATH"
unset BLACKBOX_XCRUN FAKE_LOCKED FAKE_MDLS FAKE_LISTING FAKE_KEEP

cat > "$tmp/bin/xcrun" <<'PY'
#!/usr/bin/env python3
"""Фальшивый xcrun смоука: devicectl над каталогом-контейнером $FAKE_PHONE."""
import json, os, shutil, sys
from pathlib import Path

args = sys.argv[1:]
verb = " ".join(args[2:4])
with open(os.environ["FAKE_LOG"], "a", encoding="utf-8") as log:
    log.write(verb + "\n")


def opt(flag):
    return args[args.index(flag) + 1] if flag in args else None


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


if args[:2] != ["devicectl", "device"] or opt("--device") != os.environ["FAKE_UDID"]:
    fail(f"ERROR: device {opt('--device')} not found")
if verb == "info details":
    sys.exit(print("deviceProperties: smoke") or 0)
locked = os.environ.get("FAKE_LOCKED", "")
if locked == "all" or (locked == "copy" and verb.startswith("copy")):
    fail("ERROR: The device is locked. (com.apple.dt.CoreDeviceError error 4.)")
if (opt("--domain-type"), opt("--domain-identifier")) != ("appDataContainer", "com.anthonypriceone.ally"):
    fail("ERROR: unknown domain")
phone = Path(os.environ["FAKE_PHONE"])
if verb == "info files":
    sub = phone / opt("--subdirectory")
    if not sub.is_dir():
        fail("ERROR: The file doesn't exist.")
    flat = os.environ.get("FAKE_LISTING") == "flat"  # только прямые дети, имена без каталога
    paths = sorted(sub.iterdir() if flat else sub.rglob("*"))
    files = [{"name": p.name if flat else p.relative_to(sub).as_posix(), "metadata": {"size": p.stat().st_size}}
             for p in paths]
    Path(opt("--json-output")).write_text(json.dumps({"info": {"outcome": "success"}, "result": {"files": files}}))
elif verb == "copy from":
    shutil.copyfile(phone / opt("--source"), opt("--destination"))
elif verb == "copy to" and opt("--remove-existing-content") == "true":
    target = phone / opt("--destination")
    if not os.environ.get("FAKE_KEEP"):  # FAKE_KEEP — devicectl, который ответил 0 и не стёр
        shutil.rmtree(target)
    shutil.copytree(opt("--source"), target, dirs_exist_ok=True)
else:
    fail(f"ERROR: фальшивый devicectl не знает: {' '.join(args)}")
PY
printf '#!/bin/sh\nif [ "${FAKE_MDLS:-}" = 1 ]; then printf 1; else printf "(null)"; fi\n' > "$tmp/bin/mdls"
chmod +x "$tmp/bin/xcrun" "$tmp/bin/mdls"
[ "$(command -v xcrun)" = "$tmp/bin/xcrun" ] || { echo "FAIL: фальшивый xcrun не первый на PATH — стоп"; exit 1; }

gen() {  # $1 — каталог сессии, $2 — число ходов: её WAV, кроме каждого 3-го хода; m4a Элли — на нечётных
  "$PY" - "$1" "$2" <<'PY'
import json, struct, sys
from pathlib import Path


def fnv1a(data):
    value = 0xCBF29CE484222325
    for byte in data:
        value = ((value ^ byte) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return f"fnv1a:{value:016x}"


assert fnv1a(b"") == "fnv1a:cbf29ce484222325" and fnv1a(b"a") == "fnv1a:af63dc4c8601ec8c"


def wav(samples):
    pcm = struct.pack(f"<{len(samples)}h", *samples)
    fmt = struct.pack("<IHHIIHH", 16, 1, 1, 16000, 32000, 2, 16)  # PCM16 моно 16 кГц: 44 байта заголовка
    return b"RIFF" + struct.pack("<I", 36 + len(pcm)) + b"WAVEfmt " + fmt + b"data" + struct.pack("<I", len(pcm)) + pcm


def sound(path, data, kind):
    path.write_bytes(data)
    return {"file": path.name, "bytes": len(data), "fnv1a": fnv1a(data), "format": kind}


folder = Path(sys.argv[1])
folder.mkdir(parents=True, exist_ok=True)
for turn in range(1, int(sys.argv[2]) + 1):
    n = f"{turn:04d}"
    child = sound(folder / f"{n}-child.wav", wav([turn * 100 + i for i in range(16)]), "wav-pcm16-mono") \
        if turn % 3 else {"missing": "silence"}
    elly = sound(folder / f"{n}-elly.m4a", b"\x00\x00\x00\x18ftypM4A " + bytes(range(turn, turn + 40)), "aac-lc") \
        if turn % 2 else {"missing": "not_recorded"}
    record = {"session": folder.name, "turn": turn, "heard": "раз два", "said": "проба",
              "child_audio": child, "elly_audio": elly}
    text = "ALLY-BLACKBOX/1\n" + json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n"
    (folder / f"{n}.allybox").write_text(text, encoding="utf-8")
PY
}
phone() { rm -rf "$PHONE" && gen "$PHONE/$BOX/$S1" 3 && gen "$PHONE/$BOX/$S2" 2; }
repo() { rm -rf "$1" && mkdir -p "$1" && git -C "$1" init -q && printf 'local/\n' > "$1/.gitignore"; }
corrupt() {  # $1 — файл: байт посреди отсчётов другой, размер тот же
  "$PY" -c 'import sys, pathlib; f = pathlib.Path(sys.argv[1]); d = bytearray(f.read_bytes()); d[50] ^= 255
f.write_bytes(d)' "$1"
}
run() {  # $1 — репозиторий, дальше — аргументы blackbox.py; печать — в $out, код — в $code
  local dir="$1"; shift
  : > "$FAKE_LOG"
  out="$(cd "$dir" && "$PY" "$TOOL" "$@" --device "$UDID" 2>&1)"; code=$?
}
step() { name="$1"; cases=$((cases + 1)); }
fail() { echo "FAIL ($name): $1"; printf '%s\n' "$out" | sed 's/^/    | /'; rc=1; }
expect() {  # $1 — код выхода, дальше — строки, которые команда обязана напечатать
  local want="$1" line; shift
  [ "$code" = "$want" ] || fail "код $code, ждали $want"
  for line in "$@"; do grep -qF -- "$line" <<<"$out" || fail "нет «${line}»"; done
}
none() { [ ! -e "$1" ] || fail "есть ${1#"$tmp"/} — ждали, что на диске ничего"; }
untouched() { [ ! -s "$FAKE_LOG" ] || fail "до отказа звали devicectl: $(tr '\n' ',' < "$FAKE_LOG")"; }
same() {  # $1 — сессия, $2 — каталог на Mac: каждый файл телефона там байт в байт
  local f
  for f in "$PHONE/$BOX/$1"/*; do cmp -s "$f" "$2/${f##*/}" || fail "${f##*/} сессии $1 на Mac не тот"; done
}

step "1: две сверяемые сессии"
repo "$R" && phone
run "$R" pull --date "$DAY"
expect 0 "выгружено: 2 сессий" "сверено 2 из 2"
same "$S1" "$R/local/blackbox/$DAY/$S1" && same "$S2" "$R/local/blackbox/$DAY/$S2"
none "$R/local/blackbox/$DAY/.staging"

step "7: повторный pull"
run "$R" pull --date 2026-10-26
expect 0 "выгружено: 0 сессий" "сессий уже на Mac: 2"
! grep -q "copy from" "$FAKE_LOG" || fail "уже выгруженное скопировано заново"
none "$R/local/blackbox/2026-10-26"

step "7b: сессия выросла после выгрузки — докопирована в тот же каталог"
gen "$PHONE/$BOX/$S1" 4
run "$R" pull --date "$DAY"
expect 0 "выгружено: 1 сессий" "сверено 1 из 1" "сессий уже на Mac: 1"
same "$S1" "$R/local/blackbox/$DAY/$S1"

step "1b: имена в листинге без каталога сессии — листинг каждой сессии"
repo "$R" && phone
FAKE_LISTING=flat run "$R" pull --date "$DAY"
expect 0 "выгружено: 2 сессий" "сверено 2 из 2"
same "$S1" "$R/local/blackbox/$DAY/$S1" && same "$S2" "$R/local/blackbox/$DAY/$S2"
[ "$(grep -c 'info files' "$FAKE_LOG")" = 3 ] || fail "ждали 3 листинга: ящик и две сессии"

step "2b: чужой заголовок записи, звук другого размера"
repo "$R" && phone
printf 'ALLY-BLACKBOX/2\n{}\n' > "$PHONE/$BOX/$S1/0002.allybox" && printf 'x' >> "$PHONE/$BOX/$S2/0002-child.wav"
run "$R" pull --date "$DAY"
expect 1 "не сверена: $S1 — 0002.allybox: первая строка не ALLY-BLACKBOX/1" "сверено 0 из 2" \
  "не сверена: $S2 — 0002.allybox, child_audio: 0002-child.wav: 77 байт, в записи 76"
none "$R/local"

step "2: испорчен байт WAV"
repo "$R" && phone && corrupt "$PHONE/$BOX/$S2/0001-child.wav"
run "$R" pull --date "$DAY"
expect 1 "не сверена: $S2" "0001-child.wav: FNV-1a не сходится" "выгружено: 2 сессий" "сверено 1 из 2"
same "$S1" "$R/local/blackbox/$DAY/$S1"
none "$R/local/blackbox/$DAY/$S2"
none "$R/local/blackbox/$DAY/.staging"

step "6: erase после порчи — стёрта только сверенная"
run "$R" erase --date "$DAY"
expect 1 "стёрто: 1 сессий" "оставлено: $S2 — 0001.allybox, child_audio: 0001-child.wav: FNV-1a не сходится"
[ -z "$(ls -A "$PHONE/$BOX/$S1")" ] || fail "сверенная $S1 на телефоне не стёрта"
[ -f "$PHONE/$BOX/$S2/0001-child.wav" ] && [ -f "$PHONE/$BOX/$S2/0002.allybox" ] || fail "несверенная $S2 тронута"
[ -f "$R/local/blackbox/$DAY/$S1/0003.allybox" ] || fail "копия $S1 на Mac пропала"

step "6b: devicectl ответил 0 и не стёр — не «стёрто»"
repo "$R" && phone
FAKE_KEEP=1 run "$R" erase --date "$DAY"
expect 1 "стёрто: 0 сессий" "оставлено: $S1 — файлы остались после стирания" "оставлено: $S2 — файлы остались"

step "3: .gitignore без local/ — отказ до копирования"
repo "$R" && phone && printf '*.allybox\n*.wav\n*.m4a\n' > "$R/.gitignore"
run "$R" pull --date "$DAY"
expect 1 "путь local/blackbox/$DAY не игнорируется git — выгрузка отменена"
none "$R/local" && untouched

step "4: mdls печатает 1 — отказ из-за iCloud"
repo "$R" && phone
FAKE_MDLS=1 run "$R" pull --date "$DAY"
expect 1 "каталог local/blackbox/$DAY синхронизируется с iCloud — выгрузка отменена"
none "$R/local" && untouched

step "4b: репозиторий под Library/Mobile Documents — отказ из-за iCloud"
M="$tmp/Library/Mobile Documents/com~apple~CloudDocs/ally"
repo "$M"
run "$M" pull --date "$DAY"
expect 1 "синхронизируется с iCloud — выгрузка отменена"
none "$M/local" && untouched

step "5: телефон заперт — на диске ничего"
repo "$R" && phone
FAKE_LOCKED=all run "$R" pull --date "$DAY"
expect 1 "разблокируй телефон"
none "$R/local"

step "5b: заперли посреди копирования — .staging убран, на диске ничего"
FAKE_LOCKED=copy run "$R" pull --date "$DAY"
expect 1 "разблокируй телефон"
grep -q "copy from" "$FAKE_LOG" || fail "копирование не начиналось — случай не тот"
none "$R/local"

if [ "$rc" -eq 0 ]; then
  echo "blackbox-pull: $cases случаев из $cases — выгрузка, сверка, сторожа git и iCloud, замок, стирание (B15, B16)"
else
  echo "blackbox-pull: есть провалы"
fi
exit "$rc"
