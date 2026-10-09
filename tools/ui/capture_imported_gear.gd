extends SceneTree
## Review only: uses the actual game and rig in an isolated project, restores saves.
const Persistence = preload("res://src/state/persistence.gd")
const Art = preload("res://src/data/art_catalog.gd")
var main: Node

func _init() -> void:
	call_deferred("run")

func run() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) != "Idle RPG Codex audit 30":
		push_error("Imported gear captures require the isolated review project.")
		quit(1)
		return
	var paths: Array[String] = Persistence.files_for()
	paths.append_array(["user://idle_rpg_online.json", "user://idle_rpg_online.json.tmp", "user://idle_rpg_online.json.bak"])
	for path in paths:
		if FileAccess.file_exists(path + ".gear_review_aside"):
			push_error("Restore the previous gear review's aside files first.")
			quit(1)
			return
	var aside: Array[String] = []
	for path in paths:
		if FileAccess.file_exists(path):
			if DirAccess.rename_absolute(path, path + ".gear_review_aside") != OK:
				for saved in aside:
					DirAccess.rename_absolute(saved + ".gear_review_aside", saved)
				quit(1)
				return
			aside.append(path)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.sim.set_process(false)
	main.hero_visual.set_process(false)
	for item in ["Crownblade", "Starforged Helm", "Titanheart Plate"]:
		main.sim.add_gear(item)
		main.sim.discovered[item] = true
		main.sim.equip_gear(item)
	main._sync_world(0.0)
	main._refresh_sim_ui()
	for imported in [false, true]:
		Art.imported_pilot_enabled = imported
		# Force cached equipment to reload after switching the session-only art branch.
		for slot in ["weapon", "head", "chest"]:
			main.hero_visual.set_equipment(slot, "")
		await process_frame
		main.hero_visual.set_equipment("weapon", "Crownblade")
		main.hero_visual.set_equipment("head", "Starforged Helm")
		main.hero_visual.set_equipment("chest", "Titanheart Plate")
		var prefix: String = "imported" if imported else "procedural"
		for state in ["idle", "walk", "attack"]:
			main.hero_visual.set_state(state)
			main.hero_visual.clock = 0.30
			main.hero_visual._process(0.0)
			await snap(prefix + "_" + state)
		var previous_transform: Transform3D = main.camera.transform
		main.camera.position = main.hero_visual.position + main.hero_visual.basis * Vector3(2.1, 1.8, 3.1)
		main.camera.look_at(main.hero_visual.position + Vector3(0.0, 1.0, 0.0))
		main.hero_visual.set_state("idle")
		main.hero_visual.clock = 0.30
		main.hero_visual._process(0.0)
		await snap(prefix + "_inspect")
		main.camera.transform = previous_transform
		for item in ["Crownblade", "Starforged Helm", "Titanheart Plate"]:
			main._open_chronicle_destination("gear", item)
			await snap(prefix + "_preview_" + item.to_lower().replace(" ", "_"))
			main._close_drawers()
	main.free()
	Art.imported_pilot_enabled = false
	await process_frame
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for path in aside:
		DirAccess.rename_absolute(path + ".gear_review_aside", path)
	quit()

func snap(id: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://art/review/legendary")
	root.get_texture().get_image().save_png("res://art/review/legendary/game_" + id + ".png")
	print("GEAR_REVIEW_CAPTURE ", id)
