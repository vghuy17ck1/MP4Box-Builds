#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/util/common.sh"
load_versions
set_reproducible_env

target="${1:-}"
variant="${2:-}"
requested_channel="${3:-${SOURCE_CHANNEL:-release}}"
valid_target "$target" || die "usage: build.sh <linux64|linuxarm64|win64|winarm64> <minimal|full> <release|master>"
valid_variant "$variant" || die "usage: build.sh <target> <minimal|full> <release|master>"
case "$requested_channel" in release|master) ;; custom) [[ -n "${GPAC_REF:-}" ]] || die "custom channel requires GPAC_REF" ;; *) die "channel must be release or master" ;; esac

WORK_ROOT="${WORK_ROOT:-$ROOT_DIR/work}"
OUTPUT_DIR="${OUTPUT_DIR:-${ARTIFACT_DIR:-$ROOT_DIR/artifacts}}"
mkdir -p "$WORK_ROOT" "$OUTPUT_DIR"
WORK_ROOT="$(cd "$WORK_ROOT" && pwd)"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
BUILD_ROOT="$WORK_ROOT/build/$target/$variant/$requested_channel"
SOURCE_ROOT="$WORK_ROOT/src/$target/$variant/$requested_channel"
PREFIX="$WORK_ROOT/prefix/$target/$variant/$requested_channel"
BUILD_LOG_DIR="$WORK_ROOT/logs/$target/$variant/$requested_channel"
mkdir -p "$BUILD_ROOT" "$SOURCE_ROOT" "$PREFIX" "$BUILD_LOG_DIR" "$OUTPUT_DIR"
: >"$BUILD_ROOT/patches-applied.txt"
export BUILD_ROOT SOURCE_ROOT PREFIX BUILD_LOG_DIR TARGET_PREFIX="$PREFIX"
export JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf 2)}"

SOURCE_CHANNEL="$requested_channel" bash "$ROOT_DIR/util/resolve-refs.sh" >"$BUILD_ROOT/refs.env"
source_env_file "$BUILD_ROOT/refs.env"
channel="$source_channel"
export SOURCE_CHANNEL="$channel"
source "$ROOT_DIR/targets/$target.sh"
source "$ROOT_DIR/variants/$variant.sh"
target_setup
variant_setup
printf 'architecture=%s\n' "$TARGET_ARCH" >>"$BUILD_ROOT/refs.env"
printf 'libc=%s\n' "$LIBC" >>"$BUILD_ROOT/refs.env"
printf 'toolchain_name=%s\n' "${TOOLCHAIN_NAME:-unknown}" >>"$BUILD_ROOT/refs.env"
printf 'toolchain_version=%s\n' "${TOOLCHAIN_VERSION:-unknown}" >>"$BUILD_ROOT/refs.env"
printf 'zlib_ref=%s\n' "${ZLIB_REF:-unknown}" >>"$BUILD_ROOT/refs.env"
printf 'compiler_version=%s\n' "$("$CC" --version 2>/dev/null | head -n 1 | tr ' ' '_')" >>"$BUILD_ROOT/refs.env"
source "$ROOT_DIR/scripts.d/00-toolchain.sh"
configure_toolchain "$target" "$PREFIX"
source "$ROOT_DIR/scripts.d/10-zlib.sh"
if [[ ! -f "$PREFIX/lib/libz.a" ]]; then
    zlib_source="$SOURCE_ROOT/zlib"
    bash "$ROOT_DIR/util/download.sh" clone "${ZLIB_REPO:-https://github.com/madler/zlib.git}" "${ZLIB_REF:?}" "$zlib_source" >"$BUILD_LOG_DIR/zlib-fetch.log"
    build_zlib "$zlib_source" "$PREFIX" >"$BUILD_LOG_DIR/zlib-build.log" 2>&1
fi
source "$ROOT_DIR/scripts.d/40-codec-dependencies.sh"
build_codec_dependencies "$variant"
source "$ROOT_DIR/scripts.d/50-ffmpeg.sh"
source "$ROOT_DIR/scripts.d/60-gpac-dependencies.sh"
source "$ROOT_DIR/scripts.d/90-gpac.sh"

gpac_source="$SOURCE_ROOT/gpac"
ffmpeg_source="$SOURCE_ROOT/ffmpeg"
bash "$ROOT_DIR/util/download.sh" clone "$GPAC_REPO" "$gpac_commit" "$gpac_source" >"$BUILD_LOG_DIR/gpac-fetch.log"
bash "$ROOT_DIR/util/download.sh" clone "$FFMPEG_REPO" "$ffmpeg_commit" "$ffmpeg_source" >"$BUILD_LOG_DIR/ffmpeg-fetch.log"
build_ffmpeg "$ffmpeg_source" "$PREFIX" "$variant"
bash "$ROOT_DIR/tests/verify-tls-policy.sh" "$ffmpeg_source"
printf 'tls_verification_disabled=true\n' >>"$BUILD_ROOT/refs.env"
source_env_file "$BUILD_ROOT/refs.env"
prepare_gpac_dependencies "$PREFIX"
build_gpac "$gpac_source" "$PREFIX" "$target" "$variant"
bash "$ROOT_DIR/tests/verify-gpac-tls-policy.sh" "$gpac_source"
bash "$ROOT_DIR/util/verify-prefix.sh" "$PREFIX"

