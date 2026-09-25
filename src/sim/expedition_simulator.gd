class_name BrambleExpeditionSimulator
extends RefCounted

const SeededRng = preload("res://src/sim/seeded_rng.gd")

const XP_THRESHOLDS := {1: 0, 2: 100, 3: 250, 4: 450, 5: 700}
const MAX_LEVEL := 5


func create_new_adventurer(adventurer_name: String = "") -> Dictionary:
	return {
		"name": adventurer_name,
		"level": 1,
		"xp": 0,
		"gold": 0,
		"equipment":
		{"weapon": "training_blade", "armor": "patched_coat", "trinket": "traveler_token"},
		"inventory": []
	}


func level_for_xp(xp: int) -> int:
	var level := 1
	for candidate in range(1, MAX_LEVEL + 1):
		if xp >= int(XP_THRESHOLDS[candidate]):
			level = candidate
	return level


func xp_to_next_level(xp: int, level: int) -> int:
	if level >= MAX_LEVEL:
		return 0
	return max(0, int(XP_THRESHOLDS[level + 1]) - xp)


func calculate_stats(adventurer: Dictionary, content) -> Dictionary:
	return calculate_snapshot_stats(
		int(adventurer.get("level", 1)), adventurer.get("equipment", {}), content
	)


func calculate_snapshot_stats(level: int, equipment: Dictionary, content) -> Dictionary:
	var stats := {
		"strike": 2 + max(0, level - 1),
		"guard": 2 + max(0, level - 1),
		"fortune": max(0, level - 1)
	}
	for slot in ["weapon", "armor", "trinket"]:
		var item_id := str(equipment.get(slot, ""))
		var item: Dictionary = content.get_item(item_id)
		var item_stats: Dictionary = item.get("stats", {})
		for stat_name in ["strike", "guard", "fortune"]:
			stats[stat_name] = int(stats[stat_name]) + int(item_stats.get(stat_name, 0))
	return stats


func create_expedition(
	adventurer: Dictionary, route_id: String, started_at: int, seed: int, content
) -> Dictionary:
	var route: Dictionary = content.get_route(route_id)
	var snapshot_equipment: Dictionary = adventurer.get("equipment", {}).duplicate(true)
	var duration := int(route.get("duration_seconds", 0))
	return {
		"route_id": route_id,
		"started_at": started_at,
		"seed": seed,
		"status": "away",
		"planned_duration": duration,
		"snapshot":
		{
			"name": str(adventurer.get("name", "Adventurer")),
			"level": int(adventurer.get("level", 1)),
			"xp": int(adventurer.get("xp", 0)),
			"equipment": snapshot_equipment,
			"stats":
			calculate_snapshot_stats(int(adventurer.get("level", 1)), snapshot_equipment, content)
		}
	}


