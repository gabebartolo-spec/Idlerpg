class_name AdventurerSim
extends Node

signal event_emitted(event: Dictionary)

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")

const TOWN_POSITION := Vector3(-5.0, 0.0, 3.0)
const GOBLIN_CAMP_POSITION := Vector3(1.5, 0.0, -1.5)
const WOLF_DEN_POSITION := Vector3(5.0, 0.0, -4.0)

const MOVE_SPEED := 2.4
const HERO_ATTACK_INTERVAL := 0.9
const LOOT_TIME := 0.7
const RECOVERY_TIME := 3.0
const REST_TIME := 2.5

var hero_position: Vector3 = TOWN_POSITION
var hero_level: int = 1
var hero_xp: int = 0
var hero_max_hp: int = 36
var hero_hp: int = 36
var hero_attack: int = 6
var gold: int = 0

var activity: String = ""
var activity_timer: float = 0.0
var destination_id: String = ""
var destination_name: String = ""
var destination: Vector3 = TOWN_POSITION

var enemy_kind: String = ""
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_attack_clock: float = 0.0
var hero_attack_clock: float = 0.0

var quest_stage: int = 0
var quest_cycles_completed: int = 0
var goblins_killed: int = 0
var wolves_killed: int = 0
var total_kills: int = 0
var deaths: int = 0

var last_loot: String = ""
var inventory: Dictionary = {}
var gear_inventory: Dictionary = {}
var equipped: Dictionary = {
	"weapon": "",
	"head": "",
	"chest": "",
	"offhand": ""
}
var recent_events: Array[String] = []

func _ready() -> void:
	if activity.is_empty():
		_begin_quest_cycle()

func advance(delta: float) -> void:
	if delta <= 0.0:
		return

	match activity:
		"travelling", "returning":
			_advance_travel(delta)
		"fighting":
			_advance_combat(delta)
		"looting":
			activity_timer -= delta
			if activity_timer <= 0.0:
				_finish_looting()
		"recovering":
			activity_timer -= delta
			if activity_timer <= 0.0:
				_finish_recovery()
		"resting":
			activity_timer -= delta
			if activity_timer <= 0.0:
				_begin_quest_cycle()

func simulate_elapsed(seconds: float) -> void:
	var remaining: float = max(0.0, seconds)
	while remaining > 0.0001:
		var step: float = min(0.1, remaining)
		advance(step)
		remaining -= step

func to_save_dict() -> Dictionary:
	return {
		"hero_position": [hero_position.x, hero_position.y, hero_position.z],
		"hero_level": hero_level,
		"hero_xp": hero_xp,
		"hero_max_hp": hero_max_hp,
		"hero_hp": hero_hp,
		"hero_attack": hero_attack,
		"gold": gold,
		"activity": activity,
		"activity_timer": activity_timer,
		"destination_id": destination_id,
		"destination_name": destination_name,
		"destination": [destination.x, destination.y, destination.z],
		"enemy_kind": enemy_kind,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_max_hp,
		"enemy_attack_clock": enemy_attack_clock,
		"hero_attack_clock": hero_attack_clock,
		"quest_stage": quest_stage,
		"quest_cycles_completed": quest_cycles_completed,
		"goblins_killed": goblins_killed,
		"wolves_killed": wolves_killed,
		"total_kills": total_kills,
		"deaths": deaths,
		"last_loot": last_loot,
		"inventory": inventory.duplicate(true),
		"gear_inventory": gear_inventory.duplicate(true),
		"equipped": equipped.duplicate(true)
	}

