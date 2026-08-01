#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

generate_licenses() {
    local package_dir="$1" gpac_source="$2" ffmpeg_source="$3" variant="$4" zlib_source="${5:-}"
    mkdir -p "$package_dir"
    {
        printf 'MP4Box-Builds third-party notices\n\n'
        printf 'GPAC source license\n===================\n'
        [[ -f "$gpac_source/COPYING" ]] && cat "$gpac_source/COPYING"
        printf '\nFFmpeg source license\n=====================\n'
        [[ -f "$ffmpeg_source/COPYING.LGPLv2.1" ]] && cat "$ffmpeg_source/COPYING.LGPLv2.1"
        printf '\nVariant: %s\n' "$variant"
        if [[ -n "$zlib_source" && -f "$zlib_source/LICENSE" ]]; then
            printf '\nzlib license\n============\n'
            cat "$zlib_source/LICENSE"
        fi
        printf 'The effective license is recorded in BUILD_INFO.json.\n'
    } >"$package_dir/THIRD_PARTY_LICENSES.txt"
    [[ -f "$gpac_source/COPYING" ]] && cp "$gpac_source/COPYING" "$package_dir/LICENSE-GPAC.txt"
    [[ -f "$ffmpeg_source/COPYING.LGPLv2.1" ]] && cp "$ffmpeg_source/COPYING.LGPLv2.1" "$package_dir/LICENSE-FFMPEG.txt"
    [[ -f "$package_dir/LICENSE-GPAC.txt" ]] || printf 'GPAC license text is available from the source commit in BUILD_INFO.json.\n' >"$package_dir/LICENSE-GPAC.txt"
    [[ -f "$package_dir/LICENSE-FFMPEG.txt" ]] || printf 'FFmpeg license text is available from the source commit in BUILD_INFO.json.\n' >"$package_dir/LICENSE-FFMPEG.txt"
}
