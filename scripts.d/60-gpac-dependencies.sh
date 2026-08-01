#!/usr/bin/env bash
set -euo pipefail

prepare_gpac_dependencies() {
    local prefix="$1"
    [[ -d "$prefix/include" && -d "$prefix/lib" ]] || die "target prefix is incomplete: $prefix"
    if [[ "${LINKAGE:-static}" == static ]]; then
        [[ -f "$prefix/lib/libavformat.a" ]] || die "GPAC dependency prefix has no static FFmpeg"
    else
        if [[ "$TARGET_OS" == mingw32 ]]; then
            find "$prefix/lib" "$prefix/bin" -maxdepth 1 -type f \( -name 'libavformat.dll.a' -o -iname 'avformat*.dll' -o -iname 'libavformat*.dll' \) -print -quit | grep -q . || die "GPAC dependency prefix has no shared FFmpeg"
        else
            find "$prefix/lib" -maxdepth 1 -type f -name 'libavformat.so*' -print -quit | grep -q . || die "GPAC dependency prefix has no shared FFmpeg"
        fi
    fi
}
