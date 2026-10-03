class_name GearCatalog
extends RefCounted

const ITEMS := {
	"Iron Sword": {"slot": "weapon", "attack": 2, "hp": 0, "rarity": "Common"},
	"Leather Hood": {"slot": "head", "attack": 0, "hp": 3, "rarity": "Common"},
	"Oak Buckler": {"slot": "offhand", "attack": 0, "hp": 5, "rarity": "Common"},
	"Runed Longbow": {"slot": "weapon", "attack": 4, "hp": 0, "rarity": "Rare"},
	"Knight Mail": {"slot": "chest", "attack": 0, "hp": 9, "rarity": "Rare"},
	"Ember Staff": {"slot": "weapon", "attack": 5, "hp": 0, "rarity": "Rare"},
	"Moonsteel Blade": {"slot": "weapon", "attack": 7, "hp": 2, "rarity": "Epic"},
	"Wyrmhide Coat": {"slot": "chest", "attack": 1, "hp": 14, "rarity": "Epic"},
	"Stormcaller": {"slot": "weapon", "attack": 8, "hp": 0, "rarity": "Epic"},
	"Crownblade": {"slot": "weapon", "attack": 12, "hp": 4, "rarity": "Legendary"},
	"Goblin Cleaver": {"slot": "weapon", "attack": 3, "hp": 0, "rarity": "Common"},
	"Wolfskin Hood": {"slot": "head", "attack": 1, "hp": 5, "rarity": "Common"}
}

static func has_item(item_name: String) -> bool:
	return ITEMS.has(item_name)

static func item(item_name: String) -> Dictionary:
	if not ITEMS.has(item_name):
		return {}
	return (ITEMS[item_name] as Dictionary).duplicate(true)

static func slot(item_name: String) -> String:
	return str(item(item_name).get("slot", ""))

static func attack_bonus(item_name: String) -> int:
	return int(item(item_name).get("attack", 0))

static func hp_bonus(item_name: String) -> int:
	return int(item(item_name).get("hp", 0))

static func rarity(item_name: String) -> String:
	return str(item(item_name).get("rarity", "Common"))

static func summary(item_name: String) -> String:
	var data := item(item_name)
	if data.is_empty():
		return item_name

	var parts: Array[String] = [item_name, str(data.get("slot", "")).capitalize()]
	var attack := int(data.get("attack", 0))
	var hp := int(data.get("hp", 0))
	if attack > 0:
		parts.append("+%d ATK" % attack)
	if hp > 0:
		parts.append("+%d HP" % hp)
	return " · ".join(parts)
