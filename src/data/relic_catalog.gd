extends RefCounted
# One slot, three effect families. Rarity does not replace every specialist niche.
const ITEMS := {
	"Copper Charm": {"hp": 8},
	"Old Coin": {"attack": 1},
	"Hunter's Knot": {"move": 1.20},
	"Lucky Fang": {"attack": 2},
	"Glass Idol": {"hp": 12},
	"Pilgrim Bell": {"move": 1.20},
	"Phoenix Ash": {"hp": 20},
	"Void Compass": {"move": 1.25},
	"Dragon Eye": {"attack": 3},
	"Worldstone Shard": {"attack": 4, "hp": 8}
}
const FREE_SOURCES := {"Hunter's Knot": "Opening errand reward", "Copper Charm": "First Old Thornback victory"}
static func valid(name: String) -> bool:
	return ITEMS.has(name)
static func attack(name: String) -> int:
	return int(ITEMS.get(name, {}).get("attack", 0))
static func hp(name: String) -> int:
	return int(ITEMS.get(name, {}).get("hp", 0))
static func move(name: String) -> float:
	return float(ITEMS.get(name, {}).get("move", 1.0))
static func description(name: String) -> String:
	var parts: Array[String] = []
	if attack(name) > 0:
		parts.append("+%d attack" % attack(name))
	if hp(name) > 0:
		parts.append("+%d maximum health" % hp(name))
	if move(name) > 1.0:
		parts.append("+%d%% travel speed" % int(round((move(name) - 1.0) * 100.0)))
	return ", ".join(parts) if not parts.is_empty() else "No relic equipped"
