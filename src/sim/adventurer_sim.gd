class_name AdventurerSim
extends Node

signal event_emitted(event: Dictionary)

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")

const TOWN_POSITION := Vector3(-5.0, 0.0, 3.0)
const GOBLIN_CAMP_POSITION := Vector3(1.5, 0.0, -1.5)
const WOLF_DEN_POSITION := Vector3(5.0, 0.0, -4.0)
const BRIARFEN_POSITION := Vector3(8.0, 0.0, 3.2)
const THORNBACK_POSITION := Vector3(8.0, 0.0, -1.2)

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
var quest_kind: String = "rangers_errand"
var quest_cycles_completed: int = 0
var goblins_killed: int = 0
var wolves_killed: int = 0
var briarlings_killed: int = 0
var thornback_killed: bool = false
var total_kills: int = 0
var deaths: int = 0

var last_loot: String = ""
var inventory: Dictionary = {}
var gear_inventory: Dictionary = {}
var equipped: Dictionary = {
	"weapon": "",
	"head": "",
	"chest": "",
	"legs": "",
	"hands": "",
	"feet": "",
	"offhand": "",
	"accessory": ""
}
var recent_events: Array[String] = []

var unlocked_talents: Dictionary = {}
var hero_attack_count: int = 0
var second_wind_used: bool = false
var last_stand_used: bool = false

var active_companion: String = ""
var companion_bond_xp: Dictionary = {}

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
		"quest_kind": quest_kind,
		"quest_cycles_completed": quest_cycles_completed,
		"goblins_killed": goblins_killed,
		"wolves_killed": wolves_killed,
		"briarlings_killed": briarlings_killed,
		"thornback_killed": thornback_killed,
		"total_kills": total_kills,
		"deaths": deaths,
		"last_loot": last_loot,
		"inventory": inventory.duplicate(true),
		"gear_inventory": gear_inventory.duplicate(true),
		"equipped": equipped.duplicate(true),
		"unlocked_talents": unlocked_talents.duplicate(true),
		"hero_attack_count": hero_attack_count,
		"second_wind_used": second_wind_used,
		"last_stand_used": last_stand_used,
		"active_companion": active_companion,
		"companion_bond_xp": companion_bond_xp.duplicate(true)
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
	quest_kind = str(data.get("quest_kind", "rangers_errand"))
	if quest_kind not in ["rangers_errand", "briarfen"]:
		quest_kind = "rangers_errand"
	quest_cycles_completed = max(0, int(data.get("quest_cycles_completed", 0)))
	goblins_killed = max(0, int(data.get("goblins_killed", 0)))
	wolves_killed = max(0, int(data.get("wolves_killed", 0)))
	briarlings_killed = max(0, int(data.get("briarlings_killed", 0)))
	thornback_killed = bool(data.get("thornback_killed", false))
	total_kills = max(0, int(data.get("total_kills", 0)))
	deaths = max(0, int(data.get("deaths", 0)))
	last_loot = str(data.get("last_loot", ""))
	inventory = (data.get("inventory", {}) as Dictionary).duplicate(true)
	gear_inventory = (data.get("gear_inventory", {}) as Dictionary).duplicate(true)

	equipped = {
		"weapon": "",
		"head": "",
		"chest": "",
		"legs": "",
		"hands": "",
		"feet": "",
		"offhand": "",
		"accessory": ""
	}
	var saved_equipped: Dictionary = data.get("equipped", {})
	for slot_name in equipped.keys():
		var item_name := str(saved_equipped.get(slot_name, ""))
		if not item_name.is_empty() and GearCatalogScript.has_item(item_name) and GearCatalogScript.slot(item_name) == slot_name and int(gear_inventory.get(item_name, 0)) > 0:
			equipped[slot_name] = item_name

	unlocked_talents = {}
	var saved_talents: Dictionary = data.get("unlocked_talents", {})
	for talent_id in saved_talents.keys():
		var id := str(talent_id)
		if TalentCatalogScript.has_talent(id) and bool(saved_talents[talent_id]):
			unlocked_talents[id] = true

	hero_attack_count = max(0, int(data.get("hero_attack_count", 0)))
	second_wind_used = bool(data.get("second_wind_used", false))
	last_stand_used = bool(data.get("last_stand_used", false))

	active_companion = str(data.get("active_companion", ""))
	if not active_companion.is_empty() and not CompanionCatalogScript.has_companion(active_companion):
		active_companion = ""
	companion_bond_xp = {}
	var saved_bond: Dictionary = data.get("companion_bond_xp", {})
	for companion_name in saved_bond.keys():
		var name := str(companion_name)
		if CompanionCatalogScript.has_companion(name):
			companion_bond_xp[name] = maxi(0, int(saved_bond[companion_name]))

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

