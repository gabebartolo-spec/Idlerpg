extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Catalog = preload("res://src/data/companion_catalog.gd")
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func hero(companion: String) -> Node:
	var sim := Sim.new()
	root.add_child(sim)
	sim.set_active_companion(companion)
	return sim
func _run() -> void:
	var ranger := hero("Frost Ranger")
	var warden := hero("Ancient Warden")
	var cleric := hero("Sun Cleric")
	var witch := hero("Marsh Witch")
	ranger._start_fight("thornback")
	warden._start_fight("thornback")
	ranger.advance(1.1)
	warden.advance(1.1)
	check(ranger.enemy_hp < warden.enemy_hp, "damage specialist deals more actual boss damage than Legendary all-rounder")
	check(cleric.effective_max_hp() > warden.effective_max_hp(), "protection specialist has more health than Legendary all-rounder")
	cleric.hero_hp = cleric.effective_max_hp()
	warden.hero_hp = warden.effective_max_hp()
	var burst: int = warden.hero_hp
	cleric.take_damage(burst, true)
	warden.take_damage(burst, true)
	check(cleric.hero_hp > 0 and warden.hero_hp == 0, "protection specialist survives a burst that defeats the all-rounder")
	var unaided := hero("Marsh Witch")
	unaided.clear_active_companion()
	unaided._start_fight("goblin")
	unaided.hero_hp = 5
	while unaided.activity == "fighting":
		unaided.advance(0.1)
	witch.hero_hp = 5
	witch._start_fight("goblin")
	witch.hero_hp = 5
	while witch.activity == "fighting":
		witch.advance(0.1)
	check(witch.hero_hp == unaided.hero_hp + 4, "Rare support finishes the same goblin encounter four health ahead of unaided hero")
	for name in Catalog.BOND_MOMENTS:
		var watched := hero(name)
		var offline := hero(name)
		for i in range(36000):
			watched.advance(0.1)
		offline.simulate_offline(3600.0)
		check(watched.to_save_dict() == offline.to_save_dict(), name + " role and vignette are watched/offline equivalent")
		var key := "bond_story:" + str(name)
		check(offline.chronicle.seen.has(key), name + " has a permanent bond moment")
		var restored := hero(name)
		restored.load_save_dict(JSON.parse_string(JSON.stringify(offline.to_save_dict())))
		var count: int = restored.chronicle.sequence
		restored._grant_companion_bond_xp(100)
		var stories := 0
		for entry in restored.chronicle.entries:
			if entry["key"] == key:
				stories += 1
		check(stories == 1 and restored.chronicle.sequence <= count + 1, name + " moment never repeats after reload or further bond growth")
		watched.queue_free()
		offline.queue_free()
		restored.queue_free()
	print("Companion role tests complete: %d failure(s)" % failures)
	quit(failures)
