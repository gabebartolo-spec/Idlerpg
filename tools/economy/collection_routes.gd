extends SceneTree

# R10 sensitivity experiment: actual daily simulation and collection code, one seeded
# account per cell. Hypothetical token purchases/income, not a live paid product.
const Game = preload("res://src/game.gd")
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Gear = preload("res://src/data/gear_catalog.gd")
const Talent = preload("res://src/data/talent_catalog.gd")
const Companion = preload("res://src/data/companion_catalog.gd")
const Relic = preload("res://src/data/relic_catalog.gd")
const PATTERN := ["gear", "gear", "companions", "gear", "relics"]
const CHECKPOINTS := [1, 7, 30, 90, 180]
var failures := 0
func _init() -> void:
	call_deferred("_run")

func score(item: String) -> int:
	return Gear.attack_bonus(item) * 2 + Gear.hp_bonus(item)

func prepare(sim: Node, game: Node) -> void:
	for item in sim.owned_gear_names():
		if score(item) > score(sim.equipped_item(Gear.slot(item))):
			sim.equip_gear(item)
	for branch in Talent.branch_ids():
		for talent in Talent.nodes_for_branch(branch):
			if sim.can_unlock_talent(talent):
				sim.unlock_talent(talent)
	var best := -1
	for name in game.collection_items("companions"):
		var rank := ["Common", "Rare", "Epic", "Legendary"].find(Companion.rarity(name))
		if game.collection_count("companions", name) > 0 and rank > best:
			best = rank
			if sim.active_companion != name:
				sim.set_active_companion(name)
	var relic_score := Relic.attack(sim.active_relic) * 2 + Relic.hp(sim.active_relic)
	for name in Relic.ITEMS:
		var value := Relic.attack(name) * 2 + Relic.hp(name)
		if sim.owns_relic(name, game) and value > relic_score:
			sim.equip_relic(name, game)
			relic_score = value

func cell(income: int, purchases: int) -> Dictionary:
	var game := Game.new()
	var sim := Sim.new()
	root.add_child(game)
	root.add_child(sim)
	game.set_seed(101)
	sim.drop_seed = 101
	var paid := 0
	var refunds := 0
	var salvage := 0
	var pulls := 0
	var novelty := 0
	var useful := 0
	var bonuses := 0
	var checkpoints := {}
	var pattern_index := 0
	for day in range(1, 181):
		game.grant_tokens(income + purchases)
		while game.gacha_tokens >= game.SUMMON_COST:
			var banner: String = PATTERN[pattern_index % PATTERN.size()]
			pattern_index += 1
			if game.pursuits.get(banner, {}).is_empty():
				for name in game.collection_items(banner):
					if game.collection_count(banner, name) == 0 and not (banner == "relics" and sim.earned_relics.has(name)):
						game.choose_pursuit(banner, name)
						break
			var before_power: int = sim.effective_attack() * 2 + sim.effective_max_hp()
			var receipt: Dictionary = game.pull(banner, 1)
			paid += receipt["cost"]
			refunds += receipt["refunds"]
			pulls += 1
			for result in receipt["results"]:
				if result["is_new"]:
					novelty += 1
				if result.get("route_bonus", false):
					bonuses += 1
				if banner == "gear":
					sim.add_gear(result["name"])
			prepare(sim, game)
			if sim.effective_attack() * 2 + sim.effective_max_hp() > before_power:
				useful += 1
			# Keep one owned copy; salvage additional banner gear and reinvest.
			for item in sim.owned_gear_names():
				while sim.gear_count(item) > 1:
					var tokens := Gear.salvage_tokens(item)
					if tokens == 0 or not sim.salvage_gear(item).get("ok", false):
						break
					game.grant_tokens(tokens)
					salvage += tokens
		prepare(sim, game)
		sim.simulate_offline(86400.0)
		prepare(sim, game)
		if game.gacha_tokens != game.STARTING_TOKENS + day * (income + purchases) + refunds + salvage - paid:
			failures += 1
		if day in CHECKPOINTS:
			var unique := game.collected_unique("gear") + game.collected_unique("companions") + game.collected_unique("relics")
			checkpoints[str(day)] = {"level": sim.hero_level, "attack": sim.effective_attack(), "health": sim.effective_max_hp(),
				"boss_rank": sim.thornback_rank, "draws": pulls, "new_items": novelty, "useful_draws": useful,
				"unique": unique, "saturated": unique == 45, "route_bonuses": bonuses,
				"tokens_spent": paid, "duplicate_refunds": refunds, "salvage": salvage,
				"world_counters_owned": sim.gear_count("Briarheart Charm") > 0 and sim.gear_count("Briarhook") > 0}
			print("Checkpoint income=%d purchases=%d day=%d" % [income, purchases, day])
	game.free()
	sim.free()
	return checkpoints

