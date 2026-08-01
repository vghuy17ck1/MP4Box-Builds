#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/common.sh"

apply_ffmpeg_patches() {
    local source_dir="$1"
    local patch_file="$ROOT_DIR/patches/ffmpeg/0001-disable-tls-verification.patch"
    [[ -f "$patch_file" ]] || die "FFmpeg TLS policy patch missing: $patch_file"
    sed -i 's/\r$//' "$source_dir/libavformat/tls.h" "$source_dir/libavformat/tls.c"
    git -C "$source_dir" apply --unidiff-zero --check "$patch_file"
    git -C "$source_dir" apply --unidiff-zero "$patch_file"
    printf '%s\n' "$(basename "$patch_file")" >>"$BUILD_ROOT/patches-applied.txt"
}

build_ffmpeg() {
    local source_dir="$1" prefix="$2" variant="$3"
    apply_ffmpeg_patches "$source_dir"
    local -a linkage_args=(--disable-shared --enable-static)
    [[ "${LINKAGE:-static}" == shared ]] && linkage_args=(--enable-shared --disable-static)
    local -a args=(--prefix="$prefix" "${linkage_args[@]}" --enable-pic --pkg-config="$PKG_CONFIG" --extra-cflags="-I$prefix/include $CFLAGS" --extra-ldflags="-L$prefix/lib $LDFLAGS" "${FFMPEG_CONFIGURE_ARGS[@]}")
    args+=(--arch="$TARGET_ARCH" --target-os="$TARGET_OS")
    args+=(--cc="$CC" --cxx="$CXX" --ar="$AR" --as="$AS" --ld="$CC" --ranlib="$RANLIB" --strip="$STRIP" --nm="$NM")
    [[ "$TARGET_OS" == mingw32 || "$TARGET_ARCH" == aarch64 ]] && args+=(--enable-cross-compile --cross-prefix="$CROSS_COMPILE")
    [[ "$TARGET_OS" == mingw32 ]] && args+=(--windres="$WINDRES")
    [[ "${LTO:-0}" == 1 ]] && args+=(--enable-lto)
    (cd "$source_dir" && ./configure "${args[@]}") >"$BUILD_LOG_DIR/ffmpeg-configure.log" 2>&1 || { [[ -f "$source_dir/config.log" ]] && cat "$source_dir/config.log" >&2 || true; [[ -f "$source_dir/ffbuild/config.log" ]] && cat "$source_dir/ffbuild/config.log" >&2 || true; cat "$BUILD_LOG_DIR/ffmpeg-configure.log" >&2; return 1; }
    local -a make_args=(CC="$CC" CXX="$CXX" AR="$AR" AS="$AS" LD="$CC" NM="$NM" RANLIB="$RANLIB" STRIP="$STRIP")
    [[ "$TARGET_OS" == mingw32 ]] && make_args+=(WINDRES="$WINDRES")
    make -C "$source_dir" -j"${JOBS:-2}" "${make_args[@]}" >"$BUILD_LOG_DIR/ffmpeg-build.log" 2>&1 || { cat "$BUILD_LOG_DIR/ffmpeg-build.log" >&2; return 1; }
    make -C "$source_dir" install >"$BUILD_LOG_DIR/ffmpeg-install.log" 2>&1 || { cat "$BUILD_LOG_DIR/ffmpeg-install.log" >&2; return 1; }
    if [[ "${LINKAGE:-static}" == static ]]; then
        for library in avformat avcodec avutil swresample swscale; do
            [[ -f "$prefix/lib/lib$library.a" ]] || die "FFmpeg library missing: lib$library.a"
        done
        [[ "$variant" == minimal || -f "$prefix/lib/libavfilter.a" ]] || die "full FFmpeg library missing: libavfilter.a"
    else
        for library in avformat avcodec avutil swresample swscale; do
            if [[ "$TARGET_OS" == mingw32 ]]; then
                find "$prefix/lib" "$prefix/bin" -maxdepth 1 -type f \( -name "lib$library.dll.a" -o -iname "$library*.dll" -o -iname "lib$library*.dll" \) -print -quit | grep -q . || die "FFmpeg shared library missing: $library"
            else
                find "$prefix/lib" -maxdepth 1 -type f -name "lib$library.so*" -print -quit | grep -q . || die "FFmpeg shared library missing: lib$library.so"
            fi
        done
        if [[ "$variant" != minimal ]]; then
            if [[ "$TARGET_OS" == mingw32 ]]; then
                find "$prefix/lib" "$prefix/bin" -maxdepth 1 -type f \( -name 'libavfilter.dll.a' -o -iname 'avfilter*.dll' -o -iname 'libavfilter*.dll' \) -print -quit | grep -q . || die "full FFmpeg shared library missing: avfilter"
            else
                find "$prefix/lib" -maxdepth 1 -type f -name 'libavfilter.so*' -print -quit | grep -q . || die "full FFmpeg shared library missing: libavfilter.so"
            fi
        fi
    fi
}
