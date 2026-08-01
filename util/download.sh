#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

clone_at_commit() {
    local repo="$1" ref="$2" destination="$3"
    [[ -n "$repo" && -n "$ref" && -n "$destination" ]] || die "clone_at_commit requires repository, ref, and destination"
    rm -rf "$destination"
    git init "$destination" >/dev/null
    git -C "$destination" remote add origin "$repo"
    git -C "$destination" fetch --depth=1 origin "$ref"
    git -C "$destination" checkout --detach FETCH_HEAD >/dev/null
    local actual
    actual="$(git -C "$destination" rev-parse HEAD)"
    [[ "$actual" == "$ref" ]] || die "checked out commit $actual differs from requested $ref"
    git -C "$destination" submodule update --init --recursive
    printf '%s\n' "$actual"
}

download_tarball() {
    local url="$1" sha256="$2" archive="$3"
    need_cmd curl
    curl --fail --silent --show-error --location --retry 5 --retry-delay 2 --proto '=https' --tlsv1.2 "$url" -o "$archive"
    printf '%s  %s\n' "$sha256" "$archive" | sha256sum -c -
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    case "${1:-}" in
        clone) clone_at_commit "${2:?repository}" "${3:?commit}" "${4:?destination}" ;;
        tarball) download_tarball "${2:?url}" "${3:?sha256}" "${4:?archive}" ;;
        *) die "usage: download.sh clone <repo> <commit> <destination> | tarball <url> <sha256> <archive>" ;;
    esac
fi

