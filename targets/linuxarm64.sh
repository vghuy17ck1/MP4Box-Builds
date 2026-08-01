#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=aarch64 TARGET_OS=linux LIBC=musl
    local prefix="${CROSS_PREFIX:-aarch64-linux-musl-}"
    export CC="${CC:-${prefix}gcc}" CXX="${CXX:-${prefix}g++}" AR="${AR:-${prefix}ar}" AS="${AS:-${prefix}as}"
    export LD="${LD:-${prefix}ld}" NM="${NM:-${prefix}nm}" RANLIB="${RANLIB:-${prefix}ranlib}" STRIP="${STRIP:-${prefix}strip}"
    export CFLAGS="${CFLAGS:--O2 -fno-plt -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    export LDFLAGS="${LDFLAGS:--static -Wl,--gc-sections}"
    export CROSS_COMPILE="$prefix"
}

