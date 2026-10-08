extends RefCounted

# A small, reviewed subset of existing assets. These IDs have no combat stats.
const LOOKS := {
	"trail_blade": {"name": "Trail blade", "slot": "weapon", "item": "Iron Sword"},
	"goblin_cleaver": {"name": "Goblin cleaver", "slot": "weapon", "item": "Goblin Cleaver"},
	"wolf_hood": {"name": "Wolf hood", "slot": "head", "item": "Wolfskin Hood"},
	"star_helm": {"name": "Star helm", "slot": "head", "item": "Starforged Helm"},
	"briar_shell": {"name": "Briar shell", "slot": "chest", "item": "Thornback Carapace"}
}
const SLOTS := ["weapon", "head", "chest"]

static func for_item(item: String) -> String:
	for id in LOOKS:
		if LOOKS[id]["item"] == item:
			return id
	return ""
