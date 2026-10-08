extends SceneTree

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

# The save and the backup files beside it, so the scene starts and ends clean.
# A save set aside as unreadable is left alone: it is someone's lost progress.
func _remove_saves() -> void:
	for path in PersistenceScript.files_for():
		if FileAccess.file_exists(path) and not path.ends_with(PersistenceScript.UNREADABLE_SUFFIX):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	_remove_saves()

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
	var safe: Control = instance.find_child("SafeArea", true, false)
	_check(safe != null and safe.is_ancestor_of(instance.get("equipment_panel")) and safe.is_ancestor_of(instance.get("hero_label")) and safe.is_ancestor_of(instance.get("talent_button")), "HUD, navigation and drawers share the safe display parent")
	_check(instance.get("talent_panel") != null, "main scene creates the talent drawer")
	_check(instance.get("gacha_collection_view") != null, "main scene creates the gacha collection view")
	_check(instance.get("gacha_history_view") != null, "main scene creates the summon history view")
	_check(instance.get("companion_visual") != null, "main scene creates the companion presentation root")
	_check(instance.get("talent_button") != null, "main scene creates the talent action button")
	_check(instance.get("talent_proc_visual") != null, "main scene creates a talent proc visual")
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

		game.set_dev_infinite_tokens(true)
		instance.call("_select_banner", "companions")
		instance.call("_summon", 1)
		await process_frame
		var companion_latest: Dictionary = game.recent_summons(1)[0]
		var companion_name: String = str(companion_latest.get("name", ""))
		instance.set("selected_collection_item", companion_name)
		instance.call("_use_collection_item")
		await process_frame
		_check(sim.active_companion == companion_name, "collected companion can become the active authoritative companion")
		var companion_visual: Node3D = instance.get("companion_visual")
		_check(companion_visual.visible, "active companion is visible in the watched world")

		sim.hero_level = 2
		instance.call("_refresh_sim_ui")
		var talent_button: Button = instance.get("talent_button")
		_check(talent_button.text.contains("1"), "unspent talent points are surfaced on the main action row")

		instance.call("_unlock_talent", "heavy_hand")
		await process_frame
		_check(sim.has_talent("heavy_hand"), "talent drawer actions change the authoritative build")

		instance.call("_show_talent_proc", "slayer")
		var proc_visual: MeshInstance3D = instance.get("talent_proc_visual")
		_check(proc_visual.visible, "talent procs create watch-mode feedback")

		sim.reset_talents()
		sim.hero_level = 2
		instance.call("_show_return_report", {"loaded": true, "elapsed_actual": 120, "talent_points": 1})
		var return_talent_button: Button = instance.get("return_talent_button")
		_check(return_talent_button.visible, "offline talent gains create a direct return-screen action")
		instance.call("_open_talents_from_return")
		var talent_panel: Control = instance.get("talent_panel")
		_check(talent_panel.visible, "return-screen talent action opens the talent drawer")
		var future_message: String = instance.call("_format_return_report", {"newer_version": true, "save_lost": true})
		_check(future_message.contains("Update the game") and future_message.contains("left untouched"), "future-version saves explain how to continue without claiming lost progress")

	sim.add_gear("Crownblade")
	var gear_panel: Control = instance.get("equipment_panel")
	gear_panel.worn_only = true
	gear_panel.set_slot_filter("head")
	instance.call("_show_return_report", {"loaded": true, "elapsed_actual": 100, "highlights": sim.chronicle.highlights_since(0)})
	var report_panel: Control = instance.get("return_panel")
	_check(report_panel.visible and not instance.get("talent_panel").visible, "return report uses a single overlay")
	instance.call("_open_chronicle_destination", "gear", "Crownblade")
	_check(gear_panel.visible and gear_panel.selected == "Crownblade" and not report_panel.visible, "gear highlights open the item despite previous filters")
	instance.call("_open_chronicle_destination", "companion", "Stable Hound")
	_check(instance.get("gacha_panel").visible and instance.get("gacha_panel").banner == "companions", "bond highlights open companion management")
	instance.call("_open_chronicle_destination", "boss", "")
	_check(instance.get("boss_panel").visible and not instance.get("gacha_panel").visible, "boss highlights open boss management alone")
	instance.call("_open_chronicle_destination", "chronicle", "")
	_check(instance.get("chronicle_panel").visible and not instance.get("boss_panel").visible, "chronicle opens with other overlays closed")
	instance.set_process(false)
	var before_options: Dictionary = sim.to_save_dict()
	instance.call("_toggle_sheet", instance.get("menu_panel"))
	var menu: Control = instance.get("menu_panel")
	_check(menu.visible and menu.routes.has("practice") and menu.routes.has("journal") and not instance.get("chronicle_panel").visible, "More menu keeps the full game reachable in one overlay")
	menu.options_button.pressed.emit()
	var options: Control = instance.get("options_panel")
	_check(options.visible and not menu.visible, "More opens options without stacked sheets")
	options.text_button.pressed.emit()
	options.motion_button.pressed.emit()
	await process_frame
	_check(instance.get("game").presentation.larger_text and instance.get("game").presentation.reduced_motion, "options actions change both saved comfort preferences")
	_check(sim.to_save_dict() == before_options, "changing live presentation leaves every simulated outcome unchanged")
	_check(instance.get("hero_visual").reduced_motion and not instance.get("talent_proc_visual").visible, "reduced motion reaches the real watched hero and suppresses optional pulses")
	options.music_button.pressed.emit()
	_check(instance.get("trail_audio").music_player.playing and not instance.get("trail_audio").effect_player.playing, "Options independently enables the real trail music")
	options.sounds_button.pressed.emit()
	_check(instance.get("game").presentation.sounds and sim.to_save_dict() == before_options, "live audio choices preserve all combat/economy state")
	options.music_button.pressed.emit()
	_check(not instance.get("trail_audio").music_player.playing, "Options stops trail music immediately")
	instance.call("_toggle_sheet", menu)
	for destination in ["fishing", "practice", "adventure", "builds", "identity", "journal"]:
		menu.routes[destination].pressed.emit()
		var panel_name: String = {"adventure": "adventure_panel", "builds": "loadout_panel", "identity": "identity_panel", "journal": "journal_panel", "fishing": "fishing_panel", "practice": "practice_panel"}[destination]
		_check(instance.get(panel_name).visible and not menu.visible, "More route opens " + destination)
		instance.call("_toggle_sheet", menu)
	sim.add_gear("Wolfskin Hood")
	menu.routes["wardrobe"].pressed.emit()
	var wardrobe: Control = instance.get("wardrobe_panel")
	_check(wardrobe.visible and not menu.visible, "More opens the wardrobe preview")
	wardrobe.select("wolf_hood")
	wardrobe.wear_button.pressed.emit()
	_check(instance.get("hero_visual").worn_names["head"] == "Wolfskin Hood", "worn appearance matches the real watched adventurer")
	wardrobe.clear_button.pressed.emit()
	_check(instance.get("hero_visual").worn_names["head"] == sim.equipped_item("head"), "clearing appearance restores the actual equipment model")
	instance.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	_remove_saves()

	print("Launch smoke tests complete: %d failure(s)" % failures)
	quit(failures)
