#!/usr/bin/env bash
set -euo pipefail

source_dir="${1:?FFmpeg source directory required}"
tls_header="$source_dir/libavformat/tls.h"
tls_source="$source_dir/libavformat/tls.c"

[[ -f "$tls_header" ]] || { printf 'missing %s\n' "$tls_header" >&2; exit 1; }
[[ -f "$tls_source" ]] || { printf 'missing %s\n' "$tls_source" >&2; exit 1; }
grep -Fq '#define TLS_VERIFY_DEFAULT 0' "$tls_header"
grep -Fq '    c->verify = 0;' "$tls_source"
grep -Fq 'AV_OPT_TYPE_BOOL, { .i64 = 0 }, 0, 0, .flags = TLS_OPTFL' "$tls_header"
if grep -Fq '#define TLS_VERIFY_DEFAULT 1' "$tls_header"; then
    printf 'TLS verification default is enabled\n' >&2
    exit 1
fi
printf 'TLS verification disabled\n'
