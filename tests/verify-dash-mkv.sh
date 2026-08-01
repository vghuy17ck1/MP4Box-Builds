#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
target="${2:-${TARGET:-linux64}}"
if [[ "$target" != linux64 ]]; then
    printf 'MKV-to-DASH runtime test not executed for non-native target %s\n' "$target"
    exit 0
fi
fixture="${MP4BOX_MKV_FIXTURE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/fixtures" && pwd)/sample.mkv}"
[[ -f "$fixture" ]] || { printf 'missing MKV fixture: %s\n' "$fixture" >&2; exit 1; }
gpac="$artifact_dir/bin/gpac"
output_dir="$(mktemp -d)"
trap 'rm -rf "$output_dir"' EXIT
"$gpac" -p=0 -i "$fixture" -o "$output_dir/manifest.mpd:segdur=2"
[[ -s "$output_dir/manifest.mpd" ]] || { printf 'DASH manifest was not created\n' >&2; exit 1; }
find "$output_dir" -type f -name '*.m4s' -o -name '*.mp4' | grep -q . || { printf 'DASH segments were not created\n' >&2; exit 1; }
grep -Eiq 'matroska|webm' <("$gpac" -p=0 -hx 'ffdmx:*' 2>&1) || { printf 'final gpac does not report FFmpeg Matroska/WebM demuxers\n' >&2; exit 1; }
printf 'MKV-to-DASH test passed\n'
