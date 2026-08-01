#!/usr/bin/env bash
set -euo pipefail

build_zlib() {
    local source_dir="$1" prefix="$2"
    local system_name=Linux
    [[ "$TARGET_OS" == mingw32 ]] && system_name=Windows
    local shared=OFF static=ON
    [[ "${LINKAGE:-static}" == shared ]] && shared=ON && static=OFF
    cmake -S "$source_dir" -B "$source_dir/build" -G "${CMAKE_GENERATOR:-Unix Makefiles}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DBUILD_SHARED_LIBS="$shared" -DZLIB_BUILD_SHARED="$shared" -DZLIB_BUILD_STATIC="$static" -DZLIB_BUILD_TESTING=OFF -DZLIB_INSTALL=ON -DCMAKE_SYSTEM_NAME="$system_name" -DCMAKE_SYSTEM_PROCESSOR="$TARGET_ARCH" -DCMAKE_C_COMPILER="$CC" -DCMAKE_AR="$AR" -DCMAKE_RANLIB="$RANLIB"
    cmake --build "$source_dir/build" --parallel "${JOBS:-2}"
    cmake --install "$source_dir/build"
    if [[ "$TARGET_OS" == mingw32 && "${LINKAGE:-static}" == static && -f "$prefix/lib/libzs.a" && ! -f "$prefix/lib/libz.a" ]]; then
        cp "$prefix/lib/libzs.a" "$prefix/lib/libz.a"
    fi
    [[ -f "$prefix/include/zlib.h" ]] || die "zlib headers were not installed in $prefix/include"
    if [[ "${LINKAGE:-static}" == static ]]; then
        [[ -f "$prefix/lib/libz.a" ]] || die "zlib static library was not installed in $prefix/lib"
    else
        find "$prefix/lib" "$prefix/bin" -maxdepth 1 -type f \( -name 'libz.so*' -o -iname 'zlib*.dll' -o -iname 'libz*.dll' \) -print -quit | grep -q . || die "zlib shared library was not installed in $prefix/lib or $prefix/bin"
    fi
}
