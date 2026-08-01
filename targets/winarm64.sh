#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=aarch64 TARGET_OS=mingw32 LIBC=mingw
    local prefix="${CROSS_PREFIX:-aarch64-w64-mingw32-}"
    export CC="${TARGET_CC:-${prefix}clang}" CXX="${TARGET_CXX:-${prefix}clang++}" AR="${TARGET_AR:-llvm-ar}" AS="${TARGET_AS:-${prefix}clang}"
    export LD="${TARGET_LD:-lld}" NM="${TARGET_NM:-llvm-nm}" RANLIB="${TARGET_RANLIB:-llvm-ranlib}" STRIP="${TARGET_STRIP:-llvm-strip}"
    export WINDRES="${TARGET_WINDRES:-${prefix}windres}"
    export CFLAGS="${CFLAGS:--O2 -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    local default_ldflags='-static'
    [[ "${LINKAGE:-static}" == shared ]] && default_ldflags=''
    export LDFLAGS="${LDFLAGS:-$default_ldflags}"
    export CROSS_COMPILE="$prefix"
}
