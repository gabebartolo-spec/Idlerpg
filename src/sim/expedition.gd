class_name VbExpedition
extends RefCounted

# The expedition engine.
#
# A run is planned from (zone, depth, seed) into a timeline of "beats", then
# resolved strictly in beat order against elapsed time. One RNG stream serves
# both planning and resolution, consumed in order — so a run replays
# identically from its seed no matter when or how often it is resolved.

const Rng = preload("res://src/sim/rng.gd")
const Loot = preload("res://src/sim/loot.gd")

const ECHO_CAP := 5
const DEATH_SAVE_BASE := 40
const WRATH_BONUS := 3

const ORDINALS := ["first", "second", "third", "fourth", "fifth", "sixth"]

const TRAVEL_LINES := [
	"The road goes quiet. %s keeps to the middle distance.",
	"Reeds, rust, and the long light of the ash. Onward.",
	"A mile of nothing that means them harm. For now."
]
const DISCOVERY_LINES := [
	"Something glints under the silt: a few coins, kept warm by the mud.",
	"A dead pilgrim's purse. They say a word over it and take the coin.",
	"A cache under a fallen marker — somebody meant to come back."
]
const REST_LINES := [
	"A dry moment. Breath, and the wounds seen to properly.",
	"They sit with their back to a stone and let the shaking stop."
]


## Seconds per toll for this zone, given the snapshot's gear.
static func toll_seconds(zone: Dictionary, snap: Dictionary) -> float:
	var t := float(int(zone.get("toll_seconds", 120)))
	if snap.get("specials", {}).get("light_foot", false):
		t *= 0.75
	return t


static func danger_at(zone: Dictionary, toll_index: int, snap: Dictionary) -> int:
	var danger := int(zone.get("danger_base", 1)) + maxi(0, toll_index - 2)
	if snap.get("specials", {}).get("light_foot", false):
		danger += 1
	return danger


## Luck as it stands at a given toll, with run effects applied.
static func luck_at(snap: Dictionary, toll_index: int) -> int:
	var luck := int(snap.get("luck", 0))
	var specials: Dictionary = snap.get("specials", {})
	if specials.get("no_retreat", false):
		luck *= 2
	if specials.get("deep_luck", false):
		luck += toll_index
	if "pilgrim" in snap.get("vows", []) and toll_index >= 2:
		luck += 2
	return luck


## Build the full beat timeline for a run (deterministic from the seed).
static func plan(zone: Dictionary, depth: int, seed_value: int, snap: Dictionary) -> Dictionary:
	var rng := Rng.new(seed_value)
	return _plan_with(zone, depth, snap, rng)


static func _plan_with(zone: Dictionary, depth: int, snap: Dictionary, rng) -> Dictionary:
	var toll_len := toll_seconds(zone, snap)
	var total := toll_len * float(depth)
	var beats: Array = []
	beats.append({"t": -0.5, "kind": "departure"})
	var enemies: Array = zone.get("enemies", []).duplicate()
	for i in depth:
		var base := float(i) * toll_len
		beats.append({"t": base + 0.01, "kind": "toll", "toll": i})
		if i > 0:
			beats.append({"t": base + toll_len * 0.12, "kind": "travel", "toll": i})
		var fight_t := base + toll_len * 0.5
		var boss_id := str(zone.get("boss", ""))
		var is_final := i == depth - 1
		if is_final and boss_id != "":
			beats.append({"t": fight_t, "kind": "combat", "toll": i, "enemy": boss_id, "boss": true, "elite": false})
		elif int(zone.get("elite_from_toll", 99)) <= i and rng.next_unit() < 0.2:
			beats.append({"t": fight_t, "kind": "combat", "toll": i, "enemy": str(zone.get("elite")), "boss": false, "elite": true})
		else:
			beats.append({"t": fight_t, "kind": "combat", "toll": i, "enemy": str(rng.pick(enemies)), "boss": false, "elite": false})
		if is_final and depth >= 3:
			beats.append({"t": total - 1.0, "kind": "objective", "toll": i})
		else:
			var roll := rng.next_unit()
			if roll < 0.35:
				beats.append({"t": base + toll_len * 0.8, "kind": "discovery", "toll": i})
			elif roll < 0.55:
				beats.append({"t": base + toll_len * 0.8, "kind": "rest", "toll": i})
	beats.sort_custom(func(a, b): return float(a["t"]) < float(b["t"]))
	return {"beats": beats, "total_seconds": total, "toll_seconds": toll_len}


