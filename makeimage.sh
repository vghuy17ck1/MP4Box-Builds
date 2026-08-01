#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/versions.env"
target="${1:?target required}"
case "$target" in linux64|linuxarm64|win64|winarm64) ;; *) printf 'unknown target: %s\n' "$target" >&2; exit 1 ;; esac
command -v docker >/dev/null 2>&1 || { printf 'docker is required\n' >&2; exit 1; }
base_tag="${TOOLCHAIN_VERSION:-2024-01-21}"
docker buildx build --load -f "$ROOT_DIR/images/base/Dockerfile" -t "mp4box-build-base:$base_tag" "$ROOT_DIR"
docker buildx build --load --build-arg TARGET="$target" --build-arg BASE_IMAGE="mp4box-build-base:$base_tag" -f "$ROOT_DIR/images/$target/Dockerfile" -t "mp4box-build:$target" "$ROOT_DIR"
