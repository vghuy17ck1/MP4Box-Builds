#!/usr/bin/env bash
set -euo pipefail

build_zlib() {
    local source_dir="$1" prefix="$2"
    local system_name=Linux
    [[ "$TARGET_OS" == mingw32 ]] && system_name=Windows
    cmake -S "$source_dir" -B "$source_dir/build" -G "${CMAKE_GENERATOR:-Unix Makefiles}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DBUILD_SHARED_LIBS=OFF -DZLIB_BUILD_TESTING=OFF -DCMAKE_SYSTEM_NAME="$system_name" -DCMAKE_SYSTEM_PROCESSOR="$TARGET_ARCH" -DCMAKE_C_COMPILER="$CC" -DCMAKE_AR="$AR" -DCMAKE_RANLIB="$RANLIB"
    cmake --build "$source_dir/build" --parallel "${JOBS:-2}"
    cmake --install "$source_dir/build"
}
