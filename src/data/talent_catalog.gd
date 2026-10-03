class_name TalentCatalog
extends RefCounted

const CLASS_NAME := "Wayfarer"

const BRANCHES := {
	"slayer": {
		"label": "Slayer",
		"nodes": ["heavy_hand", "sharpened_edge", "executioner", "bloodlust"]
	},
	"warden": {
		"label": "Warden",
		"nodes": ["thick_hide", "iron_guard", "second_wind", "last_stand"]
	},
	"trailblazer": {
		"label": "Trailblazer",
		"nodes": ["quick_hands", "trail_legs", "opening_strike", "hunter_eye"]
	}
}

const TALENTS := {
	"heavy_hand": {
		"branch": "slayer",
		"name": "Heavy hand",
		"description": "Every fourth attack hits 50% harder.",
		"requires": ""
	},
	"sharpened_edge": {
		"branch": "slayer",
		"name": "Sharpened edge",
		"description": "+2 attack.",
		"requires": "heavy_hand"
	},
	"executioner": {
		"branch": "slayer",
		"name": "Executioner",
		"description": "Deal 50% more damage to enemies below 25% health.",
		"requires": "sharpened_edge"
	},
	"bloodlust": {
		"branch": "slayer",
		"name": "Bloodlust",
		"description": "Killing an enemy restores 4 health.",
		"requires": "executioner"
	},

	"thick_hide": {
		"branch": "warden",
		"name": "Thick hide",
		"description": "+10 maximum health.",
		"requires": ""
	},
	"iron_guard": {
		"branch": "warden",
		"name": "Iron guard",
		"description": "Enemy hits deal 1 less damage, minimum 1.",
		"requires": "thick_hide"
	},
	"second_wind": {
		"branch": "warden",
		"name": "Second wind",
		"description": "Once per fight below 35% health, recover 8 health.",
		"requires": "iron_guard"
	},
	"last_stand": {
		"branch": "warden",
		"name": "Last stand",
		"description": "Once per quest, a lethal hit leaves you at 1 health.",
		"requires": "second_wind"
	},

	"quick_hands": {
		"branch": "trailblazer",
		"name": "Quick hands",
		"description": "Attack 15% faster.",
		"requires": ""
	},
	"trail_legs": {
		"branch": "trailblazer",
		"name": "Trail legs",
		"description": "Travel 20% faster.",
		"requires": "quick_hands"
	},
	"opening_strike": {
		"branch": "trailblazer",
		"name": "Opening strike",
		"description": "The first hit of each fight deals +4 damage.",
		"requires": "trail_legs"
	},
	"hunter_eye": {
		"branch": "trailblazer",
		"name": "Hunter's eye",
		"description": "Enemy kills grant 25% more XP.",
		"requires": "opening_strike"
	}
}

static func branch_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in BRANCHES.keys():
		ids.append(str(id))
	return ids

static func branch_label(branch_id: String) -> String:
	return str((BRANCHES.get(branch_id, {}) as Dictionary).get("label", branch_id.capitalize()))

static func nodes_for_branch(branch_id: String) -> Array[String]:
	var nodes: Array[String] = []
	var data: Dictionary = BRANCHES.get(branch_id, {})
	for id in data.get("nodes", []):
		nodes.append(str(id))
	return nodes

static func has_talent(talent_id: String) -> bool:
	return TALENTS.has(talent_id)

static func talent(talent_id: String) -> Dictionary:
	if not TALENTS.has(talent_id):
		return {}
	return (TALENTS[talent_id] as Dictionary).duplicate(true)

static func talent_name(talent_id: String) -> String:
	return str(talent(talent_id).get("name", talent_id))

static func description(talent_id: String) -> String:
	return str(talent(talent_id).get("description", ""))

static func requirement(talent_id: String) -> String:
	return str(talent(talent_id).get("requires", ""))

static func branch(talent_id: String) -> String:
	return str(talent(talent_id).get("branch", ""))
