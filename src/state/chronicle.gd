extends RefCounted

# A bounded memory of real, one-time milestones. No rewards or combat decisions.
const LIMIT := 64

var events: Array[Dictionary] = []
var seen: Dictionary = {}
var sequence: int = 0

func remember(id: String, message: String, route: String, target: String, priority: int, level: int, quest: int) -> void:
	if seen.has(id):
		return
	seen[id] = true
	sequence += 1
	events.push_front({"id": id, "sequence": sequence, "message": message, "route": route,
		"target": target, "priority": priority, "level": level, "quest": quest})
	if events.size() > LIMIT:
		events.resize(LIMIT)

func highlights_since(mark: int) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for event in events:
		if int(event["sequence"]) > mark:
			choices.append(event.duplicate(true))
	choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["priority"] != b["priority"]:
			return a["priority"] > b["priority"]
		return a["sequence"] > b["sequence"])
	return choices.slice(0, 3)

func to_save_dict() -> Dictionary:
	return {"events": events.duplicate(true), "seen": seen.duplicate(true), "sequence": sequence}

func load_save_dict(data: Dictionary) -> void:
	events.clear()
	seen = (data.get("seen", {}) as Dictionary).duplicate(true)
	sequence = maxi(0, int(data.get("sequence", 0)))
	for raw in data.get("events", []):
		if raw is Dictionary and raw.has_all(["id", "sequence", "message", "route", "target", "priority", "level", "quest"]):
			var entry: Dictionary = raw.duplicate(true)
			for key in ["sequence", "priority", "level", "quest"]:
				entry[key] = int(entry[key])
			events.append(entry)
			seen[str(raw["id"])] = true
			sequence = maxi(sequence, int(raw["sequence"]))
			if events.size() == LIMIT:
				break
