extends SceneTree

const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Persistence = preload("res://src/state/persistence.gd")
const Chronicle = preload("res://src/state/chronicle.gd")
const PATH := "user://test_chronicle.json"
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func pair() -> Array:
	var sim := Sim.new()
	var game := Game.new()
	root.add_child(sim)
	root.add_child(game)
	return [sim, game]

func clean() -> void:
	for path in Persistence.files_for(PATH):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	clean()
	var original: Node = pair()[0]
	original.set_active_companion("Stable Hound")
	var start: Dictionary = original.to_save_dict()
	var stepped: Node = pair()[0]
	var offline: Node = pair()[0]
	stepped.load_save_dict(start)
	offline.load_save_dict(start)
	stepped.simulate_elapsed(7200.0)
	offline.simulate_offline(7200.0)
	check(stepped.to_save_dict() == offline.to_save_dict(), "two-hour offline catch-up preserves authoritative state and milestone IDs")
	check(offline.chronicle.seen.has("kill:goblin") and offline.chronicle.seen.has("boss:first"), "actual first enemy and boss victories are remembered")
	check(offline.chronicle.seen.has("gear:Goblin Cleaver") and offline.chronicle.seen.has("bond:Stable Hound:2"), "useful finds and companion bonds are remembered")
	var restored: Node = pair()[0]
	restored.load_save_dict(offline.to_save_dict())
	check(restored.chronicle.to_save_dict() == offline.chronicle.to_save_dict(), "history and stable IDs survive reload")
	restored.load_save_dict(JSON.parse_string(JSON.stringify(offline.to_save_dict(), "", true, true)))
	check(restored.chronicle.to_save_dict() == offline.chronicle.to_save_dict(), "JSON round-trip restores journal numeric fields without changing history")
	var mark: int = restored.chronicle.sequence
	restored.add_gear("Goblin Cleaver")
	check(restored.chronicle.sequence == mark, "a repeated item does not become another new milestone")
	var legacy: Dictionary = offline.to_save_dict()
	legacy.erase("chronicle")
	restored.load_save_dict(legacy)
	check(restored.chronicle.entries.is_empty(), "legacy migration fabricates no historical events")
	restored.add_gear("Goblin Cleaver")
	check(restored.chronicle.entries.is_empty(), "legacy owned gear is remembered without another NEW claim")
	var journal := Chronicle.new()
	for index in 150:
		journal.record("test:%d" % index, "Milestone", "gear", 80)
	check(journal.entries.size() == Chronicle.LIMIT and journal.sequence == 150, "visible journal is bounded while IDs remain monotonic")
	journal.record("test:0", "Repeated", "gear", 80)
	check(journal.sequence == 150, "evicted firsts cannot be repeated")
	journal.observe({"type": "boss_lost", "message": "Old Thornback drove you off.", "close": false})
	check(not journal.seen.has("close:thornback"), "ordinary losses do not become fabricated near victories")
	journal.observe({"type": "boss_lost", "message": "Old Thornback drove you off.", "close": true})
	check(journal.seen.has("close:thornback"), "measured close losses have a boss recap route")
	var close: Node = pair()[0]
	close._start_fight("thornback")
	close.enemy_hp = close.enemy_max_hp / 4
	close._die()
	check(close.chronicle.seen.has("close:thornback"), "simulation marks a defeat close only at a quarter of boss health or less")
	var ordinary: Node = pair()[0]
	ordinary._start_fight("thornback")
	ordinary._die()
	check(not ordinary.chronicle.seen.has("close:thornback"), "simulation does not call a full-health boss a close defeat")
	var saved := pair()
	check(Persistence.save(saved[0], saved[1], 1000, PATH), "initial checkpoint succeeds")
	var returned := pair()
	var report := Persistence.load_and_advance(returned[0], returned[1], 1600, PATH)
	var highlights: Array = report["highlights"]
	check(not highlights.is_empty() and highlights.size() <= 3, "return selects at most three actual highlights")
	check(int(report["kills"]) == returned[0].total_kills and int(report["gold"]) == returned[0].gold, "highlight selection preserves aggregate rewards")
	var again := pair()
	var repeated := Persistence.load_and_advance(again[0], again[1], 1600, PATH)
	check(repeated["highlights"].is_empty() and int(repeated["kills"]) == 0, "immediate reopen repeats neither highlights nor rewards")
	var long_return := pair()
	var long_report := Persistence.load_and_advance(long_return[0], long_return[1], 1600 + 7 * 86400, PATH)
	check(long_report["highlights"].size() <= 3 and long_return[0].chronicle.entries.size() <= Chronicle.LIMIT, "seven-day catch-up keeps return and history bounded")
	print("Seven-day chronicle catch-up: %d ms" % int(long_report["catch_up_msec"]))
	clean()
	print("Chronicle tests complete: %d failure(s)" % failures)
	quit(failures)
