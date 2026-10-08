extends RefCounted
const Catalog = preload("res://src/data/expedition_catalog.gd")
var requested: bool = false
var selected_route: String = "greenway"
var active: bool = false
var route: String = "greenway"
var run_id: int = 0
var node: int = 0
var remainder_usec: int = 0
var attack: int = 6
var max_hp: int = 36
var hp: int = 36
var thornward: bool = false
var stew_available: bool = false
var stew_used: bool = false
var completed: int = 0
var claimed_routes: Dictionary = {}
var discoveries: Dictionary = {}
var gold_earned: int = 0
var log: Array[String] = []
var recap: Dictionary = {}

func start(hero_attack: int, hero_health: int, protected: bool, prepared: bool) -> void:
	requested = false
	active = true
	route = selected_route
	run_id += 1
	node = 0
	remainder_usec = 0
	attack = hero_attack
	max_hp = hero_health
	hp = max_hp
	thornward = protected
	stew_available = prepared
	stew_used = false
	gold_earned = 0
	log.clear()
	log.append("Set out along " + str(Catalog.ROUTES[route]["name"]) + ".")
	recap.clear()

func advance(seconds: float) -> Dictionary:
	if not active:
		return {}
	var elapsed: int = remainder_usec + int(round(seconds * 1000000.0))
	var nodes: int = elapsed / Catalog.NODE_USEC
	remainder_usec = elapsed % Catalog.NODE_USEC
	var events: Array[Dictionary] = []
	for _i in mini(nodes, 5):
		var result := _resolve_node()
		events.append(result)
		if not active:
			break
	return {"events": events, "finished": not active}

func _resolve_node() -> Dictionary:
	if stew_available and not stew_used and hp <= max_hp - 12:
		hp += 12
		stew_used = true
		log.append("Pond Stew restored twelve health along the trail.")
	var id: String = Catalog.ROUTES[route]["nodes"][node]
	var encounter: Dictionary = Catalog.ENCOUNTERS[id]
	discoveries[id] = true
	var damage: int = int(encounter.get("damage", 0))
	if id == "wolves":
		damage = maxi(4, damage - attack)
	if id == "guardian" and thornward:
		damage /= 2
	hp = maxi(0, hp - damage)
	var healed: int = mini(max_hp - hp, int(encounter.get("heal", 0)))
	hp += healed
	var gold: int = int(encounter.get("gold", 0))
	gold_earned += gold
	log.append("%d. %s %s" % [node + 1, encounter["name"], encounter["text"]])
	node += 1
	var first := false
	if hp == 0:
		_finish(false, "The route proved too hard. Found cache gold is kept; no final reward. Prepare or try the Greenway.")
	elif node == 5:
		first = not claimed_routes.has(route)
		claimed_routes[route] = true
		completed += 1
		var reward: int = Catalog.ROUTES[route]["first_gold"] if first else Catalog.ROUTES[route]["repeat_gold"]
		gold += reward
		gold_earned += reward
		_finish(true, "Returned safely. +%d final gold%s." % [reward, " for the first route completion" if first else ""])
	return {"encounter": id, "gold": gold, "first": first, "damage": damage, "healed": healed}

func _finish(won: bool, reason: String) -> void:
	active = false
	log.append(reason)
	recap = {"run": run_id, "route": route, "won": won, "nodes": node, "hp": hp,
		"gold": gold_earned, "stew_used": stew_used, "reason": reason, "log": log.duplicate()}

func abort() -> void:
	requested = false
	if active:
		_finish(false, "Expedition stopped. Found gold and unused preparation are kept; no final reward.")

func to_save_dict() -> Dictionary:
	return {"requested": requested, "selected_route": selected_route, "active": active, "route": route,
		"run_id": run_id, "node": node, "remainder_usec": remainder_usec, "attack": attack,
		"max_hp": max_hp, "hp": hp, "thornward": thornward, "stew_available": stew_available,
		"stew_used": stew_used, "completed": completed, "claimed_routes": claimed_routes.duplicate(),
		"discoveries": discoveries.duplicate(), "gold_earned": gold_earned, "log": log.duplicate(), "recap": recap.duplicate(true)}

func load_save_dict(data: Dictionary) -> void:
	requested = bool(data.get("requested", false))
	selected_route = str(data.get("selected_route", "greenway"))
	if not Catalog.ROUTES.has(selected_route):
		selected_route = "greenway"
	active = bool(data.get("active", false))
	route = str(data.get("route", "greenway"))
	if not Catalog.ROUTES.has(route):
		route = "greenway"
	run_id = maxi(0, int(data.get("run_id", 0)))
	node = clampi(int(data.get("node", 0)), 0, 5)
	if node == 5:
		active = false
	remainder_usec = clampi(int(data.get("remainder_usec", 0)), 0, Catalog.NODE_USEC - 1)
	attack = maxi(1, int(data.get("attack", 6)))
	max_hp = maxi(1, int(data.get("max_hp", 36)))
	hp = clampi(int(data.get("hp", 36)), 0, max_hp)
	thornward = bool(data.get("thornward", false))
	stew_available = bool(data.get("stew_available", false))
	stew_used = bool(data.get("stew_used", false))
	completed = maxi(0, int(data.get("completed", 0)))
	claimed_routes = _flags(data.get("claimed_routes", {}), Catalog.ROUTES)
	discoveries = _flags(data.get("discoveries", {}), Catalog.ENCOUNTERS)
	gold_earned = maxi(0, int(data.get("gold_earned", 0)))
	log.clear()
	for line in data.get("log", []):
		log.append(str(line))
	recap = data.get("recap", {}).duplicate(true)
	if not recap.is_empty():
		for key in ["run", "nodes", "hp", "gold"]:
			recap[key] = maxi(0, int(recap.get(key, 0)))

func _flags(raw: Dictionary, valid: Dictionary) -> Dictionary:
	var result := {}
	for key in valid:
		if bool(raw.get(key, false)):
			result[key] = true
	return result
