extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func _run() -> void:
	var sim := Sim.new()
	root.add_child(sim)
	var before: Dictionary = sim.report_counters()
	sim.identity.rename("  My    adventurer\n\t ")
	check(sim.identity.adventurer_name == "My adventurer", "local names normalize whitespace and remove controls")
	sim.identity.rename("A".repeat(100))
	check(sim.identity.adventurer_name.length() == 24, "long names are bounded for portrait display")
	sim.identity.rename(" ")
	check(sim.identity.adventurer_name == "Adventurer", "blank names retain a usable default")
	check(not sim.identity.choose_title("thornbreaker", sim), "earned prestige cannot be selected before its accomplishment")
	sim.quest_cycles_completed = 1
	check(sim.identity.choose_title("scout", sim), "completing the opening errand unlocks Scout")
	sim.thornback_rank = 1
	check(sim.identity.choose_title("thornbreaker", sim), "first boss victory unlocks Thornbreaker")
	sim.identity.rename("Moss Walker")
	sim.identity.set_palette("moss")
	var saved: Dictionary = sim.to_save_dict()
	var restored := Sim.new()
	root.add_child(restored)
	restored.load_save_dict(JSON.parse_string(JSON.stringify(saved)))
	check(restored.identity.to_save_dict() == sim.identity.to_save_dict(), "name, free appearance and earned title persist through JSON")
	check(sim.effective_attack() == restored.effective_attack() and sim.effective_max_hp() == restored.effective_max_hp(), "identity leaves combat stats unchanged")
	saved.erase("identity")
	restored.load_save_dict(saved)
	check(restored.identity.adventurer_name == "Adventurer" and restored.thornback_rank == 1, "older saves retain progression and gain a neutral default identity")
	var watch := Sim.new()
	var offline := Sim.new()
	root.add_child(watch)
	root.add_child(offline)
	watch.identity.rename("Fern")
	watch.identity.set_palette("slate")
	offline.load_save_dict(watch.to_save_dict())
	watch.simulate_elapsed(3600.0)
	offline.simulate_offline(3600.0)
	check(watch.to_save_dict() == offline.to_save_dict(), "identity persists across equal watched and offline progress")
	print("Identity tests complete: %d failure(s)" % failures)
	quit(failures)
