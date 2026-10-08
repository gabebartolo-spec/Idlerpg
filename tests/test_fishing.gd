extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Fishing = preload("res://src/state/fishing.gd")
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
	var watched := hero()
	var offline := hero()
	var original_activity: String = watched.activity
	watched.set_fishing(true)
	offline.set_fishing(true)
	check(watched.activity == original_activity, "fishing queues without interrupting an outing")
	watched.simulate_elapsed(3600.0)
	offline.simulate_offline(3600.0)
	check(watched.to_save_dict() == offline.to_save_dict(), "queued fishing, catches, chronicle and income match watched/offline")
	check(offline.activity == "fishing" and offline.quest_cycles_completed == 1, "current outing completes once before settling at the pond")
	for item in Fishing.Catalog.CATCHES:
		check(int(offline.fishing.stock.get(item, 0)) > 0, item + " is attainable with no minigame")
	check(offline.prepare_stew() and offline.fishing.prepared == 1, "passive catches prepare a functional dungeon stew")
	var saved: Dictionary = offline.to_save_dict()
	var restored := hero()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(saved)))
	check(restored.to_save_dict() == offline.to_save_dict(), "stock, partial cast and prepared stew persist exactly")
	var count: int = restored.fishing.catches
	var remainder: int = restored.fishing.progress_usec
	restored.set_fishing(false)
	restored.set_fishing(true)
	check(restored.fishing.catches == count and restored.fishing.progress_usec == remainder, "stopping/restarting neither awards nor discards a partial cast")
	var partial := Fishing.new()
	partial.advance(14.9)
	var reloaded := Fishing.new()
	reloaded.load_save_dict(JSON.parse_string(JSON.stringify(partial.to_save_dict())))
	reloaded.advance(0.1)
	check(reloaded.catches == 1 and reloaded.progress_usec == 0, "saved cast pays once at its exact boundary")
	var active := Fishing.new()
	for cast in range(10):
		active.advance(8.0)
		check(active.reel()["ok"], "timely optional reel succeeds for cast %d" % cast)
		check(not active.reel()["ok"], "repeated reel cannot pay twice for cast %d" % cast)
		var replay := Fishing.new()
		replay.load_save_dict(active.to_save_dict())
		check(not replay.reel()["ok"], "reload cannot repeat the reel for cast %d" % cast)
		active.advance(7.0)
	var passive := Fishing.new()
	passive.advance(150.0)
	check(active.catches == passive.catches and active.bonus_catches == 1 and active.stock["Pond Perch"] == passive.stock["Pond Perch"] + 1, "perfect active play adds only one perch per ten passive catches")
	var missed := Fishing.new()
	check(not missed.reel()["ok"], "early reel misses without a penalty")
	missed.advance(15.0)
	check(missed.catches == 1, "failed minigame still delivers the passive catch")
	var ingredients := Fishing.new()
	ingredients.advance(60.0)
	check(ingredients.prepare() and not ingredients.prepare(), "one recipe consumes its ingredients once")
	var long_return := hero()
	long_return.set_fishing(true)
	long_return.simulate_offline(3600.0)
	var begin := Time.get_ticks_msec()
	long_return.simulate_offline(604800.0)
	check(Time.get_ticks_msec() - begin < 500, "seven-day active fishing catch-up uses bounded work")
	check(long_return.income.total == 845, "fishing continues earning time-based summon tokens")
	print("Fishing tests complete: %d failure(s)" % failures)
	quit(failures)
