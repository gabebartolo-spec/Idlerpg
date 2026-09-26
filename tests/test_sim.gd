extends "res://tests/test_suite.gd"

# Simulation-level tests: rng, hero math, loot bands, expedition resolution,
# death, specials, determinism.

const Rng = preload("res://src/sim/rng.gd")
const Hero = preload("res://src/sim/hero.gd")
const Loot = preload("res://src/sim/loot.gd")
const Expedition = preload("res://src/sim/expedition.gd")
const Content = preload("res://src/data/content.gd")

var content = Content.new()


func weak_snap() -> Dictionary:
	return {
		"name": "Test", "level": 1, "vows": [], "specials": {},
		"might": 4, "ward": 4, "luck": 1, "grit_max": 2,
		"weapon_name": "hammer", "armor_name": "coat"
	}


func strong_snap() -> Dictionary:
	var ward := 11
	return {
		"name": "Strong", "level": 8, "vows": ["shelter"], "specials": {},
		"might": 12, "ward": ward, "luck": 5, "grit_max": Hero.grit_max(ward),
		"weapon_name": "hammer", "armor_name": "plate"
	}


func test_rng_deterministic_and_bounded() -> void:
	var a := Rng.new(42)
	var b := Rng.new(42)
	var c := Rng.new(43)
	var same := true
	var differs := false
	for i in 50:
		if a.next_percent() != b.next_percent():
			same = false
		if a.next_percent() == c.next_percent():
			pass
	var a2 := Rng.new(42)
	var c2 := Rng.new(43)
	for i in 20:
		if a2.next_unit() != c2.next_unit():
			differs = true
	check(same, "same seed gives same stream")
	check(differs, "different seed differs")
	var r := Rng.new(7)
	var in_bounds := true
	for i in 2000:
		var p := r.next_percent()
		if p < 0 or p > 99:
			in_bounds = false
	check(in_bounds, "next_percent stays in 0..99")
	check(r.next_int(1) == 0, "next_int(1) is 0")
	check(r.next_int(0) == 0, "next_int(0) is safe")


func test_hero_curve() -> void:
	check(Hero.level_for_xp(0) == 1, "level 1 at 0 xp")
	check(Hero.level_for_xp(44) == 1, "level 1 just under threshold")
	check(Hero.level_for_xp(45) == 2, "level 2 at threshold")
	check(Hero.level_for_xp(999999) == Hero.MAX_LEVEL, "level caps")
	var l1 := Hero.base_stats(1)
	var l8 := Hero.base_stats(8)
	check(int(l1["might"]) == 3 and int(l1["ward"]) == 3 and int(l1["luck"]) == 1, "L1 stats 3/3/1")
	check(int(l8["might"]) == 7 and int(l8["ward"]) == 6 and int(l8["luck"]) == 3, "L8 stats 7/6/3")
	check(Hero.grit_max(4) == 2, "grit floor")
	check(Hero.grit_max(10) == 4, "grit from ward")
	check(Hero.xp_to_next(0, Hero.MAX_LEVEL) == 0, "no next at cap")


func test_content_is_valid() -> void:
	var problems: Array = content.validate()
	check(problems.is_empty(), "content cross-references clean: %s" % [problems])


func test_expedition_full_replay_is_identical() -> void:
	var zone := content.get_zone("marrowfields")
	var a := Expedition.resolve(zone, 4, 777, weak_snap(), 100000, content)
	var b := Expedition.resolve(zone, 4, 777, weak_snap(), 100000, content)
	check(str(a["status"]) == "returned", "full time returns the run")
	check(a["xp"] == b["xp"] and a["gold"] == b["gold"], "rewards identical on replay")
	check(a["loot"] == b["loot"], "loot identical on replay")
	check(a["events"] == b["events"], "story identical on replay")


func test_partial_resolution_is_a_prefix() -> void:
	var zone := content.get_zone("chime_deep")
	var early := Expedition.resolve(zone, 6, 42, strong_snap(), 65, content)
	check(str(early["status"]) == "out", "run still out at 65s")
	check(int(early["planned_seconds"]) == 720, "six tolls planned at 120s each")
	var later := Expedition.resolve(zone, 6, 42, strong_snap(), 6000, content)
	check(str(later["status"]) == "returned", "run returns given full time")
	var head: Array = later["events"].slice(0, early["events"].size())
	check(head == early["events"], "partial events are a prefix of full events")
	check(int(later["xp"]) >= int(early["xp"]), "rewards grow with time")


