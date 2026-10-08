extends RefCounted

# Economy baseline for IRPG-R01. It drives the game's real state and simulation
# (src/game.gd, src/sim/adventurer_sim.gd and the catalogues) with a fixed autopilot
# player, so the numbers describe the implemented economy, not a separate model of it.
#
# Two samples per cell (a cohort under an income scenario):
#   collection  many accounts, pulls and gear only, every day of the run. Exact.
#   progression a few accounts with the combat simulation stepped in full for `sim_hours`,
#               then projected. The simulation has no randomness, so a few is enough.
#
# The autopilot, at each check-in: learn talents in a fixed order; spend tokens one pull
# at a time following `pull_pattern`; equip a gear item if it beats what is worn; travel
# with the highest-rarity companion owned; salvage every duplicate and reinvest.
# Definitions and limits: docs/ECONOMY_BASELINE.md.

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const Relics = preload("res://src/data/relic_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")

const DAY := 86400.0
const CHECK_IN := 600.0
# The first hour is watched more closely: the first quests, boss and talents all land in it.
const EARLY_CHECK_IN := 10.0
const EARLY_SECONDS := 3600.0
const RARITY_RANK := {"Common": 0, "Rare": 1, "Epic": 2, "Legendary": 3}
const WORLD_DROPS := ["Goblin Cleaver", "Wolfskin Hood", "Briarheart Charm"]

var host: Node
var inputs: Dictionary = {}
var ledger_failures: Array[String] = []
var _gear_score: Dictionary = {}
var _gear_slot: Dictionary = {}
var _gear_salvage: Dictionary = {}
var _talent_order: Array[String] = []
var _companion_rank: Dictionary = {"": -1}


class Account:
	var game: Node
	var sim: Node
	var stepped: bool = false
	var pull_index: int = 0
	var tokens_started: int = 0
	var tokens_purchased: int = 0
	var tokens_income: int = 0
	var tokens_salvaged: int = 0
	var tokens_duplicates: int = 0
	var tokens_spent: int = 0
	var gold_from_quests: int = 0
	var gold_from_discoveries: int = 0
	var gold_from_goals: int = 0
	# Per day, index 1..days.
	var draws: PackedInt32Array
	var new_draws: PackedInt32Array
	var useful_draws: PackedInt32Array
	var relic_draws: PackedInt32Array
	var target_day: int = 0
	var gear_complete_day: int = 0
	var snapshots: Dictionary = {}
	var sim_points: Dictionary = {}
	var all_talents_seconds: float = -1.0
	var boss_first_kill_seconds: float = -1.0
	var clock: float = 0.0
	var step: float = 0.0
	var world_drops_handled: Dictionary = {}

	func on_event(event: Dictionary) -> void:
		var type := str(event.get("type", ""))
		if type == "quest_completed":
			gold_from_quests += int(event.get("gold", 0))
		if type == "goal_completed":
			gold_from_goals += int(event.get("gold", 0))
		if type == "world_discovery":
			gold_from_discoveries += int(event.get("gold", 0))
		elif type == "enemy_defeated" and str(event.get("enemy", "")) == "thornback" and boss_first_kill_seconds < 0.0:
			# Known to the nearest check-in: it happened during the step just simulated.
			boss_first_kill_seconds = clock + step


func run(run_inputs: Dictionary, host_node: Node) -> Dictionary:
	inputs = run_inputs
	host = host_node
	ledger_failures.clear()
	for item_name in GearCatalogScript.ITEMS:
		var weights: Dictionary = inputs["upgrade_score"]
		_gear_score[item_name] = GearCatalogScript.attack_bonus(item_name) * int(weights["attack"]) + GearCatalogScript.hp_bonus(item_name) * int(weights["hp"])
		_gear_slot[item_name] = GearCatalogScript.slot(item_name)
		_gear_salvage[item_name] = GearCatalogScript.salvage_tokens(item_name)
	for companion_name in CompanionCatalogScript.COMPANIONS:
		_companion_rank[companion_name] = int(RARITY_RANK[CompanionCatalogScript.rarity(companion_name)])
	_talent_order.clear()
	for branch_id in TalentCatalogScript.branch_ids():
		_talent_order.append_array(TalentCatalogScript.nodes_for_branch(branch_id))

	var cells := {}
	for scenario in inputs["income_scenarios"]:
		for cohort in inputs["cohorts"]:
			cells["%s/%s" % [cohort, scenario]] = _run_cell(cohort, scenario)

	return {
		"inputs": inputs,
		"catalogue": _catalogue(),
		"cells": cells,
		"power_gaps": _power_gaps(cells),
		"ledger_failures": ledger_failures.size()
	}


