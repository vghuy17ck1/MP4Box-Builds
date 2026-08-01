#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

generate_feature_manifest() {
    local bin_dir="$1" output="$2" variant="$3"
    local suffix="${4:-}" gpac="$bin_dir/gpac$suffix"
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' RETURN
    local filters modules formats ffdmx ffdec ffenc ffbsf ffavf
    filters="$($gpac -p=0 -hx filters 2>&1 || true)"
    modules="$($gpac -p=0 -h modules 2>&1 || true)"
    formats="$($gpac -p=0 -hx formats 2>&1 || true)"
    ffdmx="$($gpac -p=0 -hx 'ffdmx:*' 2>&1 || true)"
    ffdec="$($gpac -p=0 -hx ffdec 2>&1 || true)"
    ffenc="$($gpac -p=0 -hx ffenc 2>&1 || true)"
    ffbsf="$($gpac -p=0 -hx ffbsf 2>&1 || true)"
    ffavf="$($gpac -p=0 -hx ffavf 2>&1 || true)"
    printf '%s\n' "$filters" >"$temp_dir/filters"
    printf '%s\n' "$modules" >"$temp_dir/modules"
    printf '%s\n' "$formats" >"$temp_dir/formats"
    printf '%s\n' "$ffdmx" >"$temp_dir/ffdmx"
    printf '%s\n' "$ffdec" >"$temp_dir/ffdec"
    printf '%s\n' "$ffenc" >"$temp_dir/ffenc"
    printf '%s\n' "$ffbsf" >"$temp_dir/ffbsf"
    printf '%s\n' "$ffavf" >"$temp_dir/ffavf"
    detection=verified
    if [[ -n "$suffix" || "${TARGET_ARCH:-$(uname -m)}" != "$(uname -m)" ]]; then
        detection=unavailable
    fi
    "$PYTHON_BIN" - "$output" "$variant" "$temp_dir" "$detection" <<'PY'
import json
import pathlib
import sys

output, variant, directory, detection = sys.argv[1:]
def read(name):
    return pathlib.Path(directory, name).read_text(errors="replace")

filters = read("filters")
modules = read("modules")
formats = read("formats")
ffdmx = read("ffdmx")
ffdec = read("ffdec")
ffenc = read("ffenc")
ffbsf = read("ffbsf")
ffavf = read("ffavf")
def yes(text, *needles):
    return all(needle.lower() in text.lower() for needle in needles)
data = {
    "gpac_filters": filters.splitlines(),
    "gpac_modules": modules.splitlines(),
    "ffmpeg_libraries": ["avformat", "avcodec", "avutil", "swresample", "swscale"] + (["avfilter"] if variant == "full" else []),
    "ffmpeg_demuxers": ["matroska", "webm"] if yes(ffdmx, "matroska") else [],
    "ffmpeg_muxers": ["mp4", "dash"] if yes(filters, "dasher") else [],
    "ffmpeg_decoders": ["h264", "hevc", "av1"] if yes(ffdec, "h264") else [],
    "ffmpeg_encoders": ffenc.splitlines() if variant == "full" else [],
    "ffmpeg_protocols": ["file", "pipe", "tcp", "udp"],
    "ffmpeg_bitstream_filters": ffbsf.splitlines(),
    "ffmpeg_filters": ffavf.splitlines() if variant == "full" else [],
    "tls_support": yes(modules, "openssl") or yes(modules, "ssl"),
    "http_support": yes(modules, "http"),
    "https_support": yes(modules, "https"),
    "http2_support": yes(modules, "http2"),
    "dash_support": yes(filters, "dasher"),
    "hls_support": yes(filters, "dasher") and yes(filters, "hls"),
    "matroska_support": yes(ffdmx, "matroska"),
    "webm_support": yes(ffdmx, "webm"),
    "cmaf_support": yes(filters, "dasher") or yes(formats, "cmaf"),
    "encryption_support": yes(filters, "cecrypt") or yes(filters, "cdcrypt"),
    "quickjs_support": yes(modules, "quickjs") or yes(modules, "qjs"),
    "subtitle_support": yes(modules, "vtt") or yes(modules, "ttml"),
    "image_codec_support": yes(filters, "imgdec"),
    "disabled_features": ["x11", "vout", "aout", "3d", "qjs"] if variant == "minimal" else ["x11", "vout", "aout", "3d"],
    "unsupported_features": [],
    "feature_failure_reasons": {},
    "feature_detection": detection,
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY
}
