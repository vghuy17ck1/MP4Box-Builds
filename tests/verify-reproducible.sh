#!/usr/bin/env bash
set -euo pipefail

target="${1:-linux64}"
variant="${2:-minimal}"
channel="${3:-release}"
first_dir="$(mktemp -d)"
second_dir="$(mktemp -d)"
trap 'rm -rf "$first_dir" "$second_dir"' EXIT
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}" OUTPUT_DIR="$first_dir" ./build.sh "$target" "$variant" "$channel" >"$first_dir/build.log"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}" OUTPUT_DIR="$second_dir" ./build.sh "$target" "$variant" "$channel" >"$second_dir/build.log"
first_archive="$(find "$first_dir" -maxdepth 1 -type f \( -name '*.tar.xz' -o -name '*.zip' \) | head -n 1)"
second_archive="$(find "$second_dir" -maxdepth 1 -type f \( -name '*.tar.xz' -o -name '*.zip' \) | head -n 1)"
[[ -n "$first_archive" && -n "$second_archive" ]] || { printf 'reproducibility archives missing\n' >&2; exit 1; }
first_hash="$(sha256sum "$first_archive" | awk '{print $1}')"
second_hash="$(sha256sum "$second_archive" | awk '{print $1}')"
[[ "$first_hash" == "$second_hash" ]] || { printf 'archive hashes differ: %s %s\n' "$first_hash" "$second_hash" >&2; exit 1; }
printf 'reproducibility test passed: %s\n' "$first_hash"
