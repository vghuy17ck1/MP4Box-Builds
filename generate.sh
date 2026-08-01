#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output="${1:-$ROOT_DIR/work/generated}"
mkdir -p "$output"
python_bin=python3
"$python_bin" --version >/dev/null 2>&1 || python_bin=python
"$python_bin" - "$output" <<'PY'
import json
import pathlib
import sys
targets = ["linux64", "linuxarm64", "win64", "winarm64"]
variants = ["minimal", "full"]
channels = ["release", "master"]
path = pathlib.Path(sys.argv[1])
matrix = [{"target": t, "variant": v, "channel": c} for c in channels for t in targets for v in variants]
(path / "matrix.json").write_text(json.dumps(matrix, indent=2) + "\n")
PY
