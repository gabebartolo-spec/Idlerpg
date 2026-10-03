class_name CompanionCatalog
extends RefCounted

const COMPANIONS := {
	"Pack Rat": {
		"rarity": "Common",
		"role": "Scavenger",
		"description": "Carries extra spoils. +10% quest gold.",
		"gold_mult": 1.10
	},
	"Stable Hound": {
		"rarity": "Common",
		"role": "Trail companion",
		"description": "Keeps the pace up. +10% travel speed.",
		"move_mult": 1.10
	},
	"Torch Sprite": {
		"rarity": "Common",
		"role": "Battle spark",
		"description": "Adds a little magical sting. +1 attack.",
		"attack": 1
	},
	"Hill Squire": {
		"rarity": "Rare",
		"role": "Bodyguard",
		"description": "Stands between you and trouble. +8 max health.",
		"hp": 8
	},
	"Marsh Witch": {
		"rarity": "Rare",
		"role": "Hedge healer",
		"description": "Patches you up after fights. Heal 2 after a kill.",
		"kill_heal": 2
	},
	"Clockwork Raven": {
		"rarity": "Rare",
		"role": "Scout",
		"description": "Finds better fights. +10% enemy XP.",
		"xp_mult": 1.10
	},
	"Frost Ranger": {
		"rarity": "Epic",
		"role": "Hunter",
		"description": "Adds serious pressure. +3 attack.",
		"attack": 3
	},
	"Sun Cleric": {
		"rarity": "Epic",
		"role": "Protector",
		"description": "A durable travelling blessing. +14 max health.",
		"hp": 14
	},
	"Grave Knight": {
		"rarity": "Epic",
		"role": "Executioner",
		"description": "Feeds on victories. +2 attack and heal 2 after a kill.",
		"attack": 2,
		"kill_heal": 2
	},
	"Ancient Warden": {
		"rarity": "Legendary",
		"role": "Guardian",
		"description": "A powerful all-round protector. +3 attack, +16 health, +10% travel speed.",
		"attack": 3,
		"hp": 16,
		"move_mult": 1.10
	}
}

static func has_companion(companion_name: String) -> bool:
	return COMPANIONS.has(companion_name)

static func data(companion_name: String) -> Dictionary:
	if not COMPANIONS.has(companion_name):
		return {}
	return (COMPANIONS[companion_name] as Dictionary).duplicate(true)

static func rarity(companion_name: String) -> String:
	return str(data(companion_name).get("rarity", "Common"))

static func role(companion_name: String) -> String:
	return str(data(companion_name).get("role", ""))

static func description(companion_name: String) -> String:
	return str(data(companion_name).get("description", ""))

static func attack_bonus(companion_name: String, bond_level: int = 1) -> int:
	var base: int = int(data(companion_name).get("attack", 0))
	return _scaled_int(base, bond_level)

static func hp_bonus(companion_name: String, bond_level: int = 1) -> int:
	var base: int = int(data(companion_name).get("hp", 0))
	return _scaled_int(base, bond_level)

static func kill_heal(companion_name: String, bond_level: int = 1) -> int:
	var base: int = int(data(companion_name).get("kill_heal", 0))
	return _scaled_int(base, bond_level)

static func move_multiplier(companion_name: String, bond_level: int = 1) -> float:
	return _scaled_multiplier(float(data(companion_name).get("move_mult", 1.0)), bond_level)

static func xp_multiplier(companion_name: String, bond_level: int = 1) -> float:
	return _scaled_multiplier(float(data(companion_name).get("xp_mult", 1.0)), bond_level)

static func gold_multiplier(companion_name: String, bond_level: int = 1) -> float:
	return _scaled_multiplier(float(data(companion_name).get("gold_mult", 1.0)), bond_level)

static func _scaled_int(base: int, bond_level: int) -> int:
	if base <= 0:
		return 0
	var multiplier := 1.0 + 0.10 * float(maxi(0, bond_level - 1))
	return maxi(1, int(round(float(base) * multiplier)))

static func _scaled_multiplier(base: float, bond_level: int) -> float:
	if base <= 1.0:
		return 1.0
	var bonus := base - 1.0
	return 1.0 + bonus * (1.0 + 0.10 * float(maxi(0, bond_level - 1)))

static func bond_level_for_xp(xp: int) -> int:
	if xp >= 100:
		return 5
	if xp >= 50:
		return 4
	if xp >= 25:
		return 3
	if xp >= 10:
		return 2
	return 1
