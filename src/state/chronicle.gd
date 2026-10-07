extends RefCounted

# Milestones only: quiet repeated quest cycles produce no entries. Stable keys keep
# firsts remembered even after their visible entries have left the bounded journal.
const LIMIT := 128
var entries: Array[Dictionary] = []
var seen: Dictionary = {}
var sequence: int = 0

func remember(key: String) -> void:
	seen[key] = true

func record(key: String, message: String, route: String, priority: int) -> void:
	if seen.has(key):
		return
	remember(key)
	sequence += 1
	entries.append({"id": sequence, "key": key, "message": message, "route": route, "priority": priority})
	if entries.size() > LIMIT:
		entries.pop_front()

func observe(event: Dictionary) -> void:
	var kind := str(event.get("type", ""))
	match kind:
		"relic_obtained":
			record("relic:" + str(event["relic"]), str(event["message"]), "relics", 75)
		"goal_completed":
			record("goal:" + str(event["goal"]), str(event["message"]), str(event["route"]), 85)
		"enemy_defeated":
			var enemy := str(event.get("enemy", ""))
			if enemy == "thornback":
				return # The boss victory already tells this story.
			record("kill:" + enemy, "First victory: " + str(event["message"]), "", 40)
		"boss_defeated":
			record("boss:first", "First boss victory! " + str(event["message"]), "boss", 100)
		"gear_obtained":
			if bool(event.get("useful", false)):
				record("gear:" + str(event["gear"]), "A build option: " + str(event["message"]), "gear", 80)
		"companion_bond_up":
			record("bond:%s:%d" % [event["companion"], event["bond_level"]], str(event["message"]), "companions", 70)
		"boss_lost":
			if bool(event.get("close", false)):
				record("close:thornback", "Nearly won: " + str(event["message"]) + " Review your boss preparation.", "boss", 90)

func highlights_since(cursor: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for entry in entries:
		if int(entry["id"]) > cursor:
			choices.append(entry.duplicate(true))
	choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["priority"]) != int(b["priority"]):
			return int(a["priority"]) > int(b["priority"])
		return int(a["id"]) > int(b["id"]))
	# Three different kinds, so many levels or items cannot crowd out the story.
	var result: Array[Dictionary] = []
	var kinds := {}
	for entry in choices:
		var kind := str(entry["key"]).get_slice(":", 0)
		if kinds.has(kind):
			continue
		kinds[kind] = true
		result.append(entry)
		if result.size() == 3:
			break
	return result

func to_save_dict() -> Dictionary:
	return {"sequence": sequence, "entries": entries.duplicate(true), "seen": seen.duplicate(true)}

func load_save_dict(data: Dictionary) -> void:
	sequence = maxi(0, int(data.get("sequence", 0)))
	seen = (data.get("seen", {}) as Dictionary).duplicate(true)
	entries.clear()
	for raw in data.get("entries", []):
		if not (raw is Dictionary) or not raw.has_all(["id", "key", "message", "route", "priority"]):
			continue
		var id := int(raw["id"])
		if id <= 0 or (not entries.is_empty() and id <= int(entries.back()["id"])):
			continue
		entries.append({"id": id, "key": str(raw["key"]), "message": str(raw["message"]), "route": str(raw["route"]), "priority": int(raw["priority"])})
		sequence = maxi(sequence, id)
		remember(str(raw["key"]))
	while entries.size() > LIMIT:
		entries.pop_front()