suffix="$(binary_suffix "$target")"
staging="$BUILD_ROOT/package"
rm -rf "$staging"
mkdir -p "$staging/bin"
cp "$PREFIX/bin/MP4Box$suffix" "$staging/bin/MP4Box$suffix"
cp "$PREFIX/bin/gpac$suffix" "$staging/bin/gpac$suffix"
chmod u+rx "$staging/bin/MP4Box$suffix" "$staging/bin/gpac$suffix"
printf 'MP4Box-Builds %s %s %s\n' "$target" "$variant" "$channel" >"$staging/README.txt"
printf '%s\n' "Built from immutable GPAC commit $gpac_commit and FFmpeg commit $ffmpeg_commit." >>"$staging/README.txt"
printf '%s\n' "See BUILD_INFO.json and FEATURES.json for verification status." >>"$staging/README.txt"
printf '%s\n' "--static-build --static-modules --use-ffmpeg=$PREFIX" >"$BUILD_ROOT/configure-arguments.txt"
if [[ "$target" == linux64 ]] && command -v ffmpeg >/dev/null 2>&1; then
    bash "$ROOT_DIR/tests/fixtures/create-sample.sh" "$ROOT_DIR/tests/fixtures/sample.mkv"
fi

source "$ROOT_DIR/util/feature-manifest.sh"
generate_feature_manifest "$staging/bin" "$staging/FEATURES.json" "$variant" "$suffix"

static_status=false
format_status=false
runtime_status=false
dash_status=false
transcode_status=false
if bash "$ROOT_DIR/tests/verify-static.sh" "$staging" "$target"; then static_status=true; fi
if bash "$ROOT_DIR/tests/smoke-test.sh" "$staging" "$target"; then runtime_status=true; fi
if bash "$ROOT_DIR/tests/verify-dash-mkv.sh" "$staging" "$target"; then dash_status=true; fi
if [[ "$variant" == full ]] && bash "$ROOT_DIR/tests/verify-transcode.sh" "$staging" "$target"; then transcode_status=true; fi
if bash "$ROOT_DIR/tests/verify-features.sh" "$staging" "$variant"; then format_status=true; fi

source "$ROOT_DIR/util/licenses.sh"
source "$ROOT_DIR/util/build-info.sh"
generate_licenses "$staging" "$gpac_source" "$ffmpeg_source" "$variant" "$SOURCE_ROOT/zlib"
generate_build_info "$staging/BUILD_INFO.json" "$target" "$variant" "$channel" "$BUILD_ROOT/refs.env" "$BUILD_ROOT/configure-arguments.txt" "$BUILD_ROOT/patches-applied.txt" "$static_status" "$format_status" "$runtime_status" "$dash_status" "$transcode_status" "${EFFECTIVE_LICENSE:-unknown}"
[[ "$static_status" == true ]] || die "static and binary-format verification failed for $target"
[[ "$format_status" == true ]] || die "feature verification failed for $target/$variant"
if [[ "$target" == linux64 ]]; then
    [[ "$runtime_status" == true ]] || die "native smoke test failed for linux64"
    [[ "$dash_status" == true ]] || die "native MKV-to-DASH test failed for linux64"
    if [[ "$variant" == full ]]; then
        [[ "$transcode_status" == true ]] || die "native transcoding test failed for full linux64"
    fi
fi
printf '%s\n' "BUILD_INFO.json" "FEATURES.json" "README.txt" "bin/MP4Box$suffix" "bin/gpac$suffix" | LC_ALL=C sort >"$staging/SHA256-inputs"
(cd "$staging" && find . -type f ! -name SHA256SUMS ! -name SHA256-inputs -print0 | sort -z | xargs -0 sha256sum) >"$staging/SHA256SUMS"
rm -f "$staging/SHA256-inputs"
source "$ROOT_DIR/util/package.sh"
archive="$(package_artifact "$staging" "$OUTPUT_DIR" "$target" "$variant" "$channel" "$gpac_version")"
cp -R "$staging/bin" "$OUTPUT_DIR/"
cp "$staging/BUILD_INFO.json" "$staging/FEATURES.json" "$OUTPUT_DIR/"
printf 'artifact=%s\n' "$archive"
printf 'static_verification=%s\n' "$static_status"
printf 'runtime_smoke_tested=%s\n' "$runtime_status"
printf 'functional_mkv_to_dash_tested=%s\n' "$dash_status"
printf 'transcoding_tested=%s\n' "$transcode_status"
printf 'gpac_commit=%s\n' "$gpac_commit"
printf 'ffmpeg_commit=%s\n' "$ffmpeg_commit"
