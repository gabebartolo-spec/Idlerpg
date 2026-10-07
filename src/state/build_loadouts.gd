extends RefCounted
const Gear = preload("res://src/data/gear_catalog.gd")
const Talents = preload("res://src/data/talent_catalog.gd")
const Companions = preload("res://src/data/companion_catalog.gd")
const COUNT := 3
var presets: Dictionary = {}

func save_current(index: int, name: String, sim: Node) -> bool:
	name = name.strip_edges().left(32)
	if index < 0 or index >= COUNT or name.is_empty():
		return false
	presets[str(index)] = {"name": name, "equipment": sim.equipped.duplicate(), "talents": sim.unlocked_talents.duplicate(), "companion": sim.active_companion}
	return true

func preview(index: int, sim: Node, game: Node, available: bool = false) -> Dictionary:
	var saved: Dictionary = presets.get(str(index), {})
	if saved.is_empty():
		return {"ok": false, "error": "Save a build in this slot first.", "missing": []}
	var missing: Array[String] = []
	var equipment := {}
	var wanted: Dictionary = saved.get("equipment", {})
	for slot in sim.equipped:
		var item := str(wanted.get(slot, ""))
		if not item.is_empty() and (not Gear.has_item(item) or Gear.slot(item) != slot):
			return {"ok": false, "error": "This preset contains invalid equipment.", "missing": []}
		if not item.is_empty() and sim.gear_count(item) <= 0:
			missing.append(item)
			item = sim.equipped_item(slot) if available else ""
			if sim.gear_count(item) <= 0:
				item = ""
		equipment[slot] = item
	var talents := {}
	var wanted_talents: Dictionary = saved.get("talents", {})
	for id in wanted_talents:
		if not bool(wanted_talents[id]):
			continue
		if not Talents.has_talent(str(id)):
			return {"ok": false, "error": "This preset contains an unknown talent.", "missing": missing}
		talents[str(id)] = true
	if talents.size() > sim.talent_points_total():
		return {"ok": false, "error": "Not enough talent points for this preset.", "missing": missing}
	for id in talents:
		var requirement := Talents.requirement(str(id))
		if not requirement.is_empty() and not talents.has(requirement):
			return {"ok": false, "error": "A talent prerequisite is missing.", "missing": missing}
	var companion := str(saved.get("companion", ""))
	if not companion.is_empty() and not Companions.has_companion(companion):
		return {"ok": false, "error": "This preset contains an unknown companion.", "missing": missing}
	if not companion.is_empty() and game.collection_count("companions", companion) <= 0:
		missing.append(companion)
		companion = sim.active_companion if available else ""
		if game.collection_count("companions", companion) <= 0:
			companion = ""
	return {"ok": available or missing.is_empty(), "error": "Missing pieces: " + ", ".join(missing) if not missing.is_empty() else "Ready. Applies equipment, talents and companion together.", "missing": missing, "equipment": equipment, "talents": talents, "companion": companion, "name": str(saved.get("name", "Build"))}

func apply(index: int, sim: Node, game: Node, available: bool = false) -> Dictionary:
	var plan := preview(index, sim, game, available)
	if not bool(plan["ok"]):
		return plan
	# No setters/signals until all ownership and point checks succeed. Preserve HP and
	# encounter proc budgets: switching builds cannot grant healing or another Last stand.
	sim.equipped = plan["equipment"].duplicate()
	sim.unlocked_talents = plan["talents"].duplicate()
	sim.active_companion = plan["companion"]
	sim.hero_hp = mini(sim.hero_hp, sim.effective_max_hp())
	sim._emit_event("loadout_applied", "Applied %s." % plan["name"])
	return plan

func to_save_dict() -> Dictionary:
	return presets.duplicate(true)

func load_save_dict(data: Dictionary) -> void:
	presets.clear()
	for index in COUNT:
		var value: Variant = data.get(str(index))
		if value is Dictionary:
			presets[str(index)] = value.duplicate(true)
