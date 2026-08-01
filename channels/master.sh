#!/usr/bin/env bash
set -euo pipefail
SOURCE_CHANNEL=master exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/util/resolve-refs.sh"

