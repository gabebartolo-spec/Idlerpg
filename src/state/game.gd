class_name VbGame
extends RefCounted

# The game store: owns state, persists it, resolves offline time, and exposes
# the verbs the UI calls. UI never mutates state directly.

const Hero = preload("res://src/sim/hero.gd")
const Loot = preload("res://src/sim/loot.gd")
const Expedition = preload("res://src/sim/expedition.gd")
const SaveRepo = preload("res://src/state/save.gd")

const DEPTH_MIN := 2
const DEPTH_MAX := 6
const CHAIN_CAP := 24  # max expeditions resolved per return, for pathological absences
const TEMPER_COSTS := {0: 3, 1: 8}  # shards to go from level N to N+1
const TEMPER_MAX := 2
const TEMPER_SELL_BONUS := 10

var content
var state: Dictionary
var clock_override := -1  # tests pin time; -1 = wall clock
var debug_offset_seconds := 0


func _init(content_repository) -> void:
	content = content_repository
	state = _default_state()
	var loaded := SaveRepo.load_state()
	if not loaded.is_empty():
		state = loaded
		_normalize()
	# Guard against the device clock moving backwards between sessions.
	var now := _now()
	var last_seen := int(state.get("last_seen_at", 0))
	if last_seen > 0 and now < last_seen - 120:
		state["clock_floor"] = last_seen


func _default_state() -> Dictionary:
	return {
		"schema_version": SaveRepo.SCHEMA_VERSION,
		"adventurer": {
			"name": "",
			"level": 1,
			"xp": 0,
			"vows": [],
			"gold": 0,
			"shards": 0,
			"equipment": {"weapon": {}, "armor": {}, "charm": {}},
			"inventory": []
		},
		"next_uid": 1,
		"next_seed": 1,
		"expedition": null,
		"standing": {"enabled": false, "zone_id": "marrowfields", "depth": 3},
		"pending_report": null,
		"pending_vows": [],
		"last_seen_at": 0,
		"clock_floor": 0,
		"debug_offset_seconds": 0,
		"lifetime": {"runs": 0, "kills": 0, "deaths": 0, "deepest_toll": 0}
	}


func _normalize() -> void:
	var fresh := _default_state()
	for key in fresh.keys():
		if not state.has(key):
			state[key] = fresh[key]
	var hero: Dictionary = state.get("adventurer", {})
	for key in ["name", "level", "xp", "vows", "gold", "shards", "equipment", "inventory"]:
		if not hero.has(key):
			hero[key] = fresh["adventurer"][key]
	if not hero.get("vows", []) is Array:
		hero["vows"] = []
	if not hero.get("inventory", []) is Array:
		hero["inventory"] = []
	if not hero.get("equipment", {}) is Dictionary:
		hero["equipment"] = fresh["adventurer"]["equipment"]
	state["debug_offset_seconds"] = 0


# ------------------------------------------------------------------ time

func now() -> int:
	return _now()


func _now() -> int:
	var real := clock_override if clock_override >= 0 else int(Time.get_unix_time_from_system())
	return maxi(real + debug_offset_seconds, int(state.get("clock_floor", 0)))


func debug_advance(seconds: int) -> void:
	debug_offset_seconds += seconds
	update()


# ------------------------------------------------------------------ hero

func is_new_game() -> bool:
	return str(state["adventurer"].get("name", "")).strip_edges() == ""


func create_adventurer(adventurer_name: String) -> bool:
	var clean := adventurer_name.strip_edges()
	if clean.is_empty():
		return false
	state = _default_state()
	state["adventurer"]["name"] = clean.substr(0, 24)
	_save()
	return true


func random_name() -> String:
	return content.random_name()


func hero() -> Dictionary:
	return state["adventurer"]


## A snapshot of the current build, for previews (time estimates, stat lines).
func snapshot_now() -> Dictionary:
	return Hero.make_snapshot(state, content_items(), content)


func stats() -> Dictionary:
	return Hero.total_stats(
		int(hero()["level"]), Hero.resolve_equipment(hero(), content_items())
	)


func grit_max() -> int:
	return Hero.grit_max(int(stats()["ward"]))


func content_items() -> Dictionary:
	var defs := {}
	for item in content.all_items():
		defs[str(item.get("id", ""))] = item
	return defs


func vows() -> Array:
	return hero().get("vows", [])


func lifetime() -> Dictionary:
	return state["lifetime"]


## Shard yield if the player salvaged a definition-level item (UI preview).
func content_salvage(def: Dictionary, temper: int) -> int:
	return Loot.salvage_shards(int(def.get("rarity", 0)), temper)


func pending_vows() -> Array:
	return state.get("pending_vows", [])


