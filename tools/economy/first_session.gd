extends SceneTree

# Issue #45, first action: how fast does an ORDINARY new save progress?
#   godot --headless --path . -s res://tools/economy/first_session.gd
# Writes docs/economy/first_session_tables.md and first_session_results.json.
#
# A brand-new save, the real game code, developer features never touched. The scripted
# player is one policy, not a person: it learns talents in catalogue order, wears any gear
# that scores higher (attack counts double), and spends every summon token at once. Two
# summon policies bound the luck: all on the gear banner (the best case for "full legendary
# set" claims) and the usual mixed pattern. Check-ins are every 10 s for the first 15
# minutes, every minute to the first hour, then every 10 minutes (offline catch-up).
# Reads no files and no saves. Same seeds, same output.

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")

const SEEDS := [20261010, 20261011, 20261012, 20261013, 20261014]
const CHECKPOINTS := {"5 min": 300.0, "15 min": 900.0, "30 min": 1800.0, "1 h": 3600.0, "24 h": 86400.0, "7 days": 604800.0}
const MIXED := ["gear", "gear", "gear", "companions", "companions", "gear", "gear", "relics", "companions", "gear", "companions", "relics"]
const RESULTS := "res://docs/economy/first_session_results.json"
const TABLES := "res://docs/economy/first_session_tables.md"

var _talent_order: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for branch_id in TalentCatalogScript.branch_ids():
		_talent_order.append_array(TalentCatalogScript.nodes_for_branch(branch_id))
	var results := {"talents_in_game": _talent_order.size(), "policies": {}}
	for policy in ["gear_only", "mixed"]:
		var runs: Array = []
		for seed_value in SEEDS:
			runs.append(_play(int(seed_value), policy))
		results["policies"][policy] = runs
	_write(RESULTS, JSON.stringify(results, "\t") + "\n")
	_write(TABLES, _tables(results))
	print(_tables(results))
	quit(0)

func _play(seed_value: int, policy: String) -> Dictionary:
	var game: Node = GameStateScript.new()
	root.add_child(game)
	game.set_seed(seed_value)
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	var clock := 0.0
	var points: Dictionary = {}
	var pull_index := 0
	var dev_flag: bool = game.dev_infinite_tokens
	var next_point := 0
	var labels: Array = CHECKPOINTS.keys()
	while next_point < labels.size():
		var goal: float = CHECKPOINTS[labels[next_point]]
		var step := 10.0 if clock < 900.0 else (60.0 if clock < 3600.0 else 600.0)
		step = minf(step, goal - clock)
		if clock < 3600.0:
			sim.simulate_elapsed(step)
		else:
			sim.simulate_offline(step)
		clock += step
		game.collect_income(sim)
		for talent_id in _talent_order:
			sim.unlock_talent(talent_id)
		while game.gacha_tokens >= game.SUMMON_COST:
			var banner := "gear" if policy == "gear_only" else str(MIXED[pull_index % MIXED.size()])
			pull_index += 1
			var response: Dictionary = game.pull(banner, 1)
			if banner == "gear":
				var name: String = response["results"][0]["name"]
				sim.add_gear(name)
				_wear_if_better(sim, name)
				if sim.gear_count(name) > 1:
					sim.salvage_gear(name)
					game.grant_tokens(GearCatalogScript.salvage_tokens(name))
			elif banner == "companions":
				sim.set_active_companion(str(response["results"][0]["name"]))
		for name in ["Goblin Cleaver", "Wolfskin Hood", "Briarheart Charm"]:
			if sim.gear_count(name) > 0:
				_wear_if_better(sim, name)
		if is_equal_approx(clock, goal):
			points[labels[next_point]] = _point(sim, game, pull_index)
			next_point += 1
	var result := {"seed": seed_value, "dev_infinite_tokens": dev_flag or game.dev_infinite_tokens, "points": points}
	game.free()
	sim.free()
	return result

func _score(name: String) -> int:
	return GearCatalogScript.attack_bonus(name) * 2 + GearCatalogScript.hp_bonus(name)

