#!/usr/bin/env bash
set -euo pipefail

build_curl() {
    local source_dir="$1" prefix="$2"
    "$source_dir/configure" --host="$TARGET_ARCH" --prefix="$prefix" --disable-shared --enable-static --disable-manual --disable-ldap --disable-rtsp --with-ssl="$prefix" --with-zlib="$prefix" --with-nghttp2="$prefix"
    make -C "$source_dir" -j"${JOBS:-2}"
    make -C "$source_dir" install
}

