#!/usr/bin/env bash
set -euo pipefail

source_dir="${1:?GPAC source directory required}"
ssl_source="$source_dir/src/utils/downloader_ssl.c"
curl_source="$source_dir/src/utils/downloader_curl.c"

[[ -f "$ssl_source" ]] || { printf 'missing %s\n' "$ssl_source" >&2; exit 1; }
[[ -f "$curl_source" ]] || { printf 'missing %s\n' "$curl_source" >&2; exit 1; }
grep -Fq $'Bool success = GF_TRUE;' "$ssl_source"
grep -Fq $'if (1) {' "$curl_source"
printf 'GPAC TLS verification disabled\n'
