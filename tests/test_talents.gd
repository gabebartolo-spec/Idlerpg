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

func _unlock_chain(sim: Node, ids: Array[String]) -> void:
	for talent_id in ids:
		_check(sim.unlock_talent(talent_id), "unlocks %s" % talent_id)

func _run() -> void:
	var slayer: Node = AdventurerSimScript.new()
	root.add_child(slayer)
	slayer.hero_level = 5

	_check(slayer.talent_points_total() == 4, "one talent point is earned per level after level 1")
	_check(not slayer.can_unlock_talent("sharpened_edge"), "later talents require their prerequisite")
	_unlock_chain(slayer, ["heavy_hand", "sharpened_edge", "executioner", "bloodlust"])
	_check(slayer.talent_points_available() == 0, "spent points reduce the available pool")
	_check(slayer.build_summary() == "Slayer 4", "build summary reflects branch investment without recommending a build")

	var slayer_attack: int = slayer.effective_attack()
	_check(slayer_attack == slayer.hero_attack + 2, "Sharpened edge changes authoritative attack")

	slayer._start_fight("wolf")
	var hit_one: int = slayer._next_hero_damage()
	slayer._next_hero_damage()
	slayer._next_hero_damage()
	var hit_four: int = slayer._next_hero_damage()
	_check(hit_four > hit_one, "Heavy hand changes every fourth attack")

	slayer.hero_hp = slayer.effective_max_hp() - 6
	slayer.enemy_kind = "goblin"
	slayer.enemy_hp = 0
	slayer._defeat_enemy()
	_check(slayer.hero_hp >= slayer.effective_max_hp() - 2, "Bloodlust heals after a kill")

	var saved: Dictionary = slayer.to_save_dict()
	var restored: Node = AdventurerSimScript.new()
	root.add_child(restored)
	restored.load_save_dict(saved)
	_check(restored.has_talent("executioner"), "talents survive save/load")
	_check(restored.talent_points_available() == 0, "spent talent points survive save/load")

	slayer.reset_talents()
	_check(slayer.talent_points_available() == 4, "free prototype respec returns spent points")
	_check(slayer.build_summary() == "Uncommitted", "respec clears the build summary")
	_check(slayer.effective_attack() == slayer.hero_attack, "respec removes talent stat effects")

	var warden: Node = AdventurerSimScript.new()
	root.add_child(warden)
	warden.hero_level = 5
	var base_hp: int = warden.effective_max_hp()
	_unlock_chain(warden, ["thick_hide", "iron_guard", "second_wind", "last_stand"])
	_check(warden.effective_max_hp() == base_hp + 10, "Thick hide increases maximum health")

	warden.hero_hp = 20
	warden.take_damage(4)
	_check(warden.hero_hp == 17, "Iron guard reduces enemy damage by one")

	warden.hero_hp = 10
	warden.second_wind_used = false
	warden.take_damage(1)
	_check(warden.hero_hp == 17, "Second wind automatically restores health at low health")
	_check(warden.second_wind_used, "Second wind only arms once per fight")

	warden.hero_hp = 5
	warden.last_stand_used = false
	warden.take_damage(999)
	_check(warden.hero_hp == 1 and warden.activity != "recovering", "Last stand prevents the first lethal hit in a quest")
	warden.take_damage(999)
	_check(warden.activity == "recovering", "Last stand cannot prevent a second lethal hit in the same quest")

	var trail: Node = AdventurerSimScript.new()
	root.add_child(trail)
	trail.hero_level = 5
	_unlock_chain(trail, ["quick_hands", "trail_legs", "opening_strike", "hunter_eye"])
	_check(trail.effective_attack_interval() < trail.HERO_ATTACK_INTERVAL, "Quick hands speeds up automatic attacks")
	_check(trail.effective_move_speed() > trail.MOVE_SPEED, "Trail legs speeds up autonomous travel")

	trail._start_fight("wolf")
	var opening_damage: int = trail._next_hero_damage()
	_check(opening_damage == trail.effective_attack() + 4, "Opening strike boosts the first hit")

	var xp_before: int = trail.hero_xp
	trail._grant_enemy_xp(8)
	_check(trail.hero_xp - xp_before == 10, "Hunter's eye grants 25% more enemy XP")

	print("Talent tests complete: %d failure(s)" % failures)
	quit(failures)