func _run() -> void:
	if "--render-only" in OS.get_cmdline_user_args():
		write_tables(JSON.parse_string(FileAccess.get_file_as_string("res://docs/economy/collection_route_results.json")))
		quit()
		return
	var results := {"seed": 101, "days": 180, "accounts_per_cell": 1, "starting_tokens": 250,
		"assumptions": "Daily check-in autopilot; purchases are hypothetical tokens/day. Useful means a draw immediately increased the selected build's attack*2+HP score. No boosts or extra drop access. Travel preference, player enjoyment and population tails are not modeled.", "cells": {}}
	for income in [0, 120]:
		for cohort in {"free": 0, "light": 120, "high": 600}:
			results["cells"]["%s/income%d" % [cohort, income]] = cell(income, {"free": 0, "light": 120, "high": 600}[cohort])
	results["ledger_failures"] = failures
	var file := FileAccess.open("res://docs/economy/collection_route_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	file.close()
	write_tables(results)
	print("Collection route economy complete: %d ledger failure(s)" % failures)
	quit(failures)

func write_tables(results: Dictionary) -> void:
	var lines: Array[String] = ["# R10 collection-route sensitivity results", "",
		"Generated from collection_route_results.json by tools/economy/collection_routes.gd. Seed 101, one account per cell, real daily offline combat through day 180. Zero token ledger failures.", "",
		"Purchases are hypothetical 0/120/600 tokens per day for free/light/high cohorts; income is either implemented zero or hypothetical 120/day. No live income rule or paid product is introduced. This small deterministic sample is not a population, enjoyment or fairness study.", "",
		"Useful = an immediate increase in the autopilot's attack*2+HP build score. New items and route bonuses are counted separately. Saturation = all 45 banner items collected; earned relic alternatives are also available in the game but are not counted as banner draws.", "",
		"| Cell | Day | Paid draws | New items | Useful draws | Route bonuses | Unique /45 | Saturated |",
		"|---|---:|---:|---:|---:|---:|---:|---|"]
	for key in results["cells"]:
		for day in CHECKPOINTS:
			var entry: Dictionary = results["cells"][key][str(day)]
			lines.append("| %s | %d | %d | %d | %d | %d | %d | %s |" % [key, day, entry["draws"], entry["new_items"], entry["useful_draws"], entry["route_bonuses"], entry["unique"], "yes" if entry["saturated"] else "no"])
	lines.append_array(["", "## Resulting combat power relative to the free cohort", "",
		"| Cell | Day | Level | Attack | HP | Attack / free | HP / free | Boss rank | Free counters owned |",
		"|---|---:|---:|---:|---:|---:|---:|---:|---|"])
	for key in results["cells"]:
		var reference: Dictionary = results["cells"]["free/" + str(key).get_slice("/", 1)]
		for day in [30, 90, 180]:
			var entry: Dictionary = results["cells"][key][str(day)]
			var free: Dictionary = reference[str(day)]
			lines.append("| %s | %d | %d | %d | %d | %.4f | %.4f | %d | %s |" % [key, day, entry["level"], entry["attack"], entry["health"], float(entry["attack"]) / float(free["attack"]), float(entry["health"]) / float(free["health"]), entry["boss_rank"], "yes" if entry["world_counters_owned"] else "no"])
	lines.append_array(["", "The no-income free account stops at 26 draws and 18 unique items. Cells with recurring tokens reach functional saturation by day 30; cumulative useful draws then stop increasing. The cosmetic keepsakes are finite and grant no power. These outcomes support examining earned income in R11 and later cosmetic/journal pursuits, not inflating duplicate stats.", "",
		"Some purchased cohorts have less modeled power than the free cohort: greedy companion rarity and attack/HP choices do not optimize travel or encounter progression. Uncapped levels dominate long-term stats. This is a limitation of the current autopilot and progression model, not proof that spending is harmless. Boosts, extra drop access, player build choices and population tails are excluded.", ""])
	var file := FileAccess.open("res://docs/economy/collection_route_tables.md", FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
