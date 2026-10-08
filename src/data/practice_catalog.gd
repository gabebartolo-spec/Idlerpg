extends RefCounted
const ROLES := {
	"damage": {"name": "Damage", "description": "+3 attack each turn. Shorter fights reduce incoming damage."},
	"protection": {"name": "Protection", "description": "Block 3 damage each enemy turn. Helps withstand bursts."},
	"support": {"name": "Support", "description": "Heal 10 party health every third turn. Sustains longer fights."}
}
const ROOMS := [
	{"name": "Training gate", "enemy": "Straw Watcher", "hp": 30, "damage": 5},
	{"name": "Root corridor", "enemy": "Root Guard", "hp": 45, "damage": 8},
	{"name": "Practice chamber", "enemy": "Moss Sentinel", "hp": 90, "damage": 14}
]
const ALLIES := [
	{"name": "Bran", "npc": true, "role": "Protection", "hp": 36, "attack": 3, "block": 2},
	{"name": "Iris", "npc": true, "role": "Support", "hp": 24, "attack": 2, "heal": 3}
]
const POSITION := Vector3(0.0, 0.0, 8.5)
