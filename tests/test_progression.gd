extends "res://tests/test_suite.gd"

const Game = preload("res://src/state/game.gd")
const Content = preload("res://src/data/content.gd")
const Save = preload("res://src/state/save.gd")
const Progression = preload("res://src/state/progression.gd")


func new_game() -> Game:
	wipe_save()
	var game := Game.new(Content.new(), 10000)
	game.create_adventurer("Keeper")
	return game


func run_fixture(status: String = "returned", zone: String = "marrowfields", depth: int = 4) -> Dictionary:
	return {
		"status": status, "xp": 0, "gold": 0, "shards": 0, "kills": 4,
		"deepest_toll": depth, "depth": depth, "boss_slain": false,
		"zone_id": zone, "zone_name": zone, "summary": "test", "events": [],
		"loot": [{"id": "marsh_reaver", "temper": 0}, {"id": "reedwoven_vest", "temper": 0}]
	}


func test_fresh_belfry_and_definition_integrity() -> void:
	var game := new_game()
	check(game.belfry_bonuses() == {"might": 0, "ward": 0, "luck": 0}, "no free stat bonuses")
	check(game.state["belfry"]["discoveries"].is_empty(), "ledger starts empty")
	check(game.milestones_ready() == 0, "no free milestone rewards")
	check(game.collection_rows().size() == game.content.all_items().size(), "ledger includes every item")
	var seen := {}
	for def in Progression.UPGRADES:
		check(not seen.has(def["id"]), "upgrade IDs unique")
		seen[def["id"]] = true
		check(def["stat"] in ["might", "ward", "luck"], "upgrade affects a real stat")
		for cost in def["costs"]:
			check(int(cost["gold"]) > 0 and int(cost["shards"]) >= 0, "upgrade costs valid")
	seen.clear()
	for def in Progression.MILESTONES:
		check(not seen.has(def["id"]), "milestone IDs unique")
		seen[def["id"]] = true
		check(int(def["target"]) > 0, "milestone has a positive goal")
		if def.has("zone"):
			check(not game.content.get_zone(str(def["zone"])).is_empty(), "milestone road exists")


func test_upgrades_charge_exactly_and_reject_invalid_purchases() -> void:
	var game := new_game()
	check(game.buy_upgrade("anvil") != "", "cannot buy without gold")
	check(game.buy_upgrade("bogus") != "", "unknown upgrade rejected")
	game.hero()["gold"] = 60
	check(game.buy_upgrade("anvil") == "", "first anvil rank purchased")
	check(game.hero()["gold"] == 0 and game.hero()["shards"] == 0, "exact first-rank cost charged")
	check(game.stats()["might"] == 4, "anvil increases displayed Might")
	game.hero()["gold"] = 1000
	game.hero()["shards"] = 1
	check(game.buy_upgrade("anvil") != "", "later rank requires shards too")
	check(game.hero()["gold"] == 1000 and game.hero()["shards"] == 1, "failed purchase charges nothing")
	game.hero()["shards"] = 7
	check(game.buy_upgrade("anvil") == "" and game.buy_upgrade("anvil") == "", "later ranks purchased")
	check(game.hero()["gold"] == 520 and game.hero()["shards"] == 0, "later costs charged exactly")
	var before := game.state.duplicate(true)
	check(game.buy_upgrade("anvil") != "", "rank cap enforced")
	check(game.state == before, "capped purchase changes nothing")
	check(game.belfry_bonuses()["might"] == 3, "Might bonus capped at three")