func _catalogue() -> Dictionary:
	var game: Node = GameStateScript.new()
	var banners := {}
	for banner_id in game.BANNERS:
		var by_rarity := {}
		for rarity in game.BANNERS[banner_id]["items"]:
			by_rarity[rarity] = (game.BANNERS[banner_id]["items"][rarity] as Array).size()
		banners[banner_id] = by_rarity
	var result := {
		"banners": banners,
		"summon_cost": game.SUMMON_COST,
		"starting_tokens": game.STARTING_TOKENS,
		"salvage_tokens": GearCatalogScript.SALVAGE_TOKENS,
		"world_drops": WORLD_DROPS,
		"talents": _talent_order.size(),
		"gold_sinks": 0
	}
	game.free()
	return result


func _new_account(seed_value: int, stepped: bool) -> Account:
	var account := Account.new()
	account.stepped = stepped
	account.game = GameStateScript.new()
	host.add_child(account.game)
	account.game.set_seed(seed_value)
	account.sim = AdventurerSimScript.new()
	host.add_child(account.sim)
	account.tokens_started = account.game.gacha_tokens
	var days: int = int(inputs["days"])
	for series in ["draws", "new_draws", "useful_draws", "relic_draws"]:
		var values := PackedInt32Array()
		values.resize(days + 1)
		account.set(series, values)
	if stepped:
		account.sim.event_emitted.connect(account.on_event)
	return account


func _run_cell(cohort: String, scenario: String) -> Dictionary:
	var days: int = int(inputs["days"])
	var purchases: Array = inputs["cohorts"][cohort]["purchases"]
	var income: int = int(inputs["income_scenarios"][scenario])

	var collection: Array[Account] = []
	for index in int(inputs["collection_accounts"]):
		# The same seeds in every cell, so cohorts are compared on the same luck.
		var account := _new_account(int(inputs["seed"]) + index, false)
		for item_name in WORLD_DROPS:
			_gain_gear(account, item_name)
		for day in range(1, days + 1):
			_start_day(account, day, purchases, income)
			_check_in(account, day)
			_end_day(account, day)
		_check_ledger(account, "%s/%s #%d" % [cohort, scenario, index])
		account.game.free()
		account.sim.free()
		collection.append(account)

	var progression: Array[Account] = []
	var sim_seconds: float = min(float(days) * DAY, float(inputs["sim_hours"]) * 3600.0)
	for index in int(inputs["sim_accounts"]):
		var account := _new_account(int(inputs["seed"]) + index, true)
		var day := 0
		while account.clock < sim_seconds - 0.001:
			var today := int(account.clock / DAY) + 1
			if today != day:
				day = today
				_start_day(account, day, purchases, income)
				_check_in(account, day)
			account.step = EARLY_CHECK_IN if account.clock < EARLY_SECONDS - 0.001 else CHECK_IN
			account.sim.simulate_elapsed(account.step)
			account.clock += account.step
			_check_in(account, day)
			var hour := account.clock / 3600.0
			if is_equal_approx(hour, round(hour)) and inputs["sim_checkpoint_hours"].has(float(round(hour))):
				account.sim_points[int(round(hour))] = _sim_point(account)
		_check_ledger(account, "%s/%s sim #%d" % [cohort, scenario, index])
		account.game.free()
		account.sim.free()
		progression.append(account)

	return {
		"collection": _summarise_collection(collection),
		"progression": _summarise_progression(progression)
	}


func _start_day(account: Account, day: int, purchases: Array, income: int) -> void:
	if income > 0:
		account.game.grant_tokens(income)
		account.tokens_income += income
	for purchase in purchases:
		var first: int = int(purchase["first_day"])
		var every: int = int(purchase.get("every_days", 0))
		if day == first or (every > 0 and day > first and (day - first) % every == 0):
			account.game.grant_tokens(int(purchase["tokens"]))
			account.tokens_purchased += int(purchase["tokens"])


