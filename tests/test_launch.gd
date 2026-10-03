extends SceneTree

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
	var save_path := "user://idle_rpg_save.json"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	var packed: PackedScene = load("res://main.tscn")
	_check(packed != null, "main scene loads")
	if packed == null:
		quit(failures)
		return

	var instance: Node = packed.instantiate()
	_check(instance != null, "main scene instantiates")
	if instance == null:
		quit(failures)
		return

	root.add_child(instance)
	await process_frame
	await process_frame

	_check(instance.get("sim") != null, "main scene creates the adventurer simulation")
	_check(instance.get("hero_visual") != null, "main scene creates the watched 3D adventurer")
	_check(instance.get("activity_label") != null, "main scene creates current-activity UI")
	_check(instance.get("equipment_panel") != null, "main scene creates the equipment drawer")
	_check(instance.get("talent_panel") != null, "main scene creates the talent drawer")
	_check(instance.get("gacha_collection_view") != null, "main scene creates the gacha collection view")
	_check(instance.get("gacha_history_view") != null, "main scene creates the summon history view")
	_check(instance.get("weapon_visual") != null, "main scene creates a visible weapon slot")

	var sim: Node = instance.get("sim")
	if sim != null:
		_check(sim.activity in ["travelling", "fighting", "looting", "returning", "resting", "recovering"], "simulation is actively doing something")
		var before_gear: int = sim.owned_gear_names().size()
		instance.call("_select_banner", "gear")
		instance.call("_summon", 1)
		await process_frame
		_check(sim.owned_gear_names().size() >= before_gear + 1, "Gear gacha results become owned adventurer gear")

		var game: Node = instance.get("game")
		_check(game.collected_unique("gear") >= 1, "gear summons enter the persistent collection")
		_check(game.recent_summons(1).size() == 1, "summons enter visible history")
		instance.call("_show_gacha_mode", "collection")
		await process_frame
		_check(bool(instance.get("gacha_collection_view").visible), "collection mode can be opened")

		var latest: Dictionary = game.recent_summons(1)[0]
		var pulled_name: String = str(latest.get("name", ""))
		sim.add_gear(pulled_name)
		game.set_locked(pulled_name, true)
		instance.call("_select_gear_item", pulled_name)
		instance.call("_refresh_gear_detail")
		await process_frame
		var sell_button: Button = instance.get("sell_gear_button")
		_check(sell_button.disabled, "locked collected gear is protected from disposal")

		sim.hero_level = 2
		instance.call("_unlock_talent", "heavy_hand")
		await process_frame
		_check(sim.has_talent("heavy_hand"), "talent drawer actions change the authoritative build")

	instance.queue_free()
	await process_frame
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	print("Launch smoke tests complete: %d failure(s)" % failures)
	quit(failures)
