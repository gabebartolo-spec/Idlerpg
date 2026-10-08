extends SceneTree
const Expedition = preload("res://src/state/expedition.gd")
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
func route(name: String, protected: bool, prepared: bool) -> RefCounted:
	var run := Expedition.new()
	run.selected_route = name
	run.start(6, 36, protected, prepared)
	run.advance(300.0)
	return run
func _run() -> void:
	var safe := route("greenway", false, false)
	var risky := route("causeway", false, false)
	var prepared := route("causeway", false, true)
	var protected := route("causeway", true, false)
	check(safe.recap["won"] and safe.node == 5 and safe.gold_earned == 43, "gentle route has five authored nodes and an attainable first reward")
	check(not risky.recap["won"] and risky.gold_earned == 8 and not risky.claimed_routes.has("causeway"), "risky failure keeps cache gold without granting final reward")
	check(prepared.recap["won"] and prepared.stew_used and protected.recap["won"], "passive preparation or earned Thornward protection enables the higher-risk route")
	var all: Dictionary = safe.discoveries.duplicate()
	all.merge(prepared.discoveries)
	check(all.size() == 6, "two routes cover the six finite authored encounters")
	safe.start(6, 36, false, false)
	safe.advance(300.0)
	check(safe.gold_earned == 18 and safe.completed == 2, "repeat completion uses the disclosed smaller reward")
	var watched := hero()
	var offline := hero()
	watched.fishing.prepared = 1
	offline.fishing.prepared = 1
	watched.request_expedition("causeway")
	offline.request_expedition("causeway")
	watched.simulate_elapsed(600.0)
	offline.simulate_offline(600.0)
	check(watched.to_save_dict() == offline.to_save_dict(), "queued expedition, path motion, encounters, grants and resumed adventure match offline")
	check(offline.expedition.completed == 1 and offline.chronicle.seen.has("expedition:causeway"), "route completion records a persistent return destination")
	var interrupted := hero()
	interrupted.fishing.prepared = 1
	interrupted.request_expedition("causeway")
	interrupted._begin_quest_cycle()
	interrupted.simulate_elapsed(149.9)
	var restored := hero()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(interrupted.to_save_dict())))
	interrupted.simulate_elapsed(150.1)
	restored.simulate_offline(150.1)
	check(restored.to_save_dict() == interrupted.to_save_dict(), "fractional node and frozen build resume without replaying a reward")
	check(restored.fishing.prepared == 0 and restored.expedition.gold_earned == 68, "one prepared stew is consumed with one successful route payout")
	var boundary := hero()
	boundary.fishing.prepared = 1
	var saves: Array[Dictionary] = []
	boundary.event_emitted.connect(func(event: Dictionary) -> void:
		if event["type"] == "expedition_encounter" and event.get("encounter", "") == "cache":
			saves.append(boundary.to_save_dict()))
	boundary.request_expedition("causeway")
	boundary._begin_quest_cycle()
	boundary.simulate_elapsed(180.0)
	var replay := hero()
	replay.load_save_dict(JSON.parse_string(JSON.stringify(saves[0])))
	boundary.simulate_elapsed(120.0)
	replay.simulate_offline(120.0)
	check(boundary.gold == replay.gold and boundary.expedition.to_save_dict() == replay.expedition.to_save_dict(), "event-time checkpoint cannot duplicate cache or final gold")
	var stopped := hero()
	stopped.fishing.prepared = 1
	stopped.request_expedition("greenway")
	stopped._begin_quest_cycle()
	stopped.simulate_elapsed(60.0)
	stopped.stop_expedition()
	check(stopped.gold == 0 and stopped.fishing.prepared == 1 and stopped.expedition.completed == 0 and not stopped.expedition.active, "abort preserves unused preparation and grants no completion")
	check(not stopped.request_expedition("paid_rescue"), "unknown routes cannot be selected")
	var legacy := hero()
	var data: Dictionary = legacy.to_save_dict()
	data.erase("expedition")
	legacy.load_save_dict(data)
	check(not legacy.expedition.active and legacy.expedition.claimed_routes.is_empty(), "old saves begin without invented expedition rewards")
	print("Expedition tests complete: %d failure(s)" % failures)
	quit(failures)
