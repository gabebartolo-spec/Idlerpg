#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

# Models and icons must be imported before a headless run can load them.
"$GODOT_BIN" --headless --path . --import

run_test() {
  local script="$1"
  echo "== Running $script =="
  timeout 30s "$GODOT_BIN" --headless --path . -s "res://$script"
}

run_test tests/test_gacha.gd
run_test tests/test_adventurer_sim.gd
run_test tests/test_launch.gd
run_test tests/test_persistence.gd
run_test tests/test_save_resilience.gd
run_test tests/test_chronicle.gd
run_test tests/test_gear.gd
run_test tests/test_talents.gd
run_test tests/test_companions.gd
run_test tests/test_briarfen.gd
run_test tests/test_boss.gd
run_test tests/test_hunts.gd
run_test tests/test_art.gd
run_test tests/test_ui.gd
run_test tests/test_economy.gd
