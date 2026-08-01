#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

target_setup() {
    export TARGET_ARCH=x86_64 TARGET_OS=linux LIBC=musl
    export CC="${CC:-musl-gcc}" CXX="${CXX:-g++}" AR="${AR:-ar}" AS="${AS:-as}" LD="${LD:-ld}"
    export NM="${NM:-nm}" RANLIB="${RANLIB:-ranlib}" STRIP="${STRIP:-strip}"
    export CFLAGS="${CFLAGS:--O2 -fno-plt -ffile-prefix-map=$ROOT_DIR=/usr/src/mp4box-builds}"
    export CXXFLAGS="${CXXFLAGS:-$CFLAGS}"
    export LDFLAGS="${LDFLAGS:--static -Wl,--gc-sections}"
}
