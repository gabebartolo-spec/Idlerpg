extends RefCounted
const Catalog = preload("res://src/data/practice_catalog.gd")
var requested: bool = false
var selected_role: String = "damage"
var active: bool = false
var run_id: int = 0
var role: String = "damage"
var attack: int = 6
var max_hp: int = 96
var hp: int = 96
var room: int = 0
var enemy_hp: int = 30
var turn: int = 0
var remainder_usec: int = 0
var stew_available: bool = false
var stew_used: bool = false
var clears: int = 0
var wipes: int = 0
var first_reward_claimed: bool = false
var contributions: Dictionary = {}
var log: Array[String] = []
var recap: Dictionary = {}

func start(hero_attack: int, hero_hp: int, has_stew: bool) -> void:
	requested = false
	active = true
	run_id += 1
	role = selected_role
	attack = hero_attack
	max_hp = hero_hp + 60
	hp = max_hp
	room = 0
	enemy_hp = Catalog.ROOMS[0]["hp"]
	turn = 0
	remainder_usec = 0
	stew_available = has_stew
	stew_used = false
	contributions = {"hero_damage": 0, "bran_damage": 0, "iris_damage": 0,
		"hero_block": 0, "bran_block": 0, "hero_heal": 0, "iris_heal": 0, "stew_heal": 0}
	log.clear()
	log.append("Bran (NPC protection) and Iris (NPC support) join the practice.")
	recap.clear()

func advance(seconds: float) -> Dictionary:
	if not active:
		return {}
	var elapsed: int = remainder_usec + int(round(seconds * 1000000.0))
	var turns: int = elapsed / 1000000
	remainder_usec = elapsed % 1000000
	for _i in mini(turns, 512):
		_turn()
		if not active:
			return recap.duplicate(true)
	return {}

func _turn() -> void:
	turn += 1
	if stew_available and not stew_used and hp <= max_hp - 12:
		stew_used = true
		hp += 12
		contributions["stew_heal"] = 12
		log.append("Pond Stew restored 12 party health.")
	# Actual damage credited only up to the enemy's remaining health.
	for source in [["hero_damage", attack + (3 if role == "damage" else 0)], ["bran_damage", 3], ["iris_damage", 2]]:
		var damage: int = mini(enemy_hp, int(source[1]))
		contributions[source[0]] += damage
		enemy_hp -= damage
	if enemy_hp <= 0:
		log.append("Cleared " + str(Catalog.ROOMS[room]["name"]) + ".")
		room += 1
		if room == Catalog.ROOMS.size():
			_finish(true, "All three practice rooms cleared.")
			return
		enemy_hp = Catalog.ROOMS[room]["hp"]
		return
	var incoming: int = Catalog.ROOMS[room]["damage"]
	if room == 2 and turn % 4 == 0:
		incoming *= 2
		log.append("Moss Sentinel burst; protection absorbed part of the hit.")
	var bran_block: int = mini(incoming, 2)
	incoming -= bran_block
	contributions["bran_block"] += bran_block
	var hero_block: int = mini(incoming, 3) if role == "protection" else 0
	incoming -= hero_block
	contributions["hero_block"] += hero_block
	hp = maxi(0, hp - incoming)
	if hp == 0:
		_finish(false, "Party exhausted. Try protection, support, a stronger build or Pond Stew.")
		return
	if turn % 3 == 0:
		var iris_heal: int = mini(3, max_hp - hp)
		hp += iris_heal
		contributions["iris_heal"] += iris_heal
		var hero_heal: int = mini(10, max_hp - hp) if role == "support" else 0
		hp += hero_heal
		contributions["hero_heal"] += hero_heal

func _finish(won: bool, reason: String) -> void:
	active = false
	if won:
		clears += 1
	else:
		wipes += 1
	recap = {"run": run_id, "won": won, "role": role, "rooms": room, "turns": turn,
		"hp": hp, "max_hp": max_hp, "stew_used": stew_used, "reason": reason,
		"contributions": contributions.duplicate(), "log": log.duplicate()}

func abort() -> void:
	requested = false
	if active:
		_finish(false, "Practice stopped. No reward; unused stew is kept.")

func to_save_dict() -> Dictionary:
	return {"requested": requested, "selected_role": selected_role, "active": active, "run_id": run_id,
		"role": role, "attack": attack, "max_hp": max_hp, "hp": hp, "room": room, "enemy_hp": enemy_hp,
		"turn": turn, "remainder_usec": remainder_usec, "stew_available": stew_available, "stew_used": stew_used,
		"clears": clears, "wipes": wipes, "first_reward_claimed": first_reward_claimed,
		"contributions": contributions.duplicate(), "log": log.duplicate(), "recap": recap.duplicate(true)}

func load_save_dict(data: Dictionary) -> void:
	requested = bool(data.get("requested", false))
	selected_role = str(data.get("selected_role", "damage"))
	if not Catalog.ROLES.has(selected_role):
		selected_role = "damage"
	active = bool(data.get("active", false))
	role = str(data.get("role", "damage"))
	if not Catalog.ROLES.has(role):
		role = "damage"
	run_id = maxi(0, int(data.get("run_id", 0)))
	attack = maxi(1, int(data.get("attack", 6)))
	max_hp = maxi(1, int(data.get("max_hp", 96)))
	hp = clampi(int(data.get("hp", 96)), 0, max_hp)
	room = clampi(int(data.get("room", 0)), 0, 3)
	if room == 3:
		active = false
	enemy_hp = maxi(0, int(data.get("enemy_hp", 30)))
	turn = maxi(0, int(data.get("turn", 0)))
	remainder_usec = clampi(int(data.get("remainder_usec", 0)), 0, 999999)
	stew_available = bool(data.get("stew_available", false))
	stew_used = bool(data.get("stew_used", false))
	clears = maxi(0, int(data.get("clears", 0)))
	wipes = maxi(0, int(data.get("wipes", 0)))
	first_reward_claimed = bool(data.get("first_reward_claimed", false))
	contributions = _counts(data.get("contributions", {}))
	log.clear()
	for line in data.get("log", []):
		log.append(str(line))
	recap = data.get("recap", {}).duplicate(true)
	if not recap.is_empty():
		for key in ["run", "rooms", "turns", "hp", "max_hp"]:
			recap[key] = maxi(0, int(recap.get(key, 0)))
		recap["contributions"] = _counts(recap.get("contributions", {}))

func _counts(raw: Dictionary) -> Dictionary:
	var result := {}
	for key in raw:
		if str(key) in ["hero_damage", "bran_damage", "iris_damage", "hero_block", "bran_block", "hero_heal", "iris_heal", "stew_heal"]:
			result[str(key)] = maxi(0, int(raw[key]))
	return result
