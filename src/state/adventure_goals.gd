extends RefCounted

const IDS := ["prepare", "boss", "world_collection", "lantern_kit", "moth_master", "moon_master", "lamp_master"]
const REWARD_GOLD := 25
var tracked: String = "prepare"
var completed: Dictionary = {}

func cards(sim: Node) -> Array[Dictionary]:
	var prepared: bool = not sim.equipped_item("weapon").is_empty()
	var found := 0
	for item in ["Briarheart Charm", "Briarhook", "Thornback Carapace"]:
		if sim.has_discovered(item):
			found += 1
	var result: Array[Dictionary] = [
		{"id": "prepare", "title": "Prepare your adventurer", "progress": 1 if prepared else 0, "required": 1, "route": "gear", "clue": "Equip a weapon. The first errand guarantees a Goblin Cleaver."},
		{"id": "boss", "title": "Defeat Old Thornback", "progress": mini(1, sim.thornback_rank), "required": 1, "route": "boss", "clue": "Finish the opening errand, then prepare for the first Briarfen boss."},
		{"id": "world_collection", "title": "Three Briarfen keepsakes", "progress": found, "required": 3, "route": "boss", "clue": "Discover Briarheart Charm, Briarhook and Thornback Carapace. Boss and hunts explains their guaranteed routes."}
	]
	if sim.expedition.claimed_routes.has("hollow"):
		var earned := 0
		for item in ["Mothglass Spear", "Mooncap Mantle", "Lamplighter Seal"]:
			if sim.has_discovered(item):
				earned += 1
		result.append({"id": "lantern_kit", "title": "Lanternwood keepsakes", "progress": earned, "required": 3, "route": "expedition", "clue": "Open the guaranteed gear chests from Mothwatch, Moonwell and the Lamplighter's Circuit."})
		for entry in [["moth_master", "mothwatch", "Glasswing guardian"], ["moon_master", "moonwell", "Moonwell keeper"], ["lamp_master", "lamplighter", "Keeper of the lamps"]]:
			result.append({"id": entry[0], "title": entry[2], "progress": mini(3, int(sim.expedition.route_clears.get(entry[1], 0))), "required": 3, "route": "expedition", "clue": "Return safely three times from " + str(sim.expedition.Catalog.ROUTES[entry[1]]["name"]) + ". Earn a permanent profile title. No daily attendance or consecutive days required."})
	return result

func track(id: String) -> bool:
	if not id in IDS:
		return false
	tracked = id
	return true

func update(sim: Node, grant: bool = true) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for card in cards(sim):
		var id := str(card["id"])
		if completed.has(id) or int(card["progress"]) < int(card["required"]):
			continue
		completed[id] = true
		if grant:
			sim.gold += REWARD_GOLD
			events.append({"goal": id, "title": card["title"], "route": card["route"], "gold": REWARD_GOLD})
	return events

func to_save_dict() -> Dictionary:
	return {"tracked": tracked, "completed": completed.duplicate()}

func load_save_dict(data: Dictionary) -> void:
	tracked = "prepare"
	track(str(data.get("tracked", "prepare")))
	completed.clear()
	var saved: Dictionary = data.get("completed", {})
	for id in IDS:
		if bool(saved.get(id, false)):
			completed[id] = true
