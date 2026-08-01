#!/usr/bin/env bash
set -euo pipefail

build_bzip2() {
    local source_dir="$1" prefix="$2"
    make -C "$source_dir" -j"${JOBS:-2}" CC="$CC" AR="$AR" RANLIB="$RANLIB"
    make -C "$source_dir" PREFIX="$prefix" install
}