func choose_vow(vow_id: String) -> bool:
	var pending: Array = state.get("pending_vows", [])
	if pending.is_empty():
		return false
	var level := int(pending[0])
	if not Hero.VOW_CHOICES.get(level, []).has(vow_id):
		return false
	hero()["vows"].append(vow_id)
	pending.pop_front()
	_save()
	return true


# ------------------------------------------------------------------ zones

func zone_locked(zone: Dictionary) -> bool:
	return int(hero()["level"]) < int(zone.get("min_level", 1))


func zone_ok(zone_id: String, depth: int) -> String:
	var zone := content.get_zone(zone_id)
	if zone.is_empty():
		return "No such road."
	if zone_locked(zone):
		return "The road is sealed until level %d." % int(zone.get("min_level", 1))
	if depth < DEPTH_MIN or depth > DEPTH_MAX:
		return "Choose between %d and %d tolls." % [DEPTH_MIN, DEPTH_MAX]
	return ""


# ------------------------------------------------------------------ expeditions

func send_out(zone_id: String, depth: int) -> String:
	var err := zone_ok(zone_id, depth)
	if err != "":
		return err
	if has_expedition():
		return "They are already out there."
	var snap := Hero.make_snapshot(state, content_items(), content)
	state["expedition"] = {
		"zone_id": zone_id,
		"depth": depth,
		"started_at": _now(),
		"seed": int(state["next_seed"]),
		"snapshot": snap
	}
	state["next_seed"] = int(state["next_seed"]) + 1
	state["standing"]["zone_id"] = zone_id
	state["standing"]["depth"] = depth
	_save()
	return ""


func has_expedition() -> bool:
	return state.get("expedition", null) is Dictionary and not state["expedition"].is_empty()


func expedition_info() -> Dictionary:
	if not has_expedition():
		return {}
	var exp: Dictionary = state["expedition"]
	var zone := content.get_zone(str(exp["zone_id"]))
	var snap: Dictionary = exp.get("snapshot", {})
	var elapsed := _now() - int(exp["started_at"])
	var toll_len := Expedition.toll_seconds(zone, snap)
	return {
		"zone_name": str(zone.get("name", "")),
		"depth": int(exp["depth"]),
		"elapsed": elapsed,
		"planned": int(Expedition.toll_seconds(zone, snap) * float(int(exp["depth"]))),
		"toll_index": clampi(int(floor(float(elapsed) / toll_len)), 0, int(exp["depth"]) - 1),
		"toll_seconds": int(toll_len),
		"can_recall": can_recall(),
		"no_retreat": bool(snap.get("specials", {}).get("no_retreat", false))
	}


func can_recall() -> bool:
	if not has_expedition():
		return false
	var exp: Dictionary = state["expedition"]
	var snap: Dictionary = exp.get("snapshot", {})
	if snap.get("specials", {}).get("no_retreat", false):
		return false
	var zone := content.get_zone(str(exp["zone_id"]))
	var elapsed := _now() - int(exp["started_at"])
	return elapsed < int(Expedition.toll_seconds(zone, snap) * float(int(exp["depth"])))


func recall() -> String:
	if not has_expedition():
		return "Nobody is out there."
	if not can_recall():
		return "The bell cannot reach them now."
	var exp: Dictionary = state["expedition"]
	var zone := content.get_zone(str(exp["zone_id"]))
	var run := Expedition.resolve(
		zone, int(exp["depth"]), int(exp["seed"]), exp["snapshot"], _now() - int(exp["started_at"]), content
	)
	run["status"] = "recalled"
	run["events"].append({
		"kind": "recall", "tone": "neutral",
		"text": "The recall rings out, and %s turns for home without complaint." % str(exp["snapshot"].get("name", "the Bellbound")),
		"importance": "major"
	})
	run["summary"] = "recalled home with the find intact"
	state["expedition"] = null
	_commit_runs([run])
	_save()
	return ""


func set_standing(enabled: bool) -> void:
	state["standing"]["enabled"] = enabled
	_save()


func standing() -> Dictionary:
	return state["standing"]


## Called every UI tick and after any time jump: resolves finished expeditions.
func update() -> void:
	if has_expedition():
		var exp: Dictionary = state["expedition"]
		if _now() >= int(exp["started_at"]) + _planned_seconds(exp):
			_resolve_chain()


func _planned_seconds(exp: Dictionary) -> int:
	var zone := content.get_zone(str(exp["zone_id"]))
	var toll_len := Expedition.toll_seconds(zone, exp.get("snapshot", {}))
	return int(toll_len * float(int(exp["depth"])))


