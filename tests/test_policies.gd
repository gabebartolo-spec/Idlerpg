extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func hero(policy: String) -> Node:
	var sim := Sim.new()
	root.add_child(sim)
	sim.drop_seed = 194
	sim.quest_cycles_completed = 1
	sim.set_adventure_policy(policy)
	sim._begin_quest_cycle()
	return sim
func run() -> void:
	for policy in ["safe", "push", "hunt"]:
		var sim := hero(policy)
		var start: Dictionary = sim.to_save_dict()
		var offline := hero(policy)
		offline.load_save_dict(start)
		sim.simulate_elapsed(1800.0)
		offline.simulate_offline(1800.0)
		check(sim.to_save_dict() == offline.to_save_dict(), "%s policy has identical watched/offline outcomes" % policy)
		check(sim.quest_cycles_completed > 1, "%s policy continues making progress" % policy)
		if policy == "safe":
			check(sim.thornback_rank == 0 and not sim.inventory.has("Briar Sap"), "safe farming trades boss loot for lower-risk Greenway encounters")
		if policy == "push":
			check(sim.thornback_rank > 0 and sim.deaths > 0, "push progression attempts stronger bosses and carries measurable risk")
	var hunted := hero("hunt")
	hunted.set_hunt_target("briarhook")
	hunted._begin_quest_cycle()
	var boundary: int = hunted.cycle_starts
	while hunted.cycle_starts == boundary:
		hunted.advance(0.1)
	check(hunted.thornback_rank == 0 and int(hunted.inventory.get("Briar Sap", 0)) == 4, "Briarhook outing hunts Briarlings without challenging the boss")
	var changing := hero("push")
	changing.set_adventure_policy("safe")
	check(changing.outing_policy == "push" and changing.adventure_policy == "safe", "policy changes preserve current encounter and apply next outing")
	changing._begin_quest_cycle()
	check(changing.quest_kind == "rangers_errand", "next outing honors the selected safe policy")
	changing.activity = "looting"
	changing.hero_hp = 1
	changing._finish_looting()
	check(changing.policy_retreat and changing.destination_id == "town", "low-health farming automatically returns instead of taking another fight")
	var gold: int = changing.gold
	var quests: int = changing.quest_cycles_completed
	changing._complete_quest()
	check(changing.gold == gold and changing.quest_cycles_completed == quests and changing.activity == "resting", "retreat keeps loot without an unfinished quest reward")
	var invalid: Dictionary = changing.to_save_dict()
	invalid["adventure_policy"] = "unknown"
	invalid["outing_policy"] = "unknown"
	changing.load_save_dict(invalid)
	check(changing.adventure_policy == "push" and changing.outing_policy == "push" and not changing.set_adventure_policy("unknown"), "invalid policies recover safely and cannot be selected")
	print("Policy tests complete: %d failure(s)" % failures)
	quit(failures)
