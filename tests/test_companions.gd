extends SceneTree

const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)

	var base_attack: int = sim.effective_attack()
	var base_hp: int = sim.effective_max_hp()
	var base_speed: float = sim.effective_move_speed()

	_check(not sim.set_active_companion("Not A Companion"), "unknown companions cannot be activated")
	_check(sim.set_active_companion("Torch Sprite"), "known companion can be activated")
	_check(sim.active_companion == "Torch Sprite", "active companion is recorded")
	_check(sim.effective_attack() == base_attack + 1, "Torch Sprite changes authoritative attack")

	_check(sim.set_active_companion("Hill Squire"), "active companion can be switched")
	_check(sim.effective_max_hp() == base_hp + 8, "Hill Squire changes authoritative health")

	_check(sim.set_active_companion("Stable Hound"), "Stable Hound can be activated")
	_check(sim.effective_move_speed() > base_speed, "Stable Hound changes autonomous travel speed")

	var raven: Node = AdventurerSimScript.new()
	root.add_child(raven)
	raven.set_active_companion("Clockwork Raven")
	var xp_before: int = raven.hero_xp
	raven._grant_enemy_xp(10)
	_check(raven.hero_xp - xp_before == 11, "Clockwork Raven increases enemy XP")

	var rat: Node = AdventurerSimScript.new()
	root.add_child(rat)
	rat.set_active_companion("Pack Rat")
	var gold_before: int = rat.gold
	rat._complete_quest()
	_check(rat.gold - gold_before == 22, "Pack Rat increases quest gold")

	var witch: Node = AdventurerSimScript.new()
	root.add_child(witch)
	witch.set_active_companion("Marsh Witch")
	witch.hero_hp = witch.effective_max_hp() - 5
	witch.enemy_kind = "goblin"
	witch.enemy_hp = 0
	witch._defeat_enemy()
	_check(witch.hero_hp == witch.effective_max_hp() - 3, "Marsh Witch heals after a kill")

	var bond: Node = AdventurerSimScript.new()
	root.add_child(bond)
	bond.set_active_companion("Frost Ranger")
	for _i in range(25):
		bond._grant_companion_bond_xp(1)
	_check(bond.companion_bond_level("Frost Ranger") == 3, "active companion bond rises after enough shared kills")
	_check(bond.effective_attack() > base_attack + 3, "higher bond modestly improves companion passive")

	var saved: Dictionary = bond.to_save_dict()
	var restored: Node = AdventurerSimScript.new()
	root.add_child(restored)
	restored.load_save_dict(saved)
	_check(restored.active_companion == "Frost Ranger", "active companion survives save/load")
	_check(restored.companion_bond_xp_for("Frost Ranger") == 25, "companion bond XP survives save/load")
	_check(restored.companion_bond_level("Frost Ranger") == 3, "companion bond level survives save/load")

	restored.clear_active_companion()
	_check(restored.active_companion.is_empty(), "active companion can be rested")
	_check(restored.effective_attack() == restored.hero_attack, "resting companion removes its passive")

	print("Companion tests complete: %d failure(s)" % failures)
	quit(failures)
