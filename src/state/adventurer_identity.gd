extends RefCounted
const PALETTES := {"amber": Color(0.82, 0.49, 0.16), "moss": Color(0.22, 0.49, 0.31), "slate": Color(0.25, 0.40, 0.67)}
const TITLES := {"scout": "Greenway Scout", "thornbreaker": "Thornbreaker", "moth_master": "Glasswing Guardian", "moon_master": "Moonwell Keeper", "lamp_master": "Keeper of the Lamps"}
var adventurer_name: String = "Adventurer"
var palette: String = "amber"
var title: String = ""

func rename(value: String) -> void:
	var clean := ""
	for i in value.length():
		if value.unicode_at(i) >= 32 and value.unicode_at(i) != 127:
			clean += value.substr(i, 1)
	clean = " ".join(clean.strip_edges().split(" ", false)).left(24)
	adventurer_name = clean if not clean.is_empty() else "Adventurer"

func set_palette(id: String) -> bool:
	if not PALETTES.has(id):
		return false
	palette = id
	return true

func earned_titles(sim: Node) -> Array[String]:
	var result: Array[String] = []
	if sim.quest_cycles_completed > 0:
		result.append("scout")
	if sim.thornback_rank > 0:
		result.append("thornbreaker")
	for id in ["moth_master", "moon_master", "lamp_master"]:
		if sim.goals.completed.has(id):
			result.append(id)
	return result

func choose_title(id: String, sim: Node) -> bool:
	if not id.is_empty() and id not in earned_titles(sim):
		return false
	title = id
	return true

func display_name() -> String:
	return adventurer_name + (" · " + str(TITLES[title]) if TITLES.has(title) else "")

func to_save_dict() -> Dictionary:
	return {"name": adventurer_name, "palette": palette, "title": title}

func load_save_dict(data: Dictionary, sim: Node) -> void:
	rename(str(data.get("name", "Adventurer")))
	palette = "amber"
	set_palette(str(data.get("palette", "amber")))
	title = ""
	choose_title(str(data.get("title", "")), sim)
