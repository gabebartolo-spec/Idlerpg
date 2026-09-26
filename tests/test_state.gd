extends "res://tests/test_suite.gd"

# Game-state tests: save/load, clock rollback, offline resolution, chaining,
# recall, death consequences, equipment verbs, tempering, vows, level-ups.

const GameLib = preload("res://src/state/game.gd")
const ContentLib = preload("res://src/data/content.gd")
const SaveRepo = preload("res://src/state/save.gd")
const Expedition = preload("res://src/sim/expedition.gd")
const Hero = preload("res://src/sim/hero.gd")


func fresh_game(clock: int):
	var g = GameLib.new(ContentLib.new())
	g.clock_override = clock
	return g


func make_game(clock: int, adventurer_name: String):
	wipe_save()
	var g = fresh_game(clock)
	check(g.create_adventurer(adventurer_name), "adventurer created")
	return g


func minimal_run(xp: int) -> Dictionary:
	return {
		"status": "returned", "elapsed_seconds": 360, "planned_seconds": 360,
		"events": [], "loot": [], "xp": xp, "gold": 0, "shards": 0,
		"kills": 2, "wounds": 0, "deepest_toll": 3, "boss_slain": false,
		"zone_id": "marrowfields", "zone_name": "The Marrowfields", "depth": 3,
		"summary": "test", "standout": {}
	}


func test_save_roundtrip_and_resume() -> void:
	var g = make_game(1000, "Tollborn Test")
	check(g.send_out("marrowfields", 3) == "", "sent out")
	var loaded := SaveRepo.load_state()
	check(not loaded.is_empty(), "save exists on disk")
	check(str(loaded["adventurer"]["name"]) == "Tollborn Test", "name survives the roundtrip")
	var g2 = fresh_game(1000)
	check(not g2.is_new_game(), "resume recognizes the hero")
	check(g2.has_expedition(), "expedition survives an app kill")


func test_malformed_save_starts_fresh() -> void:
	wipe_save()
	var file := FileAccess.open(SaveRepo.SAVE_PATH, FileAccess.WRITE)
	file.store_string("{not json at all,,,")
	file.close()
	var loaded := SaveRepo.load_state()
	check(loaded.is_empty(), "garbage save loads as empty")
	var g = fresh_game(0)
	check(g.is_new_game(), "game falls back to a fresh hero")


