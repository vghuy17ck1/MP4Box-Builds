#!/usr/bin/env bash
set -euo pipefail

build_xz() {
    local source_dir="$1" prefix="$2"
    "$source_dir/configure" --host="$TARGET_ARCH" --prefix="$prefix" --disable-shared --enable-static --disable-xzdec --disable-lzmadec --disable-lzmainfo
    make -C "$source_dir" -j"${JOBS:-2}"
    make -C "$source_dir" install
}

