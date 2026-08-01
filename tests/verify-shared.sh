#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
target="${2:-${TARGET:-linux64}}"
suffix=""
[[ "$target" == win64 || "$target" == winarm64 ]] && suffix=.exe
mp4box="$artifact_dir/bin/MP4Box$suffix"
gpac="$artifact_dir/bin/gpac$suffix"
[[ -f "$mp4box" && -f "$gpac" ]] || { printf 'missing binaries in %s\n' "$artifact_dir" >&2; exit 1; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { printf 'required verifier missing: %s\n' "$1" >&2; exit 1; }; }
if [[ "$target" == linux64 || "$target" == linuxarm64 ]]; then
    need_cmd file
    need_cmd readelf
    [[ -d "$artifact_dir/lib" ]] || { printf 'shared library directory missing\n' >&2; exit 1; }
    find "$artifact_dir/lib" -type f \( -name '*.so' -o -name '*.so.*' \) -print -quit | grep -q . || { printf 'shared ELF libraries missing\n' >&2; exit 1; }
    for binary in "$mp4box" "$gpac"; do
        file_output="$(file "$binary")"
        header_output="$(readelf -h "$binary")"
        program_output="$(readelf -l "$binary")"
        dynamic_output="$(readelf -d "$binary")"
        case "$target" in
            linux64) grep -Eiq 'x86-64|x86_64' <<<"$file_output $header_output" || { printf 'wrong Linux x86-64 architecture: %s\n' "$binary" >&2; exit 1; } ;;
            linuxarm64) grep -Eiq 'aarch64|ARM aarch64' <<<"$file_output $header_output" || { printf 'wrong Linux ARM64 architecture: %s\n' "$binary" >&2; exit 1; } ;;
        esac
        grep -q 'INTERP' <<<"$program_output" || { printf 'ELF interpreter missing: %s\n' "$binary" >&2; exit 1; }
        grep -q 'NEEDED' <<<"$dynamic_output" || { printf 'ELF shared dependency missing: %s\n' "$binary" >&2; exit 1; }
        grep -Eq 'RPATH|RUNPATH' <<<"$dynamic_output" || { printf 'relocatable ELF runtime path missing: %s\n' "$binary" >&2; exit 1; }
        grep -Fq '/home/runner/' <<<"$dynamic_output" && { printf 'runner path embedded in ELF: %s\n' "$binary" >&2; exit 1; }
    done
else
    need_cmd file
    find "$artifact_dir/bin" -type f -iname '*.dll' -print -quit | grep -q . || { printf 'shared Windows DLLs missing\n' >&2; exit 1; }
    if command -v llvm-readobj >/dev/null 2>&1; then
        for binary in "$mp4box" "$gpac"; do
            header_output="$(llvm-readobj --file-headers "$binary")"
            if [[ "$target" == win64 ]]; then
                grep -Eiq 'AMD64|x86_64|x86-64' <<<"$header_output" || { printf 'wrong Windows x86-64 architecture: %s\n' "$binary" >&2; exit 1; }
            else
                grep -Eiq 'ARM64|AArch64' <<<"$header_output" || { printf 'wrong Windows ARM64 architecture: %s\n' "$binary" >&2; exit 1; }
            fi
        done
    elif command -v objdump >/dev/null 2>&1; then
        for binary in "$mp4box" "$gpac"; do objdump -p "$binary" >/dev/null; done
    else
        printf 'llvm-readobj or objdump is required for PE verification\n' >&2
        exit 1
    fi
fi
printf 'shared linkage and binary-format verification passed for %s\n' "$target"
