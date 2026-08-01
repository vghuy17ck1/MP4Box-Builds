#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=x86_64 TARGET_OS=mingw32 LIBC=mingw
    local prefix="${CROSS_PREFIX:-x86_64-w64-mingw32-}"
    export CC="${CC:-${prefix}gcc}" CXX="${CXX:-${prefix}g++}" AR="${AR:-${prefix}ar}" AS="${AS:-${prefix}as}"
    export LD="${LD:-${prefix}ld}" NM="${NM:-${prefix}nm}" RANLIB="${RANLIB:-${prefix}ranlib}" STRIP="${STRIP:-${prefix}strip}"
    export WINDRES="${WINDRES:-${prefix}windres}"
    export CFLAGS="${CFLAGS:--O2 -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    export LDFLAGS="${LDFLAGS:--static -static-libgcc -static-libstdc++}"
    export CROSS_COMPILE="$prefix"
}

