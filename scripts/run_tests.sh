#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

"$GODOT_BIN" --headless --path . -s res://tests/test_gacha.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_adventurer_sim.gd
"$GODOT_BIN" --headless --path . -s res://tests/test_launch.gd
