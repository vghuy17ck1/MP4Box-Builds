#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=aarch64 TARGET_OS=mingw32 LIBC=mingw
    local prefix="${CROSS_PREFIX:-aarch64-w64-mingw32-}"
    export CC="${CC:-${prefix}clang}" CXX="${CXX:-${prefix}clang++}" AR="${AR:-llvm-ar}" AS="${AS:-llvm-as}"
    export LD="${LD:-lld}" NM="${NM:-llvm-nm}" RANLIB="${RANLIB:-llvm-ranlib}" STRIP="${STRIP:-llvm-strip}"
    export WINDRES="${WINDRES:-llvm-windres}"
    export CFLAGS="${CFLAGS:--O2 -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    export LDFLAGS="${LDFLAGS:--static}"
    export CROSS_COMPILE="$prefix"
}

