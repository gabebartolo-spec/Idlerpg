extends RefCounted
const BUILDS := {
	"striker": {"name": "Striker", "hint": "Catch a keeper's opening", "equipment": {"weapon": "Mothglass Spear", "head": "Wolfskin Hood", "chest": "", "accessory": ""}, "talent": "thick_hide"},
	"guardian": {"name": "Guardian", "hint": "Weather repeated hits", "equipment": {"weapon": "Goblin Cleaver", "head": "Wolfskin Hood", "chest": "Mooncap Mantle", "accessory": ""}, "talent": ""},
	"lamplighter": {"name": "Lamplighter", "hint": "Turn aside thorn strikes", "equipment": {"weapon": "Goblin Cleaver", "head": "Wolfskin Hood", "chest": "", "accessory": "Lamplighter Seal"}, "talent": ""}
}
static func missing(id: String, sim: Node) -> Array[String]:
	var result: Array[String] = []
	if not BUILDS.has(id): return ["Unknown build"]
	for item in BUILDS[id]["equipment"].values():
		if not str(item).is_empty() and sim.gear_count(item) == 0: result.append(item)
	var talent: String = BUILDS[id]["talent"]
	if not talent.is_empty() and not sim.has_talent(talent) and not sim.can_unlock_talent(talent): result.append("One talent point")
	return result
static func apply(id: String, sim: Node) -> bool:
	if not missing(id, sim).is_empty(): return false
	var spec: Dictionary = BUILDS[id]
	# Ownership/points are checked before any changes or event-time checkpoint.
	for slot in spec["equipment"]: sim.equipped[slot] = spec["equipment"][slot]
	var talent: String = spec["talent"]
	if not talent.is_empty(): sim.unlocked_talents[talent] = true
	sim.hero_hp = mini(sim.hero_hp, sim.effective_max_hp())
	sim._emit_event("loadout_applied", "Equipped " + str(spec["name"]) + ".")
	return true
