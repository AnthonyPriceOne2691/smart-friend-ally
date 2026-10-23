#!/usr/bin/env bash
# B11 (поставка black-box, S6 в smoke): гейт данных ребёнка краснеет на записи чёрного ящика под git под любым именем
# и через `add -f`. Проба исполнением во временном репозитории с гейтом и .gitignore проекта — канарейка доктора одна
# на скрипт и стоит на WAV (урок L4). Случаи: переименованная запись ящика (первая строка ALLY-BLACKBOX/1) в дереве и в
# индексе — data-magic; файл из local/blackbox через add -f — local-dir; переименованный WAV — data-magic; .allybox
# через add -f — data-ext; заголовок посреди текста — не находка.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)" || exit 1
PY=python3
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
rc=0
record='ALLY-BLACKBOX/1
{"heard":"Я живу на улице Морковной","session":"probe","turn":2}'

repo() {  # чистый репозиторий: гейт и .gitignore проекта, больше ничего
  rm -rf "$tmp/r" && mkdir -p "$tmp/r/scripts/lint" "$tmp/r/notes"
  cp "$ROOT/scripts/lint/check_child_data.py" "$tmp/r/scripts/lint/" && cp "$ROOT/.gitignore" "$tmp/r/"
  git -C "$tmp/r" init -q
}
gate() { (cd "$tmp/r" && "$PY" scripts/lint/check_child_data.py 2>&1); }
expect_red() {  # $1 — строка, которую обязан напечатать красный гейт
  local out
  if out="$(gate)"; then echo "FAIL: гейт зелёный, ждали «$1»"; rc=1; return; fi
  grep -qF -- "$1" <<<"$out" || { echo "FAIL: нет «$1» в выводе:"; echo "$out"; rc=1; }
}

repo && printf '%s\n' "$record" > "$tmp/r/notes/case.json"
expect_red "notes/case.json: data-magic — содержимое чёрный ящик Ally, в дереве, не игнорируется"
git -C "$tmp/r" add notes/case.json
expect_red "notes/case.json: data-magic — содержимое чёрный ящик Ally, в индексе"

repo && mkdir -p "$tmp/r/local/blackbox/2026-10-25/s" && printf '%s\n' "$record" > "$tmp/r/local/blackbox/2026-10-25/s/0002.allybox"
git -C "$tmp/r" add -f local/blackbox/2026-10-25/s/0002.allybox
expect_red "local/blackbox/2026-10-25/s/0002.allybox: local-dir"

repo && printf 'RIFF\x24\x00\x00\x00WAVEfmt ' > "$tmp/r/clip.bin"  # заголовок 0002-child.wav под чужим именем
git -C "$tmp/r" add clip.bin
expect_red "clip.bin: data-magic — содержимое WAV"

repo && mkdir -p "$tmp/r/x" && printf '{"turn":3}\n' > "$tmp/r/x/0003.allybox"
git -C "$tmp/r" add -f x/0003.allybox
expect_red "x/0003.allybox: data-ext"

repo && printf 'Файл записи начинается строкой ALLY-BLACKBOX/1.\n' > "$tmp/r/notes/readme.md"
git -C "$tmp/r" add notes/readme.md
gate >/dev/null || { echo "FAIL: заголовок посреди текста — ложная находка"; rc=1; }

[ "$rc" -eq 0 ] && echo "child-data: чёрный ящик пойман в 5 случаях из 5, ложных находок 0 (B11)"
exit "$rc"
