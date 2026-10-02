class_name IdlePersistence
extends RefCounted

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://idle_rpg_save.json"
const MAX_OFFLINE_SECONDS := 7 * 24 * 60 * 60

static func save(sim: Node, game: Node, now_unix: int = -1, path: String = DEFAULT_PATH) -> bool:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())

	var payload := {
		"version": SAVE_VERSION,
		"saved_unix": now_unix,
		"sim": sim.to_save_dict(),
		"game": game.to_save_dict()
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(payload))
	file.close()
	return true

static func load_and_advance(sim: Node, game: Node, now_unix: int = -1, path: String = DEFAULT_PATH) -> Dictionary:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())

	if not FileAccess.file_exists(path):
		return {
			"loaded": false,
			"elapsed_actual": 0,
			"elapsed_simulated": 0,
			"capped": false
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"loaded": false,
			"elapsed_actual": 0,
			"elapsed_simulated": 0,
			"capped": false,
			"error": "Could not open save"
		}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Dictionary):
		return {
			"loaded": false,
			"elapsed_actual": 0,
			"elapsed_simulated": 0,
			"capped": false,
			"error": "Save is not valid JSON"
		}

	var data: Dictionary = parsed
	if int(data.get("version", 0)) != SAVE_VERSION:
		return {
			"loaded": false,
			"elapsed_actual": 0,
			"elapsed_simulated": 0,
			"capped": false,
			"error": "Unsupported save version"
		}

	var sim_data: Dictionary = data.get("sim", {})
	var game_data: Dictionary = data.get("game", {})
	sim.load_save_dict(sim_data)
	game.load_save_dict(game_data)

	var before: Dictionary = sim.report_counters()
	var saved_unix: int = int(data.get("saved_unix", now_unix))
	var elapsed_actual: int = max(0, now_unix - saved_unix)
	var elapsed_simulated: int = mini(elapsed_actual, MAX_OFFLINE_SECONDS)

	if elapsed_simulated > 0:
		sim.simulate_elapsed(float(elapsed_simulated))

	var after: Dictionary = sim.report_counters()
	var report := _build_report(before, after, elapsed_actual, elapsed_simulated)

	# Immediately checkpoint the advanced state so reopening cannot replay
	# the same offline interval and duplicate rewards.
	save(sim, game, now_unix, path)
	return report

static func _build_report(before: Dictionary, after: Dictionary, elapsed_actual: int, elapsed_simulated: int) -> Dictionary:
	var before_inventory: Dictionary = before.get("inventory", {})
	var after_inventory: Dictionary = after.get("inventory", {})
	var loot_delta: Dictionary = {}

	for key in after_inventory.keys():
		var gained: int = int(after_inventory.get(key, 0)) - int(before_inventory.get(key, 0))
		if gained > 0:
			loot_delta[key] = gained

	return {
		"loaded": true,
		"elapsed_actual": elapsed_actual,
		"elapsed_simulated": elapsed_simulated,
		"capped": elapsed_actual > elapsed_simulated,
		"quests": max(0, int(after.get("quests", 0)) - int(before.get("quests", 0))),
		"kills": max(0, int(after.get("total_kills", 0)) - int(before.get("total_kills", 0))),
		"levels": max(0, int(after.get("level", 1)) - int(before.get("level", 1))),
		"deaths": max(0, int(after.get("deaths", 0)) - int(before.get("deaths", 0))),
		"gold": max(0, int(after.get("gold", 0)) - int(before.get("gold", 0))),
		"loot": loot_delta
	}
