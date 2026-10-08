extends RefCounted
const Catalog = preload("res://src/data/journal_catalog.gd")
var found: Dictionary = {}

func unlock(id: String, sim: Node, reward: bool = true) -> void:
	if found.has(id) or not Catalog.ENTRIES.has(id):
		return
	found[id] = true
	var entry: Dictionary = Catalog.ENTRIES[id]
	if reward and entry.has("gold"):
		sim.gold += int(entry["gold"])
		sim._emit_event("journal_discovery", "%s discovered. +%d gold." % [entry["title"], entry["gold"]], {"discovery": id, "gold": entry["gold"]})

func observe(event: Dictionary, sim: Node) -> void:
	match str(event["type"]):
		"arrived": unlock(str(event.get("destination", "")), sim)
		"world_discovery": unlock(str(event.get("gear", "")), sim)
		"enemy_defeated":
			var enemy := str(event.get("enemy", ""))
			unlock(enemy, sim)
			if enemy == "goblin" and sim.goblins_killed >= 3:
				unlock("campfire_mark", sim)
			if enemy == "wolf":
				unlock("moon_tracks", sim)
			if enemy == "briarling" and sim.briarlings_killed >= 4:
				unlock("amber_pool", sim)

func seed_legacy(sim: Node) -> void:
	var enemies := {"Goblin Trinket": "goblin", "Wolf Pelt": "wolf", "Briar Sap": "briarling", "Thornback Tusk": "thornback"}
	for loot in enemies:
		if int(sim.inventory.get(loot, 0)) > 0:
			unlock(enemies[loot], sim, false)
	for item in sim.discovered:
		unlock(str(item), sim, false)
	if sim.quest_cycles_completed > 0:
		for id in ["town", "goblin_camp", "wolf_den", "campfire_mark", "moon_tracks"]:
			unlock(id, sim, false)
	if sim.thornback_rank > 0:
		for id in ["briarfen", "thornback_lair", "thornback", "briarling", "amber_pool"]:
			unlock(id, sim, false)

func to_save_dict() -> Dictionary:
	return found.duplicate()

func load_save_dict(data: Dictionary) -> void:
	found.clear()
	for id in Catalog.ENTRIES:
		if data.get(id, false) == true:
			found[id] = true
