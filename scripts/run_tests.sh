#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

# Models and icons must be imported before a headless run can load them.
"$GODOT_BIN" --headless --path . --import

"$GODOT_BIN" --headless --path . -s res://tests/test_gacha.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_adventurer_sim.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_launch.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_persistence.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_gear.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_art.gd
