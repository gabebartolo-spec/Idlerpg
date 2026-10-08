extends SceneTree

# Management UI review: runs the real main scene with a full inventory and saves
# screenshots of the gear, talent, gacha and boss sheets. Needs a window, so run it without --headless:
#   godot --path . -s res://tools/ui/capture.gd
# Writes art/review/ui_*.png. Moves the player's save aside while it runs.

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")

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

	# A lost boss fight to explain, then a world item in the gear screen.
	sim.unequip_gear("Briarheart Charm")
	sim.thornback_rank = 30
	sim.quest_kind = "briarfen"
	sim._start_fight("thornback")
	while sim.activity == "fighting":
		sim.advance(0.1)
	var boss: Control = main.get("boss_panel")
	main.call("_toggle_boss")
	await _snap("boss_lost")
	for key in boss.row_actions:
		if boss.row_actions[key]["action"] == "equip":
			boss.select(key)
			break
	await _snap("boss_suggestion")
	boss.list.scroll_to(boss.list.max_offset())
	boss.select("hunt:briarhook")
	await _snap("boss_hunts")
	main.call("_toggle_equipment")
	gear.set_slot_filter("weapon")
	gear.select("Briarhook")
	await _snap("gear_world_item")
	gear.set_slot_filter("")
	gear.select("Crownblade")
	gear._toggle_favourite()
	gear._toggle_sort()
	await _snap("gear_upgrades")
	gear._toggle_worn()
	await _snap("gear_worn")
	gear._toggle_worn()
	gear.select("Crownblade")
	gear._sell_selected()
	await _snap("gear_confirm_sale")
	gear._cancel_disposal()

	main.call("_toggle_sheet", main.get("chronicle_panel"))
	await _snap("chronicle")
	main.call("_show_return_report", {"loaded": true, "elapsed_actual": 7200, "quests": 24, "kills": 120, "gold": 950,
		"highlights": sim.chronicle.highlights_since(0), "levels": 3, "talent_points": 3,
		"gear": {"Briarheart Charm": 1, "Crownblade": 1}})
	await _snap("return_highlights")

	main.call("_toggle_gacha")
	gacha.select_banner("gear")
	gacha.show_mode("pursuit")
	gacha.pursuit_selected = "Crownblade"
	gacha.refresh()
	await _snap("collection_pursuit")
	gacha._choose_pursuit()
	if game.pursuits.has("gear"):
		game.pursuits["gear"]["progress"] = 12
	gacha.refresh()
	await _snap("pursuit_progress")
	for item in game.collection_items("gear"):
		game.collection["gear"][item] = 1
	game.pursuits.erase("gear")
	game.duplicate_counts["gear"] = 50
	gacha.refresh()
	await _snap("collection_keepsake")
	main.call("_toggle_sheet", main.get("journal_panel"))
	sim.journal.unlock("campfire_mark", sim)
	main.get("journal_panel").refresh()
	await _snap("field_journal")
	sim.identity.rename("Moss Walker")
	sim.identity.set_palette("moss")
	sim.identity.choose_title("thornbreaker", sim)
	main.call("_toggle_sheet", main.get("identity_panel"))
	await _snap("adventurer_identity")
	main.call("_close_drawers")
	sim.hero_hp = sim.effective_max_hp()
	sim.activity = "idle"
	sim.unequip_gear("Knight Mail")
	await _snap("identity_watch")
	game.set_dev_infinite_tokens(false)
	main.call("_toggle_gacha")
	gacha.show_mode("summon")
	await _snap("earned_token_countdown")

	main.free()
	for path in PersistenceScript.files_for():
		if FileAccess.file_exists(path):
			user_dir.remove(path)
	for path in set_aside:
		user_dir.rename(path + ASIDE, path)
	quit()

func _snap(label: String) -> void:
	for frame in 20:
		await process_frame
	shot += 1
	var path := "res://art/review/ui_%d_%s.png" % [shot, label]
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Saved ", path)
