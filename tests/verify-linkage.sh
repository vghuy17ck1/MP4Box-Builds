#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
target="${2:-${TARGET:-linux64}}"
variant="${3:-${VARIANT:-minimal}}"
if [[ "$variant" == shared-* ]]; then
    exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify-shared.sh" "$artifact_dir" "$target"
fi
exec bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/verify-static.sh" "$artifact_dir" "$target"