func set_active_companion(companion_name: String) -> bool:
	if not CompanionCatalogScript.has_companion(companion_name):
		return false
	var old_max_hp := effective_max_hp()
	active_companion = companion_name
	var new_max_hp := effective_max_hp()
	if new_max_hp > old_max_hp:
		hero_hp = min(new_max_hp, hero_hp + (new_max_hp - old_max_hp))
	else:
		hero_hp = min(hero_hp, new_max_hp)
	_emit_event(
		"companion_changed",
		"%s joined the adventure." % companion_name,
		{"companion": companion_name}
	)
	return true

func clear_active_companion() -> void:
	if active_companion.is_empty():
		return
	var old_name := active_companion
	active_companion = ""
	hero_hp = min(hero_hp, effective_max_hp())
	_emit_event("companion_changed", "%s is resting." % old_name, {"companion": ""})

func companion_bond_xp_for(companion_name: String) -> int:
	return maxi(0, int(companion_bond_xp.get(companion_name, 0)))

func companion_bond_level(companion_name: String) -> int:
	if not CompanionCatalogScript.has_companion(companion_name):
		return 0
	return CompanionCatalogScript.bond_level_for_xp(companion_bond_xp_for(companion_name))

func active_companion_bond_level() -> int:
	if active_companion.is_empty():
		return 0
	return companion_bond_level(active_companion)

func _grant_companion_bond_xp(amount: int) -> void:
	if active_companion.is_empty() or amount <= 0:
		return
	var old_level := companion_bond_level(active_companion)
	companion_bond_xp[active_companion] = companion_bond_xp_for(active_companion) + amount
	var new_level := companion_bond_level(active_companion)
	if new_level > old_level:
		_emit_event(
			"companion_bond_up",
			"%s reached bond %d." % [active_companion, new_level],
			{"companion": active_companion, "bond_level": new_level}
		)

func has_talent(talent_id: String) -> bool:
	return bool(unlocked_talents.get(talent_id, false))

func talent_points_total() -> int:
	return max(0, hero_level - 1)

func talent_points_spent() -> int:
	return unlocked_talents.size()

func talent_points_available() -> int:
	return max(0, talent_points_total() - talent_points_spent())

func talent_branch_spent(branch_id: String) -> int:
	var spent := 0
	for talent_id in TalentCatalogScript.nodes_for_branch(branch_id):
		if has_talent(talent_id):
			spent += 1
	return spent

func build_summary() -> String:
	var parts: Array[String] = []
	for branch_id in TalentCatalogScript.branch_ids():
		var spent := talent_branch_spent(branch_id)
		if spent > 0:
			parts.append("%s %d" % [TalentCatalogScript.branch_label(branch_id), spent])
	if parts.is_empty():
		return "Uncommitted"
	return " · ".join(parts)

func can_unlock_talent(talent_id: String) -> bool:
	if not TalentCatalogScript.has_talent(talent_id):
		return false
	if has_talent(talent_id):
		return false
	if talent_points_available() <= 0:
		return false
	var requirement: String = TalentCatalogScript.requirement(talent_id)
	return requirement.is_empty() or has_talent(requirement)

func unlock_talent(talent_id: String) -> bool:
	if not can_unlock_talent(talent_id):
		return false
	var old_max_hp := effective_max_hp()
	unlocked_talents[talent_id] = true
	var new_max_hp := effective_max_hp()
	if new_max_hp > old_max_hp:
		hero_hp = min(new_max_hp, hero_hp + (new_max_hp - old_max_hp))
	_emit_event(
		"talent_unlocked",
		"Learned %s." % TalentCatalogScript.talent_name(talent_id),
		{"talent": talent_id}
	)
	return true

func reset_talents() -> void:
	if unlocked_talents.is_empty():
		return
	unlocked_talents.clear()
	hero_hp = min(hero_hp, effective_max_hp())
	hero_attack_count = 0
	second_wind_used = false
	last_stand_used = false
	_emit_event("talents_reset", "Talents reset.")

