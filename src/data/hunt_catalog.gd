class_name HuntCatalog
extends RefCounted

# World items the adventurer can be set to hunt. One hunt is active at a time. Each kill
# of the hunt's enemy is one roll, and the drop is certain by the `pity` kill, so bad
# luck is bounded. Hunts are earned by play only and are separate from every banner.
# Rules: docs/BOSS_AND_WORLD_ITEMS.md.

const HUNTS := {
	"briarhook": {
		"item": "Briarhook",
		"enemy": "briarling",
		"enemy_label": "Briarlings in Briarfen",
		"chance": 0.03,
		"pity": 80,
		"salt": 1
	},
	"carapace": {
		"item": "Thornback Carapace",
		"enemy": "thornback",
		"enemy_label": "Old Thornback",
		"chance": 0.10,
		"pity": 20,
		"salt": 2
	}
}

const DEFAULT_HUNT := "briarhook"
# Paid once per item, the first time it is ever found.
const FIRST_DISCOVERY_GOLD := 200

static func hunt_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in HUNTS:
		ids.append(str(id))
	return ids

static func has_hunt(hunt_id: String) -> bool:
	return HUNTS.has(hunt_id)

static func hunt(hunt_id: String) -> Dictionary:
	return (HUNTS.get(hunt_id, {}) as Dictionary).duplicate(true)

static func hunt_for_item(item_name: String) -> String:
	for id in HUNTS:
		if str(HUNTS[id]["item"]) == item_name:
			return str(id)
	return ""

# A repeatable number from 0 up to 1 for roll `index` of a hunt. The same seed, hunt and
# index always give the same number, so a save cannot be reloaded for a better roll and
# watched and offline play agree.
static func roll(seed: int, salt: int, index: int) -> float:
	var x: int = (seed * 0x9E3779B1 + salt * 0x85EBCA6B + index * 0xC2B2AE35) & 0xFFFFFFFF
	x ^= x >> 16
	x = (x * 0x7FEB352D) & 0xFFFFFFFF
	x ^= x >> 15
	x = (x * 0x846CA68B) & 0xFFFFFFFF
	x ^= x >> 16
	return float(x) / 4294967296.0
