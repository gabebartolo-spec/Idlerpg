extends SceneTree

# Management UI review: runs the real main scene with a full inventory and saves
# screenshots of the gear, talent and gacha sheets. Needs a window, so run it without --headless:
#   godot --path . -s res://tools/ui/capture.gd
# Writes art/review/ui_*.png. Moves the player's save aside while it runs.

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")

const SAVE_PATH := "user://idle_rpg_save.json"
const BACKUP_PATH := "user://idle_rpg_save.capture_backup.json"

var main: Node
var shot: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var user_dir := DirAccess.open("user://")
	var had_save := FileAccess.file_exists(SAVE_PATH)
	if had_save:
		user_dir.rename(SAVE_PATH, BACKUP_PATH)

	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame

	var sim: Node = main.get("sim")
	var game: Node = main.get("game")
	for item_name in GearCatalogScript.ITEMS:
		sim.add_gear(item_name)
	for item_name in ["Iron Sword", "Leather Hood", "Knight Mail", "Trail Boots", "Oak Buckler"]:
		sim.equip_gear(item_name)
	game.set_dev_infinite_tokens(true)
	main.call("_select_banner", "companions")
	main.call("_summon", 10)
	main.call("_select_banner", "gear")

	var gear: Control = main.get("equipment_panel")
	main.call("_toggle_equipment")
	await _snap("gear_browse")
	gear.select("Moonsteel Blade")
	await _snap("gear_compare")
	gear.list.scroll_to(gear.list.max_offset())
	gear.select("Worldwalker Boots")
	await _snap("gear_end_of_list")
	gear.set_slot_filter("chest")
	gear.select("Titanheart Plate")
	await _snap("gear_filtered")
	gear.set_slot_filter("")
	main.call("_toggle_equipment")

	sim.hero_level = 4
	var talents: Control = main.get("talent_panel")
	main.call("_toggle_talents")
	await _snap("talents")
	talents.unlock("heavy_hand")
	talents.select("sharpened_edge")
	await _snap("talents_selected")
	main.call("_toggle_talents")

	var gacha: Control = main.get("gacha_panel")
	main.call("_toggle_gacha")
	main.call("_summon", 10)
	await _snap("gacha_summon")
	main.call("_select_banner", "companions")
	main.call("_show_gacha_mode", "collection")
	gacha.select_item(str(game.recent_summons(40)[0].get("name", "")))
	for item_name in game.collection_items("companions"):
		if game.collection_count("companions", item_name) > 0:
			gacha.select_item(item_name)
			break
	await _snap("gacha_collection")
	main.call("_show_gacha_mode", "history")
	await _snap("gacha_history")

	main.free()
	if FileAccess.file_exists(SAVE_PATH):
		user_dir.remove(SAVE_PATH)
	if had_save:
		user_dir.rename(BACKUP_PATH, SAVE_PATH)
	quit()

func _snap(label: String) -> void:
	for frame in 20:
		await process_frame
	shot += 1
	var path := "res://art/review/ui_%d_%s.png" % [shot, label]
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Saved ", path)