func effective_move_speed() -> float:
	var speed := MOVE_SPEED * (1.20 if has_talent("trail_legs") else 1.0)
	if not active_companion.is_empty():
		speed *= CompanionCatalogScript.move_multiplier(active_companion, active_companion_bond_level())
	return speed

func effective_attack_interval() -> float:
	return HERO_ATTACK_INTERVAL * (0.85 if has_talent("quick_hands") else 1.0)

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

func unequip_gear(item_name: String) -> bool:
	if not GearCatalogScript.has_item(item_name):
		return false
	var slot_name: String = GearCatalogScript.slot(item_name)
	if equipped_item(slot_name) != item_name:
		return false
	equipped[slot_name] = ""
	hero_hp = min(hero_hp, effective_max_hp())
	_emit_event("gear_unequipped", "Unequipped %s." % item_name, {"gear": item_name, "slot": slot_name})
	return true

func gear_count(item_name: String) -> int:
	return max(0, int(gear_inventory.get(item_name, 0)))

func can_dispose_gear(item_name: String) -> bool:
	if not GearCatalogScript.has_item(item_name):
		return false
	var count := gear_count(item_name)
	if count <= 0:
		return false
	var slot_name := GearCatalogScript.slot(item_name)
	if equipped_item(slot_name) == item_name and count <= 1:
		return false
	return true

func sell_gear(item_name: String) -> Dictionary:
	if not can_dispose_gear(item_name):
		return {"ok": false, "gold": 0}
	var value := GearCatalogScript.sell_value(item_name)
	_remove_one_gear(item_name)
	gold += value
	_emit_event("gear_sold", "Sold %s for %d gold." % [item_name, value], {"gear": item_name, "gold": value})
	return {"ok": true, "gold": value}

func salvage_gear(item_name: String) -> Dictionary:
	if not can_dispose_gear(item_name):
		return {"ok": false, "tokens": 0}
	var tokens := GearCatalogScript.salvage_tokens(item_name)
	_remove_one_gear(item_name)
	_emit_event("gear_salvaged", "Salvaged %s for %d gacha token%s." % [item_name, tokens, "" if tokens == 1 else "s"], {"gear": item_name, "tokens": tokens})
	return {"ok": true, "tokens": tokens}

func _remove_one_gear(item_name: String) -> void:
	var count := gear_count(item_name)
	if count <= 1:
		gear_inventory.erase(item_name)
	else:
		gear_inventory[item_name] = count - 1

func owned_gear_names() -> Array[String]:
	var names: Array[String] = []
	for item_name in gear_inventory.keys():
		if int(gear_inventory.get(item_name, 0)) > 0:
			names.append(str(item_name))
	names.sort()
	return names

func effective_attack() -> int:
	var total := hero_attack
	if has_talent("sharpened_edge"):
		total += 2
	if not active_companion.is_empty():
		total += CompanionCatalogScript.attack_bonus(active_companion, active_companion_bond_level())
	for item_name in equipped.values():
		if not str(item_name).is_empty():
			total += GearCatalogScript.attack_bonus(str(item_name))
	return total

func effective_max_hp() -> int:
	var total := hero_max_hp
	if has_talent("thick_hide"):
		total += 10
	if not active_companion.is_empty():
		total += CompanionCatalogScript.hp_bonus(active_companion, active_companion_bond_level())
	for item_name in equipped.values():
		if not str(item_name).is_empty():
			total += GearCatalogScript.hp_bonus(str(item_name))
	return total

func take_damage(amount: int) -> void:
	if amount <= 0 or activity == "recovering":
		return

	var resolved_damage := amount
	if has_talent("iron_guard"):
		resolved_damage = max(1, resolved_damage - 1)

	if resolved_damage >= hero_hp and has_talent("last_stand") and not last_stand_used:
		last_stand_used = true
		hero_hp = 1
		_emit_event("talent_proc", "Last stand kept you on your feet.", {"talent": "last_stand"})
		return

	hero_hp = max(0, hero_hp - resolved_damage)
	if hero_hp <= 0:
		_die()
		return

	if has_talent("second_wind") and not second_wind_used:
		var threshold: int = max(1, int(floor(float(effective_max_hp()) * 0.35)))
		if hero_hp <= threshold:
			second_wind_used = true
			hero_hp = min(effective_max_hp(), hero_hp + 8)
			_emit_event("talent_proc", "Second wind restored 8 health.", {"talent": "second_wind"})

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
	if quest_kind == "briarfen":
		if quest_stage <= 1:
			return "Briarfen Trouble · Briarlings %d/4" % briarlings_killed
		if quest_stage <= 3 and not thornback_killed:
			return "Briarfen Trouble · Defeat Old Thornback"
		if quest_stage == 4:
			return "Briarfen Trouble · Return to Mossgate"
		return "Briarfen Trouble · Complete"

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
		"deaths": deaths,
		"active_companion": active_companion,
		"companion_bond_level": active_companion_bond_level()
	}

