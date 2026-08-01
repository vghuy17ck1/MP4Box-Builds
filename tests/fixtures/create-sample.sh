#!/usr/bin/env bash
set -euo pipefail

output="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/sample.mkv}"
command -v ffmpeg >/dev/null 2>&1 || { printf 'ffmpeg is required to generate %s\n' "$output" >&2; exit 1; }
mkdir -p "$(dirname "$output")"
ffmpeg -hide_banner -loglevel error -y -f lavfi -i "testsrc2=size=160x90:rate=2:duration=2" -f lavfi -i "sine=frequency=1000:sample_rate=48000:duration=2" -c:v libx264 -pix_fmt yuv420p -preset ultrafast -c:a aac -shortest -f matroska "$output"
[[ -s "$output" ]]