func resolve_expedition(active: Dictionary, now: int, content) -> Dictionary:
	var route: Dictionary = content.get_route(str(active.get("route_id", "")))
	if route.is_empty():
		return {"ready": true, "report": _empty_report(active, "The route could not be found.")}

	var started_at := int(active.get("started_at", now))
	var elapsed: int = maxi(0, now - started_at)
	var route_duration := int(route.get("duration_seconds", 0))
	var resolved_elapsed: int = mini(elapsed, route_duration)
	var snapshot: Dictionary = active.get("snapshot", {})
	var adventurer_name := str(snapshot.get("name", "Adventurer"))
	var rng := SeededRng.new(int(active.get("seed", 1)))
	var report := {
		"route_id": str(active.get("route_id", "")),
		"route_name": str(route.get("name", "Unknown route")),
		"zone": str(route.get("zone", "Bramblewild")),
		"elapsed_seconds": elapsed,
		"outcome": "in_progress",
		"headline": "",
		"summary": "",
		"events": [],
		"xp_gained": 0,
		"gold_gained": 0,
		"items": [],
		"encounters_won": 0,
		"danger_moments": 0,
		"level_ups": [],
		"starting_level": int(snapshot.get("level", 1)),
		"new_level": int(snapshot.get("level", 1)),
		"starting_stats": snapshot.get("stats", {}).duplicate(true),
		"ending_stats": {}
	}

	report.events.append(
		{
			"kind": "departure",
			"tone": "neutral",
			"text": "%s set out for %s." % [adventurer_name, str(route.get("name", "the road"))],
			"evidence": "The chosen route set the expedition's risk and reward profile.",
			"importance": "major"
		}
	)

	var stage_cursor := 0
	var failed := false
	var failure_text := ""
	for stage in route.get("stages", []):
		var stage_duration := int(stage.get("duration", 0))
		var stage_end := stage_cursor + stage_duration
		if resolved_elapsed < stage_end:
			break
		stage_cursor = stage_end
		var stage_result: Dictionary = _resolve_stage(
			stage, route, snapshot, adventurer_name, rng, content
		)
		var event: Dictionary = stage_result.get("event", {})
		if not event.is_empty():
			report.events.append(event)
		report.xp_gained = int(report.xp_gained) + int(stage_result.get("xp", 0))
		report.gold_gained = int(report.gold_gained) + int(stage_result.get("gold", 0))
		report.encounters_won = (
			int(report.encounters_won) + int(stage_result.get("encounters_won", 0))
		)
		report.danger_moments = (
			int(report.danger_moments) + int(stage_result.get("danger_moments", 0))
		)
		if stage_result.has("item"):
			report.items.append(stage_result["item"])
		if bool(stage_result.get("failed", false)):
			failed = true
			failure_text = str(
				stage_result.get("failure_text", event.get("text", "The expedition ended early."))
			)
			break

	var expedition_complete := not failed and stage_cursor >= route_duration
	if not expedition_complete and not failed:
		var remaining: int = maxi(0, route_duration - resolved_elapsed)
		return {
			"ready": false,
			"remaining_seconds": remaining,
			"progress_seconds": resolved_elapsed,
			"report": report
		}

	report.outcome = "retreated" if failed else "complete"
	var starting_xp := int(snapshot.get("xp", 0))
	var resulting_xp := starting_xp + int(report.xp_gained)
	report.new_level = level_for_xp(resulting_xp)
	for level in range(int(report.starting_level) + 1, int(report.new_level) + 1):
		report.level_ups.append(level)
	report.ending_stats = calculate_snapshot_stats(
		int(report.new_level), snapshot.get("equipment", {}), content
	)

	if failed:
		report.events.append(
			{
				"kind": "retreat",
				"tone": "danger",
				"text":
				(
					"%s returned from %s before the final objective was complete."
					% [adventurer_name, str(route.get("name", "the route"))]
				),
				"evidence": failure_text,
				"importance": "major"
			}
		)
	else:
		report.events.append(
			{
				"kind": "return",
				"tone": "good",
				"text": "%s completed the objective and found the road home." % adventurer_name,
				"evidence": "Every planned stage resolved successfully.",
				"importance": "major"
			}
		)

	report.headline = _build_headline(report, adventurer_name, route, content)
	report.summary = _build_summary(report, adventurer_name, route, content)
	return {
		"ready": true, "remaining_seconds": 0, "progress_seconds": route_duration, "report": report
	}


func preview_route(adventurer: Dictionary, route_id: String, content) -> Dictionary:
	var route: Dictionary = content.get_route(route_id)
	var stats: Dictionary = calculate_stats(adventurer, content)
	var highest_threat := 0
	for stage in route.get("stages", []):
		if str(stage.get("type", "")) == "combat":
			var enemy: Dictionary = content.get_enemy(str(stage.get("enemy_id", "")))
			highest_threat = max(highest_threat, int(enemy.get("threat", 0)))
	var fit := ""
	if int(route.get("danger_value", 1)) >= 6:
		fit = "Guard helps survive the Thornback; Strike can shorten the danger window."
	elif int(route.get("danger_value", 1)) >= 3:
		fit = "A balanced build has room to shine here."
	else:
		fit = "Fortune is useful when survival is already comfortable."
	return {
		"duration_seconds": int(route.get("duration_seconds", 0)),
		"highest_threat": highest_threat,
		"stats": stats,
		"fit": fit
	}


func _resolve_stage(
	stage: Dictionary,
	route: Dictionary,
	snapshot: Dictionary,
	adventurer_name: String,
	rng,
	content
) -> Dictionary:
	var stage_type := str(stage.get("type", ""))
	match stage_type:
		"travel":
			return {
				"event":
				{
					"kind": "travel",
					"tone": "neutral",
					"text":
					_format_text(str(stage.get("text", "%s travelled onward.")), adventurer_name),
					"evidence": "The route advanced to its next stage.",
					"importance": "major"
				}
			}
		"combat":
			return _resolve_combat(stage, route, snapshot, adventurer_name, rng, content)
		"discovery":
			return _resolve_discovery(stage, route, snapshot, adventurer_name, rng, content)
		"objective":
			var xp := int(stage.get("xp", 0))
			var gold := int(stage.get("gold", 0))
			return {
				"xp": xp,
				"gold": gold,
				"event":
				{
					"kind": "objective",
					"tone": "good",
					"text":
					_format_text(
						str(stage.get("text", "%s completed the objective.")), adventurer_name
					),
					"evidence": "The route objective awarded %d XP and %d gold." % [xp, gold],
					"importance": "major"
				}
			}
	return {}