func _resolve_chain() -> void:
	var runs: Array = []
	var guard := 0
	var exp: Dictionary = state["expedition"]
	while guard < CHAIN_CAP:
		guard += 1
		var zone := content.get_zone(str(exp["zone_id"]))
		var elapsed := _now() - int(exp["started_at"])
		var run := Expedition.resolve(
			zone, int(exp["depth"]), int(exp["seed"]), exp["snapshot"], elapsed, content
		)
		if str(run["status"]) == "out":
			# Finished runs are committed now (the player may be watching);
			# the unfinished one stays out on the road.
			state["expedition"] = exp
			if not runs.is_empty():
				_commit_runs(runs)
				_save()
			return
		runs.append(run)
		var next_start := int(exp["started_at"]) + int(run["planned_seconds"])
		var chain_again: bool = str(run["status"]) == "returned" and bool(state["standing"].get("enabled", false))
		exp = {
			"zone_id": exp["zone_id"], "depth": exp["depth"],
			"started_at": next_start, "seed": int(state["next_seed"]),
			"snapshot": exp["snapshot"]
		}
		state["next_seed"] = int(state["next_seed"]) + 1
		if not chain_again:
			state["expedition"] = null
			_commit_runs(runs)
			_save()
			return
		if next_start > _now():
			# The next run has begun but is not finished yet.
			state["expedition"] = exp
			_commit_runs(runs)
			_save()
			return
	# Chain cap hit: whatever is left is simply still walking.
	state["expedition"] = exp
	if not runs.is_empty():
		_commit_runs(runs)
	_save()


func _commit_runs(runs: Array) -> void:
	var adventurer: Dictionary = state["adventurer"]
	var report: Dictionary = state.get("pending_report", null) if has_report() else {}
	if report.is_empty():
		report = {
			"runs": [], "events": [], "loot": [], "standout": {},
			"totals": {"xp": 0, "gold": 0, "shards": 0},
			"levels_gained": [], "any_death": false, "chained": 0,
			"level_before": int(adventurer["level"]),
			"level_after": int(adventurer["level"])
		}
	var any_death: bool = bool(report.get("any_death", false))
	var new_xp := 0
	for run in runs:
		new_xp += int(run["xp"])
		report["totals"]["xp"] = int(report["totals"]["xp"]) + int(run["xp"])
		report["totals"]["gold"] = int(report["totals"]["gold"]) + int(run["gold"])
		report["totals"]["shards"] = int(report["totals"]["shards"]) + int(run["shards"])
		for inst in run["loot"]:
			var stamped := inst.duplicate(true)
			stamped["uid"] = int(state["next_uid"])
			state["next_uid"] = int(state["next_uid"]) + 1
			report["loot"].append(stamped)
			adventurer["inventory"].push_front(stamped)
		adventurer["gold"] = int(adventurer["gold"]) + int(run["gold"])
		adventurer["shards"] = int(adventurer["shards"]) + int(run["shards"])
		state["lifetime"]["runs"] = int(state["lifetime"]["runs"]) + 1
		state["lifetime"]["kills"] = int(state["lifetime"]["kills"]) + int(run["kills"])
		state["lifetime"]["deepest_toll"] = maxi(int(state["lifetime"]["deepest_toll"]), int(run["deepest_toll"]))
		if str(run["status"]) == "died":
			any_death = true
			state["lifetime"]["deaths"] = int(state["lifetime"]["deaths"]) + 1
		report["runs"].append({
			"zone_name": str(run["zone_name"]), "status": str(run["status"]),
			"summary": str(run["summary"]), "kills": int(run["kills"]),
			"xp": int(run["xp"]), "gold": int(run["gold"]), "shards": int(run["shards"]),
			"loot_count": run["loot"].size(), "boss_slain": bool(run["boss_slain"]),
			"tolls": int(run["deepest_toll"])
		})
		report["events"].append_array(_run_events(run, runs.size() > 1 or int(report["chained"]) > 0))
		report["chained"] = int(report["chained"]) + 1
	# XP and level-ups last, so vows queue correctly.
	adventurer["xp"] = int(adventurer["xp"]) + new_xp
	var levels_gained: Array = report["levels_gained"]
	while int(adventurer["level"]) < Hero.MAX_LEVEL and int(adventurer["xp"]) >= Hero.xp_for_level(int(adventurer["level"]) + 1):
		adventurer["level"] = int(adventurer["level"]) + 1
		levels_gained.append(int(adventurer["level"]))
		if Hero.VOW_CHOICES.has(int(adventurer["level"])):
			state["pending_vows"].append(int(adventurer["level"]))
	# best find across everything in this report
	var best_rarity := -1
	if not report["standout"].is_empty():
		best_rarity = int(report["standout"].get("rarity", 0))
	for inst in report["loot"]:
		var def := content.get_item(str(inst["id"]))
		if int(def.get("rarity", 0)) > best_rarity:
			best_rarity = int(def.get("rarity", 0))
			report["standout"] = def
	report["any_death"] = any_death
	report["level_after"] = int(adventurer["level"])
	state["pending_report"] = report


