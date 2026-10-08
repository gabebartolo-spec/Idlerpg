extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Expedition = preload("res://src/state/expedition.gd")
const Catalog = preload("res://src/data/expedition_catalog.gd")
const Art = preload("res://src/data/art_catalog.gd")
const Gear = preload("res://src/data/gear_catalog.gd")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func hero() -> Node:
	var sim := Sim.new()
	root.add_child(sim)
	return sim

func prepared_hero() -> Node:
	var sim := hero()
	sim.expedition.claimed_routes["greenway"] = true
	sim.add_gear("Briarheart Charm")
	# Ordinary boss acquisition records this discovery before the gear is saved.
	sim.discovered["Briarheart Charm"] = true
	sim.equip_gear("Briarheart Charm")
	sim.fishing.prepared = 1
	return sim

func trial(route: String, attack: int, health: int, protected: bool, stew: bool) -> RefCounted:
	var run := Expedition.new()
	run.selected_route = route
	run.start(attack, health, protected, stew)
	run.advance(float(Catalog.node_usec(route) * 5) / 1000000)
	return run

func _run() -> void:
	var locked := hero()
	check(not locked.request_expedition("hollow") and not locked.request_expedition("rise"), "new trails require real preceding route clears")
	locked.expedition.claimed_routes["greenway"] = true
	check(locked.request_expedition("hollow") and not locked.request_expedition("rise"), "Greenway opens Hollow while Rise still requires both deeper trails")
	var bare := trial("hollow", 6, 36, false, false)
	var protected := trial("hollow", 6, 36, true, true)
	var attack_build := trial("hollow", 22, 36, false, false)
	check(not bare.recap["won"] and bare.gold_earned == 12, "an unprepared beginner keeps found cache gold but cannot bypass the keeper")
	check(protected.recap["won"] and protected.stew_used and protected.gold_earned == 92, "earned Thornward plus free stew makes Hollow attainable at starting stats")
	check(attack_build.recap["won"], "a stronger attack build gives a different viable route through Hollow")
	check(not trial("rise", 6, 36, true, true).recap["won"] and trial("rise", 8, 42, true, true).recap["won"], "Rise asks for a modest earned build improvement rather than a paid gate")
	var watched := prepared_hero()
	var offline := prepared_hero()
	watched.request_expedition("hollow")
	offline.request_expedition("hollow")
	watched._begin_quest_cycle()
	offline._begin_quest_cycle()
	watched.simulate_elapsed(899.9)
	offline.simulate_offline(899.9)
	check(watched.to_save_dict() == offline.to_save_dict() and offline.expedition.active and offline.expedition.node == 4, "15-minute trail clocks, path, preparation and caches match before the final encounter")
	check(not offline.wardrobe.owned.has("lantern_crook"), "cosmetic completion reward is not paid before the keeper is cleared")
	var checkpoint: Dictionary = JSON.parse_string(JSON.stringify(offline.to_save_dict()))
	var resumed := hero()
	resumed.load_save_dict(checkpoint)
	var event_saves: Array[Dictionary] = []
	offline.event_emitted.connect(func(event: Dictionary) -> void:
		if event["type"] == "expedition_completed":
			event_saves.append(offline.to_save_dict()))
	watched.simulate_elapsed(.1)
	offline.simulate_offline(.1)
	resumed.simulate_offline(.1)
	check(watched.to_save_dict() == offline.to_save_dict() and resumed.to_save_dict() == offline.to_save_dict(), "long fractional checkpoint resumes to identical final rewards and ownership")
	check(offline.gold == 12 and not offline.wardrobe.owned.has("lantern_crook") and offline.reward_chests.pending.size() == 1, "first clear banks cache gold and secures completion contents in one chest")
	check(event_saves.size() == 1 and event_saves[0]["reward_chests"]["pending"].size() == 1 and event_saves[0]["gold"] == 12, "event-triggered save sees a settled chest before final contents are claimed")
	for claimant in [watched, offline, resumed]:
		claimant.claim_reward_chest(claimant.reward_chests.pending[0]["id"])
	check(offline.gold == 92 and offline.wardrobe.owned["lantern_crook"]["sources"] == ["expedition:hollow"], "opening pays the original total and permanently grants the earned look")
	var restored := hero()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(event_saves[0])))
	restored.claim_reward_chest(restored.reward_chests.pending[0]["id"])
	check(restored.wardrobe.wear("lantern_crook") and restored.wardrobe.visible_item("weapon", "") == "Lantern Crook", "earned cosmetic survives JSON restore and is wearable without owning combat gear")
	check(not Gear.has_item("Lantern Crook") and not Gear.has_item("Keeper Crown"), "new earned looks never enter the stat or summon economy")
	var base_attack: int = restored.effective_attack()
	restored.wardrobe.clear("weapon")
	check(restored.effective_attack() == base_attack, "wearing the lantern changes presentation without changing damage")
	var sources: Dictionary = offline.wardrobe.owned.duplicate(true)
	offline.request_expedition("hollow")
	offline._begin_quest_cycle()
	offline.simulate_offline(900)
	check(offline.expedition.gold_earned == 37 and offline.wardrobe.owned == sources, "repeat trail pays only its smaller disclosed gold reward and cannot repeat cosmetic provenance")
	offline.expedition.claimed_routes["causeway"] = true
	check(offline.request_expedition("rise"), "clearing both prerequisite trails opens Keeper's Rise")
	offline.fishing.prepared = 1
	offline._begin_quest_cycle()
	offline.simulate_offline(1800)
	for receipt in offline.reward_chests.pending.duplicate(true):
		offline.claim_reward_chest(receipt["id"])
	check(offline.expedition.gold_earned == 142 and offline.wardrobe.owned.has("keeper_crown"), "earned early gear clears Rise and awards its second distinct permanent look")
	var cancel := prepared_hero()
	cancel.request_expedition("hollow")
	cancel._begin_quest_cycle()
	cancel.simulate_elapsed(720)
	cancel.stop_expedition()
	check(cancel.gold == 12 and not cancel.wardrobe.owned.has("lantern_crook"), "leaving after a cache keeps its gold without granting the final look")
	var legacy := Expedition.new()
	legacy.load_save_dict({"route": "causeway", "active": true, "node": 3, "remainder_usec": 59900000})
	check(legacy.remainder_usec == 59900000 and legacy.active and legacy.claimed_routes.is_empty(), "existing five-minute routes keep their saved timing and no invented history")
	for id in ["lantern_moth", "root_keeper", "lantern_arch", "lantern_post", "mooncap_cluster", "keeper_shrine"]:
		var model := Art.instantiate(id)
		check(model != null, "authored scene asset loads: " + id)
		if model != null:
			model.free()
	for item in ["Lantern Crook", "Keeper Crown"]:
		check(Art.item_icon(item) != null and Art.has_model(Art.item_model(item)), "earned look has matching preview model and icon: " + item)
	var dressed := preload("res://src/view/character_visual.gd").new()
	dressed.setup("hero")
	dressed.set_equipment("weapon", "Lantern Crook")
	check(dressed.worn["weapon"][0].rotation_degrees.is_equal_approx(Vector3(-70, 0, 0)), "watch and wardrobe share the upright crook grip correction")
	dressed.free()
	var scenery := preload("res://src/view/lantern_hollow.gd").new()
	root.add_child(scenery)
	scenery.build()
	resumed.request_expedition("hollow")
	resumed._begin_quest_cycle()
	resumed.expedition.node = 1
	resumed.hero_position = Catalog.WAYPOINTS["hollow"][1]
	var before_scenery: Dictionary = resumed.to_save_dict()
	scenery.sync(resumed, true)
	check(scenery.creatures["lantern_moth"].visible and scenery.creatures["lantern_moth"].reduced_motion and not scenery.creatures["root_keeper"].is_processing(), "only the approaching creature animates, and reduced motion reaches it")
	check(before_scenery == resumed.to_save_dict(), "scenery and camera-facing poses never alter the encounter outcome")
	resumed.stop_expedition()
	scenery.sync(resumed, false)
	check(not scenery.encounter_visible and not scenery.creatures["lantern_moth"].is_processing(), "leaving the expedition stops hidden creature processing")
	scenery.free()
	for sim in [locked, watched, offline, resumed, restored, cancel]:
		sim.free()
	await process_frame
	print("Lanternwood tests complete: %d failure(s)" % failures)
	quit(failures)