## Resolve a run up to `elapsed` seconds in. Pure — never mutates shared state.
static func resolve(
	zone: Dictionary, depth: int, seed_value: int, snap: Dictionary, elapsed: int, content
) -> Dictionary:
	var rng := Rng.new(seed_value)
	var plan_data := _plan_with(zone, depth, snap, rng)
	var run := {
		"status": "in_progress",
		"elapsed_seconds": elapsed,
		"planned_seconds": int(plan_data["total_seconds"]),
		"events": [],
		"loot": [],
		"xp": 0,
		"gold": 0,
		"shards": 0,
		"kills": 0,
		"wounds": 0,
		"deepest_toll": 0,
		"boss_slain": false,
		"zone_id": str(zone.get("id", "")),
		"zone_name": str(zone.get("name", "")),
		"depth": depth,
		"grit": int(snap.get("grit_max", 3)),
		"echo": 3 if "silence" in snap.get("vows", []) else 0,
		"combats": 0,
		"near_death_warned": false,
		"combats_this_toll": {},
		"last_toll": -1
	}
	var specials: Dictionary = snap.get("specials", {})
	var limit := minf(float(elapsed), float(plan_data["total_seconds"]))
	for beat in plan_data["beats"]:
		if str(run["status"]) != "in_progress":
			break
		if float(beat["t"]) > limit:
			break
		_process_beat(beat, zone, snap, specials, rng, run, content)
	if str(run["status"]) == "in_progress" and elapsed >= int(plan_data["total_seconds"]):
		run["status"] = "returned"
		_event(run, "return", "good",
			"The bell hears them at the edge of the dark, and %s comes home." % str(snap.get("name", "the Bellbound")),
			true)
	elif str(run["status"]) == "in_progress":
		run["status"] = "out"
	run["summary"] = _summary(run)
	run["standout"] = _standout(run["loot"], content)
	return run


static func _process_beat(beat: Dictionary, zone: Dictionary, snap: Dictionary, specials: Dictionary, rng, run: Dictionary, content) -> void:
	var adventurer := str(snap.get("name", "The Bellbound"))
	var toll := int(beat.get("toll", 0))
	run["deepest_toll"] = maxi(int(run["deepest_toll"]), toll + 1)
	match str(beat["kind"]):
		"departure":
			_event(run, "departure", "neutral",
				"%s walks out. %s" % [adventurer, str(zone.get("entry", ""))], true)
		"toll":
			run["last_toll"] = toll
			run["combats_this_toll"][toll] = 0
			if "shelter" in snap.get("vows", []):
				run["grit"] = mini(int(run["grit"]) + 1, int(snap.get("grit_max", 3)))
			if toll > 0:
				_event(run, "toll", "neutral",
					"The %s toll fades over the %s." % [_ordinal(toll), str(zone.get("name", "valley"))], false)
		"travel":
			_event(run, "travel", "neutral", str(rng.pick(TRAVEL_LINES)) % adventurer, false)
		"rest":
			run["grit"] = mini(int(run["grit"]) + 1, int(snap.get("grit_max", 3)))
			_event(run, "rest", "good", str(rng.pick(REST_LINES)), false)
		"discovery":
			if rng.next_unit() < 0.3:
				var found := Loot.roll_drop(content, zone, luck_at(snap, toll), rng)
				if not found.is_empty():
					run["loot"].append(found)
					_event(run, "find", "good", "Buried off the path: %s." % _item_name(found, content), false)
			else:
				var gold := 5 + rng.next_int(11)
				run["gold"] = int(run["gold"]) + gold
				_event(run, "gold", "good", str(rng.pick(DISCOVERY_LINES)), false)
		"objective":
			var obj: Dictionary = zone.get("objective", {})
			run["xp"] = int(run["xp"]) + int(obj.get("xp", 0))
			run["gold"] = int(run["gold"]) + int(obj.get("gold", 0))
			var kept := 0
			for i in 2:
				var found := Loot.roll_drop(content, zone, luck_at(snap, toll), rng, i == 0)
				if not found.is_empty():
					run["loot"].append(found)
					kept += 1
			var suffix := " — and something in the silt besides." if kept > 0 else "."
			_event(run, "objective", "good",
				"Objective met: %s (+%d XP, +%d gold%s)" % [
					str(obj.get("text", "")), int(obj.get("xp", 0)), int(obj.get("gold", 0)), suffix
				], true)
		"combat":
			_combat(beat, zone, snap, specials, rng, run, content)