func test_upgrade_bonus_enters_new_snapshot_only() -> void:
	var game := new_game()
	game.send_out("marrowfields", 2)
	var snapshot: Dictionary = game.state["expedition"]["snapshot"].duplicate(true)
	game.hero()["gold"] = 2000
	game.hero()["shards"] = 30
	game.buy_upgrade("anvil")
	game.buy_upgrade("brazier")
	game.buy_upgrade("brazier")
	game.buy_upgrade("candles")
	check(game.snapshot_now()["might"] == snapshot["might"] + 1, "new build gets Might")
	check(game.snapshot_now()["ward"] == 5 and game.snapshot_now()["grit_max"] == 3, "Ward upgrade recalculates Grit")
	check(game.snapshot_now()["luck"] == snapshot["luck"] + 1, "new build gets Luck")
	check(game.state["expedition"]["snapshot"] == snapshot, "upgrade never rewrites the active build")
	game.set_standing(true)
	game.clock_override += 240
	game.update()
	check(game.has_expedition(), "standing order started a new leg")
	check(game.state["expedition"]["snapshot"] == snapshot, "standing-order chain preserves its original build")
	game.recall()
	check(game.send_out("marrowfields", 2) == "", "manual departure succeeds")
	check(game.state["expedition"]["snapshot"] == game.snapshot_now(), "manual departure takes the upgraded build")


func test_milestones_reward_once_and_keep_report_rewards_separate() -> void:
	var game := new_game()
	check(game.claim_milestone("first_road") != "", "cannot claim unfinished goal")
	check(game.claim_milestone("bogus") != "", "unknown goal rejected")
	game._commit_runs([run_fixture()])
	check(game.milestones_ready() == 2, "first expedition and safe marsh clear qualify")
	var report := game.pending_report().duplicate(true)
	check(game.claim_milestone("first_road") == "", "ready reward claimed")
	check(game.hero()["gold"] == 30 and game.hero()["shards"] == 1, "milestone pays gold and shards")
	check(game.pending_report() == report, "milestone is not folded into expedition totals")
	check(game.claim_milestone("first_road") != "", "reward cannot be claimed twice")
	check(game.hero()["gold"] == 30 and game.hero()["shards"] == 1, "duplicate claim pays nothing")
	game.clear_report()
	check(game.claim_milestone("marsh_path") == "", "unclaimed milestone survives clearing the report")


func test_only_safe_returns_clear_roads_and_boss_goal() -> void:
	var game := new_game()
	for status in ["recalled", "died", "broken"]:
		var run := run_fixture(status, "requiem_scar", 6)
		run["boss_slain"] = true
		game._commit_runs([run])
	check(game.state["belfry"]["cleared_depths"].is_empty(), "unsafe or recalled runs do not clear roads")
	check(game.state["belfry"]["bosses"] == 0, "boss goal requires returning safely")
	check(game.claim_milestone("gravecho") != "", "unsafe boss victory earns no boss milestone")
	var success := run_fixture("returned", "requiem_scar", 6)
	success["boss_slain"] = true
	game._commit_runs([success])
	check(game.state["belfry"]["cleared_depths"]["requiem_scar"] == 6, "safe deepest clear recorded")
	check(game.claim_milestone("gravecho") == "", "safe boss victory earns its milestone")
	game._commit_runs([run_fixture("returned", "requiem_scar", 2)])
	check(game.state["belfry"]["cleared_depths"]["requiem_scar"] == 6, "shallow runs do not overwrite best depth")


func test_collection_counts_unique_kept_loot_and_survives_trade() -> void:
	var game := new_game()
	game._commit_runs([run_fixture(), run_fixture()])
	check(game.state["belfry"]["discoveries"].size() == 2, "duplicate drops count once")
	var inventory := game.inventory().duplicate(true)
	for inst in inventory:
		game.sell(int(inst["uid"]))
	check(game.inventory().is_empty(), "test items sold")
	check(game.state["belfry"]["discoveries"].size() == 2, "sold findings stay in ledger")
	var death := run_fixture("died")
	death["loot"] = []
	game._commit_runs([death])
	check(game.state["belfry"]["discoveries"].size() == 2, "scattered loot adds no entries")
	var run := run_fixture()
	run["loot"] = []
	for def in game.content.all_items().slice(0, 10):
		run["loot"].append({"id": def["id"], "temper": 0})
	game._commit_runs([run])
	check(game.claim_milestone("collector") == "", "ten unique finds earn collector reward")


