#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
target="${2:-${TARGET:-linux64}}"
if [[ "$target" != linux64 ]]; then
    printf 'transcoding runtime test not executed for non-native target %s\n' "$target"
    exit 0
fi
fixture="${MP4BOX_MKV_FIXTURE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)/sample.mkv}"
[[ -f "$fixture" ]] || { printf 'missing MKV fixture: %s\n' "$fixture" >&2; exit 1; }
gpac="$artifact_dir/bin/gpac"
output_dir="$(mktemp -d)"
trap 'rm -rf "$output_dir"' EXIT
"$gpac" -i "$fixture" -o "$output_dir/transcoded.mp4:encoder=mpeg4"
[[ -s "$output_dir/transcoded.mp4" ]] || { printf 'transcoding output was not created\n' >&2; exit 1; }
printf 'full transcoding test passed\n'
