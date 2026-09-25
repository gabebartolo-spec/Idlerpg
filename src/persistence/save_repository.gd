class_name BrambleSaveRepository
extends RefCounted

var path: String


func _init(save_path: String = "user://bramblewild_save.json") -> void:
	path = save_path


func load_state() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func save_state(state: Dictionary) -> bool:
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to open save temp file: %s" % temporary_path)
		return false
	file.store_string(JSON.stringify(state, "\t"))
	file.close()

	var target_absolute := ProjectSettings.globalize_path(path)
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var error := DirAccess.rename_absolute(temporary_absolute, target_absolute)
	if error != OK:
		# Some platforms do not replace an existing file during rename. Remove the
		# old target only after the new contents have been written successfully.
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(target_absolute)
		error = DirAccess.rename_absolute(temporary_absolute, target_absolute)
	if error != OK:
		push_error("Unable to replace save file: %s" % error_string(error))
		return false
	return true


func delete_save() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
