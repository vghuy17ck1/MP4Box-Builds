#!/usr/bin/env bash
set -euo pipefail

build_zstd() {
    local source_dir="$1" prefix="$2"
    cmake -S "$source_dir/build/cmake" -B "$source_dir/build-output" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_PROGRAMS=OFF
    cmake --build "$source_dir/build-output" --parallel "${JOBS:-2}"
    cmake --install "$source_dir/build-output"
}

