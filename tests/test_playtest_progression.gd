extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Persistence = preload("res://src/state/persistence.gd")
const Builds = preload("res://src/data/lantern_build_catalog.gd")
const ROUTES := ["greenway", "causeway", "hollow", "rise", "mothwatch", "moonwell", "lamplighter"]
var failures := 0
var results: Array[Dictionary] = []
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func pair() -> Array[Node]:
	var sim: Node = Sim.new()
	var game: Node = Game.new()
	root.add_child(sim)
	root.add_child(game)
	return [sim, game]
func prepare(sim: Node) -> void:
	# Only owned guaranteed gear; no grant calls, draws, stat edits or gate edits.
	for item in ["Goblin Cleaver", "Wolfskin Hood", "Briarheart Charm"]:
		if sim.gear_count(item) > 0: sim.equip_gear(item)
	for talent in ["thick_hide", "heavy_hand", "sharpened_edge"]:
		if sim.can_unlock_talent(talent): sim.unlock_talent(talent)
func choose(sim: Node) -> String:
	if sim.expedition.active or sim.expedition.requested: return ""
	for route in ROUTES:
		if not sim.expedition.claimed_routes.has(route) and sim.request_expedition(route): return route
	var least := "mothwatch"
	for route in ["moonwell", "lamplighter"]:
		if int(sim.expedition.route_clears.get(route, 0)) < int(sim.expedition.route_clears.get(least, 0)): least = route
	return least if sim.request_expedition(least) else ""
func scenario(interval_hours: int) -> void:
	var path := "user://playtest_progression_%d_%d.json" % [Time.get_ticks_usec(), interval_hours]
	var nodes := pair()
	var sim: Node = nodes[0]
	var game: Node = nodes[1]
	check(sim.gear_inventory.is_empty() and sim.expedition.claimed_routes.is_empty() and sim.hero_level == 1, "scenario begins with real fresh progression")
	sim.set_hunt_target("") # Player opts out of all random hunt drops.
	var visits: Array[Dictionary] = []
	var first_owned := {}
	var base := 1000000
	var now := base
	sim.simulate_elapsed(60)
	for hour in range(0, 169, interval_hours):
		var report := {}
		var catch_up := 0
		if hour > 0:
			nodes = pair()
			var old_sim: Node = sim
			var old_game: Node = game
			sim = nodes[0]
			game = nodes[1]
			now = base + hour * 3600
			report = Persistence.load_and_advance(sim, game, now, path)
			check(report.get("loaded", false) and not report.get("save_failed", false), "real save and catch-up restore at hour %d (%dh cadence)" % [hour, interval_hours])
			catch_up = int(report.get("catch_up_msec", 0))
			old_sim.free()
			old_game.free()
			var replay := pair()
			var again := Persistence.load_and_advance(replay[0], replay[1], now, path)
			check(int(again.get("elapsed_simulated", -1)) == 0 and replay[0].report_counters() == sim.report_counters() and replay[0].reward_chests.to_save_dict() == sim.reward_chests.to_save_dict() and replay[0].expedition.to_save_dict() == sim.expedition.to_save_dict(), "reopening the same return cannot replay progress or chests")
			replay[0].free()
			replay[1].free()
		prepare(sim)
		var opened: Array[Dictionary] = []
		while not sim.reward_chests.pending.is_empty():
			opened.append(sim.claim_reward_chest(sim.reward_chests.pending[0]["id"]))
		for item in ["Goblin Cleaver", "Wolfskin Hood", "Briarheart Charm", "Mothglass Spear", "Mooncap Mantle", "Lamplighter Seal"]:
			if sim.gear_count(item) > 0 and not first_owned.has(item): first_owned[item] = hour
		var next := choose(sim) if hour < 168 else ""
		sim.simulate_elapsed(30)
		now += 30 if hour > 0 else 90
		check(Persistence.save(sim, game, now, path), "short session persists its choices and rewards")
		visits.append({"hour": hour, "scripted_live_seconds": 90 if hour == 0 else 30, "level": sim.hero_level, "gold": sim.gold, "boss_rank": sim.thornback_rank, "queued": next, "active_route": sim.expedition.route if sim.expedition.active else "", "route_clears": sim.expedition.route_clears.duplicate(), "opened": opened, "catch_up_msec_desktop": catch_up})
	check(first_owned.has_all(["Mothglass Spear", "Mooncap Mantle", "Lamplighter Seal"]), "all regional gear is earned from a fresh save in seven scripted days")
	check(sim.goals.completed.has("lantern_kit") and sim.expedition.claimed_routes.size() == 7, "fresh-save route gates and keepsake achievement are genuinely completed")
	check(game.collection.get("gear", {}).is_empty() and game.collection.get("companions", {}).is_empty(), "the progression scenario used no summon draws")
	# Three saveable loadouts use only gear earned by this scenario.
	for spec in [[0, "Striker", "Mothglass Spear", "", ""], [1, "Guardian", "Goblin Cleaver", "Mooncap Mantle", ""], [2, "Lamplighter", "Goblin Cleaver", "", "Lamplighter Seal"]]:
		for slot in sim.equipped.keys():
			if not sim.equipped_item(slot).is_empty(): sim.unequip_gear(sim.equipped_item(slot))
		sim.equip_gear("Wolfskin Hood")
		sim.equip_gear(spec[2])
		if not spec[3].is_empty(): sim.equip_gear(spec[3])
		if not spec[4].is_empty(): sim.equip_gear(spec[4])
		check(sim.loadouts.save_current(spec[0], spec[1], sim), "earned " + spec[1] + " can be saved as a loadout")
	check(Persistence.save(sim, game, now, path), "earned builds checkpoint")
	var restored := pair()
	Persistence.load_and_advance(restored[0], restored[1], now, path)
	for index in 3:
		check(restored[0].loadouts.apply(index, restored[0], restored[1]).get("ok", false), "earned saved loadout restores and applies without missing gear")
	for id in Builds.BUILDS:
		check(Builds.apply(id, restored[0]), "build recipe applies only actual earned pieces: " + id)
		restored[0].stop_expedition()
		check(restored[0].request_expedition("lamplighter"), "earned build can select the deepest regional pursuit")
		restored[0].simulate_offline(25 * 3600)
		check(restored[0].expedition.recap.get("won", false) and restored[0].expedition.recap.get("route", "") == "lamplighter", "actual post-study earned build completes its deep journey: " + id)
	results.append({"scenario": "%dh scripted return cadence" % interval_hours, "first_owned_hour": first_owned, "final_level": sim.hero_level, "completed_goals": sim.goals.completed.duplicate(), "visits": visits})
	for node in [sim, game, restored[0], restored[1]]: node.free()
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
func run() -> void:
	var fresh := pair()
	var before: Dictionary = fresh[0].to_save_dict()
	check(not Builds.apply("striker", fresh[0]) and fresh[0].to_save_dict() == before, "missing recipe pieces change neither equipment nor talents")
	fresh[0].free()
	fresh[1].free()
	scenario(12)
	scenario(8)
	var report := {"kind": "automated progression evidence, not participant data", "duration_hours": 168, "failures": failures, "scenarios": results}
	var args := OS.get_cmdline_user_args()
	if args.has("--report"):
		var index := args.find("--report") + 1
		if index < args.size():
			var file := FileAccess.open(args[index], FileAccess.WRITE)
			if file != null: file.store_string(JSON.stringify(report, "\t"))
	for result in results: print("EVIDENCE: ", result["scenario"], " first owned hours ", result["first_owned_hour"], " final level ", result["final_level"])
	print("Fresh-save playtest progression: %d failure(s)" % failures)
	quit(failures)