func _begin_quest_cycle() -> void:
	last_stand_used = false
	goblins_killed = 0
	wolves_killed = 0
	briarlings_killed = 0
	thornback_killed = false
	quest_stage = 0
	hero_hp = effective_max_hp()

	if quest_cycles_completed <= 0:
		quest_kind = "rangers_errand"
		_emit_event("quest_started", "Ranger's Errand started.")
		_travel_to("goblin_camp", "Goblin Camp", GOBLIN_CAMP_POSITION, false)
	else:
		quest_kind = "briarfen"
		_emit_event("quest_started", "Briarfen Trouble started.")
		_travel_to("briarfen", "Briarfen", BRIARFEN_POSITION, false)

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

	var step: float = effective_move_speed() * delta
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
		"briarfen":
			quest_stage = 1
			_start_fight("briarling")
		"thornback_lair":
			quest_stage = 3
			_start_fight("thornback")
		"town":
			_complete_quest()

func _start_fight(kind: String) -> void:
	enemy_kind = kind
	match kind:
		"goblin":
			enemy_max_hp = 14
		"wolf":
			enemy_max_hp = 22
		"briarling":
			enemy_max_hp = 28
		"thornback":
			enemy_max_hp = 60
		_:
			enemy_max_hp = 10

	enemy_hp = enemy_max_hp
	hero_attack_clock = 0.0
	enemy_attack_clock = 0.0
	hero_attack_count = 0
	second_wind_used = false
	activity = "fighting"
	_emit_event("fight_started", "Engaged %s." % _enemy_display_name(kind), {"enemy": kind})

func _advance_combat(delta: float) -> void:
	hero_attack_clock += delta
	enemy_attack_clock += delta

	var attack_interval := effective_attack_interval()
	while hero_attack_clock >= attack_interval and activity == "fighting":
		hero_attack_clock -= attack_interval
		var damage := _next_hero_damage()
		enemy_hp = max(0, enemy_hp - damage)
		if enemy_hp <= 0:
			_defeat_enemy()
			return

	var enemy_interval: float = 1.30
	var enemy_damage: int = 4
	match enemy_kind:
		"goblin":
			enemy_interval = 1.55
			enemy_damage = 2
		"wolf":
			enemy_interval = 1.30
			enemy_damage = 4
		"briarling":
			enemy_interval = 1.45
			enemy_damage = 4
		"thornback":
			enemy_interval = 1.55
			enemy_damage = 6
	while enemy_attack_clock >= enemy_interval and activity == "fighting":
		enemy_attack_clock -= enemy_interval
		take_damage(enemy_damage)
		if activity != "fighting":
			return

func _next_hero_damage() -> int:
	hero_attack_count += 1
	var damage := effective_attack()

	if has_talent("opening_strike") and hero_attack_count == 1:
		damage += 4
		_emit_event("talent_proc", "Opening strike hit harder.", {"talent": "opening_strike"})

	if has_talent("heavy_hand") and hero_attack_count % 4 == 0:
		damage = int(ceil(float(damage) * 1.5))
		_emit_event("talent_proc", "Heavy hand struck hard.", {"talent": "heavy_hand"})

	if has_talent("executioner") and enemy_max_hp > 0 and enemy_hp > 0:
		if enemy_hp <= int(ceil(float(enemy_max_hp) * 0.25)):
			damage = int(ceil(float(damage) * 1.5))
			_emit_event("talent_proc", "Executioner found the opening.", {"talent": "executioner"})

	return max(1, damage)

