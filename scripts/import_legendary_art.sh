#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
BLENDER_BIN="${BLENDER_BIN:-blender}"
if ! command -v "$BLENDER_BIN" >/dev/null 2>&1; then
  for candidate in "/c/Program Files/Blender Foundation"/Blender*/blender.exe /Applications/Blender.app/Contents/MacOS/Blender; do
    if [ -x "$candidate" ]; then BLENDER_BIN="$candidate"; fi
  done
fi
if [[ " ${*} " != *" --preflight "* ]]; then
  for model_id in crownblade starforged_helm titanheart_plate; do
    source="art/imported/sources/${model_id}_studio_meshopt.glb"
    decoded="art/imported/sources/${model_id}.glb"
    if [ -f "$source" ] && [ ! -f "$decoded" ]; then
      if [ ! -d tools/art/glb_decode/node_modules ]; then
        echo "Install the pinned decoder first: npm ci --ignore-scripts --prefix tools/art/glb_decode" >&2
        exit 1
      fi
      node tools/art/glb_decode/decode.mjs "$source" "$decoded"
    fi
  done
fi
"$BLENDER_BIN" --background --factory-startup --python-exit-code 1 --python tools/art/import_glb.py -- "$@"