func _wear_if_better(sim: Node, name: String) -> void:
	var worn: String = sim.equipped_item(GearCatalogScript.slot(name))
	if worn.is_empty() or _score(name) > _score(worn):
		sim.equip_gear(name)

func _point(sim: Node, game: Node, draws: int) -> Dictionary:
	var worn := {"Common": 0, "Rare": 0, "Epic": 0, "Legendary": 0}
	var owned := {"Common": 0, "Rare": 0, "Epic": 0, "Legendary": 0}
	for name in sim.equipped.values():
		if not str(name).is_empty():
			worn[GearCatalogScript.rarity(str(name))] += 1
	for name in sim.owned_gear_names():
		owned[GearCatalogScript.rarity(name)] += 1
	var gear_attack := 0
	var gear_hp := 0
	for name in sim.equipped.values():
		if not str(name).is_empty():
			gear_attack += GearCatalogScript.attack_bonus(str(name))
			gear_hp += GearCatalogScript.hp_bonus(str(name))
	return {
		"level": sim.hero_level,
		"talents_spent": sim.talent_points_spent(),
		"attack": sim.effective_attack(),
		"health": sim.effective_max_hp(),
		"attack_from_gear": gear_attack,
		"health_from_gear": gear_hp,
		"worn": worn,
		"owned": owned,
		"draws": draws,
		"tokens_left": game.gacha_tokens,
		"deaths": sim.deaths,
		"quests": sim.quest_cycles_completed,
		"boss_rank": sim.thornback_rank,
		"gold": sim.gold
	}

func _median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[int((sorted.size() - 1) / 2)])

func _col(runs: Array, label: String, key: String) -> Array:
	var values: Array = []
	for run in runs:
		values.append(float(run["points"][label][key]))
	return values

func _worn_col(runs: Array, label: String, rarity: String) -> Array:
	var values: Array = []
	for run in runs:
		values.append(float(run["points"][label]["worn"][rarity]))
	return values

func _tables(results: Dictionary) -> String:
	var lines: Array[String] = [
		"# First-session progression (issue #45)",
		"",
		"Generated by `tools/economy/first_session.gd`. Do not edit; rerun the tool. A new save on current main, real game code, developer features never used (`dev_infinite_tokens` stayed off in every run: %s). Medians of %d seeds. This is one scripted policy, not a person; the owner's own 15-minute experience is the evidence that counts." % [
			str(_any_dev(results)), SEEDS.size(),
		],
		""
	]
	for policy in ["gear_only", "mixed"]:
		var runs: Array = results["policies"][policy]
		lines += ["## Summons: %s" % ("all 250 starting tokens on the gear banner" if policy == "gear_only" else "mixed banners, 250 starting tokens"), "",
			"| When | Level | Talents of %d | Attack | Health | Gear attack | Worn Legendary | Worn Epic | Owned Legendary | Deaths | Boss kills |" % results["talents_in_game"],
			"|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|"]
		for label in CHECKPOINTS:
			var owned_legendary: Array = []
			for run in runs:
				owned_legendary.append(float(run["points"][label]["owned"]["Legendary"]))
			lines.append("| %s | %d | %d | %d | %d | %d | %d | %d | %d | %d | %d |" % [label,
				_median(_col(runs, label, "level")), _median(_col(runs, label, "talents_spent")),
				_median(_col(runs, label, "attack")), _median(_col(runs, label, "health")),
				_median(_col(runs, label, "attack_from_gear")),
				_median(_worn_col(runs, label, "Legendary")), _median(_worn_col(runs, label, "Epic")),
				_median(owned_legendary), _median(_col(runs, label, "deaths")), _median(_col(runs, label, "boss_rank"))])
		lines.append("")
	return "\n".join(lines) + "\n"

func _any_dev(results: Dictionary) -> bool:
	for policy in results["policies"]:
		for run in results["policies"][policy]:
			if bool(run["dev_infinite_tokens"]):
				return true
	return false

func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	file.store_string(text)
	file.close()
