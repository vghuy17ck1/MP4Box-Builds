#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

configure_toolchain() {
    local target="$1" prefix="$2"
    target_setup
    export TARGET_PREFIX="$prefix"
    export PKG_CONFIG="$ROOT_DIR/util/pkg-config-static"
    export PKG_CONFIG_STATIC_LOG="$prefix/pkg-config-requests.log"
    export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$prefix/share/pkgconfig"
    export PKG_CONFIG_LIBDIR="$PKG_CONFIG_PATH"
    export PKG_CONFIG_SYSROOT_DIR="/"
    need_cmd pkg-config
    for command_name in "$CC" "$AR" "$RANLIB" "$STRIP"; do
        command -v "$command_name" >/dev/null 2>&1 || die "toolchain command not found: $command_name"
    done
}
