#!/usr/bin/env bash
# Исключение «при родителе» (поставка child-lock, R): дочь пробует приложение только при родителе, и детский режим
# открывает его подписанное исключение со сроком не больше 7 дней (решение родителя 2026-10-22).
#
#   bash scripts/child_mode.sh <UDID> --until 2026-10-29T21:00:00+03:00     собрать, показать, подписать, положить
#   bash scripts/child_mode.sh <UDID> --until … --dry                        только показать текст окна
#
# Исключение — одна строка JSON: срок (`from` — сейчас, `until` — из аргумента) и поверхность той сборки, что стоит
# на телефоне (хэши данных контракта и маршрутизатора — FNV-1a 64, как в Discipline; sha256 персоны; вес «файл:байты»
# из реестра). Телефон проверяет подпись ключом родителя из .github/allowed_signers и сверяет поверхность со своей.
#
# Подписывает ТОЛЬКО родитель: окно несёт исключение целиком, кнопка по умолчанию «Не подписывать» — Enter подписи не
# ставит; ключ в анклаве Secretive требует касания. Агент этот скрипт без --dry не запускает (канон §3.4a, правило
# delivery@1.93: окно без содержимого запрещено). Каждый шаг судится кодом возврата (L10).
set -uo pipefail

UDID="${1:-}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIGNERS="$REPO/.github/allowed_signers"
BUNDLE="com.anthonypriceone.ally"
NS="ally-child-mode"
DEST="Library/Application Support/Ally"
# Путь к сокету агента берётся у приложения ключа и подставляется переменной: искать его `find`'ом по
# ~/Library/Containers нельзя — macOS отвечает «Operation not permitted» и находит ноль (§3.4a②).
AGENT_SOCKET="${CHILD_MODE_AGENT_SOCKET:-$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() { printf 'child-mode: %s\n' "$*" >&2; exit 1; }

shift || true
UNTIL="" DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --until) UNTIL="${2:-}"; shift 2 ;;
    --dry) DRY=1; shift ;;
    *) fail "не понимаю аргумент: $1" ;;
  esac
done
[ -n "$UDID" ] && [ -n "$UNTIL" ] || fail "нужно: bash scripts/child_mode.sh <UDID> --until <дата ISO 8601 со смещением> [--dry]"

# Исключение одной строкой: срок проверяется до окна — дальше 7 дней или в прошлом окна не будет.
python3 - "$REPO" "$UNTIL" >"$WORK/child-mode.json" <<'PY' || exit 1
import datetime, hashlib, json, pathlib, sys
repo, until_text = pathlib.Path(sys.argv[1]), sys.argv[2]
try:
    until = datetime.datetime.fromisoformat(until_text)
except ValueError:
    sys.exit(f"child-mode: срок не читается: {until_text} (нужно 2026-10-29T21:00:00+03:00)")
if until.tzinfo is None:
    sys.exit("child-mode: у срока нет смещения часового пояса (+03:00)")
now = datetime.datetime.now(until.tzinfo).replace(microsecond=0)
if until <= now:
    sys.exit(f"child-mode: срок {until_text} уже прошёл — окна не будет")
if until - now > datetime.timedelta(days=7):
    sys.exit(f"child-mode: срок {until_text} дальше 7 дней — окна не будет (решение родителя: не больше 7 дней)")
def fnv1a(path):
    value = 0xcbf29ce484222325
    for byte in path.read_bytes():
        value = ((value ^ byte) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
    return f"fnv1a:{value:016x}"
data = repo / "Packages/AllyDiscipline/Sources/Discipline/Resources"
registry = json.loads((repo / "App/Resources/model.json").read_text(encoding="utf-8"))
persona = hashlib.sha256((repo / "App/Resources" / registry["persona"]).read_bytes()).hexdigest()
surface = {"contract": fnv1a(data / "contract.json"), "router": fnv1a(data / "router.json"),
           "persona": f"sha256:{persona}", "model": f'{registry["model"]["file"]}:{registry["model"]["bytes"]}'}
exception = {"from": now.isoformat(), "until": until.isoformat(), "surface": surface,
             "note": "детский режим только при родителе"}
sys.stdout.write(json.dumps(exception, ensure_ascii=False, sort_keys=True, separators=(",", ":")))
PY

TEXT="Исключение «при родителе» (детский режим Ally).
Подписываешь ровно это:
$(python3 -m json.tool --no-ensure-ascii "$WORK/child-mode.json")

Дочь говорит с Элли только при тебе, до срока выше и только на этой сборке.
Дальше касание. Окно может вызвать агент, коснуться сенсора — нет."

if [ "$DRY" = 1 ]; then
  printf '%s\n' "── окно показало бы ──" "$TEXT" "── конец окна ──"
  exit 0
fi

line=$(grep -v '^[[:space:]]*#' "$SIGNERS" 2>/dev/null | grep -m1 'ecdsa-sha2-nistp256') \
  || fail "в $SIGNERS нет ключа родителя (шаг владельца: открытая строка ключа Secretive)"
WHO=$(printf '%s' "$line" | awk '{print $1}')
printf '%s\n' "$line" | grep -o 'ecdsa-sha2-nistp256 [A-Za-z0-9+/=]*' >"$WORK/parent.pub" || fail "ключ в $SIGNERS не читается"

command -v osascript >/dev/null 2>&1 || fail "окно показать нечем (нет osascript): подпись ставит родитель на своём Mac"
answer=$(osascript - "$TEXT" <<'APPLESCRIPT' 2>/dev/null
on run argv
  display dialog (item 1 of argv) with title "Детский режим при родителе" ¬
    buttons {"Не подписывать", "Подписать"} default button "Не подписывать" with icon caution
  return button returned of result
end run
APPLESCRIPT
)
[ "$answer" = "Подписать" ] || { printf 'child-mode: не подписано — ничего не скопировано\n'; exit 0; }

# 2>/dev/null, а не 2>&1: служебная строка ssh-keygen в файле подписи делает её непарсимой (§3.4a③).
SSH_AUTH_SOCK="$AGENT_SOCKET" ssh-keygen -Y sign -f "$WORK/parent.pub" -n "$NS" "$WORK/child-mode.json" 2>/dev/null \
  || fail "подпись не поставлена (Secretive: касание, сокет $AGENT_SOCKET)"
ssh-keygen -Y verify -f "$SIGNERS" -I "$WHO" -n "$NS" -s "$WORK/child-mode.json.sig" <"$WORK/child-mode.json" \
  >/dev/null 2>&1 || fail "подпись не сходится с ключом в $SIGNERS — ничего не скопировано"

for name in child-mode.json child-mode.json.sig; do
  xcrun devicectl device copy to --device "$UDID" --domain-type appDataContainer --domain-identifier "$BUNDLE" \
    --source "$WORK/$name" --destination "$DEST/$name" >/dev/null 2>&1 || fail "на телефон $UDID не скопировано: $name"
done
printf 'child-mode: OK — исключение до %s на телефоне; приложение проверит его при запуске и при «Дочке, при мне»\n' "$UNTIL"
