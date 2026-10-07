extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Relics = preload("res://src/data/relic_catalog.gd")
var failures := 0
func _init() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func hero() -> Node:
	var sim := Sim.new()
	root.add_child(sim)
	return sim
func run() -> void:
	var game := Game.new()
	root.add_child(game)
	var sim := hero()
	check(not sim.equip_relic("Worldstone Shard", game) and not sim.equip_relic("invented", game), "unowned and unknown relics are rejected")
	game.collection["relics"] = {"Worldstone Shard": 9, "Hunter's Knot": 1, "Copper Charm": 1}
	var attack: int = sim.effective_attack()
	var hp: int = sim.effective_max_hp()
	var speed: float = sim.effective_move_speed()
	sim.equip_relic("Worldstone Shard", game)
	check(sim.effective_attack() == attack + 4 and sim.effective_max_hp() == hp + 8, "one slot applies the catalog's attack and health, independent of copy count")
	sim.equip_relic("Hunter's Knot", game)
	check(is_equal_approx(sim.effective_move_speed(), speed * 1.2) and sim.effective_attack() == attack, "switching completely removes the previous relic effect")
	check(Relics.move("Hunter's Knot") > Relics.move("Worldstone Shard"), "free Common relic beats Legendary in the travel niche")
	sim.hero_hp = 3
	sim.equip_relic("Copper Charm", game)
	check(sim.hero_hp == 3 and sim.effective_max_hp() == hp + 8, "health relic changes capacity without granting repeatable healing")
	sim.equip_relic("", game)
	check(sim.effective_attack() == attack and sim.effective_max_hp() == hp and is_equal_approx(sim.effective_move_speed(), speed), "unequipping removes every effect")
	var free := hero()
	free.simulate_offline(600.0)
	var empty_game := Game.new()
	root.add_child(empty_game)
	check(free.owns_relic("Hunter's Knot", empty_game) and free.owns_relic("Copper Charm", empty_game), "ordinary no-draw adventuring guarantees travel and health alternatives")
	free.equip_relic("Hunter's Knot", empty_game)
	check(free.loadouts.save_current(0, "Trail relic", free), "loadouts save relic choice")
	free.equip_relic("Copper Charm", empty_game)
	free.loadouts.apply(0, free, empty_game)
	check(free.active_relic == "Hunter's Knot", "atomic preset application restores the relic slot")
	var state: Dictionary = free.to_save_dict()
	var stepped := hero()
	var offline := hero()
	stepped.load_save_dict(state)
	offline.load_save_dict(state)
	stepped.simulate_elapsed(1800.0)
	offline.simulate_offline(1800.0)
	check(stepped.to_save_dict() == offline.to_save_dict(), "equipped relic effects preserve watched/offline parity")
	var plain := hero()
	var stronger := hero()
	stronger.equip_relic("Worldstone Shard", game)
	var plain_time := 0.0
	var strong_time := 0.0
	while plain.total_kills == 0:
		plain.advance(0.1)
		plain_time += 0.1
	while stronger.total_kills == 0:
		stronger.advance(0.1)
		strong_time += 0.1
	check(strong_time < plain_time, "attack relic changes an actual encounter outcome, not only displayed stats")
	var legacy: Dictionary = free.to_save_dict()
	legacy.erase("earned_relics")
	legacy.erase("active_relic")
	sim.load_save_dict(legacy)
	check(sim.owns_relic("Hunter's Knot", empty_game) and sim.owns_relic("Copper Charm", empty_game) and sim.active_relic.is_empty(), "old progressed saves receive free alternatives without auto-equipping")
	print("Relic tests complete: %d failure(s)" % failures)
	quit(failures)
