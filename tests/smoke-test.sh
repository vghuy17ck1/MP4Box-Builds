#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
target="${2:-${TARGET:-linux64}}"
suffix=""
[[ "$target" == win64 || "$target" == winarm64 ]] && suffix=.exe
mp4box="$artifact_dir/bin/MP4Box$suffix"
gpac="$artifact_dir/bin/gpac$suffix"
if [[ "$target" != linux64 ]]; then
    printf 'runtime smoke test not executed for non-native target %s\n' "$target"
    exit 0
fi
"$mp4box" -version
"$mp4box" -h
"$mp4box" -h dash
"$gpac" -version
"$gpac" -h filters
"$gpac" -h ffdmx
"$gpac" -h 'ffdmx:*'
"$gpac" -h ffdec
"$gpac" -h ffbsf
printf 'runtime smoke test passed\n'
