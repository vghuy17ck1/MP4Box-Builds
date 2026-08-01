#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=x86_64 TARGET_OS=mingw32 LIBC=mingw
    local prefix="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
    export CC="${TARGET_CC:-${prefix}gcc}" CXX="${TARGET_CXX:-${prefix}g++}" AR="${TARGET_AR:-${prefix}ar}" AS="${TARGET_AS:-${prefix}as}"
    export LD="${TARGET_LD:-${prefix}ld}" NM="${TARGET_NM:-${prefix}nm}" RANLIB="${TARGET_RANLIB:-${prefix}ranlib}" STRIP="${TARGET_STRIP:-${prefix}strip}"
    export WINDRES="${TARGET_WINDRES:-${prefix}windres}"
    export CFLAGS="${CFLAGS:--O2 -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds -Wno-pointer-sign -Wno-error=pointer-sign}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    export LDFLAGS="${LDFLAGS:--static -static-libgcc -static-libstdc++}"
    export CROSS_COMPILE="$prefix"
}
