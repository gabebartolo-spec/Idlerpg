extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Persistence = preload("res://src/state/persistence.gd")
const Income = preload("res://src/state/earned_income.gd")
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
func _run() -> void:
	var watched := pair()
	var offline := pair()
	var state: Dictionary = watched[0].to_save_dict()
	offline[0].load_save_dict(state)
	watched[0].simulate_elapsed(86400.0)
	offline[0].simulate_offline(86400.0)
	check(watched[0].to_save_dict() == offline[0].to_save_dict(), "watched and offline income preserve exact authoritative parity")
	check(watched[0].income.total == 120, "one simulated day earns exactly 120 tokens")
	check(watched[1].collect_income(watched[0]) == 120 and watched[1].gacha_tokens == 370, "earned income settles into the existing wallet")
	check(watched[1].collect_income(watched[0]) == 0, "collecting again cannot duplicate income")
	var frequent := pair()
	for i in 144:
		frequent[0].income.advance(600.0)
		frequent[1].collect_income(frequent[0])
	check(frequent[1].gacha_tokens == watched[1].gacha_tokens, "frequent check-ins earn the same amount as one return")
	var bucket := Income.new()
	bucket.advance(719.9)
	var restored := Income.new()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(bucket.to_save_dict())))
	restored.advance(0.1)
	check(restored.total == 1 and restored.remainder_usec == 0, "partial earning buckets survive restart at their boundary")
	var before: Dictionary = watched[0].income.to_save_dict()
	for i in 50:
		watched[0]._complete_quest()
	check(watched[0].income.to_save_dict() == before, "extra quest completions cannot manufacture token income")
	var path := "user://test_income_return.json"
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var saved := pair()
	Persistence.save(saved[0], saved[1], 1000, path)
	var returned := pair()
	var report: Dictionary = Persistence.load_and_advance(returned[0], returned[1], 1000 + 10 * 86400, path)
	check(report["tokens"] == 840 and returned[1].gacha_tokens == 1090, "a capped long return earns seven days of income and reports it")
	var again := pair()
	var repeated: Dictionary = Persistence.load_and_advance(again[0], again[1], 1000 + 10 * 86400, path)
	check(repeated["tokens"] == 0 and again[1].gacha_tokens == returned[1].gacha_tokens, "reopening repeats neither income nor its return reward")
	var old: Dictionary = saved[0].to_save_dict()
	old.erase("income")
	returned[0].load_save_dict(old)
	check(returned[0].income.total == 0, "legacy accounts receive no invented retrospective income")
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Earned income tests complete: %d failure(s)" % failures)
	quit(failures)
