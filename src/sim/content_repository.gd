class_name BrambleContentRepository
extends RefCounted

var items: Dictionary = {}
var enemies: Dictionary = {}
var routes: Dictionary = {}


func _init() -> void:
	items = _load_collection("res://content/items.json")
	enemies = _load_collection("res://content/enemies.json")
	routes = _load_collection("res://content/routes.json")


func _load_collection(path: String) -> Dictionary:
	var result: Dictionary = {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to load content: %s" % path)
		return result
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Content file is not an array: %s" % path)
		return result
	for entry in parsed:
		if entry is Dictionary and entry.has("id"):
			result[str(entry["id"])] = entry
	return result


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_enemy(enemy_id: String) -> Dictionary:
	return enemies.get(enemy_id, {})


func get_route(route_id: String) -> Dictionary:
	return routes.get(route_id, {})


func all_routes() -> Array:
	return routes.values()
