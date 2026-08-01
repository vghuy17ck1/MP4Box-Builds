#!/usr/bin/env bash
set -euo pipefail

prefix="${1:?prefix required}"
[[ -d "$prefix" ]] || { printf 'missing prefix: %s\n' "$prefix" >&2; exit 1; }
if find "$prefix" -type f \( -name '*.so' -o -name '*.so.*' -o -name '*.dylib' -o -name '*.dll' \) -print -quit | grep -q .; then
    printf 'shared library found in target prefix\n' >&2
    find "$prefix" -type f \( -name '*.so' -o -name '*.so.*' -o -name '*.dylib' -o -name '*.dll' \) -print >&2
    exit 1
fi