func load_save_dict(data: Dictionary) -> void:
	hero_position = _vec3_from_save(data.get("hero_position", []), TOWN_POSITION)
	hero_level = max(1, int(data.get("hero_level", 1)))
	hero_xp = max(0, int(data.get("hero_xp", 0)))
	hero_max_hp = max(1, int(data.get("hero_max_hp", 36)))
	var saved_hp: int = max(0, int(data.get("hero_hp", hero_max_hp)))
	hero_attack = max(1, int(data.get("hero_attack", 6)))
	gold = max(0, int(data.get("gold", 0)))
	activity = str(data.get("activity", ""))
	activity_timer = max(0.0, float(data.get("activity_timer", 0.0)))
	destination_id = str(data.get("destination_id", ""))
	destination_name = str(data.get("destination_name", ""))
	destination = _vec3_from_save(data.get("destination", []), TOWN_POSITION)
	enemy_kind = str(data.get("enemy_kind", ""))
	enemy_hp = max(0, int(data.get("enemy_hp", 0)))
	enemy_max_hp = max(0, int(data.get("enemy_max_hp", 0)))
	enemy_attack_clock = max(0.0, float(data.get("enemy_attack_clock", 0.0)))
	hero_attack_clock = max(0.0, float(data.get("hero_attack_clock", 0.0)))
	quest_stage = clampi(int(data.get("quest_stage", 0)), 0, 5)
	quest_cycles_completed = max(0, int(data.get("quest_cycles_completed", 0)))
	goblins_killed = max(0, int(data.get("goblins_killed", 0)))
	wolves_killed = max(0, int(data.get("wolves_killed", 0)))
	total_kills = max(0, int(data.get("total_kills", 0)))
	deaths = max(0, int(data.get("deaths", 0)))
	last_loot = str(data.get("last_loot", ""))
	inventory = (data.get("inventory", {}) as Dictionary).duplicate(true)
	gear_inventory = (data.get("gear_inventory", {}) as Dictionary).duplicate(true)

	equipped = {"weapon": "", "head": "", "chest": "", "offhand": ""}
	var saved_equipped: Dictionary = data.get("equipped", {})
	for slot_name in equipped.keys():
		var item_name := str(saved_equipped.get(slot_name, ""))
		if not item_name.is_empty() and GearCatalogScript.has_item(item_name) and GearCatalogScript.slot(item_name) == slot_name and int(gear_inventory.get(item_name, 0)) > 0:
			equipped[slot_name] = item_name

	hero_hp = clampi(saved_hp, 0, effective_max_hp())
	recent_events.clear()

func report_counters() -> Dictionary:
	return {
		"level": hero_level,
		"gold": gold,
		"total_kills": total_kills,
		"quests": quest_cycles_completed,
		"deaths": deaths,
		"inventory": inventory.duplicate(true),
		"gear_inventory": gear_inventory.duplicate(true)
	}

func _vec3_from_save(value: Variant, fallback: Vector3) -> Vector3:
	if value is Array and value.size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback

func add_gear(item_name: String) -> bool:
	if not GearCatalogScript.has_item(item_name):
		return false
	gear_inventory[item_name] = int(gear_inventory.get(item_name, 0)) + 1
	_emit_event("gear_obtained", "Found %s." % item_name, {"gear": item_name})
	return true

func equip_gear(item_name: String) -> bool:
	if not GearCatalogScript.has_item(item_name):
		return false
	if int(gear_inventory.get(item_name, 0)) <= 0:
		return false
	var slot_name: String = GearCatalogScript.slot(item_name)
	if slot_name.is_empty() or not equipped.has(slot_name):
		return false
	equipped[slot_name] = item_name
	hero_hp = min(hero_hp, effective_max_hp())
	_emit_event("gear_equipped", "Equipped %s." % item_name, {"gear": item_name, "slot": slot_name})
	return true

func equipped_item(slot_name: String) -> String:
	return str(equipped.get(slot_name, ""))

func owned_gear_names() -> Array[String]:
	var names: Array[String] = []
	for item_name in gear_inventory.keys():
		if int(gear_inventory.get(item_name, 0)) > 0:
			names.append(str(item_name))
	names.sort()
	return names

func effective_attack() -> int:
	var total := hero_attack
	for item_name in equipped.values():
		if not str(item_name).is_empty():
			total += GearCatalogScript.attack_bonus(str(item_name))
	return total

func effective_max_hp() -> int:
	var total := hero_max_hp
	for item_name in equipped.values():
		if not str(item_name).is_empty():
			total += GearCatalogScript.hp_bonus(str(item_name))
	return total

