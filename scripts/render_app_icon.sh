#!/usr/bin/env bash
# Значок приложения из кода (поставка app-icon, I5, I7): рендер IconScene тестом пакета AllyShell на Mac, сжатие без
# потерь pngcrush из Xcode, копии в каталоги приложения (день и ночная пара) и демо (с пометкой «демо»), затем сверка
# каталогов с кодом (I3). Звать после правки рисунка Элли, палитры или IconScene — иначе I3 краснеет:
#
#   bash scripts/render_app_icon.sh
#
# Только Mac: рисует ImageRenderer SwiftUI, сжимает xcrun pngcrush. Тест кладёт рендер в local/shell-snapshots/icon/
# (вне git): там же снятие дизеринга — без него PNG весит ≈ 1 МБ, а гейт check-added-large-files пускает 512 КиБ.
# Корень — по месту скрипта, не git (L155).

set -euo pipefail

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"  # активный dir — CLT
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PACKAGE="$ROOT/Packages/AllyShell"
RENDERS="$ROOT/local/shell-snapshots/icon"
APP="$ROOT/App/Resources/Assets.xcassets/AppIcon.appiconset"
DEMO="$ROOT/App/Demo/Assets.xcassets/AppIcon.appiconset"
LIMIT=$((512 * 1024))  # I5: check-added-large-files --maxkb=512
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

die() { printf 'render_app_icon: %s\n' "$*" >&2; exit 1; }

[[ "$(uname)" == Darwin ]] || die "только Mac: значок рисует ImageRenderer SwiftUI"
CRUSH=$(xcrun -find pngcrush 2>/dev/null) || die "нет pngcrush из Xcode (DEVELOPER_DIR=$DEVELOPER_DIR)"
[[ -d "$APP" && -d "$DEMO" ]] || die "нет каталога значка: $APP или $DEMO"

# 1. Рендер (I1): тест пишет AppIcon.png, AppIcon-night.png, AppIcon-demo.png.
rm -f "$RENDERS"/AppIcon*.png "$RENDERS"/AppIcon*.crushed
if ! nice -n 10 swift test --disable-keychain --package-path "$PACKAGE" \
    --filter 'IconTests/testTheIconsRenderOpaqueAt1024' >"$LOG" 2>&1; then
  tail -20 "$LOG" >&2
  die "рендер не прошёл (swift test --package-path Packages/AllyShell --filter IconTests)"
fi

# 2. Сжатие без потерь и предел размера (I5) — все три до копирования: неудача оставляет каталоги как были.
pairs=("AppIcon.png:$APP/AppIcon.png" "AppIcon-night.png:$APP/AppIcon-night.png" "AppIcon-demo.png:$DEMO/AppIcon.png")
for pair in "${pairs[@]}"; do
  rendered="$RENDERS/${pair%%:*}"
  [[ -f "$rendered" ]] || die "тест не оставил $rendered"
  "$CRUSH" -q -l 9 "$rendered" "${rendered%.png}.crushed" >/dev/null || die "pngcrush не сжал $rendered"
  size=$(stat -f %z "${rendered%.png}.crushed")
  (( size <= LIMIT )) || die "${pair%%:*} — $size байт, больше предела гейта $LIMIT: каталоги не тронуты"
done
# 3. Копии в каталоги (I7).
for pair in "${pairs[@]}"; do
  rendered="$RENDERS/${pair%%:*}" stored="${pair#*:}"
  cp "${rendered%.png}.crushed" "$stored"
  printf '%s — %d КиБ\n' "${stored#"$ROOT"/}" $(( ($(stat -f %z "$stored") + 1023) / 1024 ))
done

# 4. Каталоги против свежего рендера (I3).
if ! nice -n 10 swift test --disable-keychain --package-path "$PACKAGE" \
    --filter 'IconTests/testTheCatalogsMatchTheCode' >"$LOG" 2>&1; then
  tail -20 "$LOG" >&2
  die "каталоги не совпали с кодом (I3)"
fi
printf 'render_app_icon: OK — значок пересобран из кода, каталоги совпадают с ним\n'
