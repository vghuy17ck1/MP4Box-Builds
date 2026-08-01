#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT_DIR

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

if python3 --version >/dev/null 2>&1; then
    export PYTHON_BIN=python3
else
    need_cmd python
    export PYTHON_BIN=python
fi

valid_target() {
    case "$1" in
        linux64|linuxarm64|win64|winarm64) return 0 ;;
        *) return 1 ;;
    esac
}

valid_variant() {
    case "$1" in
        minimal|full) return 0 ;;
        *) return 1 ;;
    esac
}

valid_channel() {
    case "$1" in
        release|master|custom) return 0 ;;
        *) return 1 ;;
    esac
}

target_arch() {
    case "$1" in
        linux64|win64) printf 'x86_64\n' ;;
        linuxarm64|winarm64) printf 'aarch64\n' ;;
        *) die "unknown target: $1" ;;
    esac
}

target_os() {
    case "$1" in
        linux64|linuxarm64) printf 'linux\n' ;;
        win64|winarm64) printf 'mingw32\n' ;;
        *) die "unknown target: $1" ;;
    esac
}

binary_suffix() {
    case "$1" in
        win64|winarm64) printf '.exe\n' ;;
        *) printf '\n' ;;
    esac
}

load_versions() {
    local file="${1:-$ROOT_DIR/versions.env}"
    [[ -f "$file" ]] || die "version file not found: $file"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        local key="${line%%=*}"
        [[ -n "${!key+x}" ]] || export "$line"
    done <"$file"
}

set_reproducible_env() {
    export TZ=UTC LC_ALL=C LANG=C
    export SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
    [[ "$SOURCE_DATE_EPOCH" =~ ^[0-9]+$ ]] || die "SOURCE_DATE_EPOCH must be an integer"
}

json_escape() {
    "$PYTHON_BIN" -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))'
}

write_kv() {
    printf '%s=%s\n' "$1" "$2"
}

source_env_file() {
    local file="$1"
    [[ -f "$file" ]] || die "metadata file not found: $file"
    set -a
    source "$file"
    set +a
}
