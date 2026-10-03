#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

run_test() {
  local script="$1"
  echo "== Running $script =="
  timeout 30s "$GODOT_BIN" --headless --path . -s "res://$script"
}

run_test tests/test_gacha.gd
run_test tests/test_adventurer_sim.gd
run_test tests/test_launch.gd
run_test tests/test_persistence.gd
run_test tests/test_gear.gd
run_test tests/test_talents.gd