func test_offline_resolution_records_progress_once() -> void:
	var game := new_game()
	game.set_standing(true)
	game.send_out("marrowfields", 2)
	game.clock_override += 240 * 3
	game.update()
	var records: Dictionary = game.state["belfry"].duplicate(true)
	var runs := int(game.lifetime()["runs"])
	check(runs == 3, "offline legs recorded")
	check(int(records["cleared_depths"]["marrowfields"]) == 2, "offline safe clear recorded")
	game.update()
	check(game.state["belfry"] == records and game.lifetime()["runs"] == runs, "repeat update does not duplicate progress")


func test_belfry_roundtrip_and_old_save_migration() -> void:
	var game := new_game()
	game.hero()["gold"] = 100
	game.buy_upgrade("anvil")
	game._commit_runs([run_fixture()])
	game.claim_milestone("first_road")
	var loaded := Game.new(Content.new(), game.now())
	check(loaded.belfry_bonuses() == game.belfry_bonuses(), "upgrades survive reload")
	check(loaded.state["belfry"]["discoveries"] == game.state["belfry"]["discoveries"], "ledger survives reload")
	check(loaded.claim_milestone("first_road") != "", "claimed reward cannot be replayed after reload")
	var legacy := game.state.duplicate(true)
	legacy.erase("belfry")
	Save.save_state(legacy)
	loaded = Game.new(Content.new(), game.now())
	check(not loaded.is_new_game(), "old hero preserved")
	check(JSON.stringify(loaded.hero()) == JSON.stringify(game.hero()), "migration preserves inventory and currencies")
	check(loaded.belfry_bonuses()["might"] == 0, "old save gets an unrestored belfry")
	check(loaded.state["belfry"]["discoveries"].size() == 2, "old inventory seeds the ledger")
	check(loaded.claim_milestone("first_road") == "", "old lifetime counts qualify for new milestones")


func test_malformed_belfry_is_normalized_without_resetting_hero() -> void:
	var game := new_game()
	game.state["belfry"] = {"upgrades": {"anvil": 999, "brazier": -3, "candles": "bad"},
		"claimed": ["first_road", "first_road", "unknown", 7],
		"discoveries": ["marsh_reaver", "marsh_reaver", "unknown"],
		"cleared_depths": {"marrowfields": 99}, "bosses": -1}
	Save.save_state(game.state)
	var loaded := Game.new(Content.new(), game.now())
	check(loaded.hero()["name"] == "Keeper", "bad progression does not wipe hero")
	check(loaded.belfry_bonuses() == {"might": 3, "ward": 0, "luck": 0}, "ranks clamped and sanitized")
	check(loaded.state["belfry"]["claimed"] == ["first_road"], "claimed IDs sanitized")
	check(loaded.state["belfry"]["discoveries"] == ["marsh_reaver"], "discovery IDs sanitized")
	check(loaded.state["belfry"]["cleared_depths"]["marrowfields"] == 6, "clear depth capped")
	game.state["belfry"] = null
	Save.save_state(game.state)
	loaded = Game.new(Content.new(), game.now())
	check(loaded.belfry_bonuses() == {"might": 0, "ward": 0, "luck": 0}, "invalid section replaced with defaults")


func test_restoration_survives_death_and_new_hero_starts_clean() -> void:
	var game := new_game()
	game.hero()["gold"] = 1000
	game.hero()["shards"] = 10
	game.buy_upgrade("anvil")
	game.buy_upgrade("candles")
	game._commit_runs([run_fixture()])
	game.claim_milestone("first_road")
	var before: Dictionary = game.state["belfry"].duplicate(true)
	var death := run_fixture("died")
	death["loot"] = []
	game._commit_runs([death])
	check(game.state["belfry"] == before, "death keeps upgrades, claims, discoveries, and best clears")
	game.create_adventurer("New Keeper")
	check(game.belfry_bonuses() == {"might": 0, "ward": 0, "luck": 0}, "new hero does not inherit upgrades")
	check(game.state["belfry"]["claimed"].is_empty() and game.state["belfry"]["discoveries"].is_empty(), "new hero resets the milestone and collection records")
