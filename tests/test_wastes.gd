extends "res://tests/test_suite.gd"

const Content = preload("res://src/data/content.gd")
const Game = preload("res://src/state/game.gd")
const Expedition = preload("res://src/sim/expedition.gd")
const Loot = preload("res://src/sim/loot.gd")
const Save = preload("res://src/state/save.gd")
var content := Content.new()


func new_game() -> Game:
	wipe_save()
	var game := Game.new(content, 10000)
	game.create_adventurer("Lamplighter")
	return game


func strong_snap() -> Dictionary:
	return {"name": "Test", "might": 30, "ward": 30, "luck": 5, "grit_max": 8,
		"vows": [], "specials": {}, "weapon_name": "glaive", "armor_name": "cloak"}


func boss_return(zone_id: String, boss_id: String) -> Dictionary:
	return {"zone_id": zone_id, "zone_name": zone_id, "boss_id": boss_id,
		"boss_slain": true, "status": "returned", "depth": 4, "deepest_toll": 4,
		"xp": 0, "gold": 0, "shards": 0, "kills": 8, "loot": [], "events": [], "summary": "test"}


func test_wastes_content_and_two_fight_timeline() -> void:
	check(content.validate().is_empty(), "expanded content validates")
	check(content.all_zones().size() == 4 and content.all_items().size() == 26, "four roads and 26 findings")
	var zone := content.get_zone("lantern_wastes")
	var plan := Expedition.plan(zone, 4, 71, strong_snap())
	check(plan["total_seconds"] == 600, "Wastes have 150-second tolls")
	var fights: Array = plan["beats"].filter(func(beat): return beat["kind"] == "combat")
	check(fights.size() == 8, "four tolls contain eight fights")
	check(fights[0]["t"] == 75.0 and fights[1]["t"] == 108.0, "second fight is later in the same toll")
	check(fights[-1]["enemy"] == "lantern_eater" and fights[-1]["boss"], "final second fight is the boss")
	check(fights.filter(func(beat): return beat["boss"]).size() == 1, "boss appears only once")
	for i in range(1, plan["beats"].size()):
		check(float(plan["beats"][i]["t"]) >= float(plan["beats"][i - 1]["t"]), "beats remain chronological")
	var old := Expedition.plan(content.get_zone("marrowfields"), 4, 71, strong_snap())
	check(old["beats"].filter(func(beat): return beat["kind"] == "combat").size() == 4, "original roads retain one fight per toll")


func test_boss_drops_are_zone_specific_and_not_random_loot() -> void:
	for entry in [["requiem_scar", "gravechos_tongue"], ["lantern_wastes", "last_lantern"]]:
		var zone := content.get_zone(entry[0])
		var victory := false
		for seed_value in range(1, 51):
			var run := Expedition.resolve(zone, 4, seed_value, strong_snap(), 9999, content)
			if run["boss_slain"]:
				victory = true
				check(run["boss_id"] == zone["boss"], "run identifies the boss it faced")
				check(run["loot"].any(func(item): return item["id"] == entry[1]), "victory yields the correct unique relic")
				var other := "last_lantern" if entry[1] == "gravechos_tongue" else "gravechos_tongue"
				check(not run["loot"].any(func(item): return item["id"] == other), "no relic from the other boss")
				break
		check(victory, "a well-equipped build can defeat the boss")
		var pool := Loot.zone_pool(content, entry[0])
		for band in pool.values():
			check(not band.any(func(item): return item.get("boss_only", false)), "boss relics never enter a random pool")


class WoundRng:
	extends RefCounted
	func roll(_chance: int) -> bool:
		return true
	func next_int(_limit: int) -> int:
		return 0
	func pick(items: Array):
		return items[0]


func test_last_lantern_absorbs_exactly_one_wound() -> void:
	var snap := strong_snap()
	snap["specials"] = {"ember_guard": true}
	var zone := content.get_zone("marrowfields")
	var run := Expedition.resolve(zone, 3, 1, snap, 0, content)
	var beat := {"kind": "combat", "t": 60, "toll": 0, "enemy": "reed_shambler", "boss": false, "elite": false}
	var rng := WoundRng.new()
	Expedition._process_beat(beat, zone, snap, snap["specials"], rng, run, content)
	check(run["ward_spent"] and run["wounds"] == 0, "first wound is absorbed")
	check(run["grit"] == snap["grit_max"] and run["echo"] == 1, "guard preserves Grit and the kill's Echo")
	Expedition._process_beat(beat, zone, snap, snap["specials"], rng, run, content)
	check(run["wounds"] == 1 and run["grit"] == snap["grit_max"] - 1, "second wound consumes Grit")
	check(run["echo"] == 0, "second wound silences Echo normally")
	check(run["events"].filter(func(event): return event["kind"] == "ward").size() == 1, "guard story appears once")
	var next := Expedition.resolve(zone, 3, 1, snap, 0, content)
	check(not next["ward_spent"], "new expedition restores the guard")


