#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

generate_build_info() {
    local output="$1" target="$2" variant="$3" channel="$4" metadata="$5" configure_file="$6" patches_file="$7" static_status="$8" format_status="$9" runtime_status="${10}" dash_status="${11}" transcode_status="${12}" effective_license="${13}"
    "$PYTHON_BIN" - "$output" "$target" "$variant" "$channel" "$metadata" "$configure_file" "$patches_file" "$static_status" "$format_status" "$runtime_status" "$dash_status" "$transcode_status" "$effective_license" "$SOURCE_DATE_EPOCH" <<'PY'
import json
import pathlib
import platform
import sys

(output, target, variant, channel, metadata_path, configure_path, patches_path,
 static_status, format_status, runtime_status, dash_status, transcode_status,
 license_name, epoch) = sys.argv[1:]
metadata = {}
for line in pathlib.Path(metadata_path).read_text().splitlines():
    if "=" in line and not line.startswith("#"):
        key, value = line.split("=", 1)
        metadata[key] = value
data = {
    "project_name": "MP4Box-Builds",
    "build_id": f"{target}-{variant}-{channel}-{metadata.get('gpac_short_commit', 'unknown')}",
    "target": target,
    "architecture": metadata.get("architecture", "unknown"),
    "variant": variant,
    "source_channel": channel,
    "gpac_repository": metadata.get("gpac_repository", "https://github.com/gpac/gpac.git"),
    "gpac_requested_ref": metadata.get("gpac_requested_ref", ""),
    "gpac_resolved_ref": metadata.get("gpac_resolved_ref", ""),
    "gpac_release_tag": metadata.get("gpac_release_tag", ""),
    "gpac_commit": metadata.get("gpac_commit", ""),
    "gpac_short_commit": metadata.get("gpac_short_commit", ""),
    "gpac_version": metadata.get("gpac_version", ""),
    "gpac_is_prerelease": metadata.get("gpac_is_prerelease", "false") == "true",
    "gpac_is_development_build": channel in ("master", "custom"),
    "ffmpeg_repository": metadata.get("ffmpeg_repository", "https://github.com/FFmpeg/FFmpeg.git"),
    "ffmpeg_requested_ref": metadata.get("ffmpeg_requested_ref", ""),
    "ffmpeg_resolved_ref": metadata.get("ffmpeg_resolved_ref", ""),
    "ffmpeg_commit": metadata.get("ffmpeg_commit", ""),
    "ffmpeg_short_commit": metadata.get("ffmpeg_short_commit", ""),
    "ffmpeg_version": metadata.get("ffmpeg_version", ""),
    "tls_verification_disabled": metadata.get("tls_verification_disabled", "false") == "true",
    "dependency_versions": {"zlib": metadata.get("zlib_ref", "")},
    "toolchain_name": metadata.get("toolchain_name", ""),
    "toolchain_version": metadata.get("toolchain_version", ""),
    "compiler_version": metadata.get("compiler_version", ""),
    "linker_version": metadata.get("linker_version", ""),
    "libc": metadata.get("libc", ""),
    "windows_runtime_target": metadata.get("windows_runtime_target", "system-dlls-only"),
    "build_timestamp": int(epoch),
    "source_date_epoch": int(epoch),
    "configure_arguments": pathlib.Path(configure_path).read_text().splitlines(),
    "patches_applied": pathlib.Path(patches_path).read_text().splitlines(),
    "effective_license": license_name,
    "static_verification": static_status == "true",
    "binary_format_verification": format_status == "true",
    "runtime_smoke_tested": runtime_status == "true",
    "functional_mkv_to_dash_tested": dash_status == "true",
    "transcoding_tested": transcode_status == "true",
    "host_platform": platform.platform(),
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY
}
