class_name VbSave
extends RefCounted

# Save/load: JSON at user://vesperbell.json, written to a temp file and renamed
# so a crash mid-write cannot destroy the save.

const SAVE_PATH := "user://vesperbell.json"
const TEMP_PATH := "user://vesperbell.json.tmp"
const SCHEMA_VERSION := 1


static func save_state(state: Dictionary) -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state, "\t"))
	file.close()
	var err := DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	return err == Error.OK


## Returns {} when the save is missing or unusable — the game then starts fresh.
static func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var state: Dictionary = parsed
	if int(state.get("schema_version", 0)) != SCHEMA_VERSION:
		return {}
	if not state.get("adventurer", {}) is Dictionary:
		return {}
	return state
