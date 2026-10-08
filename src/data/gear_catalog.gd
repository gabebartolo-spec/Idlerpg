class_name GearCatalog
extends RefCounted

const ITEMS := {
	"Iron Sword": {"slot": "weapon", "attack": 2, "hp": 0, "rarity": "Common"},
	"Leather Hood": {"slot": "head", "attack": 0, "hp": 3, "rarity": "Common"},
	"Oak Buckler": {"slot": "offhand", "attack": 0, "hp": 5, "rarity": "Common"},
	"Rough Trousers": {"slot": "legs", "attack": 0, "hp": 3, "rarity": "Common"},
	"Hide Gloves": {"slot": "hands", "attack": 1, "hp": 1, "rarity": "Common"},
	"Trail Boots": {"slot": "feet", "attack": 0, "hp": 3, "rarity": "Common"},
	"Copper Ring": {"slot": "accessory", "attack": 1, "hp": 1, "rarity": "Common"},

	"Runed Longbow": {"slot": "weapon", "attack": 4, "hp": 0, "rarity": "Rare"},
	"Knight Mail": {"slot": "chest", "attack": 0, "hp": 9, "rarity": "Rare"},
	"Ember Staff": {"slot": "weapon", "attack": 5, "hp": 0, "rarity": "Rare"},
	"Steel Greaves": {"slot": "legs", "attack": 1, "hp": 7, "rarity": "Rare"},
	"Knight Gauntlets": {"slot": "hands", "attack": 2, "hp": 4, "rarity": "Rare"},
	"Ranger Boots": {"slot": "feet", "attack": 2, "hp": 4, "rarity": "Rare"},
	"Sapphire Charm": {"slot": "accessory", "attack": 2, "hp": 5, "rarity": "Rare"},

	"Moonsteel Blade": {"slot": "weapon", "attack": 7, "hp": 2, "rarity": "Epic"},
	"Wyrmhide Coat": {"slot": "chest", "attack": 1, "hp": 14, "rarity": "Epic"},
	"Stormcaller": {"slot": "weapon", "attack": 8, "hp": 0, "rarity": "Epic"},
	"Dragon Legguards": {"slot": "legs", "attack": 2, "hp": 11, "rarity": "Epic"},
	"Rune Grips": {"slot": "hands", "attack": 4, "hp": 5, "rarity": "Epic"},
	"Shadow Treads": {"slot": "feet", "attack": 3, "hp": 7, "rarity": "Epic"},
	"Phoenix Sigil": {"slot": "accessory", "attack": 4, "hp": 8, "rarity": "Epic"},

	"Crownblade": {"slot": "weapon", "attack": 12, "hp": 4, "rarity": "Legendary"},
	"Starforged Helm": {"slot": "head", "attack": 4, "hp": 14, "rarity": "Legendary"},
	"Titanheart Plate": {"slot": "chest", "attack": 3, "hp": 24, "rarity": "Legendary"},
	"Worldwalker Boots": {"slot": "feet", "attack": 5, "hp": 12, "rarity": "Legendary"},

	"Goblin Cleaver": {"slot": "weapon", "attack": 3, "hp": 0, "rarity": "Common"},
	"Wolfskin Hood": {"slot": "head", "attack": 1, "hp": 5, "rarity": "Common"},
	"Briarheart Charm": {"slot": "accessory", "attack": 2, "hp": 6, "rarity": "Rare", "effect": "thornward", "source": "boss"},

	# Hunted in the world (src/data/hunt_catalog.gd). Never on a banner.
	"Briarhook": {"slot": "weapon", "attack": 4, "hp": 0, "rarity": "Rare", "effect": "opportunist", "source": "hunt"},
	"Thornback Carapace": {"slot": "chest", "attack": 0, "hp": 10, "rarity": "Epic", "effect": "carapace", "source": "hunt"}
}

# What a world item does beyond its numbers. The rules are in the simulation; these are
# the words shown for them. See docs/BOSS_AND_WORLD_ITEMS.md.
const EFFECTS := {
	"thornward": {"name": "Thornward", "text": "Telegraphed blows deal half damage."},
	"opportunist": {"name": "Opportunist", "text": "Hits deal double damage while the enemy is winding up."},
	"carapace": {"name": "Hardened", "text": "Every hit taken deals 25% less damage."}
}

const SOURCES := {
	"boss": "Old Thornback drops one whenever you do not have it.",
	"hunt": "Hunted in the world. See Boss and hunts."
}

const SELL_VALUES := {
	"Common": 8,
	"Rare": 24,
	"Epic": 70,
	"Legendary": 220
}

const SALVAGE_TOKENS := {
	"Common": 1,
	"Rare": 2,
	"Epic": 5,
	"Legendary": 8
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

static func sell_value(item_name: String) -> int:
	return int(SELL_VALUES.get(rarity(item_name), 0))

static func effect(item_name: String) -> String:
	return str(item(item_name).get("effect", ""))

static func effect_text(item_name: String) -> String:
	var data: Dictionary = EFFECTS.get(effect(item_name), {})
	if data.is_empty():
		return ""
	return "%s: %s" % [data["name"], data["text"]]

static func source(item_name: String) -> String:
	return str(item(item_name).get("source", ""))

static func source_text(item_name: String) -> String:
	return str(SOURCES.get(source(item_name), ""))

# The item in `effect_id`'s name, for advice.
static func item_with_effect(effect_id: String) -> String:
	for item_name in ITEMS:
		if str(ITEMS[item_name].get("effect", "")) == effect_id:
			return item_name
	return ""

# Items the world gives back are worth no tokens, or losing and regaining one would be a
# token source.
static func salvage_tokens(item_name: String) -> int:
	if not source(item_name).is_empty():
		return 0
	return int(SALVAGE_TOKENS.get(rarity(item_name), 0))

static func comparison(item_name: String, equipped_name: String) -> String:
	if not has_item(item_name):
		return ""
	var attack_delta := attack_bonus(item_name) - attack_bonus(equipped_name)
	var hp_delta := hp_bonus(item_name) - hp_bonus(equipped_name)
	var parts: Array[String] = []
	if attack_delta != 0:
		parts.append("%s%d ATK" % ["+" if attack_delta > 0 else "", attack_delta])
	if hp_delta != 0:
		parts.append("%s%d HP" % ["+" if hp_delta > 0 else "", hp_delta])
	if parts.is_empty():
		return "Same combat stats"
	return " · ".join(parts)

static func summary(item_name: String) -> String:
	var data := item(item_name)
	if data.is_empty():
		return item_name

	var parts: Array[String] = [item_name, str(data.get("rarity", "Common")), str(data.get("slot", "")).capitalize()]
	var attack := int(data.get("attack", 0))
	var hp := int(data.get("hp", 0))
	if attack > 0:
		parts.append("+%d ATK" % attack)
	if hp > 0:
		parts.append("+%d HP" % hp)
	return " · ".join(parts)