static func _combat(beat: Dictionary, zone: Dictionary, snap: Dictionary, specials: Dictionary, rng, run: Dictionary, content) -> void:
	var adventurer := str(snap.get("name", "The Bellbound"))
	var enemy: Dictionary = content.get_enemy(str(beat.get("enemy", "")))
	var enemy_name := str(enemy.get("name", "something in the ash"))
	var threat := int(enemy.get("threat", 1))
	var toll := int(beat.get("toll", 0))
	var danger := danger_at(zone, toll, snap)
	var is_boss := bool(beat.get("boss", false))
	if is_boss:
		danger += 4  # the Gravecho does not fight fair
	var is_elite := bool(beat.get("elite", false))

	var per_toll := int(run["combats_this_toll"].get(toll, 0))
	var auto_win: bool = specials.get("first_strike", false) and per_toll == 0
	run["combats_this_toll"][toll] = per_toll + 1
	run["combats"] = int(run["combats"]) + 1

	var might := int(snap.get("might", 0))
	might += int(run["echo"]) * (2 if specials.get("echo_loud", false) else 1)
	if "wrath" in snap.get("vows", []) and (int(run["combats"]) - 1) % 3 == 2:
		might += WRATH_BONUS

	var win_chance := clampi(50 + (might - threat) * 8 - danger * 4, 15, 95)
	var win := auto_win or rng.roll(win_chance)

	var wound_chance := clampi(30 + danger * 12 - int(snap.get("ward", 0)) * 2 - (5 if win else 0), 5, 85)
	var wounded := (not auto_win) and rng.roll(wound_chance)

	if win:
		run["kills"] = int(run["kills"]) + 1
		run["xp"] = int(run["xp"]) + int(enemy.get("xp", 0))
		run["gold"] = int(run["gold"]) + int(enemy.get("gold", 0))
		if specials.get("tithe", false):
			run["shards"] = int(run["shards"]) + 1
		run["echo"] = mini(int(run["echo"]) + 1, ECHO_CAP)
		if is_boss:
			run["boss_slain"] = true
			var spoils := Loot.fixed_drop(content, "gravechos_tongue")
			if not spoils.is_empty():
				run["loot"].append(spoils)
			_event(run, "boss", "good",
				"%s puts the %s through the %s — and the valley hears it stop." % [
					adventurer, str(snap.get("weapon_name", "hammer")), enemy_name.capitalize()
				], true)
		elif is_elite:
			_event(run, "combat", "good",
				"The %s falls after a long, careful fight. %s takes its measure and moves on." % [enemy_name, adventurer], true)
		else:
			_event(run, "combat", "good",
				_struck_line(rng) % [adventurer, str(snap.get("weapon_name", "hammer")), enemy_name], false)
		var luck_eff := luck_at(snap, toll) + (15 if is_elite else 0)
		var drop := Loot.roll_drop(content, zone, luck_eff, rng, is_elite)
		if not drop.is_empty():
			run["loot"].append(drop)
			_event(run, "find", "good", "It was carrying %s." % _item_name(drop, content), false)
	else:
		run["echo"] = 0
		_event(run, "combat", "danger",
			"The %s will not die cleanly. %s gives ground, spending the toll on survival." % [enemy_name, adventurer], false)

	if wounded:
		run["wounds"] = int(run["wounds"]) + 1
		if specials.get("echo_hold", false):
			run["echo"] = int(ceil(float(int(run["echo"])) / 2.0))
		else:
			run["echo"] = 0
		if int(run["grit"]) > 0:
			run["grit"] = int(run["grit"]) - 1
			_event(run, "wound", "danger", _wound_line(rng) % [adventurer, enemy_name], false)
			if int(run["grit"]) == 0 and not bool(run["near_death_warned"]):
				run["near_death_warned"] = true
				_event(run, "near_death", "danger",
					"%s is running on nothing now — no Grit left, only stubbornness." % adventurer, true)
		else:
			# Out of Grit: the next wound asks the last question.
			var save_chance := clampi(DEATH_SAVE_BASE + (int(snap.get("ward", 0)) - danger) * 6, 5, 90)
			if rng.roll(save_chance):
				run["status"] = "broken"
				_event(run, "broken", "danger",
					"%s is done: bleeding, upright, and pointed home. The run ends here." % adventurer, true)
			else:
				run["status"] = "died"
				var kept := 0
				if specials.get("death_writ", false):
					kept = int(ceil(float(run["loot"].size()) / 2.0))
				run["loot"] = run["loot"].slice(0, kept)
				_event(run, "death", "grave",
					"%s falls in the %s. The bell pulls them home through the ash — %s" % [
						adventurer, str(zone.get("name", "valley")),
						"something stayed behind to mark the spot: half the find came home." if kept > 0 else "empty-handed, but breathing."
					], true)