func _resolve_combat(
	stage: Dictionary,
	route: Dictionary,
	snapshot: Dictionary,
	adventurer_name: String,
	rng,
	content
) -> Dictionary:
	var enemy: Dictionary = content.get_enemy(str(stage.get("enemy_id", "")))
	var enemy_name := str(enemy.get("name", "unknown enemy"))
	var threat := int(enemy.get("threat", 1))
	var danger := int(route.get("danger_value", 1))
	var stats: Dictionary = snapshot.get("stats", {})
	var strike := int(stats.get("strike", 0))
	var guard := int(stats.get("guard", 0))
	var attack_chance := clampi(86 + (strike - threat) * 7 - danger * 2, 25, 97)
	var survival_chance := clampi(90 + (guard - threat) * 7 - danger * 2, 20, 98)
	var attack_roll: int = rng.next_percent()
	var survival_roll: int = rng.next_percent()
	var attack_ok: bool = attack_roll < attack_chance
	var survival_ok: bool = survival_roll < survival_chance
	var weapon: Dictionary = content.get_item(str(snapshot.get("equipment", {}).get("weapon", "")))
	var armor: Dictionary = content.get_item(str(snapshot.get("equipment", {}).get("armor", "")))
	var weapon_name := str(weapon.get("name", "weapon"))
	var armor_name := str(armor.get("name", "armor"))
	var level := int(snapshot.get("level", 1))
	var base_strike: int = 2 + maxi(0, level - 1)
	var base_guard: int = 2 + maxi(0, level - 1)
	var gear_strike: int = strike - base_strike
	var gear_guard: int = guard - base_guard
	var xp := int(enemy.get("xp", 0))
	var gold := int(enemy.get("gold", 0))

	var evidence := (
		"Strike chance %d%% (roll %d); Guard chance %d%% (roll %d). "
		% [attack_chance, attack_roll, survival_chance, survival_roll]
	)
	evidence += "Equipped gear contributed +%d Strike and +%d Guard." % [gear_strike, gear_guard]
	if attack_ok:
		var text := (
			"%s used the %s to break through the %s." % [adventurer_name, weapon_name, enemy_name]
		)
		var tone := "good"
		var danger_moments := 0
		if survival_ok:
			text += " The fight was over before it could become a serious threat."
		else:
			text += " The %s absorbed a dangerous blow; it was a close call." % armor_name
			tone = "danger"
			danger_moments = 1
		return {
			"xp": xp,
			"gold": gold,
			"encounters_won": 1,
			"danger_moments": danger_moments,
			"event":
			{
				"kind": "combat",
				"tone": tone,
				"text": text,
				"evidence": evidence,
				"importance": "major"
			}
		}

	if survival_ok:
		return {
			"danger_moments": 1,
			"failed": true,
			"failure_text":
			(
				"%s could not find a way through the %s, but the %s gave %s enough protection to retreat."
				% [adventurer_name, enemy_name, armor_name, adventurer_name]
			),
			"event":
			{
				"kind": "combat",
				"tone": "danger",
				"text":
				(
					"%s held off the %s, but could not overcome it and chose to retreat."
					% [adventurer_name, enemy_name]
				),
				"evidence": evidence + " Guard turned the failed attack into a survivable retreat.",
				"importance": "major"
			}
		}

	return {
		"danger_moments": 1,
		"failed": true,
		"failure_text":
		"%s overwhelmed %s before there was a safe opening." % [enemy_name, adventurer_name],
		"event":
		{
			"kind": "combat",
			"tone": "danger",
			"text":
			"The %s overwhelmed %s, forcing an early retreat." % [enemy_name, adventurer_name],
			"evidence": evidence + " Neither the attack nor the survival check succeeded.",
			"importance": "major"
		}
	}


func _resolve_discovery(
	stage: Dictionary,
	route: Dictionary,
	snapshot: Dictionary,
	adventurer_name: String,
	rng,
	content
) -> Dictionary:
	var stats: Dictionary = snapshot.get("stats", {})
	var fortune := int(stats.get("fortune", 0))
	var base_chance := int(stage.get("drop_chance", 0))
	var chance := clampi(base_chance + fortune * 3, 0, 100)
	var roll: int = rng.next_percent()
	var gold := int(stage.get("gold", 0))
	var evidence := (
		"Discovery chance %d%% (roll %d); Fortune contributed %d points."
		% [chance, roll, fortune * 3]
	)
	if roll >= chance:
		return {
			"gold": gold,
			"event":
			{
				"kind": "discovery",
				"tone": "neutral",
				"text":
				(
					"%s found a hidden hollow, but its best treasure was already gone."
					% adventurer_name
				),
				"evidence": evidence,
				"importance": "major"
			}
		}

	var table: Array = stage.get("loot_table", [])
	var selected_id := _choose_loot(table, fortune, rng, content)
	var item: Dictionary = content.get_item(selected_id)
	if item.is_empty():
		return {"gold": gold}
	var item_entry := {
		"item_id": selected_id,
		"source": "%s discovery" % str(route.get("name", "route")),
		"rarity": str(item.get("rarity", "Common"))
	}
	var text := (
		"%s searched the hollow and found a %s: %s."
		% [adventurer_name, str(item.get("rarity", "Common")), str(item.get("name", "new item"))]
	)
	if fortune > 1:
		text += " The adventurer's Fortune helped spot the useful find."
	return {
		"gold": gold,
		"item": item_entry,
		"event":
		{
			"kind": "discovery",
			"tone": "loot",
			"text": text,
			"evidence":
			evidence + " The weighted loot table selected %s." % str(item.get("name", "the item")),
			"importance": "major"
		}
	}


