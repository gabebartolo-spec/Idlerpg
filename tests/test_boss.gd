extends SceneTree

# IRPG-R08: Old Thornback's telegraphed burst, the free counters to it, what a loss
# explains and suggests, and that watching and being away give the same outcome.

const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const BossCatalogScript = preload("res://src/data/boss_catalog.gd")
const BossAdviceScript = preload("res://src/sim/boss_advice.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")

const PAID_WORDS := ["summon", "banner", "gacha", "token", "buy", "purchase"]

var failures: int = 0
var events: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _on_event(event: Dictionary) -> void:
	events.append(event)

# An adventurer of a given level, with every talent if they have the points, wearing `gear`.
func _hero(level: int, gear: Array = []) -> Node:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	sim.hunt_target = ""
	sim.hero_level = level
	sim.hero_attack = 6 + (level - 1)
	sim.hero_max_hp = 36 + 5 * (level - 1)
	for branch_id in TalentCatalogScript.branch_ids():
		for talent_id in TalentCatalogScript.nodes_for_branch(branch_id):
			sim.unlock_talent(talent_id)
	for item_name in gear:
		sim.add_gear(item_name)
		sim.equip_gear(item_name)
	return sim

# Puts the adventurer straight in front of Old Thornback at `rank`, fresh, and fights.
func _duel(sim: Node, rank: int) -> bool:
	sim.thornback_rank = rank
	sim.quest_kind = "briarfen"
	sim.quest_stage = 3
	sim.briarlings_killed = 4
	sim.thornback_killed = false
	sim.last_stand_used = false
	sim.hero_hp = sim.effective_max_hp()
	sim._start_fight("thornback")
	while sim.activity == "fighting":
		sim.advance(sim.STEP)
	return sim.thornback_killed

# The highest rank this build beats, climbing from rank 0.
func _highest_rank(level: int, gear: Array) -> int:
	for rank in 400:
		var sim := _hero(level, gear)
		var won := _duel(sim, rank)
		sim.free()
		if not won:
			return rank - 1
	return 400

func _run() -> void:
	_test_numbers()
	_test_telegraph()
	_test_first_fight()
	_test_counters()
	_test_loss_and_retry()
	_test_advice()
	_test_free_path()
	_test_watched_and_offline()
	_test_save_mid_fight()
	print("Boss tests complete: %d failure(s)" % failures)
	quit(failures)

func _test_numbers() -> void:
	_check(BossCatalogScript.max_hp(0) == 60, "rank 0 keeps Old Thornback's original health")
	_check(BossCatalogScript.max_hp(5) > BossCatalogScript.max_hp(4) and BossCatalogScript.damage(5) > BossCatalogScript.damage(4), "each rank is stronger than the last")
	_check(BossCatalogScript.burst_damage(3) == BossCatalogScript.damage(3) * 3, "the burst is three ordinary hits")
	_check(not BossCatalogScript.is_burst(2) and BossCatalogScript.is_burst(3) and BossCatalogScript.is_burst(6), "every third attack is the burst")
	_check(BossCatalogScript.is_winding_up(2) and not BossCatalogScript.is_winding_up(3), "the wind-up is the stretch before a burst")

func _test_telegraph() -> void:
	var sim := _hero(20)
	events.clear()
	sim.event_emitted.connect(_on_event)
	_duel(sim, 16)
	var warned := false
	var bursts := 0
	var unwarned := 0
	for event in events:
		match str(event["type"]):
			"boss_windup":
				warned = true
			"boss_burst":
				bursts += 1
				if not warned:
					unwarned += 1
				warned = false
	_check(bursts >= 1, "a long enough fight includes the burst (%d)" % bursts)
	_check(unwarned == 0, "every burst is warned of first")
	_check(int(sim.last_boss_fight["bursts"]) == bursts, "the fight tally counts the bursts that landed")
	_check(int(sim.last_boss_fight["burst_damage"]) > 0 and int(sim.last_boss_fight["burst_damage"]) <= int(sim.last_boss_fight["damage_taken"]), "burst damage is part of the damage taken")
	sim.free()

func _test_first_fight() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	var elapsed := 0.0
	while sim.thornback_rank < 1 and elapsed < 300.0:
		sim.advance(sim.STEP)
		elapsed += sim.STEP
	_check(sim.thornback_rank == 1 and sim.deaths == 0, "a new adventurer beats rank 0 on the first attempt, untouched by luck")
	_check(sim.gear_count("Briarheart Charm") == 1, "the first win gives the Briarheart Charm")
	_check(bool(sim.last_boss_fight.get("won", false)) and int(sim.last_boss_fight["rank"]) == 0, "the win is recorded against the rank fought")
	sim.free()

