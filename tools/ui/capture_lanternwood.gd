extends SceneTree

# Run only in an isolated review project, never against a player's ordinary save.
# Captures the actual main scene at its portrait window size.
const Persistence = preload("res://src/state/persistence.gd")
var main: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) == "Idle RPG":
		push_error("Use an isolated review project for captures.")
		quit(1)
		return
	var user_dir := DirAccess.open("user://")
	var aside: Array[String] = []
	for path in Persistence.files_for():
		if FileAccess.file_exists(path):
			user_dir.rename(path, path + ".lantern_aside")
			aside.append(path)
	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var sim: Node = main.sim
	main.game.presentation.larger_text = true
	main.game.presentation.reduced_motion = true
	main.presentation_controller.apply()
	sim.identity.rename("Moss Walker")
	sim.add_gear("Iron Sword")
	sim.equip_gear("Iron Sword")
	sim.add_gear("Briarheart Charm")
	sim.equip_gear("Briarheart Charm")
	sim.fishing.prepared = 1
	main._open_chronicle_destination("expedition", "")
	main.expedition_panel.tabs["hollow"].pressed.emit()
	await snap("lantern_01_locked")
	sim.expedition.claimed_routes["greenway"] = true
	main.expedition_panel.refresh()
	await snap("lantern_02_prepare")
	main._close_drawers()
	main.event_label.visible = false
	sim.request_expedition("hollow")
	sim._begin_quest_cycle()
	sim.expedition.node = 0
	sim.expedition.remainder_usec = 165000000
	sim.hero_position = Vector3(11.25, 0, 9.8)
	main._sync_world(100)
	await snap("lantern_03_gate")
	sim.expedition.node = 1
	sim.expedition.remainder_usec = 170000000
	sim.hero_position = Vector3(14.75, 0, 10.9)
	main._sync_world(100)
	await snap("lantern_04_moths")
	sim.expedition.node = 4
	sim.expedition.remainder_usec = 170000000
	sim.hero_position = Vector3(19.7, 0, 11.2)
	main._sync_world(100)
	await snap("lantern_05_keeper")
	# Fresh settled state for the earned look, not a fabricated completion recap.
	sim.expedition.abort()
	sim.expedition.selected_route = "hollow"
	sim.expedition.requested = true
	sim._begin_quest_cycle()
	sim.simulate_offline(900)
	main._open_chronicle_destination("expedition", "")
	main.expedition_panel.mode_tabs["story"].pressed.emit()
	await snap("lantern_06_rewards")
	main._open_chronicle_destination("wardrobe", "")
	main.wardrobe_panel.slot = "weapon"
	main.wardrobe_panel.select("lantern_crook")
	await snap("lantern_07_crook")
	main.wardrobe_panel.wear_button.pressed.emit()
	sim.expedition.claimed_routes["causeway"] = true
	sim.fishing.prepared = 1
	sim.request_expedition("rise")
	sim._begin_quest_cycle()
	sim.simulate_offline(1800)
	main.wardrobe_panel.slot = "head"
	main.wardrobe_panel.select("keeper_crown")
	await snap("lantern_08_crown")
	main.set_process(false)
	main.free()
	await create_timer(.3).timeout
	for path in Persistence.files_for():
		if FileAccess.file_exists(path):
			user_dir.remove(path)
	for path in aside:
		user_dir.rename(path + ".lantern_aside", path)
	quit()

func snap(name_: String) -> void:
	main._refresh_sim_ui()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/review/" + name_ + ".png")
	print("Saved ", name_)
