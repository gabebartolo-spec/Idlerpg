extends SceneTree
const Persistence = preload("res://src/state/persistence.gd")
const Trails = preload("res://src/data/expedition_catalog.gd")
var main: Node
func _init() -> void:
	call_deferred("run")
func run() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) == "Idle RPG":
		push_error("Use an isolated review project.")
		quit(1)
		return
	var paths: Array[String] = Persistence.files_for()
	paths.append_array(["user://idle_rpg_online.json", "user://idle_rpg_online.json.tmp", "user://idle_rpg_online.json.bak"])
	for path in paths:
		if FileAccess.file_exists(path + ".build_aside"):
			push_error("Restore existing capture aside before running.")
			quit(1)
			return
	var aside: Array[String] = []
	for path in paths:
		if FileAccess.file_exists(path):
			if DirAccess.rename_absolute(path, path + ".build_aside") != OK:
				for saved in aside: DirAccess.rename_absolute(saved + ".build_aside", saved)
				quit(1)
				return
			aside.append(path)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.game.presentation.larger_text = true
	main.game.presentation.reduced_motion = true
	main.presentation_controller.apply()
	var sim: Node = main.sim
	sim.add_gear("Briarheart Charm")
	sim.discovered["Briarheart Charm"] = true
	sim.equip_gear("Briarheart Charm")
	sim.add_gear("Goblin Cleaver")
	sim.equip_gear("Goblin Cleaver")
	sim.add_gear("Wolfskin Hood")
	sim.equip_gear("Wolfskin Hood")
	# Review fixture opens existing region gates; new reward ownership is earned.
	for route in ["greenway", "causeway", "hollow", "rise"]:
		sim.expedition.claimed_routes[route] = true
		sim.expedition.route_clears[route] = 1
	for route in ["mothwatch", "moonwell", "lamplighter"]:
		main._open_chronicle_destination("expedition", "")
		main.expedition_panel.tabs[route].pressed.emit()
		await snap(route + "_pursuit")
		sim.request_expedition(route)
		sim._begin_quest_cycle()
		# Hours of simulated travel outlast the previous five-second HUD notice.
		main.event_clock = 0
		sim.simulate_offline(Trails.node_usec(route) * 5 / 1000000.0)
		main._open_chronicle_destination("rewards", "")
		main.reward_panel.action_button.pressed.emit()
		await snap(route + "_reveal")
		main.reward_panel.wear_button.pressed.emit()
		await snap(route + "_equipped")
		# Keep the earned starter preparation constant for the next reviewed trail.
		sim.unequip_gear(Trails.ROUTES[route]["gear"])
		sim.equip_gear("Briarheart Charm")
		sim.equip_gear("Goblin Cleaver")
	main._open_chronicle_destination("expedition", "")
	main.expedition_panel.mode_tabs["builds"].pressed.emit()
	await snap("build_ideas")
	for child in main.expedition_panel.list.content.get_children():
		if child is Button and child.text == "Equip Guardian":
			child.pressed.emit()
			break
	await snap("guardian_recipe")
	var cursor: int = sim.chronicle.sequence
	for repeat in 2:
		main.event_clock = 0
		sim.request_expedition("lamplighter")
		sim._begin_quest_cycle()
		sim.simulate_offline(24 * 3600)
		if not sim.reward_chests.pending.is_empty(): sim.claim_reward_chest(sim.reward_chests.pending[0]["id"])
	main._close_drawers()
	main.return_panel.show_report({"highlights": sim.chronicle.highlights_since(cursor)}, "Two lamp circuits completed")
	await snap("mastery_return")
	main._open_chronicle_destination("identity", "lamp_master")
	for child in main.identity_panel.title_list.content.get_children():
		if child is Button and child.text == "Earned: Keeper of the Lamps":
			child.pressed.emit()
			break
	main.identity_panel.title_list.scroll_to(main.identity_panel.title_list.max_offset())
	await snap("mastery_profile")
	main.free()
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	for path in aside: DirAccess.rename_absolute(path + ".build_aside", path)
	quit()
func snap(id: String) -> void:
	main._refresh_sim_ui()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://art/review")
	root.get_texture().get_image().save_png("res://art/review/build_" + id + ".png")
