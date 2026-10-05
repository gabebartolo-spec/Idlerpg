extends SceneTree

# IRPG-R02: saves survive damage, interruption, old versions and clock changes, the gacha
# cannot be rerolled by reloading, and offline catch-up gives exactly what stepping gives.

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")

const SUFFIXES := ["", ".tmp", ".bak", ".unreadable"]

var failures: int = 0
var paths: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _path(label: String) -> String:
	var path := "user://test_resilience_%s.json" % label
	paths.append(path)
	_remove(path)
	return path

func _remove(path: String) -> void:
	for suffix in SUFFIXES:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func _pair() -> Array:
	var game: Node = GameStateScript.new()
	var sim: Node = AdventurerSimScript.new()
	root.add_child(game)
	root.add_child(sim)
	return [sim, game]

func _draw_names(game: Node, count: int) -> Array:
	var names: Array = []
	for result in game.pull("gear", count)["results"]:
		names.append(result["name"])
	return names

func _run() -> void:
	_test_catch_up_parity()
	_test_catch_up_speed()
	_test_version_one()
	_test_random_state()
	_test_backup_recovery()
	_test_unreadable()
	_test_interrupted_write()
	_test_clock_rollback()
	_test_save_failure()
	for path in paths:
		_remove(path)
	print("Save resilience tests complete: %d failure(s)" % failures)
	quit(failures)

# --- catch-up ----------------------------------------------------------------

func _states() -> Dictionary:
	var states := {}
	var fresh: Node = _pair()[0]
	states["a new adventurer"] = fresh.to_save_dict()

	var early: Node = _pair()[0]
	early.simulate_elapsed(13.4)
	states["mid-fight on the first quest"] = early.to_save_dict()

	# A developed build: gear, talents and a companion whose bond is still growing.
	var built: Node = _pair()[0]
	built.simulate_elapsed(900.0)
	for item_name in ["Crownblade", "Knight Mail", "Trail Boots", "Oak Buckler"]:
		built.add_gear(item_name)
		built.equip_gear(item_name)
	for talent_id in ["heavy_hand", "sharpened_edge", "thick_hide", "quick_hands", "trail_legs", "opening_strike", "hunter_eye"]:
		built.unlock_talent(talent_id)
	built.set_active_companion("Clockwork Raven")
	built.simulate_elapsed(7.7)
	states["a geared build with a companion"] = built.to_save_dict()
	return states

func _test_catch_up_parity() -> void:
	var states := _states()
	for label in states:
		for seconds in [0.05, 7.3, 59.95, 600.0, 7200.0, 60000.0]:
			var stepped: Node = _pair()[0]
			var caught_up: Node = _pair()[0]
			stepped.load_save_dict(states[label])
			caught_up.load_save_dict(states[label])
			stepped.simulate_elapsed(seconds)
			caught_up.simulate_offline(seconds)
			_check(caught_up.to_save_dict() == stepped.to_save_dict(), "catch-up matches stepping for %s over %s s" % [label, str(seconds)])
			stepped.free()
			caught_up.free()

func _test_catch_up_speed() -> void:
	var day_one: Node = _pair()[0]
	day_one.simulate_offline(86400.0)
	var state: Dictionary = day_one.to_save_dict()

	var stepped: Node = _pair()[0]
	stepped.load_save_dict(state)
	var started := Time.get_ticks_msec()
	stepped.simulate_elapsed(86400.0)
	var stepped_msec := Time.get_ticks_msec() - started

	var caught_up: Node = _pair()[0]
	caught_up.load_save_dict(state)
	started = Time.get_ticks_msec()
	caught_up.simulate_offline(86400.0)
	var day_msec := Time.get_ticks_msec() - started
	_check(caught_up.to_save_dict() == stepped.to_save_dict(), "catch-up matches stepping over a whole day at high level")

	var week: Node = _pair()[0]
	week.load_save_dict(state)
	started = Time.get_ticks_msec()
	week.simulate_offline(7.0 * 86400.0)
	var week_msec := Time.get_ticks_msec() - started
	print("One day: stepping %d ms, catch-up %d ms. Seven-day catch-up: %d ms, reaching level %d." % [stepped_msec, day_msec, week_msec, week.hero_level])
	_check(day_msec * 4 < stepped_msec, "catch-up is at least four times faster than stepping")
	_check(week_msec < 3000, "a seven-day catch-up takes under three seconds here")

# --- save files --------------------------------------------------------------

func _test_version_one() -> void:
	var path := _path("v1")
	var pair := _pair()
	pair[0].simulate_elapsed(40.0)
	pair[1].gacha_tokens = 77
	var old_game: Dictionary = pair[1].to_save_dict()
	old_game.erase("rng_seed")
	old_game.erase("rng_state")
	_write(path, JSON.stringify({"version": 1, "saved_unix": 1000, "sim": pair[0].to_save_dict(), "game": old_game}))

	var loaded := _pair()
	var report: Dictionary = PersistenceScript.load_and_advance(loaded[0], loaded[1], 1000, path)
	_check(bool(report.get("loaded", false)), "a version 1 save loads")
	_check(int(report.get("migrated_from", 0)) == 1, "the return reports that it was migrated")
	_check(loaded[1].gacha_tokens == 77 and loaded[0].total_kills == pair[0].total_kills, "a version 1 save keeps its progress")
	var rewritten: Dictionary = JSON.parse_string(_text(path))
	_check(int(rewritten["version"]) == PersistenceScript.SAVE_VERSION and rewritten["game"].has("rng_state"), "it is rewritten in the current format")

