extends SceneTree

# IRPG-R09: world item effects, the two hunts, bounded bad luck, the first-discovery
# reward, and that none of it is a source of tokens or reaches a banner.

const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const GameStateScript = preload("res://src/game.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const HuntCatalogScript = preload("res://src/data/hunt_catalog.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _sim(seed: int = 5) -> Node:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	sim.drop_seed = seed
	return sim

func _run() -> void:
	_test_catalogue()
	_test_rolls()
	_test_targeting()
	_test_distribution()
	_test_discovery()
	_test_no_token_source()
	_test_in_play()
	_test_saves()
	print("Hunt tests complete: %d failure(s)" % failures)
	quit(failures)

func _test_catalogue() -> void:
	var effects: Dictionary = {}
	for item_name in GearCatalogScript.ITEMS:
		var effect_id: String = GearCatalogScript.effect(item_name)
		if effect_id.is_empty():
			continue
		effects[effect_id] = item_name
		_check(GearCatalogScript.EFFECTS.has(effect_id) and not GearCatalogScript.effect_text(item_name).is_empty(), "%s's effect has words for the player" % item_name)
		_check(not GearCatalogScript.source_text(item_name).is_empty(), "%s says where it comes from" % item_name)
	_check(effects.size() == 3, "three world items carry an effect %s" % str(effects.values()))

	_check(HuntCatalogScript.hunt_ids().size() == 2, "there are two hunts")
	for hunt_id in HuntCatalogScript.hunt_ids():
		var hunt: Dictionary = HuntCatalogScript.hunt(hunt_id)
		var item_name := str(hunt["item"])
		_check(GearCatalogScript.source(item_name) == "hunt" and HuntCatalogScript.hunt_for_item(item_name) == hunt_id, "%s is marked as hunted, and by this hunt" % item_name)
		_check(str(hunt["enemy"]) in ["briarling", "thornback"], "%s is hunted from an enemy the quest really fights" % item_name)
		_check(float(hunt["chance"]) > 0.0 and int(hunt["pity"]) > 1, "%s has a chance and a bound" % item_name)

	var game: Node = GameStateScript.new()
	root.add_child(game)
	var on_banner: Array[String] = []
	for banner_id in game.banner_ids():
		for item_name in game.collection_items(banner_id):
			if not GearCatalogScript.source(item_name).is_empty():
				on_banner.append(item_name)
	_check(on_banner.is_empty(), "no world item is on a banner %s" % str(on_banner))
	game.free()

func _test_rolls() -> void:
	_check(HuntCatalogScript.roll(7, 1, 3) == HuntCatalogScript.roll(7, 1, 3), "the same seed, hunt and roll give the same number")
	_check(HuntCatalogScript.roll(7, 1, 3) != HuntCatalogScript.roll(8, 1, 3) and HuntCatalogScript.roll(7, 1, 3) != HuntCatalogScript.roll(7, 2, 3), "another seed or hunt gives another number")
	var total := 0.0
	var low := 0
	var count := 40000
	for index in count:
		var value := HuntCatalogScript.roll(1234, 1, index)
		if value < 0.0 or value >= 1.0:
			failures += 1
			push_error("roll out of range")
		total += value
		if value < 0.03:
			low += 1
	_check(absf(total / count - 0.5) < 0.01, "rolls average a half (%.4f)" % (total / count))
	_check(absf(float(low) / count - 0.03) < 0.004, "three in a hundred rolls fall under 0.03 (%.4f)" % (float(low) / count))

func _test_targeting() -> void:
	var sim := _sim()
	_check(sim.hunt_target == HuntCatalogScript.DEFAULT_HUNT, "a new adventurer hunts the Briarhook by default")
	sim._roll_hunt("thornback")
	sim._roll_hunt("goblin")
	_check(sim.hunt_kills("briarhook") == 0 and sim.hunt_rolls.is_empty(), "other enemies do not count towards a hunt")
	sim._roll_hunt("briarling")
	_check(sim.hunt_kills("briarhook") + sim.gear_count("Briarhook") == 1, "the quarry does")

	_check(not sim.set_hunt_target("dragon"), "an unknown hunt is refused")
	_check(sim.set_hunt_target("carapace") and sim.hunt_target == "carapace", "the hunt can be changed")
	var kills: int = sim.hunt_kills("briarhook")
	sim._roll_hunt("briarling")
	_check(sim.hunt_kills("briarhook") == kills, "only the chosen hunt makes progress")
	_check(sim.set_hunt_target("") and sim.hunt_target.is_empty(), "hunting can be turned off")
	sim._roll_hunt("thornback")
	_check(sim.hunt_kills("carapace") == 0, "and then nothing rolls")
	sim.free()

# Long-run drops: how many kills each hunt takes over many seeds.
func _test_distribution() -> void:
	var sim := _sim()
	for hunt_id in HuntCatalogScript.hunt_ids():
		var hunt: Dictionary = HuntCatalogScript.hunt(hunt_id)
		var item_name := str(hunt["item"])
		var pity := int(hunt["pity"])
		var chance := float(hunt["chance"])
		var trials := 3000
		var total := 0
		var worst := 0
		var at_pity := 0
		for seed in trials:
			sim.drop_seed = seed + 1
			sim.gear_inventory.clear()
			sim.hunt_progress.clear()
			sim.hunt_rolls.clear()
			sim.hunt_target = hunt_id
			var kills := 0
			while sim.gear_count(item_name) == 0 and kills < pity + 5:
				sim._roll_hunt(str(hunt["enemy"]))
				kills += 1
			total += kills
			worst = maxi(worst, kills)
			if kills == pity:
				at_pity += 1
		var expected := (1.0 - pow(1.0 - chance, pity)) / chance
		var expected_at_pity := pow(1.0 - chance, pity - 1)
		var mean := float(total) / trials
		var pity_share := float(at_pity) / trials
		print("%s: mean %.1f kills (expected %.1f), worst %d (bound %d), %.1f%% reached the bound (expected %.1f%%)" % [
			item_name, mean, expected, worst, pity, pity_share * 100.0, expected_at_pity * 100.0])
		_check(worst == pity, "%s: the unluckiest adventurer gets it on kill %d and no later" % [item_name, pity])
		_check(absf(mean - expected) < expected * 0.06, "%s: the average matches the stated chance" % item_name)
		_check(absf(pity_share - expected_at_pity) < 0.03, "%s: the share saved by the bound matches the stated chance" % item_name)
	sim.free()

func _find(sim: Node, hunt_id: String) -> void:
	var hunt: Dictionary = HuntCatalogScript.hunt(hunt_id)
	sim.hunt_target = hunt_id
	while sim.gear_count(str(hunt["item"])) == 0:
		sim._roll_hunt(str(hunt["enemy"]))

func _test_discovery() -> void:
	var sim := _sim()
	var gold: int = sim.gold
	_find(sim, "briarhook")
	_check(sim.gold == gold + HuntCatalogScript.FIRST_DISCOVERY_GOLD and sim.has_discovered("Briarhook"), "the first Briarhook pays the discovery reward")
	_check(sim.hunt_target == "carapace", "with one hunt done the adventurer moves on to the other")
	_check(sim.hunt_kills("briarhook") == 0, "progress towards the bound starts again after a drop")

	var rolls := int(sim.hunt_rolls["briarhook"])
	sim.hunt_target = "briarhook"
	sim._roll_hunt("briarling")
	_check(int(sim.hunt_rolls["briarhook"]) == rolls and sim.gear_count("Briarhook") == 1, "an item already owned is not hunted again")

	var sale: Dictionary = sim.sell_gear("Briarhook")
	_check(bool(sale["ok"]) and sim.gear_count("Briarhook") == 0, "a hunted item can be sold")
	gold = sim.gold
	_find(sim, "briarhook")
	_check(sim.gear_count("Briarhook") == 1 and sim.gold == gold, "it can be hunted again, and pays no second discovery reward")

	# The same for the boss's own drop.
	var charm := _sim()
	charm.add_gear("Briarheart Charm")
	charm._discover("Briarheart Charm")
	gold = charm.gold
	charm.sell_gear("Briarheart Charm")
	charm._discover("Briarheart Charm")
	_check(charm.gold == gold + GearCatalogScript.sell_value("Briarheart Charm"), "selling and regaining the Briarheart Charm earns only its sale price")
	sim.free()
	charm.free()

func _test_no_token_source() -> void:
	for item_name in GearCatalogScript.ITEMS:
		if not GearCatalogScript.source(item_name).is_empty():
			_check(GearCatalogScript.salvage_tokens(item_name) == 0, "%s, which the world gives back, salvages for no tokens" % item_name)
	_check(GearCatalogScript.salvage_tokens("Iron Sword") == 1 and GearCatalogScript.salvage_tokens("Crownblade") == 15, "banner gear salvages as before")

# The hunts as they happen in the real quest loop.
func _test_in_play() -> void:
	var sim := _sim(321)
	var elapsed := 0.0
	while elapsed < 3600.0 and sim.gear_count("Briarhook") == 0:
		sim.simulate_elapsed(30.0)
		elapsed += 30.0
	var hook_minutes := elapsed / 60.0
	_check(sim.gear_count("Briarhook") == 1, "an hour of questing is enough for the Briarhook whatever the luck (%.0f minutes)" % hook_minutes)
	_check(sim.briarlings_killed <= 4 and sim.hunt_target == "carapace", "the adventurer then hunts the Carapace without being told")
	while elapsed < 6.0 * 3600.0 and sim.gear_count("Thornback Carapace") == 0:
		sim.simulate_elapsed(60.0)
		elapsed += 60.0
	_check(sim.gear_count("Thornback Carapace") == 1 and sim.thornback_rank >= 1, "the Carapace comes from beating Old Thornback (after %.0f minutes, rank %d)" % [elapsed / 60.0, sim.thornback_rank])
	_check(sim.gold >= 2 * HuntCatalogScript.FIRST_DISCOVERY_GOLD, "both discoveries were paid")
	sim.free()

func _test_saves() -> void:
	var sim := _sim(77)
	for _kill in 9:
		sim._roll_hunt("briarling")
	_find(sim, "carapace")
	var restored: Node = AdventurerSimScript.new()
	root.add_child(restored)
	restored.load_save_dict(JSON.parse_string(JSON.stringify(sim.to_save_dict(), "", true, true)))
	_check(restored.to_save_dict() == sim.to_save_dict(), "hunt progress, rolls, seed and discoveries survive a save")
	sim.hunt_target = "briarhook"
	restored.hunt_target = "briarhook"
	for _kill in 200:
		sim._roll_hunt("briarling")
		restored._roll_hunt("briarling")
	_check(restored.to_save_dict() == sim.to_save_dict(), "reloading does not change what the next rolls give")

	# A save from before this change: no hunt fields, a Briarheart Charm already owned.
	var old: Dictionary = sim.to_save_dict()
	for key in ["enemy_attack_count", "thornback_rank", "thornback_lost", "boss_retry_mark", "boss_fight", "last_boss_fight", "hunt_target", "hunt_progress", "hunt_rolls", "discovered", "drop_seed"]:
		old.erase(key)
	old["gear_inventory"] = {"Briarheart Charm": 1, "Iron Sword": 2}
	old["equipped"] = {"accessory": "Briarheart Charm"}
	var migrated: Node = AdventurerSimScript.new()
	root.add_child(migrated)
	migrated.load_save_dict(old)
	_check(migrated.thornback_rank == 0 and migrated.hunt_target == HuntCatalogScript.DEFAULT_HUNT and migrated.last_boss_fight.is_empty(), "an older save starts the boss at rank 0 with the default hunt")
	_check(migrated.has_discovered("Briarheart Charm") and not migrated.has_discovered("Briarhook"), "a world item it already owns counts as discovered, so it cannot be claimed again")
	_check(migrated.equipped_item("accessory") == "Briarheart Charm" and migrated.has_gear_effect("thornward"), "and the Charm it was wearing now carries its effect")
	_check(PersistenceScript.SAVE_VERSION == 3, "the save format is version 3")
	sim.free()
	restored.free()
	migrated.free()