func _check_in(account: Account, day: int) -> void:
	var sim := account.sim
	var game := account.game
	if account.stepped and sim.talent_points_available() > 0:
		for talent_id in _talent_order:
			sim.unlock_talent(talent_id)
		if account.all_talents_seconds < 0.0 and sim.talent_points_spent() == _talent_order.size():
			account.all_talents_seconds = account.clock

	if account.stepped:
		# Quest rewards arrive from the simulation; wear them if they beat what is worn.
		for item_name in WORLD_DROPS:
			if not account.world_drops_handled.has(item_name) and sim.gear_count(item_name) > 0:
				account.world_drops_handled[item_name] = true
				if int(_gear_score[item_name]) > int(_gear_score.get(sim.equipped_item(_gear_slot[item_name]), 0)):
					sim.equip_gear(item_name)

	_choose_relic(account)
	var pattern: Array = inputs["pull_pattern"]
	var cost: int = game.SUMMON_COST
	while game.gacha_tokens >= cost:
		var banner: String = pattern[account.pull_index % pattern.size()]
		account.pull_index += 1
		var response: Dictionary = game.pull(banner, 1)
		account.tokens_duplicates += int(response["refunds"])
		var result: Dictionary = response["results"][0]
		account.tokens_spent += cost
		account.draws[day] += 1
		if bool(result["is_new"]):
			account.new_draws[day] += 1
		var item_name: String = result["name"]
		if banner == "gear":
			if _gain_gear(account, item_name):
				account.useful_draws[day] += 1
			if account.target_day == 0 and item_name == inputs["target_item"]:
				account.target_day = day
			if account.gear_complete_day == 0 and bool(result["is_new"]) and game.collected_unique("gear") == game.banner_item_count("gear"):
				account.gear_complete_day = day
		elif banner == "companions":
			if int(_companion_rank[item_name]) > int(_companion_rank[sim.active_companion]):
				sim.set_active_companion(item_name)
				account.useful_draws[day] += 1
		else:
			account.relic_draws[day] += 1
			if _choose_relic(account):
				account.useful_draws[day] += 1


# Uses the existing documented attack/HP score; this scripted player does not value
# travel effects. Real build preference is a player-research question.
func _choose_relic(account: Account) -> bool:
	var weights: Dictionary = inputs["upgrade_score"]
	var selected: String = account.sim.active_relic
	var best: int = Relics.attack(selected) * int(weights["attack"]) + Relics.hp(selected) * int(weights["hp"])
	for name in Relics.ITEMS:
		var score: int = Relics.attack(name) * int(weights["attack"]) + Relics.hp(name) * int(weights["hp"])
		if account.sim.owns_relic(name, account.game) and score > best:
			selected = name
			best = score
	if selected == account.sim.active_relic:
		return false
	return account.sim.equip_relic(selected, account.game)

# Adds a gear item, equips it if it beats what is worn, and salvages a duplicate.
# Returns true if it was an upgrade.
func _gain_gear(account: Account, item_name: String) -> bool:
	var sim := account.sim
	sim.add_gear(item_name)
	var worn: String = sim.equipped_item(_gear_slot[item_name])
	var upgrade: bool = int(_gear_score[item_name]) > int(_gear_score.get(worn, 0))
	if upgrade:
		sim.equip_gear(item_name)
	if sim.gear_count(item_name) > 1 and bool(sim.salvage_gear(item_name).get("ok", false)):
		account.game.grant_tokens(int(_gear_salvage[item_name]))
		account.tokens_salvaged += int(_gear_salvage[item_name])
	return upgrade


func _end_day(account: Account, day: int) -> void:
	if not inputs["checkpoints"].has(float(day)):
		return
	var game := account.game
	var gear_attack := 0
	var gear_hp := 0
	for item_name in account.sim.equipped.values():
		if not str(item_name).is_empty():
			gear_attack += GearCatalogScript.attack_bonus(str(item_name))
			gear_hp += GearCatalogScript.hp_bonus(str(item_name))
	account.snapshots[day] = {
		"gear": game.collected_unique("gear"),
		"companions": game.collected_unique("companions"),
		"relics": game.collected_unique("relics"),
		"gear_attack": gear_attack,
		"gear_hp": gear_hp,
		"tokens": game.gacha_tokens
	}


func _check_ledger(account: Account, label: String) -> void:
	var expected := account.tokens_started + account.tokens_purchased + account.tokens_income + account.tokens_salvaged + account.tokens_duplicates - account.tokens_spent
	if expected != account.game.gacha_tokens or account.game.gacha_tokens < 0:
		ledger_failures.append("%s: tokens %d, ledger says %d" % [label, account.game.gacha_tokens, expected])
	var gold_earned: int = account.gold_from_quests + account.gold_from_discoveries + account.gold_from_goals
	if account.stepped and gold_earned != account.sim.gold:
		ledger_failures.append("%s: gold %d, ledger says %d" % [label, account.sim.gold, gold_earned])


