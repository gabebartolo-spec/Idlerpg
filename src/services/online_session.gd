extends RefCounted

# Separate, device-local bearer session. Recovery secrets are never written.
# Android app storage is private; desktop protection follows user-folder ACLs.
# This is not an encrypted credential vault or trusted online gameplay state.
const DEFAULT_PATH := "user://idle_rpg_online.json"
var path := DEFAULT_PATH
var data: Dictionary = {}
var newer := false

func load_session() -> void:
	data.clear()
	newer = false
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if not parsed is Dictionary:
			continue
		var version: Variant = parsed.get("version", 0)
		if not version is int and not version is float:
			continue
		if int(version) > 1:
			newer = true
			return
		if int(version) == 1:
			data = parsed
			data.erase("recovery_key")
			var pending: Variant = data.get("pending")
			if pending != null and (not pending is Dictionary or not pending.get("body") is Dictionary or not pending.get("path") is String or not pending.get("key") is String or not pending.get("account") is String):
				data.erase("pending")
			return

func save_session() -> bool:
	if newer:
		return false
	var output := data.duplicate(true)
	output["version"] = 1
	output.erase("recovery_key")
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(output))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		if DirAccess.rename_absolute(path, path + ".bak") != OK:
			return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func discard() -> void:
	data.clear()
	newer = false
	for candidate in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)