func test_first_strike_does_not_skip_the_second_fight() -> void:
	var snap := strong_snap()
	snap["specials"] = {"first_strike": true}
	var zone := content.get_zone("lantern_wastes")
	var run := Expedition.resolve(zone, 2, 1, snap, 0, content)
	var beat := {"kind": "combat", "t": 75, "toll": 0, "enemy": "glass_stalker", "boss": false, "elite": false}
	var rng := WoundRng.new()
	Expedition._process_beat(beat, zone, snap, snap["specials"], rng, run, content)
	check(run["wounds"] == 0, "first fight is auto-won without a wound")
	beat["t"] = 108
	Expedition._process_beat(beat, zone, snap, snap["specials"], rng, run, content)
	check(run["wounds"] == 1, "second fight still rolls and can wound")


func test_wastes_gate_and_boss_records_survive_reload() -> void:
	var game := new_game()
	game.hero()["level"] = 8
	check(game.zone_ok("lantern_wastes", 3).contains("Gravecho"), "level alone does not open the road")
	game._commit_runs([boss_return("requiem_scar", "gravecho")])
	game.hero()["level"] = 6
	check(game.zone_ok("lantern_wastes", 3).contains("level 7"), "boss win does not bypass level gate")
	game.hero()["level"] = 7
	check(game.zone_ok("lantern_wastes", 3) == "", "safe Gravecho victory and level seven open the Wastes")
	game._commit_runs([boss_return("lantern_wastes", "lantern_eater")])
	check(game.state["belfry"]["bosses"] == 1, "new boss does not inflate legacy Gravecho counter")
	check(game.state["belfry"]["boss_victories"]["lantern_eater"] == 1, "new boss counted separately")
	check(game.claim_milestone("last_light") == "", "new boss milestone is claimable")
	var loaded := Game.new(content, game.now())
	check(loaded.zone_ok("lantern_wastes", 3) == "", "road stays open after reload")
	check(loaded.claim_milestone("last_light") != "", "new reward remains collected")
	game.state["belfry"].erase("boss_victories")
	Save.save_state(game.state)
	loaded = Game.new(content, game.now())
	check(loaded.zone_ok("lantern_wastes", 3) == "", "legacy safe Gravecho counter migrates to the gate")


func test_preview_is_a_read_only_elapsed_prefix() -> void:
	var game := new_game()
	game.send_out("marrowfields", 4)
	var before := game.state.duplicate(true)
	var departure := game.expedition_view()
	check(departure["events"].size() == 1 and departure["events"][0]["kind"] == "departure", "only departure is visible at zero seconds")
	game.clock_override += 60
	var early := game.expedition_view()
	check(early == game.expedition_view(), "repeated observation does not reroll")
	check(game.state == before, "observation never mutates or banks state")
	for event in early["events"]:
		check(int(event["at_seconds"]) <= 60, "no future timestamp in preview")
	game.clock_override += 120
	var later := game.expedition_view()
	check(later["events"].slice(0, early["events"].size()) == early["events"], "later journal retains the observed prefix")
	later["events"].clear()
	check(not game.expedition_view()["events"].is_empty(), "caller cannot mutate the cached journal")
	check(game.hero()["inventory"].is_empty() and not game.has_report(), "findings stay unbanked before return")


func test_early_death_is_final_and_cannot_be_recalled_away() -> void:
	var game := new_game()
	var snap := strong_snap()
	snap["ward"] = 0
	snap["might"] = 0
	snap["grit_max"] = 0
	var zone := content.get_zone("requiem_scar")
	var seed_value := -1
	for candidate in range(1, 101):
		if Expedition.resolve(zone, 6, candidate, snap, 60, content)["status"] == "died":
			seed_value = candidate
			break
	check(seed_value > 0, "found an early fatal encounter")
	if seed_value < 0:
		return
	game.state["expedition"] = {"zone_id": "requiem_scar", "depth": 6, "seed": seed_value, "snapshot": snap, "started_at": game.now()}
	game.clock_override += 60
	check(not game.can_recall(), "terminal combat cannot be recalled")
	check(game.recall() != "", "recall refuses to rewrite a death as a return")
	check(game.has_report() and game.pending_report()["any_death"], "early outcome immediately produces its report")
	check(not game.has_expedition(), "failed expedition is no longer walking")
	var runs := int(game.lifetime()["runs"])
	game.update()
	check(game.lifetime()["runs"] == runs, "early terminal outcome commits once")


func test_partial_wastes_replay_and_timestamps() -> void:
	var zone := content.get_zone("lantern_wastes")
	var snap := strong_snap()
	var early := Expedition.resolve(zone, 4, 12, snap, 108, content)
	var full := Expedition.resolve(zone, 4, 12, snap, 9999, content)
	check(early["combats"] == 2, "journal includes both elapsed fights")
	check(full["events"].slice(0, early["events"].size()) == early["events"], "Wastes replay keeps the same observed prefix")
	var last_time := -1
	for event in full["events"]:
		check(int(event["at_seconds"]) >= last_time, "journal timestamps never go backwards")
		last_time = int(event["at_seconds"])
	check(last_time <= 600, "return and all beats fall inside the planned duration")
