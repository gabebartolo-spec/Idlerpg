class_name IdlePersistence
extends RefCounted

# Local save and offline catch-up. Rules and file layout: docs/SAVE_AND_OFFLINE.md.
#
# These saves are for single-player continuity. They are files on the player's device and
# a device clock, so nothing here can be trusted as online or competitive state.

const SAVE_VERSION := 15
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

# Standard save companions. Numbered unreadable archives are retained independently.
static func files_for(path: String = DEFAULT_PATH) -> Array[String]:
	return [path, path + TEMP_SUFFIX, path + BACKUP_SUFFIX, path + UNREADABLE_SUFFIX]

static func save(sim: Node, game: Node, now_unix: int = -1, path: String = DEFAULT_PATH) -> bool:
	# An older build must not replace progress written by a newer build.
	for existing in [path, path + TEMP_SUFFIX, path + BACKUP_SUFFIX]:
		if FileAccess.file_exists(existing) and bool(_read(existing).get("newer", false)):
			return false
	game.collect_income(sim)
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
	# Full precision, so the clocks read back exactly and play resumes as it would have.
	file.store_string(JSON.stringify(payload, "", true, true))
	file.flush()
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
			if _keep_unreadable(path).is_empty():
				return false
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
		if bool(result.get("newer", false)):
			report["error"] = result["error"]
			report["save_lost"] = true
			report["newer_version"] = true
			return report
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
			var kept := _keep_unreadable(path)
			report["kept_copy"] = not kept.is_empty()
		return report

	var saved_version := int(data["version"])
	data = _migrate(data)
	sim.load_save_dict(data["sim"])
	game.load_save_dict(data["game"])
	if not sim.active_relic.is_empty() and not sim.owns_relic(sim.active_relic, game):
		sim.active_relic = ""
		sim.hero_hp = mini(sim.hero_hp, sim.effective_max_hp())

	var chronicle_cursor: int = sim.chronicle.sequence
	var before: Dictionary = sim.report_counters()
	var saved_unix: int = int(data.get("saved_unix", now_unix))
	var elapsed_actual: int = max(0, now_unix - saved_unix)
	var elapsed_simulated: int = mini(elapsed_actual, MAX_OFFLINE_SECONDS)

	var started := Time.get_ticks_msec()
	if elapsed_simulated > 0:
		sim.simulate_offline(float(elapsed_simulated))
	game.collect_income(sim)
	var catch_up_msec := Time.get_ticks_msec() - started

	var after: Dictionary = sim.report_counters()
	report = _build_report(before, after, elapsed_actual, elapsed_simulated)
	report["catch_up_msec"] = catch_up_msec
	report["highlights"] = sim.chronicle.highlights_since(chronicle_cursor)
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
	if not _whole_number(data.get("version")):
		return {"ok": false, "error": "The save version is invalid."}
	var version := int(data["version"])
	if version < 1:
		return {"ok": false, "error": "The save has no version."}
	if version > SAVE_VERSION:
		return {"ok": false, "newer": true, "error": "The save is from a newer version of the game."}
	if not (data.get("sim") is Dictionary) or not (data.get("game") is Dictionary):
		return {"ok": false, "error": "The save is incomplete."}
	if not _whole_number(data.get("saved_unix")) or float(data["saved_unix"]) < 0.0:
		return {"ok": false, "error": "The save timestamp is invalid."}
	return {"ok": true, "data": data, "error": ""}

static func _whole_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return is_finite(number) and number == floorf(number) and abs(number) < float(0x7fffffffffffffff)

# Each damaged file gets its own archive; never replace a previous recovery copy.
static func _keep_unreadable(path: String) -> String:
	var target := path + UNREADABLE_SUFFIX
	var index := 2
	while FileAccess.file_exists(target) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(target)):
		target = path + UNREADABLE_SUFFIX + ".%d" % index
		index += 1
	return target if _rename(path, target) == OK else ""

# Brings an older save up to the current format, one version at a time.
static func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data["version"])
	if version == 1:
		# Version 2 adds the gacha generator state to "game". A version 1 save has none,
		# and the game keeps a freshly randomised generator for it.
		version = 2
	if version == 2:
		# Version 3 adds Old Thornback's rank, the boss fight tally and world hunts to
		# "sim". A version 2 save has none, and the simulation starts them from nothing:
		# rank 0, the default hunt, and world items already owned counted as discovered.
		version = 3
	if version == 3:
		# Version 4 adds a bounded milestone chronicle. Older saves seed known firsts
		# without fabricating events; see AdventurerSim._seed_legacy_chronicle.
		version = 4
	if version == 4:
		# Version 5 adds permanent goals; old completed criteria seed without rewards.
		version = 5
	if version == 5:
		# Version 6 preserves the selected and current-outing policies.
		version = 6
	if version == 6:
		# Version 7 adds three optional named build presets.
		version = 7
	if version == 7:
		# Version 8 adds one relic slot and guaranteed earned alternatives.
		version = 8
	if version == 8:
		# Version 9 adds independent collection pursuits and cosmetic duplicate counts.
		version = 9
	if version == 9:
		# Version 10 adds time-based earned income and its settlement cursor.
		version = 10
	if version == 10:
		# Version 11 adds permanent journal discoveries; old evidence seeds without rewards.
		version = 11
	if version == 11:
		# Version 12 adds local adventurer identity and appearance.
		version = 12
	if version == 12:
		# Version 13 stores fishing, ingredients, optional attempts and prepared stew.
		version = 13
	if version == 13:
		# Version 14 adds queued/active practice, frozen roles, contributions and first-clear settlement.
		version = 14
	if version == 14:
		# Version 15 stores chosen expedition routes, node progress and settled rewards.
		version = 15
	data["version"] = version
	return data

static func _rename(from: String, to: String) -> Error:
	if not FileAccess.file_exists(from):
		return ERR_FILE_NOT_FOUND
	var source := ProjectSettings.globalize_path(from).simplify_path()
	var target := ProjectSettings.globalize_path(to).simplify_path()
	if source == target or (OS.has_feature("windows") and source.to_lower() == target.to_lower()):
		return OK
	if FileAccess.file_exists(to):
		var removed := DirAccess.remove_absolute(target)
		if removed != OK:
			return removed
	return DirAccess.rename_absolute(source, target)

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
		"boss_ranks": max(0, int(after.get("thornback_rank", 0)) - int(before.get("thornback_rank", 0))),
		"tokens": maxi(0, int(after.get("earned_tokens", 0)) - int(before.get("earned_tokens", 0))),
		"fish_catches": maxi(0, int(after.get("fish_catches", 0)) - int(before.get("fish_catches", 0))),
		"practice_clears": maxi(0, int(after.get("practice_clears", 0)) - int(before.get("practice_clears", 0))),
		"expeditions": maxi(0, int(after.get("expeditions", 0)) - int(before.get("expeditions", 0))),
		"gold": max(0, int(after.get("gold", 0)) - int(before.get("gold", 0))),
		"loot": loot_delta,
		"gear": gear_delta
	}
