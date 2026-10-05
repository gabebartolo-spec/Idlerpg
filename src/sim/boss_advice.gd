class_name BossAdvice
extends RefCounted

# Explains the last fight with Old Thornback from what happened in it, and suggests what
# to change. Every suggestion is something play alone provides: a world item, a hunt, a
# talent point or another level. Nothing here ever points at a banner.
# Rules: docs/BOSS_AND_WORLD_ITEMS.md.

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const BossCatalogScript = preload("res://src/data/boss_catalog.gd")
const HuntCatalogScript = preload("res://src/data/hunt_catalog.gd")

# The burst counts as the problem when it did at least this share of the damage taken.
const BURST_SHARE := 0.30
# The fight counts as close when the boss had no more than this share of its health left.
const CLOSE_SHARE := 0.35

# Returns {"headline", "facts": [text], "suggestions": [{"text", "action", "target"}]}.
# Actions: "equip" (target = item), "hunt" (target = hunt id), "talents", or "" for
# advice with nothing to tap.
static func advise(sim: Node) -> Dictionary:
	var fight: Dictionary = sim.last_boss_fight
	var result := {"headline": "", "facts": [] as Array[String], "suggestions": [] as Array[Dictionary]}
	if fight.is_empty():
		result["headline"] = "%s has not been fought yet." % BossCatalogScript.NAME
		result["facts"].append("Every third attack is %s, three times as hard. It raises its thorns first." % BossCatalogScript.BURST_NAME)
		return result

	var rank := int(fight["rank"])
	var taken := int(fight["damage_taken"])
	var burst := int(fight["burst_damage"])
	var burst_share: float = float(burst) / float(taken) if taken > 0 else 0.0
	if int(fight["bursts"]) > 0:
		result["facts"].append("%s landed %d time%s for %d damage: %d%% of the damage you took." % [
			BossCatalogScript.BURST_NAME, int(fight["bursts"]), "" if int(fight["bursts"]) == 1 else "s", burst, int(round(burst_share * 100.0))])
	if int(fight["windup_damage"]) > 0:
		result["facts"].append("Striking during the wind-up added %d damage." % int(fight["windup_damage"]))

	if bool(fight.get("won", false)):
		result["headline"] = "Beat %s at rank %d." % [BossCatalogScript.NAME, rank]
		result["facts"].append("It has returned at rank %d." % sim.thornback_rank)
		return result

	var left := int(fight["boss_hp_left"])
	var left_share: float = float(left) / float(maxi(1, int(fight["boss_max_hp"])))
	result["headline"] = "%s drove you off at rank %d." % [BossCatalogScript.NAME, rank]
	result["facts"].append("It had %d of %d health left (%d%%)." % [left, int(fight["boss_max_hp"]), int(ceil(left_share * 100.0))])

	var suggestions: Array[Dictionary] = result["suggestions"]
	var points: int = sim.talent_points_available()
	if points > 0:
		suggestions.append({"text": "Spend %d talent point%s." % [points, "" if points == 1 else "s"], "action": "talents", "target": ""})
	if burst_share >= BURST_SHARE:
		_suggest_effect(sim, suggestions, "thornward")
	if left_share <= CLOSE_SHARE:
		_suggest_effect(sim, suggestions, "opportunist")
	_suggest_effect(sim, suggestions, "carapace")
	if burst_share < BURST_SHARE:
		_suggest_effect(sim, suggestions, "thornward")
	if left_share > CLOSE_SHARE:
		_suggest_effect(sim, suggestions, "opportunist")
	suggestions.append({
		"text": "Or keep questing. Your adventurer will try again at level %d, or as soon as their gear, talents or companion change." % (sim.hero_level + 1),
		"action": "", "target": ""})
	return result

# Adds the next step towards wearing the item with this effect, unless it is worn.
static func _suggest_effect(sim: Node, suggestions: Array[Dictionary], effect_id: String) -> void:
	if sim.has_gear_effect(effect_id):
		return
	var item_name: String = GearCatalogScript.item_with_effect(effect_id)
	var effect_text: String = GearCatalogScript.effect_text(item_name)
	if sim.gear_count(item_name) > 0:
		suggestions.append({"text": "Equip %s. %s" % [item_name, effect_text], "action": "equip", "target": item_name})
		return

	var hunt_id: String = HuntCatalogScript.hunt_for_item(item_name)
	if hunt_id.is_empty():
		suggestions.append({"text": "%s: %s %s" % [item_name, effect_text, GearCatalogScript.source_text(item_name)], "action": "", "target": ""})
		return
	var hunt: Dictionary = HuntCatalogScript.HUNTS[hunt_id]
	var progress := "%d of %d kills towards a certain drop" % [sim.hunt_kills(hunt_id), int(hunt["pity"])]
	if sim.hunt_target == hunt_id:
		suggestions.append({"text": "Keep hunting %s from %s (%s). %s" % [item_name, hunt["enemy_label"], progress, effect_text], "action": "", "target": ""})
	else:
		suggestions.append({"text": "Hunt %s from %s (%s). %s" % [item_name, hunt["enemy_label"], progress, effect_text], "action": "hunt", "target": hunt_id})