func _test_counters() -> void:
	# Seeded trials: the same adventurer, the same boss, only the counter differs.
	for level in [15, 40, 120]:
		var plain := _highest_rank(level, [])
		var charm := _highest_rank(level, ["Briarheart Charm"])
		var hook := _highest_rank(level, ["Briarhook"])
		var both := _highest_rank(level, ["Briarheart Charm", "Briarhook"])
		var all := _highest_rank(level, ["Briarheart Charm", "Briarhook", "Thornback Carapace"])
		print("level %d highest rank beaten: plain %d, charm %d, hook %d, both %d, all three %d" % [level, plain, charm, hook, both, all])
		_check(charm > plain, "level %d: the Briarheart Charm beats ranks a plain build cannot" % level)
		_check(hook > plain, "level %d: the Briarhook beats ranks a plain build cannot" % level)
		_check(both > charm and both > hook, "level %d: the two counters together go further than either" % level)
		_check(all > both, "level %d: the Thornback Carapace goes further still" % level)

	# Banner gear does not make the world items pointless, and the reverse.
	var early_world := _highest_rank(3, ["Briarhook"])
	var early_banner := _highest_rank(3, ["Crownblade"])
	var late_world := _highest_rank(120, ["Briarhook"])
	var late_banner := _highest_rank(120, ["Crownblade"])
	print("Briarhook against Crownblade: level 3 %d vs %d, level 120 %d vs %d" % [early_world, early_banner, late_world, late_banner])
	_check(early_banner > early_world, "early on, a Legendary weapon is the better weapon against the boss")
	_check(late_world > late_banner, "later, the world weapon beats ranks the Legendary cannot")

func _test_loss_and_retry() -> void:
	var sim := _hero(40)
	var wall := _highest_rank(40, []) + 1
	sim.thornback_rank = wall
	sim.quest_cycles_completed = 1
	sim._begin_quest_cycle()
	events.clear()
	sim.event_emitted.connect(_on_event)

	var cycles: int = sim.quest_cycles_completed
	while sim.quest_cycles_completed < cycles + 1:
		sim.advance(sim.STEP)
	_check(sim.deaths == 1 and sim.thornback_rank == wall, "losing to the boss costs one defeat and no rank")
	_check(not bool(sim.last_boss_fight["won"]) and int(sim.last_boss_fight["boss_hp_left"]) > 0, "the loss is recorded with the health the boss had left")
	_check(sim.hero_position.distance_to(sim.TOWN_POSITION) < 0.01, "a lost boss fight still ends the quest back in town")
	_check(not sim.will_challenge_boss(), "the adventurer does not walk straight back into a fight they just lost")

	while sim.quest_cycles_completed < cycles + 3:
		sim.advance(sim.STEP)
	var skipped := 0
	for event in events:
		if str(event["type"]) == "boss_skipped":
			skipped += 1
	_check(sim.deaths == 1 and skipped == 2, "they clear the Briarlings and go home until something changes (%d skips)" % skipped)

	sim.add_gear("Briarheart Charm")
	sim.equip_gear("Briarheart Charm")
	_check(sim.will_challenge_boss(), "changing gear is enough to try again")
	while sim.quest_cycles_completed < cycles + 4:
		sim.advance(sim.STEP)
	_check(sim.thornback_rank == wall + 1 and sim.deaths == 1, "with the counter worn, the same adventurer wins the rank they lost to")
	sim.free()

	var levelled := _hero(40)
	levelled.thornback_rank = wall
	_duel(levelled, wall)
	_check(not levelled.will_challenge_boss(), "a loss is remembered")
	levelled._grant_xp(levelled.xp_to_next_level())
	_check(levelled.will_challenge_boss(), "a new level is enough to try again")
	levelled.free()

func _texts(advice: Dictionary) -> Array[String]:
	var texts: Array[String] = [str(advice["headline"])]
	texts.append_array(advice["facts"])
	for suggestion in advice["suggestions"]:
		texts.append(str(suggestion["text"]))
	return texts

func _test_advice() -> void:
	var fresh := _hero(1)
	var before: Dictionary = BossAdviceScript.advise(fresh)
	_check(str(before["headline"]).contains("not been fought") and before["suggestions"].is_empty(), "before any fight the screen describes the boss and suggests nothing")
	fresh.free()

	var wall := _highest_rank(40, []) + 1
	var sim := _hero(40)
	sim.add_gear("Briarheart Charm")
	_duel(sim, wall)
	var advice: Dictionary = BossAdviceScript.advise(sim)
	var fight: Dictionary = sim.last_boss_fight
	_check(str(advice["headline"]).contains("rank %d" % wall), "the explanation names the rank that was lost to")
	var facts := " ".join(advice["facts"])
	_check(facts.contains("%d damage" % int(fight["burst_damage"])) and facts.contains("%d of %d health" % [int(fight["boss_hp_left"]), int(fight["boss_max_hp"])]), "the facts are the fight's own numbers")

	var equip_charm := false
	var hunt_hook := false
	for suggestion in advice["suggestions"]:
		if suggestion["action"] == "equip" and suggestion["target"] == "Briarheart Charm":
			equip_charm = true
		if suggestion["action"] == "hunt" and suggestion["target"] == "briarhook":
			hunt_hook = true
		if suggestion["action"] == "equip":
			_check(sim.gear_count(str(suggestion["target"])) > 0 and not GearCatalogScript.source(str(suggestion["target"])).is_empty(), "an equip suggestion is a world item already owned")
	_check(equip_charm, "an owned, unworn counter is suggested for equipping")
	_check(hunt_hook, "a counter not yet owned is suggested as a hunt, with its progress")

	var paid := false
	for text in _texts(advice):
		for word in PAID_WORDS:
			if text.to_lower().contains(word):
				paid = true
	_check(not paid, "no suggestion points at a draw or a purchase")

	sim.equip_gear("Briarheart Charm")
	sim.set_hunt_target("briarhook")
	var after: Dictionary = BossAdviceScript.advise(sim)
	var repeats := false
	for suggestion in after["suggestions"]:
		if suggestion["target"] == "Briarheart Charm" or suggestion["action"] == "hunt" and suggestion["target"] == "briarhook":
			repeats = true
	_check(not repeats, "advice already taken is not offered again")
	sim.free()

	var pointed := _hero(40)
	pointed.reset_talents()
	_duel(pointed, 30)
	var with_points: Dictionary = BossAdviceScript.advise(pointed)
	_check(with_points["suggestions"][0]["action"] == "talents", "unspent talent points are the first suggestion")
	pointed.free()

