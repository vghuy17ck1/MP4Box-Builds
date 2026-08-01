#!/usr/bin/env bash
set -euo pipefail

build_codec_dependencies() {
    local variant="$1"
    [[ "$variant" == full ]] || return 0
    export FFMPEG_EXTERNAL_CFLAGS="-I$TARGET_PREFIX/include"
    export FFMPEG_EXTERNAL_LDFLAGS="-L$TARGET_PREFIX/lib"
}

