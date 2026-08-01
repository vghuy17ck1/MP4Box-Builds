#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
load_versions
set_reproducible_env
need_cmd git
need_cmd curl

GPAC_REPO="${GPAC_REPO:?}"
FFMPEG_REPO="${FFMPEG_REPO:?}"
SOURCE_CHANNEL="${SOURCE_CHANNEL:-release}"
ALLOW_PRERELEASE="${ALLOW_PRERELEASE:-0}"

resolve_ref() {
    local repo="$1" ref="$2" result
    [[ -n "$repo" && -n "$ref" ]] || die "cannot resolve an empty source reference"
    if [[ "$ref" =~ ^[0-9a-fA-F]{40}$ ]]; then
        result="$(git ls-remote "$repo" | awk -v wanted="$ref" '$1 == wanted { print $1; exit}')"
    else
        local refs
        refs="$(git ls-remote "$repo" "refs/heads/$ref" "refs/tags/$ref" "refs/tags/$ref^{}")"
        result="$(printf '%s\n' "$refs" | awk '$2 ~ /\^\{\}$/ { print $1; exit}')"
        [[ -n "$result" ]] || result="$(printf '%s\n' "$refs" | awk '$2 !~ /\^\{\}$/ { print $1; exit}')"
        if [[ -z "$result" ]]; then
            refs="$(git ls-remote "$repo" "$ref")"
            result="$(printf '%s\n' "$refs" | awk '$2 ~ /\^\{\}$/ { print $1; exit}')"
            [[ -n "$result" ]] || result="$(printf '%s\n' "$refs" | awk '$2 !~ /\^\{\}$/ { print $1; exit}')"
        fi
    fi
    result="${result//$'\r'/}"
    [[ "$result" =~ ^[0-9a-fA-F]{40}$ ]] || die "could not resolve $ref in $repo"
    printf '%s\n' "$result"
}

latest_release() {
    local payload
    payload="$(curl --fail --silent --show-error --location --retry 5 --retry-delay 2 --proto '=https' --tlsv1.2 -H 'Accept: application/vnd.github+json' -H 'X-GitHub-Api-Version: 2022-11-28' 'https://api.github.com/repos/gpac/gpac/releases/latest')"
    "$PYTHON_BIN" - "$ALLOW_PRERELEASE" "$payload" <<'PY'
import json
import sys
release = json.loads(sys.argv[2])
if release.get("draft"):
    raise SystemExit("latest GPAC release API returned a draft")
if release.get("prerelease") and sys.argv[1] != "1":
    raise SystemExit("latest GPAC release is a prerelease; set ALLOW_PRERELEASE=1 to allow it")
tag = release.get("tag_name", "")
if not tag:
    raise SystemExit("latest GPAC release API returned no tag_name")
print(tag)
print("true" if release.get("prerelease") else "false")
PY
}

resolve_ffmpeg() {
    local requested="${FFMPEG_REF:-}" resolved
    [[ -n "$requested" ]] || die "FFMPEG_REF is empty"
    resolved="$(resolve_ref "$FFMPEG_REPO" "$requested")"
    FFMPEG_REQUESTED_REF="$requested"
    FFMPEG_RESOLVED_REF="$resolved"
    FFMPEG_COMMIT="$resolved"
    FFMPEG_SHORT_COMMIT="${resolved:0:12}"
    FFMPEG_VERSION="${requested#n}"
}

resolve_zlib() {
    local requested="${ZLIB_REF:-}" resolved
    [[ -n "$requested" ]] || die "ZLIB_REF is empty"
    resolved="$(resolve_ref "$ZLIB_REPO" "$requested")"
    ZLIB_REQUESTED_REF="$requested"
    ZLIB_RESOLVED_REF="$resolved"
    ZLIB_COMMIT="$resolved"
    ZLIB_SHORT_COMMIT="${resolved:0:12}"
}

resolve_gpac() {
    local requested tag prerelease resolved
    if [[ -n "${GPAC_REF:-}" ]]; then
        SOURCE_CHANNEL=custom
        requested="$GPAC_REF"
        tag=""
        prerelease=false
    elif [[ "$SOURCE_CHANNEL" == release ]]; then
        requested="${GPAC_RELEASE_REF:-latest}"
        if [[ "$requested" == latest ]]; then
            mapfile -t release_data < <(latest_release)
            tag="${release_data[0]:-}"
            prerelease="${release_data[1]:-false}"
            tag="${tag//$'\r'/}"
            prerelease="${prerelease//$'\r'/}"
            [[ -n "$tag" ]] || die "latest GPAC release did not return a tag"
            requested="$tag"
        else
            tag="$requested"
            prerelease=false
        fi
    elif [[ "$SOURCE_CHANNEL" == master ]]; then
        requested="${GPAC_MASTER_REF:-master}"
        tag=""
        prerelease=false
    else
        die "unsupported source channel: $SOURCE_CHANNEL"
    fi
    resolved="$(resolve_ref "$GPAC_REPO" "$requested")"
    GPAC_REQUESTED_REF="$requested"
    GPAC_RESOLVED_REF="$resolved"
    GPAC_COMMIT="$resolved"
    GPAC_SHORT_COMMIT="${resolved:0:12}"
    GPAC_RELEASE_TAG="$tag"
    GPAC_VERSION="${tag#v}"
    [[ -n "$GPAC_VERSION" ]] || GPAC_VERSION="master-${GPAC_SHORT_COMMIT}"
    GPAC_IS_PRERELEASE="$prerelease"
    [[ "$SOURCE_CHANNEL" == master || "$SOURCE_CHANNEL" == custom ]] && GPAC_IS_DEVELOPMENT_BUILD=true || GPAC_IS_DEVELOPMENT_BUILD=false
}

case "$SOURCE_CHANNEL" in
    release|master) ;;
    *) [[ -n "${GPAC_REF:-}" ]] || die "SOURCE_CHANNEL must be release or master" ;;
esac
resolve_gpac
resolve_ffmpeg
resolve_zlib

channels='["release","master"]'
[[ "$SOURCE_CHANNEL" == custom ]] && channels='["custom"]'
cat <<EOF
source_channel=$SOURCE_CHANNEL
gpac_repository=$GPAC_REPO
gpac_requested_ref=$GPAC_REQUESTED_REF
gpac_resolved_ref=$GPAC_RESOLVED_REF
gpac_release_tag=$GPAC_RELEASE_TAG
gpac_commit=$GPAC_COMMIT
gpac_short_commit=$GPAC_SHORT_COMMIT
gpac_version=$GPAC_VERSION
gpac_is_prerelease=$GPAC_IS_PRERELEASE
gpac_is_development_build=$GPAC_IS_DEVELOPMENT_BUILD
ffmpeg_repository=$FFMPEG_REPO
ffmpeg_requested_ref=$FFMPEG_REQUESTED_REF
ffmpeg_resolved_ref=$FFMPEG_RESOLVED_REF
ffmpeg_commit=$FFMPEG_COMMIT
ffmpeg_short_commit=$FFMPEG_SHORT_COMMIT
ffmpeg_version=$FFMPEG_VERSION
ffmpeg_sha=$FFMPEG_COMMIT
zlib_repository=$ZLIB_REPO
zlib_requested_ref=$ZLIB_REQUESTED_REF
zlib_resolved_ref=$ZLIB_RESOLVED_REF
zlib_commit=$ZLIB_COMMIT
zlib_short_commit=$ZLIB_SHORT_COMMIT
gpac_release_sha=$GPAC_RESOLVED_REF
gpac_master_sha=$GPAC_RESOLVED_REF
channels=$channels
EOF