func _sim_point(account: Account) -> Dictionary:
	var sim := account.sim
	var gear_attack := 0
	for item_name in sim.equipped.values():
		if not str(item_name).is_empty():
			gear_attack += GearCatalogScript.attack_bonus(str(item_name))
	return {
		"level": sim.hero_level,
		"total_xp": 15 * sim.hero_level * (sim.hero_level - 1) + sim.hero_xp,
		"attack": sim.effective_attack(),
		"health": sim.effective_max_hp(),
		"attack_not_from_level": sim.effective_attack() - sim.hero_attack,
		"health_not_from_level": sim.effective_max_hp() - sim.hero_max_hp,
		"gear_attack": gear_attack,
		"gold": sim.gold,
		"quests": sim.quest_cycles_completed,
		"deaths": sim.deaths,
		"talents": sim.talent_points_spent(),
		"talent_points_unspent": sim.talent_points_available()
	}


static func _stats(values: Array) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted:
		total += float(value)
	var count: int = sorted.size()
	return {
		"mean": snappedf(total / max(1, count), 0.01),
		"p10": sorted[int(floor((count - 1) * 0.1))],
		"p50": sorted[int(floor((count - 1) * 0.5))],
		"p90": sorted[int(floor((count - 1) * 0.9))]
	}


func _summarise_collection(accounts: Array[Account]) -> Dictionary:
	var count: int = accounts.size()
	var days: int = int(inputs["days"])

	var windows := {}
	for window in inputs["windows"]:
		var first: int = int(window[0])
		var last: int = min(int(window[1]), days)
		if first > days:
			continue
		var draws := 0
		var new_draws := 0
		var useful := 0
		var relics := 0
		for account in accounts:
			for day in range(first, last + 1):
				draws += account.draws[day]
				new_draws += account.new_draws[day]
				useful += account.useful_draws[day]
				relics += account.relic_draws[day]
		var span: int = last - first + 1
		windows["days_%d_%d" % [first, last]] = {
			"draws_per_account_per_day": snappedf(float(draws) / count / span, 0.01),
			"new_item_share": snappedf(float(new_draws) / max(1, draws), 0.0001),
			"useful_share": snappedf(float(useful) / max(1, draws), 0.0001),
			"no_effect_share": snappedf(float(relics) / max(1, draws), 0.0001),
			"useful_per_account_per_day": snappedf(float(useful) / count / span, 0.0001)
		}

	var checkpoints := {}
	for day_value in inputs["checkpoints"]:
		var day: int = int(day_value)
		if day > days:
			continue
		var point := {}
		for key in ["gear", "companions", "relics", "gear_attack", "gear_hp", "tokens"]:
			var values: Array = []
			for account in accounts:
				values.append(account.snapshots[day][key])
			point[key] = _stats(values)
		var with_target := 0
		var gear_complete := 0
		for account in accounts:
			if account.target_day > 0 and account.target_day <= day:
				with_target += 1
			if account.gear_complete_day > 0 and account.gear_complete_day <= day:
				gear_complete += 1
		point["target_item_share"] = snappedf(float(with_target) / count, 0.0001)
		point["gear_banner_complete_share"] = snappedf(float(gear_complete) / count, 0.0001)
		checkpoints["day_%d" % day] = point

	var ledger := {}
	for key in ["tokens_started", "tokens_purchased", "tokens_income", "tokens_salvaged", "tokens_duplicates", "tokens_spent"]:
		var total := 0.0
		for account in accounts:
			total += float(account.get(key))
		ledger[key] = snappedf(total / count, 0.01)
	ledger["salvage_returned_per_token_spent"] = snappedf(float(ledger["tokens_salvaged"]) / max(1.0, float(ledger["tokens_spent"])), 0.0001)

	return {"accounts": count, "windows": windows, "checkpoints": checkpoints, "token_ledger": ledger}


