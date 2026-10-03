extends SceneTree

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")

const TEST_PATH := "user://idle_rpg_persistence_test.json"

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var original_game: Node = GameStateScript.new()
	var original_sim: Node = AdventurerSimScript.new()
	root.add_child(original_game)
	root.add_child(original_sim)

	original_sim.simulate_elapsed(13.4)
	original_game.gacha_tokens = 123
	original_game.pity["gear"] = 17

	var saved_sim: Dictionary = original_sim.to_save_dict()
	var saved_game: Dictionary = original_game.to_save_dict()
	_check(PersistenceScript.save(original_sim, original_game, 1000, TEST_PATH), "save writes successfully")

	var loaded_game: Node = GameStateScript.new()
	var loaded_sim: Node = AdventurerSimScript.new()
	root.add_child(loaded_game)
	root.add_child(loaded_sim)

	var report: Dictionary = PersistenceScript.load_and_advance(loaded_sim, loaded_game, 1120, TEST_PATH)
	_check(bool(report.get("loaded", false)), "saved game loads")
	_check(int(report.get("elapsed_actual", -1)) == 120, "offline elapsed time is measured")
	_check(int(report.get("elapsed_simulated", -1)) == 120, "normal offline interval is fully simulated")
	_check(loaded_game.gacha_tokens == 123, "gacha wallet survives save/load")
	_check(int(loaded_game.pity.get("gear", 0)) == 17, "gacha pity survives save/load")

	var control_game: Node = GameStateScript.new()
	var control_sim: Node = AdventurerSimScript.new()
	root.add_child(control_game)
	root.add_child(control_sim)
	control_sim.load_save_dict(saved_sim)
	control_game.load_save_dict(saved_game)
	control_sim.simulate_elapsed(120.0)

	_check(loaded_sim.hero_level == control_sim.hero_level, "offline and direct simulation reach the same level")
	_check(loaded_sim.hero_xp == control_sim.hero_xp, "offline and direct simulation retain the same XP")
	_check(loaded_sim.gold == control_sim.gold, "offline and direct simulation grant the same gold")
	_check(loaded_sim.total_kills == control_sim.total_kills, "offline and direct simulation record the same kills")
	_check(loaded_sim.quest_cycles_completed == control_sim.quest_cycles_completed, "offline and direct simulation complete the same quests")
	_check(loaded_sim.inventory == control_sim.inventory, "offline and direct simulation produce the same loot")
	_check(int(report.get("kills", 0)) > 0, "return report includes offline kills")
	_check(int(report.get("gold", 0)) > 0, "return report includes offline gold")
	_check(int(report.get("talent_points", -1)) == int(report.get("levels", -2)), "offline level gains expose the same number of new talent decisions")

	var second_game: Node = GameStateScript.new()
	var second_sim: Node = AdventurerSimScript.new()
	root.add_child(second_game)
	root.add_child(second_sim)
	var second_report: Dictionary = PersistenceScript.load_and_advance(second_sim, second_game, 1120, TEST_PATH)
	_check(int(second_report.get("elapsed_actual", -1)) == 0, "advanced state checkpoints immediately after return")
	_check(int(second_report.get("kills", -1)) == 0, "same offline interval cannot duplicate kills")
	_check(int(second_report.get("gold", -1)) == 0, "same offline interval cannot duplicate rewards")
	_check(second_sim.total_kills == loaded_sim.total_kills, "reopen at same timestamp preserves advanced state exactly")

	var absolute_path := ProjectSettings.globalize_path(TEST_PATH)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(absolute_path)

	print("Persistence tests complete: %d failure(s)" % failures)
	quit(failures)
