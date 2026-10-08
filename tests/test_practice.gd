extends SceneTree
const Practice = preload("res://src/state/practice_dungeon.gd")
const Sim = preload("res://src/sim/adventurer_sim.gd")
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func hero() -> Node:
	var node := Sim.new()
	root.add_child(node)
	return node
func _run() -> void:
	var outcomes := {}
	for role in Practice.Catalog.ROLES:
		var run := Practice.new()
		run.selected_role = role
		run.start(6, 36, false)
		run.advance(60.0)
		outcomes[role] = run.recap
		print("ROLE ", role, " ", JSON.stringify(run.recap))
		check(run.recap["contributions"]["bran_block"] > 0 and run.recap["contributions"]["iris_heal"] > 0, "NPC protection and support measurably contribute for " + str(role))
	check(outcomes["damage"]["turns"] < outcomes["protection"]["turns"], "damage role changes encounter duration")
	check(outcomes["protection"]["contributions"]["hero_block"] > 0 and outcomes["support"]["contributions"]["hero_heal"] > 0, "other hero roles produce distinct protection and support contributions")
	var protected := Practice.new()
	protected.selected_role = "protection"
	protected.start(6, 36, true)
	protected.advance(60.0)
	check(not outcomes["protection"]["won"] and protected.recap["won"], "passive fishing preparation changes an underprepared protection loss into a victory")
	var damage_prepared := Practice.new()
	damage_prepared.start(6, 36, true)
	damage_prepared.advance(60.0)
	check(not damage_prepared.recap["won"] and protected.recap["won"], "same free stats and stew produce different outcomes when the role changes")
	var common := hero()
	common.set_active_companion("Torch Sprite")
	common.request_practice("damage")
	common._begin_quest_cycle()
	while common.practice.active:
		common.advance(0.1)
	check(common.practice.clears == 1, "Common Torch Sprite can make a useful free damage build for practice")
	var watched := hero()
	var offline := hero()
	watched.fishing.prepared = 1
	offline.fishing.prepared = 1
	watched.request_practice("protection")
	offline.request_practice("protection")
	watched.simulate_elapsed(180.0)
	offline.simulate_offline(180.0)
	check(watched.to_save_dict() == offline.to_save_dict(), "queued practice, stew consumption, first reward and resumed adventure match offline")
	check(offline.practice.clears == 1 and offline.practice.first_reward_claimed and offline.chronicle.seen.has("practice:first"), "three rooms settle one first-clear reward and permanent milestone")
	check(offline.fishing.prepared == 0 and offline.practice.recap["contributions"]["stew_heal"] == 12, "stew restores and consumes exactly once")
	var replay := hero()
	replay.request_practice("damage")
	replay._begin_quest_cycle()
	replay.advance(2.5)
	var frozen_attack: int = replay.practice.attack
	replay.hero_attack = 100
	check(replay.practice.attack == frozen_attack, "build changes during a run do not rewrite its frozen attack")
	var restored := hero()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(replay.to_save_dict())))
	replay.simulate_elapsed(15.0)
	restored.simulate_offline(15.0)
	check(restored.to_save_dict() == replay.to_save_dict(), "interrupted room and fractional turn reload deterministically")
	var repeated := hero()
	repeated.hero_attack = 20
	repeated.request_practice("damage")
	repeated._begin_quest_cycle()
	while repeated.practice.active:
		repeated.advance(0.1)
	var gold: int = repeated.gold
	repeated.request_practice("damage")
	repeated._begin_quest_cycle()
	while repeated.practice.active:
		repeated.advance(0.1)
	check(repeated.gold == gold and repeated.practice.clears == 2, "repeating a clear cannot claim the first-clear reward again")
	var stopped := hero()
	stopped.fishing.prepared = 1
	stopped.request_practice("support")
	stopped._begin_quest_cycle()
	stopped.advance(0.5)
	stopped.stop_practice()
	check(stopped.fishing.prepared == 1 and stopped.gold == 0 and not stopped.practice.active, "early abort keeps unused preparation and awards nothing")
	check(not stopped.request_practice("paid_role"), "unknown roles cannot queue a practice run")
	print("Practice tests complete: %d failure(s)" % failures)
	quit(failures)
