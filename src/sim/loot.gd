class_name VbLoot
extends RefCounted

# Loot generation: drop rolls, rarity bands, item instancing.

const Rng = preload("res://src/sim/rng.gd")

const RARITY_NAMES := ["Worn", "Tempered", "Bellforged", "Requiem"]

const BASE_DROP_PERCENT := 26
const LUCK_DROP_PERCENT := 3
const LUCK_UPGRADE_PERCENT := 4
const MAX_UPGRADE_PERCENT := 20
const ELITE_BONUS_PERCENT := 30
const SALVAGE_SHARDS := {0: 0, 1: 1, 2: 3, 3: 6}


## Items available in a zone, grouped by rarity: {rarity: [def, ...]}
static func zone_pool(content, zone_id: String) -> Dictionary:
	var pool := {}
	for rarity in 4:
		pool[rarity] = []
	for item in content.all_items():
		if str(item.get("special", "")) == "first_strike":
			continue  # boss-only spoils
		if zone_id in item.get("zones", []):
			pool[int(item.get("rarity", 0))].append(item)
	return pool


## Roll one drop. Returns {} when nothing dropped.
## luck_eff is the Luck value after run effects (deep_luck, pilgrim, no_retreat...).
static func roll_drop(content, zone: Dictionary, luck_eff: int, rng, force: bool = false) -> Dictionary:
	var chance := BASE_DROP_PERCENT + luck_eff * LUCK_DROP_PERCENT
	if not force and not rng.roll(chance):
		return {}
	var pool := zone_pool(content, str(zone.get("id", "")))
	var rarity := _roll_rarity(zone, luck_eff, rng)
	var band: Array = pool.get(rarity, [])
	if band.is_empty():
		for fallback in [rarity - 1, rarity - 2, rarity + 1, rarity + 2]:
			band = pool.get(fallback, [])
			if not band.is_empty():
				break
	if band.is_empty():
		return {}
	var def: Dictionary = rng.pick(band)
	return instance(def)


## A fixed drop (boss spoils).
static func fixed_drop(content, item_id: String) -> Dictionary:
	var def: Dictionary = content.get_item(item_id)
	if def.is_empty():
		return {}
	return instance(def)


static func instance(def: Dictionary) -> Dictionary:
	return {"uid": "", "id": str(def.get("id", "")), "temper": 0}


static func _roll_rarity(zone: Dictionary, luck_eff: int, rng) -> int:
	var weights: Dictionary = zone.get("rarity_weights", {"0": 100})
	var total := 0
	for key in weights.keys():
		total += int(weights[key])
	var roll_value := rng.next_int(maxi(1, total))
	var rarity := 0
	var cursor := 0
	var keys := weights.keys()
	keys.sort()
	for key in keys:
		cursor += int(weights[key])
		if roll_value < cursor:
			rarity = int(key)
			break
	# Luck can upgrade a tier; deeper pockets of luck make Requiem reachable.
	var upgrade := mini(luck_eff * LUCK_UPGRADE_PERCENT, MAX_UPGRADE_PERCENT)
	if rng.roll(upgrade):
		rarity = mini(rarity + 1, 3)
	return rarity


static func salvage_shards(rarity: int, temper: int) -> int:
	return int(SALVAGE_SHARDS.get(clampi(rarity, 0, 3), 0)) + temper
