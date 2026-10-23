#!/usr/bin/env bash
# One ONNX Runtime in the app (voice series V1, example Z1; decision of the lead 2026-10-23).
#
# The voice (Supertonic, RUAccent) and the hearing (Silero VAD and GigaAM through sherpa-onnx) share Packages/AllyOnnx —
# Microsoft's official onnxruntime-c pod as the only `binaryTarget` with ONNX Runtime. A second runtime in the same binary
# means duplicate symbols or two runtimes of different API versions. Refused anywhere in the manifests:
#   - a `binaryTarget` mentioning onnxruntime outside Packages/AllyOnnx, or a second one inside it;
#   - packages that bring their own runtime: microsoft/onnxruntime-swift-package-manager, csukuangfj/onnxruntime-libs,
#     and k2-fsa/sherpa-onnx as a package (its Package.swift pins onnxruntime-libs).
# Allowed: sherpa-onnx's static xcframework as a `binaryTarget` — no runtime inside, it links AllyOnnx's.
#
# Usage: bash scripts/lint/check_single_ort.sh [root]   (root — a repository tree, default: this one)
set -euo pipefail

root="${1:-$(git rev-parse --show-toplevel)}"
cd "$root"
home=./Packages/AllyOnnx/Package.swift
errors=0
fail() { echo "check_single_ort: $1" >&2; errors=$((errors + 1)); }

find_manifests() {
  find . \( -path ./local -o -name .build \) -prune -o \( "$@" \) -type f -print | sort
}

# binaryTarget blocks (from `.binaryTarget(` to the line that closes it) that mention onnxruntime, per file
ort_targets() {
  awk 'BEGIN { IGNORECASE = 1 }
       /\.binaryTarget\(/ { inside = 1; block = "" }
       inside { block = block $0 "\n"; if ($0 ~ /\)[[:space:]]*,?[[:space:]]*(\/\/.*)?$/) { inside = 0
                if (tolower(block) ~ /onnxruntime/) count++ } }
       END { print count + 0 }' "$1"
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  for package in onnxruntime-swift-package-manager onnxruntime-libs; do
    if grep -qi "$package" "$file"; then fail "$file: $package brings its own ONNX Runtime"; fi
  done
  case "$file" in
    */Package.swift)
      # the .package( call itself, across lines; sherpa's static xcframework as a binaryTarget (releases URL, with or
      # without a platform condition, as k2-fsa's own Package.swift 1.13.8 has it) is not a .package( and passes
      if tr '\n' ' ' < "$file" | grep -Eqi '\.package[[:space:]]*\([^)]*sherpa-onnx'; then
        fail "$file: k2-fsa/sherpa-onnx as a package pins onnxruntime-libs — use its static xcframework as a binaryTarget"
      fi
      count=$(ort_targets "$file")
      if [ "$file" = "$home" ]; then
        [ "$count" -eq 1 ] || fail "$file: $count binaryTargets with ONNX Runtime — exactly one is the app's runtime"
      elif [ "$count" -gt 0 ]; then
        fail "$file: a binaryTarget with ONNX Runtime outside Packages/AllyOnnx"
      fi ;;
    *)
      if grep -qi 'sherpa-onnx' "$file"; then fail "$file: k2-fsa/sherpa-onnx as a package pins onnxruntime-libs"; fi ;;
  esac
done < <(find_manifests -name Package.swift -o -name Package.resolved -o -path ./App/project.yml)

[ -f "$home" ] || fail "$home: missing — the app's ONNX Runtime lives there"

if [ "$errors" -gt 0 ]; then
  echo "check_single_ort: $errors problem(s); one ONNX Runtime in the app — Packages/AllyOnnx" >&2
  exit 1
fi
echo "check_single_ort: one ONNX Runtime — $(grep -o 'pod-archive-onnxruntime-c-[0-9.]*[0-9]' "$home" | head -1)"
