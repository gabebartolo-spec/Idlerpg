#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot was not found. Install Godot 4.x or set GODOT_BIN to its executable." >&2
  exit 2
fi

echo "Also validating content (no engine needed):"
python3 "$ROOT_DIR/tools/validate_content.py"

exec "$GODOT_BIN" --headless --path "$ROOT_DIR" --script res://tests/test_runner.gd
