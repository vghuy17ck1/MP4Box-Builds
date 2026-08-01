#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
load_versions

printf 'GPAC_REPO=%s\n' "${GPAC_REPO:?}"
printf 'FFMPEG_REPO=%s\n' "${FFMPEG_REPO:?}"
printf 'FFMPEG_REF=%s\n' "${FFMPEG_REF:?}"
printf 'ZLIB_REF=%s\n' "${ZLIB_REF:?}"
printf 'TOOLCHAIN_NAME=%s\n' "${TOOLCHAIN_NAME:?}"
printf 'TOOLCHAIN_VERSION=%s\n' "${TOOLCHAIN_VERSION:?}"
