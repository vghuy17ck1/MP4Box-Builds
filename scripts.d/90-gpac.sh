#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

apply_gpac_patches() {
    local source_dir="$1"
    local patch_file="$ROOT_DIR/patches/gpac/0001-disable-tls-verification.patch"
    [[ -f "$patch_file" ]] || die "GPAC TLS policy patch missing: $patch_file"
    sed -i 's/\r$//' "$source_dir/src/utils/downloader_ssl.c" "$source_dir/src/utils/downloader_curl.c"
    git -C "$source_dir" apply --unidiff-zero --check "$patch_file"
    git -C "$source_dir" apply --unidiff-zero "$patch_file"
    printf '%s\n' "$(basename "$patch_file")" >>"$BUILD_ROOT/patches-applied.txt"
}

gpac_has_option() {
    local help_file="$1" option="$2"
    grep -F -- "$option" "$help_file" >/dev/null 2>&1
}

build_gpac() {
    local source_dir="$1" prefix="$2" target="$3" variant="$4"
    apply_gpac_patches "$source_dir"
    local help_file="$BUILD_LOG_DIR/gpac-configure-help.txt"
    (cd "$source_dir" && ./configure --help) >"$help_file" 2>&1 || die "GPAC configure --help failed"
    gpac_has_option "$help_file" --static-build || die "selected GPAC source does not support --static-build"
    gpac_has_option "$help_file" --static-modules || die "selected GPAC source does not support --static-modules"
    gpac_has_option "$help_file" --use-ffmpeg= || die "selected GPAC source does not support --use-ffmpeg"
    local -a args=(--prefix="$prefix" --static-build --static-modules --use-ffmpeg="$prefix" --extra-cflags="-I$prefix/include $CFLAGS" --extra-ldflags="-L$prefix/lib $LDFLAGS" --target-os="$TARGET_OS" --cpu="$TARGET_ARCH")
    [[ "$TARGET_OS" == mingw32 ]] && args+=(--cross-prefix="$CROSS_COMPILE")
    for option in "${GPAC_CONFIGURE_ARGS[@]}"; do
        if gpac_has_option "$help_file" "${option%%=*}"; then
            args+=("$option")
        fi
    done
    (cd "$source_dir" && ./configure "${args[@]}") >"$BUILD_LOG_DIR/gpac-configure.log" 2>&1 || { cat "$source_dir/config.log" >&2 || true; cat "$BUILD_LOG_DIR/gpac-configure.log" >&2; return 1; }
    make -C "$source_dir" -j"${JOBS:-2}" >"$BUILD_LOG_DIR/gpac-build.log" 2>&1 || { cat "$BUILD_LOG_DIR/gpac-build.log" >&2; return 1; }
    make -C "$source_dir" install >"$BUILD_LOG_DIR/gpac-install.log" 2>&1 || { cat "$BUILD_LOG_DIR/gpac-install.log" >&2; return 1; }
    local suffix
    suffix="$(binary_suffix "$target")"
    [[ -x "$prefix/bin/MP4Box$suffix" ]] || die "MP4Box was not installed in $prefix/bin"
    [[ -x "$prefix/bin/gpac$suffix" ]] || die "gpac was not installed in $prefix/bin"
}
