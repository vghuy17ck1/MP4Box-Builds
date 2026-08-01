#!/usr/bin/env bash
set -euo pipefail

build_openssl() {
    local source_dir="$1" prefix="$2"
    local platform=linux-x86_64
    [[ "$TARGET_OS" == mingw32 ]] && platform=mingw64
    (cd "$source_dir" && ./Configure "$platform" --prefix="$prefix" --libdir=lib no-shared no-tests no-apps)
    make -C "$source_dir" -j"${JOBS:-2}"
    make -C "$source_dir" install_sw
}

