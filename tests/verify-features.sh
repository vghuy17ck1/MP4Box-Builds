#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:?artifact directory required}"
variant="${2:-${VARIANT:-minimal}}"
manifest="$artifact_dir/FEATURES.json"
[[ -f "$manifest" ]] || { printf 'missing feature manifest\n' >&2; exit 1; }
if python3 --version >/dev/null 2>&1; then python_bin=python3; else python_bin=python; fi
"$python_bin" - "$manifest" "$variant" <<'PY'
import json
import pathlib
import sys
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
variant = sys.argv[2]
required = ("matroska_support", "webm_support", "dash_support", "cmaf_support")
missing = [key for key in required if data.get(key) is False]
if missing and data.get("feature_detection") != "unavailable":
    raise SystemExit("missing required detected features: " + ", ".join(missing))
if variant == "full" and data.get("feature_detection") != "unavailable" and not data.get("ffmpeg_encoders"):
    raise SystemExit("full feature manifest has no FFmpeg encoders")
print("feature manifest is valid")
PY