func _summarise_progression(accounts: Array[Account]) -> Dictionary:
	if accounts.is_empty():
		return {}
	var points := {}
	var hours: Array = accounts[0].sim_points.keys()
	hours.sort()
	for hour in hours:
		var point := {}
		for key in accounts[0].sim_points[hour]:
			var total := 0.0
			var low := INF
			var high := -INF
			for account in accounts:
				var value := float(account.sim_points[hour][key])
				total += value
				low = min(low, value)
				high = max(high, value)
			point[key] = {"mean": snappedf(total / accounts.size(), 0.01), "min": low, "max": high}
		points["hour_%d" % hour] = point

	var all_talents: Array = []
	var boss: Array = []
	for account in accounts:
		all_talents.append(account.all_talents_seconds)
		boss.append(account.boss_first_kill_seconds)
	var summary := {
		"accounts": accounts.size(),
		"points": points,
		"seconds_to_all_talents": all_talents,
		"seconds_to_first_boss_kill": boss
	}
	summary["projection"] = _project(points)
	return summary


# Beyond the stepped days, experience is extrapolated at the rate of the last stepped
# stretch, and level follows from the game's own curve (level L costs 30 * L experience).
# Attack and health not from level are held at their last stepped value. A projection,
# checked by predicting the last stepped point from the stretch before it.
func _project(points: Dictionary) -> Dictionary:
	var hours: Array = []
	for key in points:
		hours.append(int(str(key).trim_prefix("hour_")))
	hours.sort()
	if hours.size() < 3:
		return {}
	var last: int = hours[-1]
	var previous: int = hours[-2]
	var earlier: int = hours[-3]
	var xp_last: float = points["hour_%d" % last]["total_xp"]["mean"]
	var xp_previous: float = points["hour_%d" % previous]["total_xp"]["mean"]
	var xp_earlier: float = points["hour_%d" % earlier]["total_xp"]["mean"]

	var check_rate := (xp_previous - xp_earlier) / float(previous - earlier)
	var predicted_level := _level_for(xp_previous + check_rate * float(last - previous))
	var actual_level: float = points["hour_%d" % last]["level"]["mean"]

	var rate := (xp_last - xp_previous) / float(last - previous)
	var extra_attack: float = points["hour_%d" % last]["attack_not_from_level"]["mean"]
	var extra_health: float = points["hour_%d" % last]["health_not_from_level"]["mean"]
	var result := {
		"xp_per_hour": snappedf(rate, 0.01),
		"check_predicted_level_at_last_point": snappedf(predicted_level, 0.1),
		"check_actual_level_at_last_point": actual_level,
		"days": {}
	}
	for day_value in inputs["checkpoints"]:
		var day: int = int(day_value)
		if day * 24 <= last or day > int(inputs["days"]):
			continue
		var level := _level_for(xp_last + rate * float(day * 24 - last))
		result["days"]["day_%d" % day] = {
			"level": snappedf(level, 0.1),
			"attack": snappedf(6.0 + (level - 1.0) + extra_attack, 0.1),
			"health": snappedf(36.0 + 5.0 * (level - 1.0) + extra_health, 0.1)
		}
	return result


static func _level_for(total_xp: float) -> float:
	# total_xp = 15 * L * (L - 1)
	return (1.0 + sqrt(1.0 + 4.0 * total_xp / 15.0)) / 2.0


# Attack and health of each cohort relative to the free cohort under the same income.
func _power_gaps(cells: Dictionary) -> Dictionary:
	var gaps := {}
	for scenario in inputs["income_scenarios"]:
		var free_cell: Dictionary = cells["free/%s" % scenario]["progression"]
		if free_cell.is_empty():
			continue
		for cohort in inputs["cohorts"]:
			if cohort == "free":
				continue
			var cell: Dictionary = cells["%s/%s" % [cohort, scenario]]["progression"]
			var gap := {}
			for key in cell["points"]:
				gap[key] = _ratio(cell["points"][key]["attack"]["mean"], cell["points"][key]["health"]["mean"],
					free_cell["points"][key]["attack"]["mean"], free_cell["points"][key]["health"]["mean"])
			for key in cell["projection"].get("days", {}):
				var mine: Dictionary = cell["projection"]["days"][key]
				var theirs: Dictionary = free_cell["projection"]["days"][key]
				gap[key + "_projected"] = _ratio(mine["attack"], mine["health"], theirs["attack"], theirs["health"])
			gaps["%s/%s" % [cohort, scenario]] = gap
	return gaps


static func _ratio(attack: float, health: float, free_attack: float, free_health: float) -> Dictionary:
	return {
		"attack_ratio": snappedf(attack / free_attack, 0.001),
		"health_ratio": snappedf(health / free_health, 0.001)
	}