# The unlucky free path: no draws, no hunt drops, only what the game hands everyone.
func _test_free_path() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	sim.hunt_target = ""
	var elapsed := 0.0
	var followed := 0
	while elapsed < 1800.0:
		sim.simulate_elapsed(10.0)
		elapsed += 10.0
		for branch_id in TalentCatalogScript.branch_ids():
			for talent_id in TalentCatalogScript.nodes_for_branch(branch_id):
				sim.unlock_talent(talent_id)
		# Follow only the suggestions that need nothing but a tap.
		if not sim.last_boss_fight.is_empty() and not bool(sim.last_boss_fight["won"]):
			for suggestion in BossAdviceScript.advise(sim)["suggestions"]:
				if suggestion["action"] == "equip":
					sim.equip_gear(str(suggestion["target"]))
					followed += 1
	_check(followed >= 1 and sim.has_gear_effect("thornward"), "following the advice puts the guaranteed counter on")
	_check(sim.owned_gear_names() == ["Briarheart Charm", "Goblin Cleaver", "Wolfskin Hood"], "the path used only what every adventurer is given %s" % str(sim.owned_gear_names()))
	_check(sim.thornback_rank >= 15, "with no luck and no draws the boss is still beaten again and again (rank %d in 30 minutes)" % sim.thornback_rank)
	_check(sim.quest_cycles_completed > 60, "losses never stall the adventure (%d quests)" % sim.quest_cycles_completed)
	sim.free()

func _test_watched_and_offline() -> void:
	var builds := {
		"new": [],
		"countered": ["Briarheart Charm", "Briarhook", "Thornback Carapace"]
	}
	for label in builds:
		var start := _hero(1, builds[label])
		start.hunt_target = "briarhook"
		start.drop_seed = 99
		var state: Dictionary = start.to_save_dict()
		start.free()
		for seconds in [47.3, 600.0, 3600.0, 4 * 3600.0]:
			var stepped: Node = AdventurerSimScript.new()
			root.add_child(stepped)
			stepped.load_save_dict(state)
			stepped.simulate_elapsed(seconds)
			var caught_up: Node = AdventurerSimScript.new()
			root.add_child(caught_up)
			caught_up.load_save_dict(state)
			caught_up.simulate_offline(seconds)
			_check(stepped.to_save_dict() == caught_up.to_save_dict(), "%s build, %s s: catch-up matches stepping, boss rank %d" % [label, str(seconds), stepped.thornback_rank])
			stepped.free()
			caught_up.free()

	# A long absence still resolves quickly now that boss fights break up the cycles.
	var away := _hero(1)
	away.hunt_target = "briarhook"
	var started := Time.get_ticks_msec()
	away.simulate_offline(7.0 * 24.0 * 3600.0)
	var took := Time.get_ticks_msec() - started
	print("seven days of catch-up took %d ms, reaching level %d and boss rank %d" % [took, away.hero_level, away.thornback_rank])
	_check(took < 15000, "seven days away resolves in seconds, not minutes")
	away.free()

func _test_save_mid_fight() -> void:
	var sim := _hero(30, ["Briarhook"])
	sim._discover("Briarhook")
	sim.thornback_rank = 20
	sim.quest_kind = "briarfen"
	sim.quest_stage = 3
	sim.briarlings_killed = 4
	sim._start_fight("thornback")
	for _step in 40:
		sim.advance(sim.STEP)
	_check(sim.activity == "fighting" and sim.enemy_attack_count >= 2, "the save is taken part-way through the fight")

	var restored: Node = AdventurerSimScript.new()
	root.add_child(restored)
	restored.load_save_dict(JSON.parse_string(JSON.stringify(sim.to_save_dict(), "", true, true)))
	_check(restored.to_save_dict() == sim.to_save_dict(), "a boss fight survives being written to a file and read back")
	sim.simulate_elapsed(120.0)
	restored.simulate_elapsed(120.0)
	_check(restored.to_save_dict() == sim.to_save_dict(), "and plays out the same afterwards")
	sim.free()
	restored.free()