func test_wrong_schema_starts_fresh() -> void:
	wipe_save()
	var file := FileAccess.open(SaveRepo.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version": 999, "adventurer": {}}))
	file.close()
	check(SaveRepo.load_state().is_empty(), "unknown schema rejected")


func test_clock_rollback_is_clamped() -> void:
	var g = make_game(5000, "Clockwatcher")  # saved at t=5000
	var g2 = fresh_game(4000)  # device clock rolled back 1000s
	check(g2.now() == 5000, "now() is clamped to the last save time")
	var g3 = fresh_game(9000)
	check(g3.now() == 9000, "clock moving forward is fine")


func test_offline_time_resolves_the_run() -> void:
	var g = make_game(10000, "Wanderer")
	check(g.send_out("marrowfields", 3) == "", "sent for three tolls")
	g.clock_override = 10000 + 360 + 1
	g.update()
	check(g.has_report(), "the report waits at the bell")
	var rep: Dictionary = g.pending_report()
	check(int(rep["chained"]) == 1, "one run came home")
	check(str(rep["runs"][0]["status"]) == "returned", "and it went well")
	check(int(g.hero()["gold"]) == int(rep["totals"]["gold"]), "gold banked exactly once")
	check(not g.has_expedition(), "the bell is empty with standing orders off")
	check(g.hero()["inventory"].size() == rep["loot"].size(), "bag matches the report")


func test_standing_orders_chain_overnight() -> void:
	var g = make_game(10000, "Marathon")
	g.set_standing(true)
	check(g.send_out("marrowfields", 2) == "", "sent with standing orders")
	g.clock_override = 10000 + 240 * 3
	g.update()
	check(g.has_report(), "finished runs report immediately")
	check(int(g.pending_report()["chained"]) == 3, "three runs came home while away")
	check(g.has_expedition(), "a fourth run is already underway")
	g.clock_override += 240
	g.update()
	check(int(g.pending_report()["chained"]) == 4, "reports merge instead of vanishing")


func test_chain_cap_holds_for_pathological_absence() -> void:
	var g = make_game(10000, "Rip")
	g.set_standing(true)
	g.send_out("marrowfields", 2)
	g.clock_override = 10000 + 240 * 40
	g.update()
	check(int(g.pending_report()["chained"]) <= 24, "chain cap holds")
	check(g.has_expedition() or g.has_report(), "time still resolves to something")


func test_recall_brings_them_home_early() -> void:
	var g = make_game(10000, "Homesick")
	g.send_out("marrowfields", 6)
	g.clock_override = 10000 + 130
	check(g.can_recall(), "recall reaches them mid-run")
	check(g.recall() == "", "the recall rings")
	var rep: Dictionary = g.pending_report()
	check(str(rep["runs"][0]["status"]) == "recalled", "they turned for home")
	check(not g.has_expedition(), "nobody is out there")
	check(int(rep["loot"].size()) == g.hero()["inventory"].size(), "the find came home intact")


func test_death_loses_the_find_but_keeps_progress() -> void:
	var content = ContentLib.new()
	var weak := {
		"name": "Test", "level": 1, "vows": [], "specials": {},
		"might": 4, "ward": 4, "luck": 1, "grit_max": 2,
		"weapon_name": "hammer", "armor_name": "coat"
	}
	var deadly_seed := -1
	for seed_v in range(1, 400):
		var zone := content.get_zone("requiem_scar")
		var r := Expedition.resolve(zone, 6, seed_v, weak, 100000, content)
		if str(r["status"]) == "died":
			deadly_seed = seed_v
			break
	check(deadly_seed != -1, "found a deadly seed")
	if deadly_seed == -1:
		return
	wipe_save()
	var g = fresh_game(0)
	g.create_adventurer("Reckless")
	g.state["expedition"] = {
		"zone_id": "requiem_scar", "depth": 6, "started_at": 0,
		"seed": deadly_seed, "snapshot": weak
	}
	g.clock_override = 10000
	g.update()
	check(g.has_report(), "the bell tells the truth")
	check(bool(g.pending_report()["any_death"]), "and it says they fell")
	check(g.hero()["inventory"].is_empty(), "the find is scattered")
	check(int(g.hero()["gold"]) == int(g.pending_report()["totals"]["gold"]), "but the wages come home")


func test_equip_sell_salvage_verbs() -> void:
	var g = make_game(0, "Quartermaster")
	g.hero()["inventory"].append({"uid": 500, "id": "marsh_reaver", "temper": 0})
	g.hero()["inventory"].append({"uid": 501, "id": "chipped_bell_hammer", "temper": 0})
	g.hero()["inventory"].append({"uid": 502, "id": "verdigris_hauberk", "temper": 0})
	check(g.equip(500), "wield the reaver")
	check(str(g.equipped()["weapon"]["id"]) == "marsh_reaver", "it is the weapon now")
	check(g.sell(500) == 0, "cannot sell what is worn")
	check(g.equip(501), "swap to the hammer")
	check(g.inventory().any(func(x): return int(x.get("uid", 0)) == 500), "reaver returns to the bag")
	var gold_before := int(g.hero()["gold"])
	var sold := g.sell(500)
	check(sold == 18, "reaver sells for its price")
	check(int(g.hero()["gold"]) == gold_before + sold, "gold paid")
	var shards_before := int(g.hero()["shards"])
	var salvaged := g.salvage(502)
	check(salvaged == 1, "tempered-tier armor yields one shard")
	check(int(g.hero()["shards"]) == shards_before + salvaged, "shards paid")


func test_tempering_costs_and_caps() -> void:
	var g = make_game(0, "Smith")
	g.hero()["inventory"].append({"uid": 600, "id": "marsh_reaver", "temper": 0})
	g.equip(600)
	g.hero()["shards"] = 20
	var might0 := int(g.stats()["might"])
	check(g.temper_cost("weapon") == 3, "first temper costs 3 shards")
	check(g.temper("weapon") == "", "first temper succeeds")
	check(int(g.stats()["might"]) == might0 + 1, "temper sharpens the blade")
	check(g.temper_cost("weapon") == 8, "second temper costs 8")
	g.hero()["shards"] = 1
	var err: String = g.temper("weapon")
	check(err != "", "shards gate the forge")
	g.hero()["shards"] = 50
	check(g.temper("weapon") == "", "second temper succeeds")
	check(g.temper_cost("weapon") == 0, "the bell tempers no further")
	check(g.temper("weapon") != "", "third temper refused")
	# salvage value includes the temper
	g.hero()["inventory"].append({"uid": 601, "id": "chipped_bell_hammer", "temper": 0})
	g.equip(601)  # reaver goes back to the bag
	var inst = g.find_instance(600)
	var shards_before := int(g.hero()["shards"])
	var got := g.salvage(600)
	check(got == 1 + 2, "tempered salvage pays the temper back in shards")
	check(int(g.hero()["shards"]) == shards_before + got, "shards banked")


func test_vow_choices_are_gated_by_level() -> void:
	var g = make_game(0, "Sworn")
	check(not g.choose_vow("wrath"), "no vow while none pending")
	g.state["pending_vows"] = [3]
	check(not g.choose_vow("silence"), "silence is not offered at level 3")
	check(g.choose_vow("wrath"), "wrath accepted")
	check("wrath" in g.vows(), "vow kept forever")
	check(g.pending_vows().is_empty(), "queue drains")


func test_levelups_and_vow_queueing() -> void:
	var g = make_game(0, "Learner")
	g.hero()["xp"] = 40
	g._commit_runs([minimal_run(50)])
	check(int(g.hero()["level"]) == 2, "50 xp crosses into level 2")
	g._commit_runs([minimal_run(100)])
	check(int(g.hero()["level"]) == 3, "enough xp crosses into level 3")
	check(g.pending_vows() == [3], "the bell asks for a vow at level 3")
	check(g.choose_vow("wrath"), "vow chosen")
	check(g.hero()["xp"] == 40 + 50 + 100, "xp accumulates exactly")


func test_snapshot_carries_gear_specials() -> void:
	var g = make_game(0, "Echo")
	g.hero()["inventory"].append({"uid": 700, "id": "sextons_crook", "temper": 0})
	g.equip(700)
	var snap: Dictionary = g.snapshot_now()
	check(bool(snap["specials"].get("echo_hold", false)), "Sexton's Crook changes the run rules")
	var no_mantle := Expedition.toll_seconds(g.content.get_zone("marrowfields"), snap)
	check(absf(no_mantle - 120.0) < 0.001, "crook does not touch toll length")
