#!/usr/bin/env bash
# M25 (поставка memory-core, S7 в smoke): гейт данных ребёнка краснеет на спутниках базы памяти под git под любым
# именем — WAL с записью (её слова до чекпойнта), SHM, журнал отката; без `add -f` спутники игнорируются. Проба
# исполнением во временном репозитории с гейтом и .gitignore проекта: второе правило судит смоук (урок L57). Гейт —
# переменная CHILD_DATA_GATE (по умолчанию гейт проекта); отрицательный контроль — гейт main до поставки: на тех же
# файлах он зелёный, и смоук краснеет.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)" || exit 1
GATE="${CHILD_DATA_GATE:-$ROOT/scripts/lint/check_child_data.py}"
PY=python3
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
rc=0

repo() {  # чистый репозиторий: гейт и .gitignore проекта, больше ничего
  rm -rf "$tmp/r" && mkdir -p "$tmp/r/scripts/lint" "$tmp/r/notes" "$tmp/r/x"
  cp "$GATE" "$tmp/r/scripts/lint/check_child_data.py" && cp "$ROOT/.gitignore" "$tmp/r/"
  git -C "$tmp/r" init -q
}
gate() { (cd "$tmp/r" && "$PY" scripts/lint/check_child_data.py 2>&1); }
expect_red() {  # $1 — строка, которую обязан напечатать красный гейт
  local out
  if out="$(gate)"; then echo "FAIL: гейт зелёный, ждали «$1»"; rc=1; return; fi
  grep -qF -- "$1" <<<"$out" || { echo "FAIL: нет «$1» в выводе:"; echo "$out"; rc=1; }
}

# Настоящий WAL базы с вымышленной записью: соединение открыто, чекпойнта нет — копии WAL и SHM снимаются до закрытия.
"$PY" - "$tmp/w" <<'PY' || { echo "FAIL: WAL не собрался"; exit 1; }
import os, shutil, sqlite3, sys
os.makedirs(sys.argv[1])
base = os.path.join(sys.argv[1], "memory.sqlite")
con = sqlite3.connect(base)
con.execute("PRAGMA journal_mode = WAL")
con.execute("PRAGMA wal_autocheckpoint = 0")
con.execute("CREATE TABLE fact (value TEXT)")
con.execute("INSERT INTO fact VALUES ('кошка Мурка рыжая')")
con.commit()
for suffix in ("-wal", "-shm"):
    shutil.copy(base + suffix, os.path.join(sys.argv[1], "copy" + suffix))
con.close()
assert "Мурка".encode() in open(os.path.join(sys.argv[1], "copy-wal"), "rb").read()
PY

repo
cp "$tmp/w/copy-wal" "$tmp/r/notes/memory.sqlite-wal" && cp "$tmp/w/copy-wal" "$tmp/r/notes/clip.bin"
cp "$tmp/w/copy-shm" "$tmp/r/notes/memory.sqlite-shm"
printf '\xd9\xd5\x05\xf9\x20\xa1\x63\xd7' > "$tmp/r/x/old.db-journal"
for sidecar in notes/memory.sqlite-wal notes/memory.sqlite-shm x/old.db-journal; do
  git -C "$tmp/r" check-ignore -q "$sidecar" || { echo "FAIL: $sidecar не игнорируется"; rc=1; }
done
git -C "$tmp/r" add -f notes/memory.sqlite-wal notes/memory.sqlite-shm x/old.db-journal && git -C "$tmp/r" add notes/clip.bin
expect_red "notes/memory.sqlite-wal: data-ext"
expect_red "notes/clip.bin: data-magic — содержимое SQLite WAL, в индексе"
expect_red "notes/memory.sqlite-shm: data-ext"
expect_red "x/old.db-journal: data-ext"

repo && printf 'Свежие записи лежат в memory.sqlite-wal до чекпойнта.\n' > "$tmp/r/notes/readme.md"
git -C "$tmp/r" add notes/readme.md
gate >/dev/null || { echo "FAIL: имя спутника посреди текста — ложная находка"; rc=1; }

[ "$rc" -eq 0 ] && echo "child-data: спутники базы пойманы в 4 случаях из 4, игнор на месте, ложных находок 0 (M25)"
exit "$rc"
