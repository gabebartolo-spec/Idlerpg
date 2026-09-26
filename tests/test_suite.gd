extends RefCounted

# Shared base for test suites: tiny check harness, no framework.

var failures: Array = []
var checks: int = 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)


func wipe_save() -> void:
	if FileAccess.file_exists(VbSavePath.PATH):
		DirAccess.remove_absolute(VbSavePath.PATH)


## Kept in one place so suites do not hardcode the path.
class VbSavePath:
	const PATH := "user://vesperbell.json"
