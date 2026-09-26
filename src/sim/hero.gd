class_name VbHero
extends RefCounted

# Hero math: levels, stats, grit, vows. All static and pure.

const MAX_LEVEL := 8

# Cumulative XP needed to REACH each level (index = level).
const XP_THRESHOLDS := {1: 0, 2: 45, 3: 110, 4: 210, 5: 350, 6: 540, 7: 780, 8: 1100}

const VOWS := {
	"wrath": {
		"name": "Vow of Wrath",
		"text": "Every third fight of an expedition, they strike with terrible certainty (+3 Might)."
	},
	"shelter": {
		"name": "Vow of Shelter",
		"text": "Between tolls they bind their wounds and recover 1 Grit."
	},
	"silence": {
		"name": "Vow of Silence",
		"text": "They walk out already listening: every expedition begins with 3 Echo."
	},
	"pilgrim": {
		"name": "Vow of the Pilgrim",
		"text": "Past the second toll, Luck runs +2. The deep pays for patience."
	}
}

const VOW_CHOICES := {3: ["wrath", "shelter"], 6: ["silence", "pilgrim"]}


static func xp_for_level(level: int) -> int:
	return int(XP_THRESHOLDS.get(clampi(level, 1, MAX_LEVEL), 0))


static func level_for_xp(xp: int) -> int:
	var level := 1
	for candidate in range(1, MAX_LEVEL + 1):
		if xp >= int(XP_THRESHOLDS[candidate]):
			level = candidate
	return level


static func xp_to_next(xp: int, level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return maxi(0, xp_for_level(level + 1) - xp)


## Base stats from level alone (before gear and tempering).
static func base_stats(level: int) -> Dictionary:
	return {
		"might": 3 + int(floor(float(level) / 2.0)),
		"ward": 3 + int(floor(float(level - 1) / 2.0)),
		"luck": 1 + (1 if level >= 4 else 0) + (1 if level >= 7 else 0)
	}


## Highest base stat of an item, for tempering.
static func temper_stat(item: Dictionary) -> String:
	var best := "might"
	var best_val := -1
	for stat in ["might", "ward", "luck"]:
		var v := int(item.get(stat, 0))
		if v > best_val:
			best_val = v
			best = stat
	return best


## Total stats from level + equipment (instances carry their own temper level).
## equipment: {slot: merged item def with "temper"}
static func total_stats(level: int, equipment: Dictionary) -> Dictionary:
	var stats := base_stats(level)
	for slot in ["weapon", "armor", "charm"]:
		var item: Dictionary = equipment.get(slot, {})
		if item.is_empty():
			continue
		for stat in ["might", "ward", "luck"]:
			stats[stat] = int(stats[stat]) + int(item.get(stat, 0))
		var temper := int(item.get("temper", 0))
		if temper > 0:
			var boost_stat := temper_stat(item)
			stats[boost_stat] = int(stats[boost_stat]) + temper
	return stats


static func grit_max(ward: int) -> int:
	return 2 + int(floor(float(ward) / 5.0))


## The frozen build an expedition resolves against.
static func make_snapshot(state: Dictionary, item_defs: Dictionary, content) -> Dictionary:
	var hero: Dictionary = state.get("adventurer", {})
	var level := int(hero.get("level", 1))
	var equipment := resolve_equipment(hero, item_defs)
	var stats := total_stats(level, equipment)
	var vows: Array = []
	for v in hero.get("vows", []):
		vows.append(str(v))
	var specials := {}
	for slot in ["weapon", "armor", "charm"]:
		var item: Dictionary = equipment.get(slot, {})
		var sp := str(item.get("special", ""))
		if sp != "":
			specials[sp] = true
	return {
		"name": str(hero.get("name", "The Bellbound")),
		"level": level,
		"vows": vows,
		"specials": specials,
		"might": int(stats["might"]),
		"ward": int(stats["ward"]),
		"luck": int(stats["luck"]),
		"grit_max": grit_max(int(stats["ward"])),
		"weapon_name": str(equipment.get("weapon", {}).get("name", "bare hands")),
		"armor_name": str(equipment.get("armor", {}).get("name", "a thick coat"))
	}


## Merge equipped item uids with their definitions.
static func _resolve_equipment(hero: Dictionary, item_defs: Dictionary) -> Dictionary:
	var out := {}
	var equipped: Dictionary = hero.get("equipment", {})
	for slot in equipped.keys():
		var inst: Dictionary = equipped[slot]
		if inst is Dictionary and not inst.is_empty():
			var def: Dictionary = item_defs.get(str(inst.get("id", "")), {})
			if not def.is_empty():
				var merged := def.duplicate(true)
				merged["uid"] = inst.get("uid", "")
				out[slot] = merged
	return out