func test_death_is_possible_and_costly_in_the_scar() -> void:
	var zone := content.get_zone("requiem_scar")
	var deaths := 0
	var kept_loot_on_death := 0
	for seed_v in range(1, 301):
		var r := Expedition.resolve(zone, 6, seed_v, weak_snap(), 100000, content)
		if str(r["status"]) == "died":
			deaths += 1
			kept_loot_on_death += int(r["loot"].size())
	check(deaths >= 10, "scar at depth 6 kills weak builds often enough (%d/300)" % deaths)
	check(kept_loot_on_death == 0, "death without the writ scatters every find")


func test_death_writ_keeps_something() -> void:
	var zone := content.get_zone("requiem_scar")
	var snap := strong_snap()
	snap["specials"] = {"death_writ": true}
	snap["ward"] = 4
	snap["grit_max"] = 2
	var kept_any := false
	for seed_v in range(1, 301):
		var r := Expedition.resolve(zone, 6, seed_v, snap, 100000, content)
		if str(r["status"]) == "died" and int(r["loot"].size()) > 0:
			kept_any = true
	check(kept_any, "the Unmarked Grave carries findings home")


func test_strong_build_beats_the_gravecho() -> void:
	var zone := content.get_zone("requiem_scar")
	var wins := 0
	for seed_v in range(1, 101):
		var r := Expedition.resolve(zone, 6, seed_v, strong_snap(), 100000, content)
		if str(r["status"]) == "returned" and bool(r["boss_slain"]):
			wins += 1
	check(wins >= 20, "strong build slays the Gravecho regularly (%d/100)" % wins)


func test_objective_only_on_real_runs() -> void:
	var zone := content.get_zone("requiem_scar")
	var r := Expedition.resolve(zone, 6, 5, strong_snap(), 100000, content)
	var saw_objective := false
	for e in r["events"]:
		if str(e["kind"]) == "objective":
			saw_objective = true
	check(saw_objective, "deep runs meet the objective")
	var quick := Expedition.resolve(zone, 2, 5, strong_snap(), 100000, content)
	var no_objective := true
	for e in quick["events"]:
		if str(e["kind"]) == "objective":
			no_objective = false
	check(no_objective, "shallow runs have no objective")


func test_first_strike_sweeps_one_fight_per_toll() -> void:
	var zone := content.get_zone("marrowfields")
	var snap := strong_snap()
	snap["specials"] = {"first_strike": true}
	for seed_v in range(1, 51):
		var r := Expedition.resolve(zone, 3, seed_v, snap, 100000, content)
		if str(r["status"]) == "returned":
			check(int(r["kills"]) == 3, "first_strike kills each toll's first foe (seed %d: %d)" % [seed_v, int(r["kills"])])


func test_tithe_collects_one_shard_per_kill() -> void:
	var zone := content.get_zone("marrowfields")
	var snap := strong_snap()
	snap["specials"] = {"tithe": true}
	for seed_v in range(1, 51):
		var r := Expedition.resolve(zone, 4, seed_v, snap, 100000, content)
		if str(r["status"]) == "returned":
			check(int(r["shards"]) == int(r["kills"]), "tithe pays per kill (seed %d)" % seed_v)


func test_zone_loot_bands_hold() -> void:
	var rng := Rng.new(99)
	var fields := content.get_zone("marrowfields")
	for i in 300:
		var drop := Loot.roll_drop(content, fields, 0, rng, true)
		var def := content.get_item(str(drop["id"]))
		check(int(def["rarity"]) <= 1, "marrowfields stays Worn/Tempered at 0 luck")
	var scar := content.get_zone("requiem_scar")
	var saw_bellforged := false
	for i in 300:
		var drop := Loot.roll_drop(content, scar, 0, rng, true)
		var def := content.get_item(str(drop["id"]))
		if int(def["rarity"]) == 2:
			saw_bellforged = true
	check(saw_bellforged, "scar yields Bellforged things")


func test_light_foot_shortens_time() -> void:
	var zone := content.get_zone("marrowfields")
	var plain := Expedition.toll_seconds(zone, weak_snap())
	var with_mantle := weak_snap()
	with_mantle["specials"] = {"light_foot": true}
	var fast := Expedition.toll_seconds(zone, with_mantle)
	check(absf(fast - plain * 0.75) < 0.001, "Ashveil Mantle shortens tolls by a quarter")
	check(Expedition.danger_at(zone, 0, with_mantle) == Expedition.danger_at(zone, 0, weak_snap()) + 1, "Ashveil Mantle thickens the ash")
