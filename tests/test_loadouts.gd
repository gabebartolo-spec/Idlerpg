extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func run() -> void:
	var sim := Sim.new()
	var game := Game.new()
	root.add_child(sim)
	root.add_child(game)
	sim.hero_level = 10
	sim.add_gear("Goblin Cleaver")
	sim.equip_gear("Goblin Cleaver")
	sim.unlock_talent("heavy_hand")
	sim.unlock_talent("sharpened_edge")
	game.collection["companions"] = {"Stable Hound": 1}
	sim.set_active_companion("Stable Hound")
	check(sim.loadouts.save_current(0, "Trail slayer", sim), "a named equipment/talent/companion build can be saved free")
	check(not sim.loadouts.save_current(3, "Fourth", sim) and not sim.loadouts.save_current(1, "  ", sim), "only three named slots exist")
	sim.unequip_gear("Goblin Cleaver")
	sim.reset_talents()
	sim.clear_active_companion()
	sim.hero_hp = 5
	sim.last_stand_used = true
	sim.second_wind_used = true
	sim.hero_attack_count = 7
	var owned: Dictionary = sim.gear_inventory.duplicate()
	var applied: Dictionary = sim.loadouts.apply(0, sim, game)
	check(applied["ok"] and sim.equipped_item("weapon") == "Goblin Cleaver" and sim.has_talent("sharpened_edge") and sim.active_companion == "Stable Hound", "valid preset applies all parts together")
	check(sim.gear_inventory == owned and sim.hero_hp == 5 and sim.last_stand_used and sim.second_wind_used and sim.hero_attack_count == 7, "application duplicates no gear and grants no healing or fresh encounter procs")
	sim.unequip_gear("Goblin Cleaver")
	sim.sell_gear("Goblin Cleaver")
	sim.add_gear("Iron Sword")
	sim.equip_gear("Iron Sword")
	var before: Dictionary = sim.to_save_dict()
	var missing: Dictionary = sim.loadouts.preview(0, sim, game)
	check(not missing["ok"] and "Goblin Cleaver" in missing["missing"], "sold gear is previewed as missing")
	check(not sim.loadouts.apply(0, sim, game)["ok"] and sim.to_save_dict() == before, "failed application makes no partial change")
	check(sim.loadouts.apply(0, sim, game, true)["ok"] and sim.equipped_item("weapon") == "Iron Sword", "explicit available-pieces mode keeps the current owned replacement")
	sim.loadouts.presets["1"] = {"name": "Broken", "equipment": {}, "talents": {"executioner": true}, "companion": ""}
	before = sim.to_save_dict()
	check(not sim.loadouts.apply(1, sim, game, true)["ok"] and sim.to_save_dict() == before, "invalid prerequisites fail atomically even with fallback")
	game.collection["companions"] = {}
	check(not sim.loadouts.preview(0, sim, game)["ok"], "unowned companions cannot be applied")
	var restored := Sim.new()
	root.add_child(restored)
	restored.load_save_dict(JSON.parse_string(JSON.stringify(sim.to_save_dict(), "", true, true)))
	check(restored.loadouts.to_save_dict() == sim.loadouts.to_save_dict(), "preset names and choices survive JSON persistence")
	var start: Dictionary = sim.to_save_dict()
	var stepped := Sim.new()
	var offline := Sim.new()
	root.add_child(stepped)
	root.add_child(offline)
	stepped.load_save_dict(start)
	offline.load_save_dict(start)
	stepped.simulate_elapsed(900.0)
	offline.simulate_offline(900.0)
	check(stepped.to_save_dict() == offline.to_save_dict(), "saved builds preserve watched/offline parity")
	print("Loadout tests complete: %d failure(s)" % failures)
	quit(failures)
