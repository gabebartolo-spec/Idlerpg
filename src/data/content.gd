class_name VbContent
extends RefCounted

# Loads and indexes the JSON content, and can audit itself for broken refs.

const ITEMS_PATH := "res://data/items.json"
const ENEMIES_PATH := "res://data/enemies.json"
const ZONES_PATH := "res://data/zones.json"
const NAMES_PATH := "res://data/names.json"

var _items := {}
var _items_list: Array = []
var _enemies := {}
var _enemies_list: Array = []
var _zones := {}
var _zones_list: Array = []
var _names := {}


func _init() -> void:
	_items_list = _read_array(ITEMS_PATH)
	_enemies_list = _read_array(ENEMIES_PATH)
	_zones_list = _read_array(ZONES_PATH)
	_names = _read_dict(NAMES_PATH)
	for item in _items_list:
		_items[str(item.get("id", ""))] = item
	for enemy in _enemies_list:
		_enemies[str(enemy.get("id", ""))] = enemy
	for zone in _zones_list:
		_zones[str(zone.get("id", ""))] = zone


func _read_array(path: String) -> Array:
	var data := _read_dict(path)
	return data.get("items" if path == ITEMS_PATH else ("enemies" if path == ENEMIES_PATH else "zones"), [])


func _read_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func get_item(id: String) -> Dictionary:
	return _items.get(id, {})


func get_enemy(id: String) -> Dictionary:
	return _enemies.get(id, {})


func get_zone(id: String) -> Dictionary:
	return _zones.get(id, {})


func all_items() -> Array:
	return _items_list


func all_zones() -> Array:
	return _zones_list


func random_name() -> String:
	var first: Array = _names.get("first", ["Maren"])
	var epithet: Array = _names.get("epithet", ["of the Sixth Toll"])
	var f := str(first[randi() % first.size()])
	var e := str(epithet[randi() % epithet.size()])
	return "%s %s" % [f, e]


## Returns a list of content problems (empty list = clean).
func validate() -> Array:
	var problems: Array = []
	for item in _items_list:
		var id := str(item.get("id", ""))
		if id.is_empty():
			problems.append("item with empty id")
		if not str(item.get("slot", "")) in ["weapon", "armor", "charm"]:
			problems.append("%s: bad slot" % id)
		if int(item.get("rarity", -1)) < 0 or int(item.get("rarity", -1)) > 3:
			problems.append("%s: bad rarity" % id)
		var zones: Array = item.get("zones", [])
		for z in zones:
			if not _zones.has(str(z)):
				problems.append("%s: unknown zone %s" % [id, str(z)])
		if int(item.get("value", -1)) < 0:
			problems.append("%s: bad value" % id)
		if _items_list.filter(func(x): return str(x.get("id", "")) == id).size() > 1:
			problems.append("%s: duplicate id" % id)
	for zone in _zones_list:
		var zid := str(zone.get("id", ""))
		if str(zone.get("boss", "")) != "" and not _enemies.has(str(zone.get("boss"))):
			problems.append("%s: unknown boss" % zid)
		if str(zone.get("elite", "")) != "" and not _enemies.has(str(zone.get("elite"))):
			problems.append("%s: unknown elite" % zid)
		for e in zone.get("enemies", []):
			if not _enemies.has(str(e)):
				problems.append("%s: unknown enemy %s" % [zid, str(e)])
		for rarity in int(zone.get("rarity_weights", {}).keys().size()):
			pass
		var pool := {}
		for item in _items_list:
			if zid in item.get("zones", []) and str(item.get("special", "")) != "first_strike":
				pool[int(item.get("rarity", 0))] = true
		for key in zone.get("rarity_weights", {}).keys():
			if not pool.has(int(key)):
				problems.append("%s: rarity band %s has no items" % [zid, str(key)])
	for enemy in _enemies_list:
		if not _zones.has(str(enemy.get("zone", ""))):
			problems.append("%s: unknown zone" % str(enemy.get("id", "")))
	return problems