func take_damage(amount: int) -> void:
	if amount <= 0 or activity == "recovering":
		return
	hero_hp = max(0, hero_hp - amount)
	if hero_hp <= 0:
		_die()

func current_activity_text() -> String:
	match activity:
		"travelling":
			return "Running to %s" % destination_name
		"returning":
			return "Heading back to Mossgate"
		"fighting":
			return "Fighting %s · %d/%d HP" % [_enemy_display_name(enemy_kind), enemy_hp, enemy_max_hp]
		"looting":
			return "Picking up %s" % last_loot
		"recovering":
			return "Recovering in Mossgate"
		"resting":
			return "Resting after the quest"
		_:
			return "Waiting in Mossgate"

func current_quest_text() -> String:
	if quest_stage <= 1:
		return "Ranger's Errand · Goblins %d/3" % goblins_killed
	if quest_stage <= 3:
		return "Ranger's Errand · Wolves %d/2" % wolves_killed
	if quest_stage == 4:
		return "Ranger's Errand · Return to Mossgate"
	return "Ranger's Errand · Complete"

func xp_to_next_level() -> int:
	return hero_level * 30

func get_snapshot() -> Dictionary:
	return {
		"position": hero_position,
		"level": hero_level,
		"xp": hero_xp,
		"xp_to_next": xp_to_next_level(),
		"hp": hero_hp,
		"max_hp": effective_max_hp(),
		"attack": effective_attack(),
		"gold": gold,
		"activity": activity,
		"activity_text": current_activity_text(),
		"quest_text": current_quest_text(),
		"enemy_kind": enemy_kind,
		"enemy_hp": enemy_hp,
		"enemy_max_hp": enemy_max_hp,
		"quest_cycles_completed": quest_cycles_completed,
		"deaths": deaths
	}

func _begin_quest_cycle() -> void:
	goblins_killed = 0
	wolves_killed = 0
	quest_stage = 0
	hero_hp = effective_max_hp()
	_emit_event("quest_started", "Ranger's Errand started.")
	_travel_to("goblin_camp", "Goblin Camp", GOBLIN_CAMP_POSITION, false)

func _travel_to(id: String, label: String, target: Vector3, returning: bool) -> void:
	destination_id = id
	destination_name = label
	destination = target
	activity = "returning" if returning else "travelling"
	_emit_event("travel_started", current_activity_text(), {"destination": id})

func _advance_travel(delta: float) -> void:
	var distance: float = hero_position.distance_to(destination)
	if distance <= 0.01:
		hero_position = destination
		_arrive()
		return

	var step: float = MOVE_SPEED * delta
	hero_position = hero_position.move_toward(destination, step)
	if hero_position.distance_to(destination) <= 0.01:
		hero_position = destination
		_arrive()

func _arrive() -> void:
	_emit_event("arrived", "Arrived at %s." % destination_name, {"destination": destination_id})

	match destination_id:
		"goblin_camp":
			quest_stage = 1
			_start_fight("goblin")
		"wolf_den":
			quest_stage = 3
			_start_fight("wolf")
		"town":
			_complete_quest()

func _start_fight(kind: String) -> void:
	enemy_kind = kind
	match kind:
		"goblin":
			enemy_max_hp = 14
		"wolf":
			enemy_max_hp = 22
		_:
			enemy_max_hp = 10

	enemy_hp = enemy_max_hp
	hero_attack_clock = 0.0
	enemy_attack_clock = 0.0
	activity = "fighting"
	_emit_event("fight_started", "Engaged %s." % _enemy_display_name(kind), {"enemy": kind})

func _advance_combat(delta: float) -> void:
	hero_attack_clock += delta
	enemy_attack_clock += delta

	while hero_attack_clock >= HERO_ATTACK_INTERVAL and activity == "fighting":
		hero_attack_clock -= HERO_ATTACK_INTERVAL
		enemy_hp = max(0, enemy_hp - effective_attack())
		if enemy_hp <= 0:
			_defeat_enemy()
			return

	var enemy_interval: float = 1.55 if enemy_kind == "goblin" else 1.30
	var enemy_damage: int = 2 if enemy_kind == "goblin" else 4
	while enemy_attack_clock >= enemy_interval and activity == "fighting":
		enemy_attack_clock -= enemy_interval
		take_damage(enemy_damage)
		if activity != "fighting":
			return

