#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

apply_gpac_patches() {
    local source_dir="$1"
    local patch_files=(
        "$ROOT_DIR/patches/gpac/0001-disable-tls-verification.patch"
        "$ROOT_DIR/patches/gpac/0002-case-correct-winsock-header.patch"
        "$ROOT_DIR/patches/gpac/0003-use-configured-windres.patch"
        "$ROOT_DIR/patches/gpac/0004-remove-unused-postproc-link.patch"
        "$ROOT_DIR/patches/gpac/0005-use-static-pkg-config-for-cross.patch"
        "$ROOT_DIR/patches/gpac/0006-remove-windows-rpath-link.patch"
    )
    [[ -f "$source_dir/src/utils/downloader_ssl.c" && -f "$source_dir/src/utils/downloader_curl.c" ]] || die "GPAC downloader sources missing"
    sed -i 's/\r$//' "$source_dir/src/utils/downloader_ssl.c" "$source_dir/src/utils/downloader_curl.c"
    for patch_file in "${patch_files[@]}"; do
        [[ -f "$patch_file" ]] || die "GPAC patch missing: $patch_file"
        git -C "$source_dir" apply --unidiff-zero --check "$patch_file"
        git -C "$source_dir" apply --unidiff-zero "$patch_file"
        printf '%s\n' "$(basename "$patch_file")" >>"$BUILD_ROOT/patches-applied.txt"
    done
}

gpac_has_option() {
    local help_file="$1" option="$2"
    grep -F -- "$option" "$help_file" >/dev/null 2>&1
}

gpac_supports_ffmpeg() {
    local help_file="$1"
    if gpac_has_option "$help_file" --use-ffmpeg=; then
        return 0
    fi
    gpac_has_option "$help_file" --use-FOO= || return 1
    grep -E '(^|[[:space:]])ffmpeg([[:space:]]|$)' "$help_file" >/dev/null 2>&1
}

build_gpac() {
    local source_dir="$1" prefix="$2" target="$3" variant="$4"
    apply_gpac_patches "$source_dir"
    local help_file="$BUILD_LOG_DIR/gpac-configure-help.txt"
(cd "$source_dir" && ./configure --help) >"$help_file" 2>&1 || true
    gpac_has_option "$help_file" --static-build || die "selected GPAC source does not support --static-build"
    gpac_has_option "$help_file" --static-modules || die "selected GPAC source does not support --static-modules"
    gpac_supports_ffmpeg "$help_file" || die "selected GPAC source does not support FFmpeg configuration"
    local gpac_cross_prefix=""
    local gpac_cc="$CC" gpac_cxx="$CXX" gpac_ar="$AR" gpac_ranlib="$RANLIB" gpac_strip="$STRIP" gpac_windres="${WINDRES:-windres}"
    if [[ "$TARGET_OS" == mingw32 || "$TARGET_ARCH" == aarch64 ]]; then
        gpac_cross_prefix="${CROSS_COMPILE:-}"
    fi
    if [[ -n "$gpac_cross_prefix" && "$gpac_cc" == "$gpac_cross_prefix"* ]]; then gpac_cc="${gpac_cc#$gpac_cross_prefix}"; fi
    if [[ -n "$gpac_cross_prefix" && "$gpac_cxx" == "$gpac_cross_prefix"* ]]; then gpac_cxx="${gpac_cxx#$gpac_cross_prefix}"; fi
    if [[ -n "$gpac_cross_prefix" && "$gpac_ar" == "$gpac_cross_prefix"* ]]; then gpac_ar="${gpac_ar#$gpac_cross_prefix}"; fi
    if [[ -n "$gpac_cross_prefix" && "$gpac_ranlib" == "$gpac_cross_prefix"* ]]; then gpac_ranlib="${gpac_ranlib#$gpac_cross_prefix}"; fi
    if [[ -n "$gpac_cross_prefix" && "$gpac_strip" == "$gpac_cross_prefix"* ]]; then gpac_strip="${gpac_strip#$gpac_cross_prefix}"; fi
    if [[ -n "$gpac_cross_prefix" && "$gpac_windres" == "$gpac_cross_prefix"* ]]; then gpac_windres="${gpac_windres#$gpac_cross_prefix}"; fi
    local gpac_extra_cflags="-I$prefix/include $CFLAGS"
    if [[ "$TARGET_OS" == mingw32 ]]; then
        gpac_extra_cflags+=" -DGPAC_ALLOW_UNSAFE_STRFUNC"
    fi
    local -a args=(--prefix="$prefix" --static-build --static-modules --enable-fin --enable-fout --enable-dasher --use-zlib="$prefix" --use-ffmpeg=system --cc="$gpac_cc" --cxx="$gpac_cxx" --extra-cflags="$gpac_extra_cflags" --extra-ldflags="-L$prefix/lib $LDFLAGS" --target-os="$TARGET_OS" --cpu="$TARGET_ARCH")
    if [[ -n "$gpac_cross_prefix" ]] && gpac_has_option "$help_file" --cross-prefix; then
        args+=(--cross-prefix="$gpac_cross_prefix")
    fi
    for option in "${GPAC_CONFIGURE_ARGS[@]}"; do
        if gpac_has_option "$help_file" "${option%%=*}"; then
            args+=("$option")
        fi
    done
    (
        export CC="$gpac_cc" CXX="$gpac_cxx" AR="$gpac_ar" RANLIB="$gpac_ranlib" STRIP="$gpac_strip" WINDRES="$gpac_windres"
        cd "$source_dir"
        ./configure "${args[@]}"
    ) >"$BUILD_LOG_DIR/gpac-configure.log" 2>&1 || { cat "$source_dir/config.log" >&2 || true; cat "$BUILD_LOG_DIR/gpac-configure.log" >&2; return 1; }
    if grep -Eiq '^FFmpeg: (no|force-no)' "$BUILD_LOG_DIR/gpac-configure.log"; then
        if [[ -f "$source_dir/config.log" ]]; then
            grep -Eiq 'ffmpeg|libav|pkg-config|cannot|error|failed' "$source_dir/config.log" >&2 || true
        fi
        cat "$BUILD_LOG_DIR/gpac-configure.log" >&2
        die "GPAC was configured without FFmpeg support"
    fi
    make -C "$source_dir" -j"${JOBS:-2}" >"$BUILD_LOG_DIR/gpac-build.log" 2>&1 || { cat "$BUILD_LOG_DIR/gpac-build.log" >&2; return 1; }
    make -C "$source_dir" install >"$BUILD_LOG_DIR/gpac-install.log" 2>&1 || { cat "$BUILD_LOG_DIR/gpac-install.log" >&2; return 1; }
    local suffix
    suffix="$(binary_suffix "$target")"
    [[ -x "$prefix/bin/MP4Box$suffix" ]] || die "MP4Box was not installed in $prefix/bin"
    [[ -x "$prefix/bin/gpac$suffix" ]] || die "gpac was not installed in $prefix/bin"
}
