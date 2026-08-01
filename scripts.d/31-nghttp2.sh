#!/usr/bin/env bash
set -euo pipefail

build_nghttp2() {
    local source_dir="$1" prefix="$2"
    cmake -S "$source_dir" -B "$source_dir/build" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DENABLE_LIB_ONLY=ON -DENABLE_APP=OFF -DBUILD_SHARED_LIBS=OFF
    cmake --build "$source_dir/build" --parallel "${JOBS:-2}"
    cmake --install "$source_dir/build"
}