func _choose_loot(table: Array, fortune: int, rng, content) -> String:
	var total_weight := 0
	for entry in table:
		var item: Dictionary = content.get_item(str(entry.get("item_id", "")))
		var weight := int(entry.get("weight", 0))
		var rarity := str(item.get("rarity", "Common"))
		if rarity == "Uncommon":
			weight += fortune
		elif rarity == "Rare":
			weight += fortune * 2
		total_weight += max(0, weight)
	if total_weight <= 0:
		return ""
	var roll: int = rng.next_int(total_weight)
	var cursor := 0
	for entry in table:
		var item: Dictionary = content.get_item(str(entry.get("item_id", "")))
		var weight := int(entry.get("weight", 0))
		var rarity := str(item.get("rarity", "Common"))
		if rarity == "Uncommon":
			weight += fortune
		elif rarity == "Rare":
			weight += fortune * 2
		cursor += max(0, weight)
		if roll < cursor:
			return str(entry.get("item_id", ""))
	return str(table.back().get("item_id", ""))


func _build_headline(
	report: Dictionary, adventurer_name: String, route: Dictionary, content
) -> String:
	if str(report.get("outcome", "")) == "retreated":
		return "%s returned after a dangerous retreat." % adventurer_name
	if not report.get("level_ups", []).is_empty():
		return (
			"%s reached Level %d on the road." % [adventurer_name, int(report.get("new_level", 1))]
		)
	for item_entry in report.get("items", []):
		var item: Dictionary = content.get_item(str(item_entry.get("item_id", "")))
		if str(item.get("rarity", "")) == "Rare":
			return (
				"%s returned with a Rare discovery: %s."
				% [adventurer_name, str(item.get("name", "unknown item"))]
			)
	if not report.get("items", []).is_empty():
		var first_item: Dictionary = content.get_item(
			str(report.get("items", [])[0].get("item_id", ""))
		)
		return (
			"%s found %s on the expedition."
			% [adventurer_name, str(first_item.get("name", "a new item"))]
		)
	return (
		"%s completed %s and came home safely."
		% [adventurer_name, str(route.get("name", "the route"))]
	)


func _build_summary(
	report: Dictionary, adventurer_name: String, route: Dictionary, _content
) -> String:
	var summary := (
		"%s spent %s on %s. "
		% [
			adventurer_name,
			format_duration(int(report.get("elapsed_seconds", 0))),
			str(route.get("name", "the route"))
		]
	)
	if str(report.get("outcome", "")) == "retreated":
		summary += "The route ended early, but the progress already earned made it home."
	else:
		summary += "The objective was completed and the important discoveries are ready to review."
	return summary


func _empty_report(active: Dictionary, text: String) -> Dictionary:
	return {
		"route_id": str(active.get("route_id", "")),
		"route_name": "Unknown route",
		"zone": "Bramblewild",
		"elapsed_seconds": 0,
		"outcome": "retreated",
		"headline": text,
		"summary": text,
		"events":
		[
			{
				"kind": "error",
				"tone": "danger",
				"text": text,
				"evidence": "The route definition was unavailable.",
				"importance": "major"
			}
		],
		"xp_gained": 0,
		"gold_gained": 0,
		"items": [],
		"encounters_won": 0,
		"danger_moments": 0,
		"level_ups": [],
		"starting_level": 1,
		"new_level": 1,
		"starting_stats": {},
		"ending_stats": {}
	}


func _format_text(text: String, adventurer_name: String) -> String:
	return text.replace("{name}", adventurer_name)


static func format_duration(seconds: int) -> String:
	if seconds < 60:
		return "%ds" % seconds
	var minutes := int(seconds / 60)
	var remaining_seconds := seconds % 60
	if minutes < 60:
		return "%dm %02ds" % [minutes, remaining_seconds]
	var hours := int(minutes / 60)
	return "%dh %02dm" % [hours, minutes % 60]