func _test_random_state() -> void:
	var path := _path("rng")
	var pair := _pair()
	pair[1].set_seed(99)
	pair[1].gacha_tokens = 10000
	_draw_names(pair[1], 7)
	PersistenceScript.save(pair[0], pair[1], 2000, path)
	var expected := _draw_names(pair[1], 12)

	for attempt in 2:
		var reloaded := _pair()
		PersistenceScript.load_and_advance(reloaded[0], reloaded[1], 2000, path)
		_check(_draw_names(reloaded[1], 12) == expected, "reloading gives the same next draws, attempt %d" % (attempt + 1))

func _test_backup_recovery() -> void:
	var path := _path("backup")
	var pair := _pair()
	pair[1].gacha_tokens = 111
	_check(PersistenceScript.save(pair[0], pair[1], 3000, path), "the first save succeeds")
	pair[1].gacha_tokens = 222
	_check(PersistenceScript.save(pair[0], pair[1], 3010, path), "the second save succeeds")
	_check(FileAccess.file_exists(path + ".bak") and not FileAccess.file_exists(path + ".tmp"), "saving keeps the previous save as a backup and leaves no temporary file")

	var whole := _text(path)
	_write(path, whole.substr(0, whole.length() / 2))
	var loaded := _pair()
	var report: Dictionary = PersistenceScript.load_and_advance(loaded[0], loaded[1], 3020, path)
	_check(bool(report.get("loaded", false)) and bool(report.get("recovered_from_backup", false)), "a truncated save falls back to the backup and says so")
	_check(loaded[1].gacha_tokens == 111, "the backup's state is what loads")
	_check(int(report.get("elapsed_actual", -1)) == 20, "time away is counted from the backup's own timestamp")

	var again := _pair()
	var second: Dictionary = PersistenceScript.load_and_advance(again[0], again[1], 3020, path)
	_check(bool(second.get("loaded", false)) and not second.has("recovered_from_backup"), "after recovery the save is whole again")
	_check(int(second.get("elapsed_actual", -1)) == 0 and int(second.get("kills", -1)) == 0, "reloading after recovery replays nothing")

func _test_unreadable() -> void:
	var path := _path("unreadable")
	_write(path, "{ this is not a save")
	var loaded := _pair()
	var report: Dictionary = PersistenceScript.load_and_advance(loaded[0], loaded[1], 4000, path)
	_check(not bool(report.get("loaded", true)) and bool(report.get("save_lost", false)), "an unreadable save with no backup is reported as lost")
	_check(bool(report.get("kept_copy", false)) and _text(path + ".unreadable") == "{ this is not a save", "the unreadable file is kept, untouched")
	_check(not FileAccess.file_exists(path), "the new game starts from a clean save path")

	var newer := _path("newer")
	_write(newer, JSON.stringify({"version": 99, "saved_unix": 4000, "sim": {}, "game": {}}))
	var newer_report: Dictionary = PersistenceScript.load_and_advance(loaded[0], loaded[1], 4000, newer)
	_check(bool(newer_report.get("save_lost", false)) and str(newer_report.get("error", "")).contains("newer"), "a save from a newer version is refused, with the reason")
	_check(FileAccess.file_exists(newer + ".unreadable"), "and kept, so an older build cannot overwrite it")

func _test_interrupted_write() -> void:
	var path := _path("interrupted")
	var pair := _pair()
	pair[1].gacha_tokens = 333
	PersistenceScript.save(pair[0], pair[1], 5000, path)
	_write(path + ".tmp", "{\"version\": 2, \"saved_un")
	var loaded := _pair()
	var report: Dictionary = PersistenceScript.load_and_advance(loaded[0], loaded[1], 5000, path)
	_check(bool(report.get("loaded", false)) and not report.has("recovered_from_backup") and loaded[1].gacha_tokens == 333, "a half-written temporary file is ignored when the save is whole")

	# A crash after the old save was moved aside but before the new one was swapped in.
	var swap := _path("swap")
	pair[1].gacha_tokens = 444
	PersistenceScript.save(pair[0], pair[1], 5100, swap)
	pair[1].gacha_tokens = 555
	PersistenceScript.save(pair[0], pair[1], 5110, swap)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(swap), ProjectSettings.globalize_path(swap + ".tmp"))
	var resumed := _pair()
	var swap_report: Dictionary = PersistenceScript.load_and_advance(resumed[0], resumed[1], 5110, swap)
	_check(bool(swap_report.get("loaded", false)) and resumed[1].gacha_tokens == 555, "a complete temporary file is used ahead of the older backup")

func _test_clock_rollback() -> void:
	var path := _path("clock")
	var pair := _pair()
	PersistenceScript.save(pair[0], pair[1], 9000, path)

	var back := _pair()
	var report: Dictionary = PersistenceScript.load_and_advance(back[0], back[1], 8000, path)
	_check(bool(report.get("clock_rollback", false)) and int(report.get("elapsed_simulated", -1)) == 0, "a clock behind the save is reported and counts no time")

	# Playing and saving while the clock is wrong must not move the timestamp back.
	PersistenceScript.save(back[0], back[1], 8200, path)
	var forward := _pair()
	var forward_report: Dictionary = PersistenceScript.load_and_advance(forward[0], forward[1], 9100, path)
	_check(int(forward_report.get("elapsed_actual", -1)) == 100, "putting the clock right counts only the time since the real last save, not since the rollback")

func _test_save_failure() -> void:
	var pair := _pair()
	_check(not PersistenceScript.save(pair[0], pair[1], 100, "user://no_such_folder/save.json"), "a save that cannot be written reports failure")
