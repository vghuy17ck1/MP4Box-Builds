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
    for binary in "$mp4box" "$gpac"; do
        file_output="$(file "$binary")"
        header_output="$(readelf -h "$binary")"
        program_output="$(readelf -l "$binary")"
        dynamic_output="$(readelf -d "$binary")"
        case "$target" in
            linux64) grep -Eiq 'x86-64|x86_64' <<<"$file_output $header_output" || { printf 'wrong Linux x86-64 architecture: %s\n' "$binary" >&2; exit 1; } ;;
            linuxarm64) grep -Eiq 'aarch64|ARM aarch64' <<<"$file_output $header_output" || { printf 'wrong Linux ARM64 architecture: %s\n' "$binary" >&2; exit 1; } ;;
        esac
        if grep -q 'INTERP' <<<"$program_output"; then printf 'ELF interpreter present: %s\n' "$binary" >&2; exit 1; fi
        if grep -q 'NEEDED' <<<"$dynamic_output"; then printf 'ELF shared dependency present: %s\n' "$binary" >&2; exit 1; fi
        if ldd_output="$(ldd "$binary" 2>&1)"; then
            [[ "$ldd_output" == *"not a dynamic executable"* ]] || { printf 'dynamic dependency detected: %s\n%s\n' "$binary" "$ldd_output" >&2; exit 1; }
        else
            grep -Eq 'not a dynamic executable|statically linked' <<<"$ldd_output" || { printf 'could not prove static linkage: %s\n%s\n' "$binary" "$ldd_output" >&2; exit 1; }
        fi
    done
else
    need_cmd file
    if command -v llvm-readobj >/dev/null 2>&1; then
        for binary in "$mp4box" "$gpac"; do
            header_output="$(llvm-readobj --file-headers "$binary")"
            imports_output="$(llvm-readobj --coff-imports "$binary")"
            if [[ "$target" == win64 ]]; then
                grep -Eiq 'AMD64|x86_64|x86-64' <<<"$header_output" || { printf 'wrong Windows x86-64 architecture: %s\n' "$binary" >&2; exit 1; }
            else
                grep -Eiq 'ARM64|AArch64' <<<"$header_output" || { printf 'wrong Windows ARM64 architecture: %s\n' "$binary" >&2; exit 1; }
            fi
            if grep -Eiq 'libgpac|avcodec|avformat|avutil|swscale|swresample|openssl|libgcc|libstdc\+\+|mingw' <<<"$imports_output"; then printf 'forbidden non-system DLL import: %s\n' "$binary" >&2; exit 1; fi
        done
    elif command -v objdump >/dev/null 2>&1; then
        for binary in "$mp4box" "$gpac"; do
            imports_output="$(objdump -p "$binary")"
            if grep -Eiq 'libgpac|avcodec|avformat|avutil|swscale|swresample|openssl|libgcc|libstdc\+\+|mingw' <<<"$imports_output"; then printf 'forbidden non-system DLL import: %s\n' "$binary" >&2; exit 1; fi
        done
    else
        printf 'llvm-readobj or objdump is required for PE verification\n' >&2
        exit 1
    fi
fi
printf 'static and binary-format verification passed for %s\n' "$target"
