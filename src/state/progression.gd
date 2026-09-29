extends RefCounted

# Belfry progression is separate from the expedition engine. Bonuses enter the
# frozen departure snapshot; claiming rewards never rewrites an ongoing run.

const UPGRADES := [
	{"id": "anvil", "name": "The Sexton's Anvil", "stat": "might",
		"text": "A truer edge, a steadier hand. +1 Might per rank.",
		"costs": [{"gold": 60, "shards": 0}, {"gold": 160, "shards": 2}, {"gold": 320, "shards": 5}]},
	{"id": "brazier", "name": "The Vigil Brazier", "stat": "ward",
		"text": "Warmth carried into the ash. +1 Ward per rank.",
		"costs": [{"gold": 60, "shards": 0}, {"gold": 160, "shards": 2}, {"gold": 320, "shards": 5}]},
	{"id": "candles", "name": "The Pilgrim's Candles", "stat": "luck",
		"text": "A light for things worth finding. +1 Luck per rank.",
		"costs": [{"gold": 120, "shards": 1}, {"gold": 300, "shards": 4}]}
]

const MILESTONES := [
	{"id": "first_road", "name": "The First Toll", "text": "Resolve your first expedition.",
		"metric": "runs", "target": 1, "gold": 30, "shards": 1},
	{"id": "ash_hunter", "name": "A Quieter Road", "text": "Slay 12 enemies across your expeditions.",
		"metric": "kills", "target": 12, "gold": 60, "shards": 2},
	{"id": "marsh_path", "name": "Cords Through the Reeds", "text": "Return safely from 4 tolls in the Marrowfields.",
		"metric": "clear", "zone": "marrowfields", "target": 4, "gold": 80, "shards": 2},
	{"id": "collector", "name": "Things Worth Keeping", "text": "Bring home 10 different items. Selling them is fine.",
		"metric": "discoveries", "target": 10, "gold": 100, "shards": 3},
	{"id": "deep_path", "name": "The Drowned Choir", "text": "Return safely from 4 tolls in the Chime Deep.",
		"metric": "clear", "zone": "chime_deep", "target": 4, "gold": 140, "shards": 4},
	{"id": "gravecho", "name": "The Last Word", "text": "Slay the Gravecho and return safely.",
		"metric": "bosses", "target": 1, "gold": 240, "shards": 6},
	{"id": "wastes_path", "name": "Lights Along the Edge", "text": "Return safely from 4 tolls in the Lantern Wastes.",
		"metric": "clear", "zone": "lantern_wastes", "target": 4, "gold": 200, "shards": 5},
	{"id": "last_light", "name": "A Light of Your Own", "text": "Slay the Lantern-Eater and return safely.",
		"metric": "boss_victory", "boss": "lantern_eater", "target": 1, "gold": 320, "shards": 8}
]


static func fresh() -> Dictionary:
	return {"upgrades": {}, "claimed": [], "discoveries": [], "cleared_depths": {}, "bosses": 0, "boss_victories": {}}


static func upgrade(id: String) -> Dictionary:
	for def in UPGRADES:
		if str(def["id"]) == id:
			return def
	return {}


static func milestone(id: String) -> Dictionary:
	for def in MILESTONES:
		if str(def["id"]) == id:
			return def
	return {}


static func _number(value) -> int:
	return maxi(0, int(value)) if value is int or value is float else 0


static func normalize(saved, item_defs: Dictionary) -> Dictionary:
	var out := fresh()
	if not saved is Dictionary:
		return out
	var ranks = saved.get("upgrades", {})
	if ranks is Dictionary:
		for def in UPGRADES:
			out["upgrades"][def["id"]] = mini(_number(ranks.get(def["id"], 0)), def["costs"].size())
	var claimed = saved.get("claimed", [])
	if claimed is Array:
		for id in claimed:
			if id is String and not milestone(id).is_empty() and not id in out["claimed"]:
				out["claimed"].append(id)
	var discoveries = saved.get("discoveries", [])
	if discoveries is Array:
		for id in discoveries:
			if id is String and item_defs.has(id) and not id in out["discoveries"]:
				out["discoveries"].append(id)
	var depths = saved.get("cleared_depths", {})
	if depths is Dictionary:
		for id in ["marrowfields", "chime_deep", "requiem_scar", "lantern_wastes"]:
			out["cleared_depths"][id] = mini(6, _number(depths.get(id, 0)))
	out["bosses"] = _number(saved.get("bosses", 0))
	var victories = saved.get("boss_victories", {})
	if victories is Dictionary:
		for id in ["gravecho", "lantern_eater"]:
			out["boss_victories"][id] = _number(victories.get(id, 0))
	# Before the Wastes, all safe boss victories were against the Gravecho.
	out["boss_victories"]["gravecho"] = maxi(out["bosses"], int(out["boss_victories"].get("gravecho", 0)))
	return out


static func bonuses(belfry: Dictionary) -> Dictionary:
	var result := {"might": 0, "ward": 0, "luck": 0}
	for def in UPGRADES:
		result[def["stat"]] += int(belfry["upgrades"].get(def["id"], 0))
	return result


static func apply_bonuses(stats: Dictionary, belfry: Dictionary) -> Dictionary:
	var result := stats.duplicate(true)
	var extra := bonuses(belfry)
	for stat in extra:
		result[stat] = int(result.get(stat, 0)) + int(extra[stat])
	return result


static func progress(def: Dictionary, belfry: Dictionary, lifetime: Dictionary) -> int:
	match str(def["metric"]):
		"runs", "kills":
			return int(lifetime.get(def["metric"], 0))
		"clear":
			return int(belfry["cleared_depths"].get(def["zone"], 0))
		"discoveries":
			return belfry["discoveries"].size()
		"boss_victory":
			return int(belfry["boss_victories"].get(def["boss"], 0))
		"bosses":
			return int(belfry["bosses"])
	return 0
