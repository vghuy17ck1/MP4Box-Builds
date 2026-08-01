#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

artifact_stem() {
    local version="$1" channel="$2" target="$3" variant="$4"
    local label
    case "$channel" in
        release) label="$version-release" ;;
        master) label="master-${GPAC_SHORT_COMMIT:?}" ;;
        custom) label="${GPAC_REQUESTED_REF:?}-custom" ;;
        *) die "unsupported artifact channel: $channel" ;;
    esac
    label="$(printf '%s' "$label" | tr '/: ' '---' | tr -cd '[:alnum:]._-')"
    printf 'mp4box-%s-%s-%s\n' "$label" "$target" "$variant"
}

package_artifact() {
    local staging="$1" output_dir="$2" target="$3" variant="$4" channel="$5" version="$6"
    local stem archive
    stem="$(artifact_stem "$version" "$channel" "$target" "$variant")"
    mkdir -p "$output_dir"
    if [[ "$target" == linux64 || "$target" == linuxarm64 ]]; then
        archive="$output_dir/$stem.tar.xz"
        tar --sort=name --mtime="@${SOURCE_DATE_EPOCH}" --owner=0 --group=0 --numeric-owner -cJf "$archive" -C "$staging" .
    else
        archive="$output_dir/$stem.zip"
        (cd "$staging" && find . -type f -print | LC_ALL=C sort | zip -X -q "$archive" -@)
    fi
    (cd "$output_dir" && sha256sum "$(basename "$archive")" >"$(basename "$archive").sha256")
    printf '%s\n' "$archive"
}
