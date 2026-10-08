extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Trails = preload("res://src/data/expedition_catalog.gd")
const Expedition = preload("res://src/state/expedition.gd")
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func hero() -> Node:
	var sim := Sim.new()
	root.add_child(sim)
	return sim
func run() -> void:
	var sim := hero()
	check(not sim.request_expedition("mothwatch") and not sim.request_expedition("moonwell"), "long pursuits require actual preceding trail clears")
	for route in ["greenway", "causeway", "hollow", "rise"]:
		sim.expedition.claimed_routes[route] = true
		sim.expedition.route_clears[route] = 1
	sim.add_gear("Briarheart Charm")
	sim.discovered["Briarheart Charm"] = true # Ordinary boss acquisition records this.
	sim.equip_gear("Briarheart Charm")
	sim.add_gear("Goblin Cleaver")
	sim.equip_gear("Goblin Cleaver")
	sim.add_gear("Wolfskin Hood")
	sim.equip_gear("Wolfskin Hood")
	for route in ["mothwatch", "moonwell", "lamplighter"]:
		check(sim.request_expedition(route), "earned starter preparation can select " + route)
		sim._begin_quest_cycle()
		var duration: float = Trails.node_usec(route) * 5 / 1000000.0
		var before: Dictionary = sim.to_save_dict()
		var restored := hero()
		restored.load_save_dict(JSON.parse_string(JSON.stringify(before, "", true, true)))
		sim.simulate_offline(duration - .1)
		check(sim.expedition.active and sim.reward_chests.pending.is_empty(), "no early gear grant before " + route + " final encounter")
		var mid := hero()
		mid.load_save_dict(JSON.parse_string(JSON.stringify(sim.to_save_dict(), "", true, true)))
		sim.simulate_offline(.1)
		mid.simulate_elapsed(.1)
		restored.simulate_offline(duration)
		check(sim.to_save_dict() == mid.to_save_dict() and sim.to_save_dict() == restored.to_save_dict(), "interrupted and uninterrupted offline trail outcomes agree for " + route)
		check(sim.expedition.recap.get("won", false) and sim.reward_chests.pending.size() == 1, "prepared starter earns a fixed chest on " + route)
		var item: String = Trails.ROUTES[route]["gear"]
		check(sim.gear_count(item) == 0, "secured gear waits for deliberate opening")
		var id: String = sim.reward_chests.pending[0]["id"]
		var gold_before: int = sim.gold
		var receipt: Dictionary = sim.claim_reward_chest(id)
		check(receipt.get("gear", "") == item and sim.gear_count(item) == 1 and sim.has_discovered(item), "opening delivers real gear and permanent discovery")
		var paid: int = sim.gold
		check(paid >= gold_before + int(receipt["gold"]) and sim.claim_reward_chest(id).is_empty() and sim.gold == paid and sim.gear_count(item) == 1, "opening replay cannot duplicate rewards")
		restored.free()
		mid.free()
	check(sim.goals.completed.has("lantern_kit"), "three actual opened gear rewards complete the collection milestone")
	sim.wardrobe.grant("lantern_crook", "expedition:hollow")
	sim.wardrobe.wear("lantern_crook")
	check(sim.equip_gear("Mothglass Spear") and sim.wardrobe.equipped.get("weapon") == "lantern_crook", "ordinary gear changes preserve the chosen outfit")
	check(sim.equip_gear("Mothglass Spear", true) and sim.wardrobe.visible_item("weapon", "Mothglass Spear") == "Mothglass Spear", "explicit equip-and-show reveals the actual earned item")
	sim.equip_gear("Goblin Cleaver")
	sim.request_expedition("mothwatch")
	sim._begin_quest_cycle()
	sim.simulate_offline(7200)
	check(sim.reward_chests.pending[0]["gear"] == "", "owned gear is not promised again on repeat trails")
	sim.claim_reward_chest(sim.reward_chests.pending[0]["id"])
	check(GearCatalog.salvage_tokens("Mothglass Spear") == 0, "replaceable regional gear cannot farm summon tokens")
	sim.sell_gear("Mothglass Spear")
	sim.request_expedition("mothwatch")
	sim._begin_quest_cycle()
	sim.simulate_offline(7200)
	check(sim.reward_chests.pending[0]["gear"] == "Mothglass Spear", "a new successful trail replaces disposed gear")
	sim.claim_reward_chest(sim.reward_chests.pending[0]["id"])
	var build_specs := [["Striker", "Mothglass Spear", "", "", true], ["Guardian", "Goblin Cleaver", "Mooncap Mantle", "", false], ["Lamplighter", "Goblin Cleaver", "", "Lamplighter Seal", false]]
	for spec in build_specs:
		var build := hero()
		build.load_save_dict(sim.to_save_dict())
		build.unequip_gear("Briarheart Charm")
		build.equip_gear(spec[1])
		if not spec[2].is_empty(): build.equip_gear(spec[2])
		if not spec[3].is_empty(): build.equip_gear(spec[3])
		if spec[4]:
			build.hero_level = 2
			check(build.unlock_talent("thick_hide"), "Striker uses one earned talent point")
		for route in ["mothwatch", "moonwell", "lamplighter"]:
			var trial := Expedition.new()
			trial.selected_route = route
			trial.start(build.effective_attack(), build.effective_max_hp(), build.has_gear_effect("thornward"), false, build.has_gear_effect("carapace"), build.has_gear_effect("opportunist"))
			trial.advance(Trails.node_usec(route) * 5 / 1000000.0)
			check(trial.recap["won"], "%s survives %s without a paid rescue or stew" % [spec[0], route])
		build.free()
	var parity := hero()
	parity.load_save_dict(sim.to_save_dict())
	parity.request_expedition("mothwatch")
	parity._begin_quest_cycle()
	var watched := hero()
	watched.load_save_dict(parity.to_save_dict())
	parity.simulate_offline(1440.3)
	watched.simulate_elapsed(1440.3)
	check(parity.to_save_dict() == watched.to_save_dict(), "batched quiet trail movement matches reference steps across a real node boundary")
	var legacy: Dictionary = sim.expedition.to_save_dict()
	legacy.erase("route_clears")
	var old := Expedition.new()
	old.load_save_dict(legacy)
	check(old.route_clears["lamplighter"] == 1, "legacy route flags seed only one proven clear")
	sim.expedition.route_clears["lamplighter"] = 3
	var earned: int = sim.gold
	sim.goals.update(sim)
	check(sim.goals.completed.has("lamp_master") and sim.gold == earned + 25, "third safe return earns a once-only mastery milestone")
	check(sim.goals.update(sim).is_empty(), "mastery cannot repay on refresh")
	check(sim.identity.choose_title("lamp_master", sim), "mastery unlocks a selectable permanent profile title")
	var journal = preload("res://src/state/chronicle.gd").new()
	journal.observe({"type": "goal_completed", "goal": "lamp_master", "title": "Keeper of the lamps", "route": "expedition", "message": "Long milestone text"})
	check(journal.entries[0]["route"] == "identity" and journal.entries[0]["target"] == "lamp_master", "earned-title return milestone opens the actual profile")
	var returned = preload("res://src/ui/return_screen.gd").new()
	check(returned._highlight_title(journal.entries[0]) == "Title earned · Keeper of the Lamps", "return milestone names the earned title concisely")
	root.add_child(returned)
	returned.setup()
	var destinations: Array[String] = []
	returned.destination_requested.connect(func(route: String, _target: String) -> void: destinations.append(route))
	var legacy_title: Dictionary = journal.entries[0].duplicate(true)
	legacy_title["route"] = "expedition"
	legacy_title["target"] = ""
	returned.show_report({"highlights": [legacy_title]}, "Returned")
	returned.list.content.get_child(0).pressed.emit()
	check(destinations == ["identity"], "an older saved title milestone still opens the profile")
	returned.free()
	var titled := hero()
	titled.load_save_dict(JSON.parse_string(JSON.stringify(sim.to_save_dict(), "", true, true)))
	check(titled.identity.title == "lamp_master" and titled.identity.display_name().contains("Keeper of the Lamps"), "earned title selection survives save/reload")
	titled.free()
	for node in [sim, parity, watched]: node.free()
	print("Lantern builds complete: %d failure(s)" % failures)
	quit(failures)
