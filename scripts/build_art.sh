#!/usr/bin/env bash
# Rebuild the game's 3D art with Blender. See docs/ART_PIPELINE.md.
#   scripts/build_art.sh                    everything
#   scripts/build_art.sh --only iron_sword  just these models
set -euo pipefail

cd "$(dirname "$0")/.."

BLENDER_BIN="${BLENDER_BIN:-blender}"
if ! command -v "$BLENDER_BIN" >/dev/null 2>&1; then
	for candidate in "/c/Program Files/Blender Foundation"/Blender*/blender.exe /Applications/Blender.app/Contents/MacOS/Blender; do
		if [ -x "$candidate" ]; then
			BLENDER_BIN="$candidate"
		fi
	done
fi

"$BLENDER_BIN" --background --factory-startup --python-exit-code 1 --python tools/art/build.py -- "$@"
