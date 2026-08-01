#!/usr/bin/env bash
set -euo pipefail

prepare_gpac_dependencies() {
    local prefix="$1"
    [[ -d "$prefix/include" && -d "$prefix/lib" ]] || die "target prefix is incomplete: $prefix"
    [[ -f "$prefix/lib/libavformat.a" ]] || die "GPAC dependency prefix has no static FFmpeg"
}
