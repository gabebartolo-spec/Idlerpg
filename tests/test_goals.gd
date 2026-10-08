extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Goals = preload("res://src/state/adventure_goals.gd")
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func hero() -> Node:
	var sim := Sim.new()
	root.add_child(sim)
	return sim
func run() -> void:
	var sim := hero()
	check(sim.goals.cards(sim).size() == 3 and sim.goals.completed.is_empty(), "new adventurer has three honest unfinished goals")
	check(sim.set_tracked_goal("world_collection") and not sim.set_tracked_goal("daily"), "one valid pursuit can be tracked")
	sim.add_gear("Goblin Cleaver")
	check(not sim.goals.completed.has("prepare"), "owning a weapon is not confused with equipping it")
	var before: int = sim.gold
	sim.equip_gear("Goblin Cleaver")
	check(sim.gold == before + Goals.REWARD_GOLD and sim.goals.completed.has("prepare"), "preparation grants its gold once")
	sim.unequip_gear("Goblin Cleaver")
	sim.equip_gear("Goblin Cleaver")
	check(sim.gold == before + Goals.REWARD_GOLD, "unequip and re-equip cannot farm the reward")
	var state: Dictionary = sim.to_save_dict()
	var a := hero()
	var b := hero()
	a.load_save_dict(state)
	b.load_save_dict(state)
	a.simulate_elapsed(1800.0)
	b.simulate_offline(1800.0)
	check(a.to_save_dict() == b.to_save_dict(), "goal rewards and chronicle are identical watched and offline")
	check(b.goals.completed.has("boss") and b.chronicle.seen.has("goal:boss"), "offline boss goal produces a real return milestone")
	for item in ["Briarheart Charm", "Briarhook", "Thornback Carapace"]:
		b._discover(item)
	check(b.goals.completed.has("world_collection"), "permanent discoveries finish the collection pursuit")
	var earned: int = b.gold
	var reloaded := hero()
	reloaded.load_save_dict(JSON.parse_string(JSON.stringify(b.to_save_dict(), "", true, true)))
	reloaded._discover("Briarhook")
	check(reloaded.gold == earned and reloaded.goals.tracked == "world_collection", "reload preserves tracking and once-only completion")
	var legacy: Dictionary = b.to_save_dict()
	legacy.erase("goals")
	reloaded.load_save_dict(legacy)
	reloaded.set_tracked_goal("boss")
	check(reloaded.gold == earned and reloaded.goals.completed.size() == 3, "older saves keep completed criteria without retroactive reward farming")
	print("Goal tests complete: %d failure(s)" % failures)
	quit(failures)
