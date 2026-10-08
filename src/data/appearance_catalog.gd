extends RefCounted

# A small, reviewed subset of existing assets. These IDs have no combat stats.
const LOOKS := {
	"trail_blade": {"name": "Trail blade", "slot": "weapon", "item": "Iron Sword"},
	"goblin_cleaver": {"name": "Goblin cleaver", "slot": "weapon", "item": "Goblin Cleaver"},
	"wolf_hood": {"name": "Wolf hood", "slot": "head", "item": "Wolfskin Hood"},
	"star_helm": {"name": "Star helm", "slot": "head", "item": "Starforged Helm"},
	"briar_shell": {"name": "Briar shell", "slot": "chest", "item": "Thornback Carapace"},
	"lantern_crook": {"name": "Lantern crook", "slot": "weapon", "item": "Lantern Crook", "clue": "Clear Lantern Hollow", "grip_degrees": Vector3(-70, 0, 0)},
	"keeper_crown": {"name": "Keeper crown", "slot": "head", "item": "Keeper Crown", "clue": "Clear Keeper's Rise"},
	"warden_lantern": {"name": "Warden lantern", "slot": "weapon", "item": "Warden Lantern", "clue": "Defeat the Hollow Warden with your guild", "grip_degrees": Vector3(-70, 0, 0)}
}
const SLOTS := ["weapon", "head", "chest"]

static func for_item(item: String) -> String:
	for id in LOOKS:
		if LOOKS[id]["item"] == item:
			return id
	return ""
