#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=x86_64 TARGET_OS=linux LIBC=musl
    export CC="${TARGET_CC:-musl-gcc}" CXX="${TARGET_CXX:-g++}" AR="${TARGET_AR:-ar}" AS="${TARGET_AS:-as}" LD="${TARGET_LD:-ld}"
    export NM="${TARGET_NM:-nm}" RANLIB="${TARGET_RANLIB:-ranlib}" STRIP="${TARGET_STRIP:-strip}"
    export CFLAGS="${CFLAGS:--O2 -fno-plt -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    export LDFLAGS="${LDFLAGS:--static -Wl,--gc-sections}"
}
