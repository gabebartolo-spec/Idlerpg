#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot was not found. Install Godot 4.3+ or set GODOT_BIN to its executable." >&2
  exit 2
fi

echo "Also validating content (no engine needed):"
python3 "$ROOT_DIR/tools/validate_content.py"

# Tests create/delete saves. Keep their user:// separate from the player's data.
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
export HOME="$TEST_DIR"
export XDG_DATA_HOME="$TEST_DIR/data"
export XDG_CONFIG_HOME="$TEST_DIR/config"
export XDG_CACHE_HOME="$TEST_DIR/cache"

run_suite() {
  local script="$1" marker="$2"
  local log="$TEST_DIR/godot.log"
  # Godot can return 0 despite GDScript errors, so inspect output as well as status.
  # The frame cap also prevents a broken asynchronous smoke test hanging forever.
  if ! "$GODOT_BIN" --headless --path "$ROOT_DIR" --quit-after 600 --script "$script" >"$log" 2>&1; then
    cat "$log"
    return 1
  fi
  cat "$log"
  if grep -Eq 'SCRIPT ERROR:|^ERROR:' "$log" || ! grep -Fq "$marker" "$log"; then
    echo "Godot errors or incomplete test run: $script" >&2
    return 1
  fi
}

run_suite res://tests/test_runner.gd "ALL TESTS PASSED"
run_suite res://tests/test_launch.gd "LAUNCH TESTS PASSED"
