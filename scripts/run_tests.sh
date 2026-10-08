#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

# Models and icons must be imported before a headless run can load them.
"$GODOT_BIN" --headless --path . --import

run_test() {
  local script="$1"
  shift
  echo "== Running $script =="
  local output
  output=$(mktemp)
  if ! timeout 30s "$GODOT_BIN" --headless --path . -s "res://$script" -- "$@" >"$output" 2>&1; then
    cat "$output"
    rm "$output"
    return 1
  fi
  cat "$output"
  # Godot can report a runtime script error and still exit zero. Such a run
  # has not verified the game, even if its assertions reach the final line.
  if grep -Eq '^ERROR:|^SCRIPT ERROR:' "$output"; then
    echo "Engine/script errors in $script"
    rm "$output"
    return 1
  fi
  rm "$output"
}

run_test tests/test_gacha.gd
run_test tests/test_collection_route.gd
run_test tests/test_earned_income.gd
run_test tests/test_journal.gd
run_test tests/test_identity.gd
run_test tests/test_online_session.gd
run_test tests/test_fishing.gd
run_test tests/test_practice.gd
run_test tests/test_expedition.gd
run_test tests/test_lanternwood.gd
run_test tests/test_lantern_builds.gd
run_test tests/test_reward_chests.gd
run_test tests/test_reward_chests.gd --large-text
run_test tests/test_adventurer_sim.gd
run_test tests/test_launch.gd
run_test tests/test_persistence.gd
run_test tests/test_save_resilience.gd
run_test tests/test_chronicle.gd
run_test tests/test_goals.gd
run_test tests/test_policies.gd
run_test tests/test_loadouts.gd
run_test tests/test_relics.gd
run_test tests/test_gear.gd
run_test tests/test_talents.gd
run_test tests/test_companions.gd
run_test tests/test_companion_roles.gd
run_test tests/test_briarfen.gd
run_test tests/test_boss.gd
run_test tests/test_hunts.gd
run_test tests/test_art.gd
run_test tests/test_ui.gd
run_test tests/test_ui.gd --large-text
run_test tests/test_typography.gd
run_test tests/test_presentation.gd
run_test tests/test_audio.gd
run_test tests/test_wardrobe.gd
run_test tests/test_economy.gd