## Pick the events that earn their place in the report.
## Single runs keep the full story (major first, then finds and wounds);
## chained runs collapse to a one-line summary plus the loudest moments.
func _run_events(run: Dictionary, chained: bool) -> Array:
	var major: Array = []
	var minor: Array = []
	for event in run["events"]:
		if str(event.get("importance", "minor")) == "major":
			major.append(event)
		elif str(event.get("kind", "")) in ["find", "wound", "combat", "objective"]:
			minor.append(event)
	var merged: Array = []
	if not chained:
		merged.append_array(major)
		for event in minor:
			if merged.size() >= 9:
				break
			merged.append(event)
		return merged
	merged.append({
		"kind": "run_line", "tone": _tone_for(str(run["status"])),
		"text": "%s — %s" % [str(run["zone_name"]), str(run["summary"])],
		"importance": "major"
	})
	for event in major:
		if merged.size() >= 4:
			break
		merged.append(event)
	return merged


func _tone_for(status: String) -> String:
	match status:
		"died":
			return "grave"
		"broken":
			return "danger"
		_:
			return "good"


func has_report() -> bool:
	return state.get("pending_report", null) is Dictionary and not state["pending_report"].is_empty()


func pending_report() -> Dictionary:
	return state.get("pending_report", {})


func clear_report() -> void:
	state["pending_report"] = null
	_save()


# ------------------------------------------------------------------ inventory

func inventory() -> Array:
	return hero().get("inventory", [])


func equipped() -> Dictionary:
	return hero().get("equipment", {})


func find_instance(uid: int) -> Dictionary:
	for inst in hero()["inventory"]:
		if int(inst.get("uid", -1)) == uid:
			return inst
	for slot in hero()["equipment"].keys():
		var inst: Dictionary = hero()["equipment"][slot]
		if inst is Dictionary and int(inst.get("uid", -1)) == uid:
			return inst
	return {}


func equip(uid: int) -> bool:
	var inst := find_instance(uid)
	if inst.is_empty():
		return false
	var def := content.get_item(str(inst["id"]))
	var slot := str(def.get("slot", ""))
	if slot == "":
		return false
	var inv: Array = hero()["inventory"]
	inv.erase(inst)
	var current: Dictionary = hero()["equipment"].get(slot, {})
	if current is Dictionary and not current.is_empty():
		inv.push_front(current)
	hero()["equipment"][slot] = inst
	_save()
	return true


func sell(uid: int) -> int:
	var inst := find_instance(uid)
	if inst.is_empty():
		return 0
	var def := content.get_item(str(inst["id"]))
	if not hero()["inventory"].has(inst):
		return 0  # must unequip before selling
	var gold := int(def.get("value", 0)) + int(inst.get("temper", 0)) * TEMPER_SELL_BONUS
	hero()["inventory"].erase(inst)
	hero()["gold"] = int(hero()["gold"]) + gold
	_save()
	return gold


func salvage(uid: int) -> int:
	var inst := find_instance(uid)
	if inst.is_empty():
		return 0
	var def := content.get_item(str(inst["id"]))
	if not hero()["inventory"].has(inst):
		return 0
	var shards := Loot.salvage_shards(int(def.get("rarity", 0)), int(inst.get("temper", 0)))
	hero()["inventory"].erase(inst)
	hero()["shards"] = int(hero()["shards"]) + shards
	_save()
	return shards


func temper_cost(slot: String) -> int:
	var inst: Dictionary = hero()["equipment"].get(slot, {})
	if not inst is Dictionary or inst.is_empty():
		return 0
	var level := int(inst.get("temper", 0))
	if level >= TEMPER_MAX:
		return 0
	return int(TEMPER_COSTS.get(level, 0))


func temper(slot: String) -> String:
	var inst: Dictionary = hero()["equipment"].get(slot, {})
	if not inst is Dictionary or inst.is_empty():
		return "Nothing worn there."
	var cost := temper_cost(slot)
	if cost == 0:
		return "The bell can temper this no further."
	if int(hero()["shards"]) < cost:
		return "Not enough Ashen Shards (%d needed)." % cost
	hero()["shards"] = int(hero()["shards"]) - cost
	inst["temper"] = int(inst.get("temper", 0)) + 1
	_save()
	return ""


# ------------------------------------------------------------------ persistence

func _save() -> void:
	state["last_seen_at"] = _now()
	SaveRepo.save_state(state)