func _defeat_enemy() -> void:
	var defeated_kind: String = enemy_kind
	total_kills += 1

	if defeated_kind == "goblin":
		goblins_killed += 1
		last_loot = "Goblin Trinket"
		_grant_xp(8)
	else:
		wolves_killed += 1
		last_loot = "Wolf Pelt"
		_grant_xp(12)

	inventory[last_loot] = int(inventory.get(last_loot, 0)) + 1
	_emit_event(
		"enemy_defeated",
		"Defeated %s and found %s." % [_enemy_display_name(defeated_kind), last_loot],
		{"enemy": defeated_kind, "loot": last_loot}
	)

	# The first quest guarantees one weapon and one armour choice so the
	# equipment loop can be tested without depending on gacha luck.
	if quest_cycles_completed == 0 and defeated_kind == "goblin" and goblins_killed == 3 and int(gear_inventory.get("Goblin Cleaver", 0)) == 0:
		add_gear("Goblin Cleaver")
	elif quest_cycles_completed == 0 and defeated_kind == "wolf" and wolves_killed == 2 and int(gear_inventory.get("Wolfskin Hood", 0)) == 0:
		add_gear("Wolfskin Hood")

	activity = "looting"
	activity_timer = LOOT_TIME
	enemy_hp = 0

func _finish_looting() -> void:
	enemy_kind = ""

	if quest_stage == 1:
		if goblins_killed < 3:
			_start_fight("goblin")
		else:
			quest_stage = 2
			_travel_to("wolf_den", "Wolf Den", WOLF_DEN_POSITION, false)
		return

	if quest_stage == 3:
		if wolves_killed < 2:
			_start_fight("wolf")
		else:
			quest_stage = 4
			_travel_to("town", "Mossgate", TOWN_POSITION, true)

func _complete_quest() -> void:
	quest_cycles_completed += 1
	gold += 20
	_grant_xp(20)
	hero_hp = effective_max_hp()
	quest_stage = 5
	activity = "resting"
	activity_timer = REST_TIME
	_emit_event(
		"quest_completed",
		"Ranger's Errand complete. +20 gold.",
		{"gold": 20, "cycle": quest_cycles_completed}
	)

func _die() -> void:
	deaths += 1
	activity = "recovering"
	activity_timer = RECOVERY_TIME
	hero_position = TOWN_POSITION
	enemy_kind = ""
	enemy_hp = 0
	_emit_event("death", "Your adventurer was defeated and returned to Mossgate.")

func _finish_recovery() -> void:
	hero_hp = effective_max_hp()
	_emit_event("recovered", "Recovered. Back to the errand.")

	if goblins_killed < 3:
		quest_stage = 0
		_travel_to("goblin_camp", "Goblin Camp", GOBLIN_CAMP_POSITION, false)
	elif wolves_killed < 2:
		quest_stage = 2
		_travel_to("wolf_den", "Wolf Den", WOLF_DEN_POSITION, false)
	else:
		quest_stage = 4
		_travel_to("town", "Mossgate", TOWN_POSITION, true)

func _grant_xp(amount: int) -> void:
	hero_xp += amount
	while hero_xp >= xp_to_next_level():
		hero_xp -= xp_to_next_level()
		hero_level += 1
		hero_max_hp += 5
		hero_attack += 1
		hero_hp = effective_max_hp()
		_emit_event("level_up", "Reached level %d." % hero_level, {"level": hero_level})

func _enemy_display_name(kind: String) -> String:
	match kind:
		"goblin":
			return "Goblin"
		"wolf":
			return "Grey Wolf"
		_:
			return "Enemy"

func _emit_event(type: String, message: String, details: Dictionary = {}) -> void:
	var event: Dictionary = {"type": type, "message": message}
	for key in details.keys():
		event[key] = details[key]

	recent_events.push_front(message)
	if recent_events.size() > 6:
		recent_events.resize(6)

	event_emitted.emit(event)
