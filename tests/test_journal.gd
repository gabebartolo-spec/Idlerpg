extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Catalog = preload("res://src/data/journal_catalog.gd")
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func sim() -> Node:
	var node := Sim.new()
	root.add_child(node)
	node.drop_seed = 12
	return node
func _run() -> void:
	var watched := sim()
	var offline := sim()
	offline.load_save_dict(watched.to_save_dict())
	watched.simulate_elapsed(3600.0)
	offline.simulate_offline(3600.0)
	check(watched.to_save_dict() == offline.to_save_dict(), "journal discoveries and rewards match watched and offline simulation")
	for id in ["campfire_mark", "moon_tracks", "amber_pool"]:
		check(watched.journal.found.has(id) and watched.chronicle.seen.has("journal:" + id), "%s has an authored discovery and return milestone" % id)
	var before: int = watched.gold
	for id in Catalog.ENTRIES:
		watched.journal.unlock(id, watched)
	check(watched.gold == before and watched.journal.found.size() == 15, "repeated discovery cannot pay and the volume stays finite")
	var saved: Dictionary = watched.to_save_dict()
	var restored := sim()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(saved)))
	check(restored.journal.found == watched.journal.found, "journal entries survive JSON restoration")
	restored.unequip_gear("Briarheart Charm")
	restored.sell_gear("Briarheart Charm")
	check(restored.journal.found.has("Briarheart Charm"), "selling a world item cannot erase its journal entry")
	saved.erase("journal")
	var legacy := sim()
	legacy.load_save_dict(saved)
	check(legacy.gold == watched.gold and legacy.journal.found.has("campfire_mark"), "legacy evidence seeds discovered entries without retrospective rewards")
	for id in Catalog.ENTRIES:
		check(not str(Catalog.ENTRIES[id]["clue"]).is_empty(), "%s has an actionable discovery clue" % id)
	print("Journal tests complete: %d failure(s)" % failures)
	quit(failures)
