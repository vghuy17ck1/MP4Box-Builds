#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=aarch64 TARGET_OS=linux LIBC=musl
    local prefix="${CROSS_PREFIX:-aarch64-linux-musl-}"
    export CC="${TARGET_CC:-${prefix}gcc}" CXX="${TARGET_CXX:-${prefix}g++}" AR="${TARGET_AR:-${prefix}ar}" AS="${TARGET_AS:-${prefix}gcc}"
    export LD="${TARGET_LD:-${prefix}ld}" NM="${TARGET_NM:-${prefix}nm}" RANLIB="${TARGET_RANLIB:-${prefix}ranlib}" STRIP="${TARGET_STRIP:-${prefix}strip}"
    export CFLAGS="${CFLAGS:--O2 -fno-plt -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    local default_ldflags='-static -Wl,--gc-sections'
    [[ "${LINKAGE:-static}" == shared ]] && default_ldflags='-Wl,--gc-sections'
    export LDFLAGS="${LDFLAGS:-$default_ldflags}"
    export CROSS_COMPILE="$prefix"
}
