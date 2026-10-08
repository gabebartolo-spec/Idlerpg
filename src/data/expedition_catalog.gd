extends RefCounted
const NODE_USEC := 60000000
const POSITION := Vector3(3.0, 0.0, 7.5)
const ENCOUNTERS := {
	"stream": {"name": "Quiet stream", "text": "You follow the stream and cool your hands in the water.", "heal": 3},
	"camp": {"name": "Abandoned camp", "text": "A dry campfire gives you a sheltered place to rest.", "heal": 6},
	"wolves": {"name": "Watchful wolves", "text": "You drive the wolves from the trail. A stronger attack makes the passage safer.", "damage": 18},
	"bridge": {"name": "Fallen bridge", "text": "You cross the broken causeway slowly, taking a few hard knocks.", "damage": 10},
	"cache": {"name": "Amber cache", "text": "A marked cache holds eight gold for a patient explorer.", "gold": 8},
	"guardian": {"name": "Thorn guardian", "text": "The guardian releases a thorn burst. Thornward protection halves its damage.", "damage": 24}
}
const ROUTES := {
	"greenway": {"name": "Gentle Greenway", "clue": "Lower risk. Wolves are the only damaging encounter; streams and camp restore health. Five minutes.", "nodes": ["stream", "camp", "wolves", "stream", "cache"], "first_gold": 35, "repeat_gold": 10},
	"causeway": {"name": "Shattered Causeway", "clue": "Higher risk: bridge, wolves and a 24-damage thorn burst. Prepare Pond Stew or earned Thornward gear. Five minutes.", "nodes": ["bridge", "wolves", "cache", "guardian", "camp"], "first_gold": 60, "repeat_gold": 20}
}
const WAYPOINTS := {
	"greenway": [Vector3(3, 0, 6.5), Vector3(4, 0, 6.5), Vector3(5, 0, 5), Vector3(4, 0, 4), Vector3(3, 0, 3)],
	"causeway": [Vector3(5, 0, 6), Vector3(7, 0, 5), Vector3(9, 0, 4), Vector3(10, 0, 2), Vector3(8, 0, 4)]
}