static func _ordinal(index: int) -> String:
	if index >= 0 and index < ORDINALS.size():
		return ORDINALS[index]
	return "%dth" % (index + 1)


static func _struck_line(rng) -> String:
	var lines := [
		"%s breaks the %s across the %s and does not stop walking.",
		"One clean exchange: %s and the %s put the %s down.",
		"The %s wades in, %s first, and the %s scatters."
	]
	return str(rng.pick(lines))


static func _wound_line(rng) -> String:
	var lines := [
		"%s takes a hit from the %s that rings their teeth.",
		"%s pays a little of themselves to the %s and presses on.",
		"%s bleeds where the %s found the gap, and keeps the line."
	]
	return str(rng.pick(lines))


static func _item_name(inst: Dictionary, content) -> String:
	var def: Dictionary = content.get_item(str(inst.get("id", "")))
	return str(def.get("name", "something unnamed"))


static func _event(run: Dictionary, kind: String, tone: String, text: String, major: bool) -> void:
	run["events"].append({
		"kind": kind, "tone": tone, "text": text,
		"importance": "major" if major else "minor"
	})


static func _standout(loot: Array, content) -> Dictionary:
	var best := {}
	var best_rarity := -1
	for inst in loot:
		var def: Dictionary = content.get_item(str(inst.get("id", "")))
		var rarity := int(def.get("rarity", 0))
		if rarity > best_rarity:
			best_rarity = rarity
			best = def
	return best


static func _summary(run: Dictionary) -> String:
	var dt := int(run["deepest_toll"])
	match str(run["status"]):
		"returned":
			return "%d tolls · %d slain · came home whole" % [dt, int(run["kills"])]
		"died":
			if dt >= 1 and dt <= ORDINALS.size():
				return "fell at the %s toll" % ORDINALS[dt - 1]
			return "fell deep in the dark"
		"broken":
			if dt >= 1 and dt <= ORDINALS.size():
				return "walked home bleeding from the %s toll" % ORDINALS[dt - 1]
			return "walked home bleeding"
		"recalled":
			if dt < ORDINALS.size():
				return "recalled at the %s toll" % ORDINALS[dt]
			return "recalled"
		_:
			return "still out there"
