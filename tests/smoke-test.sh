#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
target="${2:-${TARGET:-linux64}}"
suffix=""
[[ "$target" == win64 || "$target" == winarm64 ]] && suffix=.exe
mp4box="$artifact_dir/bin/MP4Box$suffix"
gpac="$artifact_dir/bin/gpac$suffix"
if [[ -d "$artifact_dir/lib" ]]; then export LD_LIBRARY_PATH="$artifact_dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; fi
if [[ "$target" != linux64 ]]; then
    printf 'runtime smoke test not executed for non-native target %s\n' "$target"
    exit 0
fi
"$mp4box" -version
"$mp4box" -h
"$mp4box" -h dash
"$gpac" -h >/dev/null 2>&1
"$gpac" -hx filters >/dev/null 2>&1
"$gpac" -hx formats >/dev/null 2>&1
"$gpac" -hx 'ffdmx:*' >/dev/null 2>&1
"$gpac" -hx ffdec >/dev/null 2>&1
"$gpac" -hx ffbsf >/dev/null 2>&1
printf 'runtime smoke test passed\n'
