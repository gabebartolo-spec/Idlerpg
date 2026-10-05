class_name IdlePersistence
extends RefCounted

# Local save and offline catch-up. Rules and file layout: docs/SAVE_AND_OFFLINE.md.
#
# These saves are for single-player continuity. They are files on the player's device and
# a device clock, so nothing here can be trusted as online or competitive state.

const SAVE_VERSION := 2
const DEFAULT_PATH := "user://idle_rpg_save.json"
const MAX_OFFLINE_SECONDS := 7 * 24 * 60 * 60

# Beside the save: the write in progress, the last good save, and a save that could not
# be read, kept so it is never silently destroyed.
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"
const UNREADABLE_SUFFIX := ".unreadable"

# The latest timestamp written or read this session, per save path. Saving never moves it
# backwards, so winding the device clock back cannot be used to bank offline time.
static var _latest_unix: Dictionary = {}

# Every file that can hold save data for `path`: the save and the files kept beside it.
static func files_for(path: String = DEFAULT_PATH) -> Array[String]:
	return [path, path + TEMP_SUFFIX, path + BACKUP_SUFFIX, path + UNREADABLE_SUFFIX]

static func save(sim: Node, game: Node, now_unix: int = -1, path: String = DEFAULT_PATH) -> bool:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())
	now_unix = maxi(now_unix, int(_latest_unix.get(path, 0)))

	var payload := {
		"version": SAVE_VERSION,
		"saved_unix": now_unix,
		"sim": sim.to_save_dict(),
		"game": game.to_save_dict()
	}

	# Write beside the save, check it reads back, then swap it in. A crash at any point
	# leaves at least one complete file.
	var temp := path + TEMP_SUFFIX
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	var write_error := file.get_error()
	file.close()
	if write_error != OK or not bool(_read(temp)["ok"]):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
		return false

	if FileAccess.file_exists(path):
		# Only a save that still reads becomes the backup; a damaged one must not replace
		# a good backup.
		if bool(_read(path)["ok"]):
			if _rename(path, path + BACKUP_SUFFIX) != OK:
				return false
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if _rename(temp, path) != OK:
		return false
	_latest_unix[path] = now_unix
	return true

static func load_and_advance(sim: Node, game: Node, now_unix: int = -1, path: String = DEFAULT_PATH) -> Dictionary:
	if now_unix < 0:
		now_unix = int(Time.get_unix_time_from_system())

	var report := {
		"loaded": false,
		"elapsed_actual": 0,
		"elapsed_simulated": 0,
		"capped": false
	}

	# The save, then an interrupted write, then the previous save.
	var sources := [path, path + TEMP_SUFFIX, path + BACKUP_SUFFIX]
	var found_any := false
	var data: Dictionary = {}
	var first_error := ""
	var used := ""
	for source in sources:
		if not FileAccess.file_exists(source):
			continue
		found_any = true
		var result: Dictionary = _read(source)
		if bool(result["ok"]):
			data = result["data"]
			used = source
			break
		if first_error.is_empty():
			first_error = str(result["error"])

	if not found_any:
		return report

	if used.is_empty():
		# Nothing readable. Keep the save aside so starting again cannot destroy it.
		report["error"] = first_error
		report["save_lost"] = true
		if FileAccess.file_exists(path):
			report["kept_copy"] = _rename(path, path + UNREADABLE_SUFFIX) == OK
		return report

	var saved_version := int(data["version"])
	data = _migrate(data)
	sim.load_save_dict(data["sim"])
	game.load_save_dict(data["game"])

	var before: Dictionary = sim.report_counters()
	var saved_unix: int = int(data.get("saved_unix", now_unix))
	var elapsed_actual: int = max(0, now_unix - saved_unix)
	var elapsed_simulated: int = mini(elapsed_actual, MAX_OFFLINE_SECONDS)

	var started := Time.get_ticks_msec()
	if elapsed_simulated > 0:
		sim.simulate_offline(float(elapsed_simulated))
	var catch_up_msec := Time.get_ticks_msec() - started

	var after: Dictionary = sim.report_counters()
	report = _build_report(before, after, elapsed_actual, elapsed_simulated)
	report["catch_up_msec"] = catch_up_msec
	if used != path:
		report["recovered_from_backup"] = true
		if not first_error.is_empty():
			report["error"] = first_error
	if saved_version != SAVE_VERSION:
		report["migrated_from"] = saved_version
	if now_unix < saved_unix:
		report["clock_rollback"] = true

	# Immediately checkpoint the advanced state so reopening cannot replay the same
	# offline interval and duplicate rewards. The timestamp never moves backwards.
	_latest_unix[path] = maxi(saved_unix, int(_latest_unix.get(path, 0)))
	if not save(sim, game, now_unix, path):
		report["save_failed"] = true
	return report

# Reads and validates one save file. Returns {"ok", "data", "error"}.
static func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "The save could not be opened."}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {"ok": false, "error": "The save is damaged."}
	var data: Dictionary = json.data
	if not (data.get("sim") is Dictionary) or not (data.get("game") is Dictionary):
		return {"ok": false, "error": "The save is incomplete."}
	var version := int(data.get("version", 0))
	if version < 1:
		return {"ok": false, "error": "The save has no version."}
	if version > SAVE_VERSION:
		return {"ok": false, "error": "The save is from a newer version of the game."}
	return {"ok": true, "data": data, "error": ""}

# Brings an older save up to the current format, one version at a time.
static func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data["version"])
	if version == 1:
		# Version 2 adds the gacha generator state to "game". A version 1 save has none,
		# and the game keeps a freshly randomised generator for it.
		version = 2
	data["version"] = version
	return data

static func _rename(from: String, to: String) -> Error:
	var target := ProjectSettings.globalize_path(to)
	if FileAccess.file_exists(to):
		DirAccess.remove_absolute(target)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from), target)

static func _build_report(before: Dictionary, after: Dictionary, elapsed_actual: int, elapsed_simulated: int) -> Dictionary:
	var before_inventory: Dictionary = before.get("inventory", {})
	var after_inventory: Dictionary = after.get("inventory", {})
	var before_gear: Dictionary = before.get("gear_inventory", {})
	var after_gear: Dictionary = after.get("gear_inventory", {})
	var loot_delta: Dictionary = {}
	var gear_delta: Dictionary = {}

	for key in after_inventory.keys():
		var gained: int = int(after_inventory.get(key, 0)) - int(before_inventory.get(key, 0))
		if gained > 0:
			loot_delta[key] = gained

	for key in after_gear.keys():
		var gained: int = int(after_gear.get(key, 0)) - int(before_gear.get(key, 0))
		if gained > 0:
			gear_delta[key] = gained

	return {
		"loaded": true,
		"elapsed_actual": elapsed_actual,
		"elapsed_simulated": elapsed_simulated,
		"capped": elapsed_actual > elapsed_simulated,
		"quests": max(0, int(after.get("quests", 0)) - int(before.get("quests", 0))),
		"kills": max(0, int(after.get("total_kills", 0)) - int(before.get("total_kills", 0))),
		"levels": max(0, int(after.get("level", 1)) - int(before.get("level", 1))),
		"talent_points": max(0, int(after.get("talent_points", 0)) - int(before.get("talent_points", 0))),
		"deaths": max(0, int(after.get("deaths", 0)) - int(before.get("deaths", 0))),
		"gold": max(0, int(after.get("gold", 0)) - int(before.get("gold", 0))),
		"loot": loot_delta,
		"gear": gear_delta
	}
