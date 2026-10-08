extends RefCounted
const NODE_USEC := 60000000
const POSITION := Vector3(3.0, 0.0, 7.5)
const ENCOUNTERS := {
	"stream": {"name": "Quiet stream", "text": "You follow the stream and cool your hands in the water.", "heal": 3},
	"camp": {"name": "Abandoned camp", "text": "A dry campfire gives you a sheltered place to rest.", "heal": 6},
	"wolves": {"name": "Watchful wolves", "text": "You drive the wolves from the trail. A stronger attack makes the passage safer.", "damage": 18},
	"bridge": {"name": "Fallen bridge", "text": "You cross the broken causeway slowly, taking a few hard knocks.", "damage": 10},
	"cache": {"name": "Amber cache", "text": "A marked cache holds eight gold for a patient explorer.", "gold": 8},
	"guardian": {"name": "Thorn guardian", "text": "The guardian releases a thorn burst. Thornward protection halves its damage.", "damage": 24},
	"lantern_gate": {"name": "Lantern gate", "text": "Amber lamps mark a passage beneath roots older than Mossgate. The hollow opens beyond them."},
	"moths": {"name": "Lantern moths", "text": "Broad cream wings scatter sparks across the trail. A decisive attack drives the swarm away.", "damage": 24, "attack_reduction": true, "minimum_damage": 6, "model": "lantern_moth"},
	"briar_tunnel": {"name": "Briar tunnel", "text": "You push beneath a living arch of thorns. Thornward turns its snapping branches aside.", "damage": 16, "telegraphed": true},
	"mushroom_rest": {"name": "Mooncap clearing", "text": "Blue mushrooms light a sheltered pool. You rest in their cool glow before climbing higher.", "heal": 8},
	"keeper": {"name": "Root keeper", "text": "The keeper lowers its great wooden shield, then strikes. Attack weakens the blow; Thornward halves what remains.", "damage": 38, "attack_reduction": true, "minimum_damage": 14, "telegraphed": true, "model": "root_keeper"},
	"lantern_cache": {"name": "Lamplighter's cache", "text": "A weathered pack beneath the lamps holds twelve gold. Someone prepared this trail before you.", "gold": 12},
	"elder_keeper": {"name": "Elder root keeper", "text": "At the old shrine, an elder keeper tests your resolve with a heavy, clearly signalled blow.", "damage": 66, "attack_reduction": true, "minimum_damage": 22, "telegraphed": true, "model": "root_keeper"}
}
const ROUTES := {
	"greenway": {"name": "Gentle Greenway", "clue": "Lower risk. Wolves are the only damaging encounter; streams and camp restore health. Five minutes.", "nodes": ["stream", "camp", "wolves", "stream", "cache"], "first_gold": 35, "repeat_gold": 10},
	"causeway": {"name": "Shattered Causeway", "clue": "Higher risk: bridge, wolves and a 24-damage thorn burst. Prepare Pond Stew or earned Thornward gear. Five minutes.", "nodes": ["bridge", "wolves", "cache", "guardian", "camp"], "first_gold": 60, "repeat_gold": 20},
	"hollow": {"name": "Lantern Hollow", "clue": "Clear Gentle Greenway to discover the hollow. Moths reward attack; the Root Keeper rewards Thornward. A prepared beginner with Thornward can succeed.", "nodes": ["lantern_gate", "moths", "mushroom_rest", "lantern_cache", "keeper"], "node_usec": 180000000, "first_gold": 80, "repeat_gold": 25, "requires": ["greenway"], "look": "lantern_crook", "risk": "Woodland trial", "hint": "Attack + Thornward; stew helps"},
	"rise": {"name": "Keeper's Rise", "clue": "Clear Lantern Hollow and Shattered Causeway first. This deeper trail combines moths, thorns and an elder keeper. Prepare health, attack, Thornward or stew; there is no paid rescue.", "nodes": ["moths", "briar_tunnel", "mushroom_rest", "lantern_cache", "elder_keeper"], "node_usec": 360000000, "first_gold": 130, "repeat_gold": 40, "requires": ["hollow", "causeway"], "look": "keeper_crown", "risk": "Deep woodland", "hint": "Bring Thornward + stew or better gear"}
}
const WAYPOINTS := {
	"greenway": [Vector3(3, 0, 6.5), Vector3(4, 0, 6.5), Vector3(5, 0, 5), Vector3(4, 0, 4), Vector3(3, 0, 3)],
	"causeway": [Vector3(5, 0, 6), Vector3(7, 0, 5), Vector3(9, 0, 4), Vector3(10, 0, 2), Vector3(8, 0, 4)],
	"hollow": [Vector3(12, 0, 10), Vector3(15, 0, 11), Vector3(15, 0, 14), Vector3(18, 0, 14), Vector3(20, 0, 11)],
	"rise": [Vector3(15, 0, 11), Vector3(19, 0, 17), Vector3(22, 0, 18), Vector3(24, 0, 16), Vector3(26, 0, 13)]
}

static func node_usec(route: String) -> int:
	return int(ROUTES.get(route, {}).get("node_usec", NODE_USEC))

static func total_gold(route: String, first: bool) -> int:
	var entry: Dictionary = ROUTES[route]
	var gold: int = entry["first_gold"] if first else entry["repeat_gold"]
	for id in entry["nodes"]:
		gold += int(ENCOUNTERS[id].get("gold", 0))
	return gold

static func locked_reason(route: String, claimed: Dictionary) -> String:
	for required in ROUTES.get(route, {}).get("requires", []):
		if not claimed.has(required):
			return "Clear " + str(ROUTES[required]["name"]) + " first"
	return ""
