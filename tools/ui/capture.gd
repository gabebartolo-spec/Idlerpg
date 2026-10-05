extends SceneTree

# Management UI review: runs the real main scene with a full inventory and saves
# screenshots of the gear screen and the other drawers, and reports any drawer that does
# not fit on screen. Needs a window, so run it without --headless:
#   godot --path . -s res://tools/ui/capture.gd
# Writes art/review/ui_*.png. Moves the player's save aside while it runs.

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")

const PersistenceScript = preload("res://src/state/persistence.gd")
const ASIDE := ".capture_aside"

var main: Node
var shot: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Set the player's save and its backups aside; the scene must start from nothing.
	var user_dir := DirAccess.open("user://")
	var set_aside: Array[String] = []
	for path in PersistenceScript.files_for():
		if FileAccess.file_exists(path):
			user_dir.rename(path, path + ASIDE)
			set_aside.append(path)

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

	main.call("_toggle_talents")
	await _snap("talents")
	_report("talents", main.get("talent_panel"))
	main.call("_toggle_talents")

	main.call("_toggle_gacha")
	await _snap("gacha_summon")
	_report("gacha summon", main.get("gacha_panel"))
	main.call("_show_gacha_mode", "collection")
	await _snap("gacha_collection")
	_report("gacha collection", main.get("gacha_panel"))
	main.call("_show_gacha_mode", "history")
	await _snap("gacha_history")
	_report("gacha history", main.get("gacha_panel"))

	main.free()
	for path in PersistenceScript.files_for():
		if FileAccess.file_exists(path):
			user_dir.remove(path)
	for path in set_aside:
		user_dir.rename(path + ASIDE, path)
	quit()

func _report(label: String, panel: Control) -> void:
	var view := root.get_visible_rect()
	var rect := panel.get_global_rect()
	print("%-17s %s  top %d  bottom %d of %d" % [
		label, "fits" if view.encloses(rect) else "DOES NOT FIT", rect.position.y, rect.end.y, view.size.y])

func _snap(label: String) -> void:
	for frame in 20:
		await process_frame
	shot += 1
	var path := "res://art/review/ui_%d_%s.png" % [shot, label]
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Saved ", path)