func _defeat_enemy() -> void:
	var defeated_kind: String = enemy_kind
	total_kills += 1

	match defeated_kind:
		"goblin":
			goblins_killed += 1
			last_loot = "Goblin Trinket"
			_grant_enemy_xp(8)
		"wolf":
			wolves_killed += 1
			last_loot = "Wolf Pelt"
			_grant_enemy_xp(12)
		"briarling":
			briarlings_killed += 1
			last_loot = "Briar Sap"
			_grant_enemy_xp(16)
		"thornback":
			thornback_killed = true
			last_loot = "Thornback Tusk"
			_grant_enemy_xp(40)
			if int(gear_inventory.get("Briarheart Charm", 0)) == 0:
				add_gear("Briarheart Charm")
		_:
			last_loot = "Unknown Trophy"
			_grant_enemy_xp(5)

	if has_talent("bloodlust"):
		var hp_before := hero_hp
		hero_hp = min(effective_max_hp(), hero_hp + 4)
		if hero_hp > hp_before:
			_emit_event("talent_proc", "Bloodlust restored %d health." % (hero_hp - hp_before), {"talent": "bloodlust"})

	if not active_companion.is_empty():
		var companion_heal := CompanionCatalogScript.kill_heal(active_companion, active_companion_bond_level())
		if companion_heal > 0:
			var companion_hp_before := hero_hp
			hero_hp = min(effective_max_hp(), hero_hp + companion_heal)
			if hero_hp > companion_hp_before:
				_emit_event(
					"companion_proc",
					"%s restored %d health." % [active_companion, hero_hp - companion_hp_before],
					{"companion": active_companion}
				)
		_grant_companion_bond_xp(1)

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

	if quest_kind == "briarfen":
		if quest_stage == 1:
			if briarlings_killed < 4:
				_start_fight("briarling")
			else:
				quest_stage = 2
				_travel_to("thornback_lair", "Old Thornback's Hollow", THORNBACK_POSITION, false)
			return

		if quest_stage == 3:
			if not thornback_killed:
				_start_fight("thornback")
			else:
				quest_stage = 4
				_travel_to("town", "Mossgate", TOWN_POSITION, true)
			return

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
	var completed_quest := quest_kind
	var gold_reward := 40 if completed_quest == "briarfen" else 20
	var xp_reward := 35 if completed_quest == "briarfen" else 20
	if not active_companion.is_empty():
		gold_reward = int(round(float(gold_reward) * CompanionCatalogScript.gold_multiplier(active_companion, active_companion_bond_level())))

	quest_cycles_completed += 1
	gold += gold_reward
	_grant_xp(xp_reward)
	hero_hp = effective_max_hp()
	quest_stage = 5
	activity = "resting"
	activity_timer = REST_TIME
	var quest_name := "Briarfen Trouble" if completed_quest == "briarfen" else "Ranger's Errand"
	_emit_event(
		"quest_completed",
		"%s complete. +%d gold." % [quest_name, gold_reward],
		{"gold": gold_reward, "cycle": quest_cycles_completed, "quest": completed_quest}
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
	_emit_event("recovered", "Recovered. Back to the quest.")

	if quest_kind == "briarfen":
		if briarlings_killed < 4:
			quest_stage = 0
			_travel_to("briarfen", "Briarfen", BRIARFEN_POSITION, false)
		elif not thornback_killed:
			quest_stage = 2
			_travel_to("thornback_lair", "Old Thornback's Hollow", THORNBACK_POSITION, false)
		else:
			quest_stage = 4
			_travel_to("town", "Mossgate", TOWN_POSITION, true)
		return

	if goblins_killed < 3:
		quest_stage = 0
		_travel_to("goblin_camp", "Goblin Camp", GOBLIN_CAMP_POSITION, false)
	elif wolves_killed < 2:
		quest_stage = 2
		_travel_to("wolf_den", "Wolf Den", WOLF_DEN_POSITION, false)
	else:
		quest_stage = 4
		_travel_to("town", "Mossgate", TOWN_POSITION, true)

func _grant_enemy_xp(amount: int) -> void:
	var resolved_amount := amount
	if has_talent("hunter_eye"):
		resolved_amount = int(round(float(resolved_amount) * 1.25))
	if not active_companion.is_empty():
		resolved_amount = int(round(float(resolved_amount) * CompanionCatalogScript.xp_multiplier(active_companion, active_companion_bond_level())))
	_grant_xp(resolved_amount)

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
		"briarling":
			return "Briarling"
		"thornback":
			return "Old Thornback"
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
