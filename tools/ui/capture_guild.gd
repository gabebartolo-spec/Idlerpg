extends SceneTree
# Actual player sheets against a disposable listening service. Never normal saves.
const Persistence = preload("res://src/state/persistence.gd")
const Client = preload("res://src/services/playtest_client.gd")
var main: Node
var panel: Control
var paths: Array[String] = []
var aside: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func wait_online() -> void:
	while panel.online.busy:
		await create_timer(.01).timeout

func press(id: String) -> void:
	panel.buttons[id].pressed.emit()
	await wait_online()

func _run() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) == "Idle RPG" or OS.get_environment("IDLE_TEST_URL").is_empty():
		push_error("Use disposable server and isolated review project")
		quit(1)
		return
	paths = Persistence.files_for()
	for suffix in ["", ".tmp", ".bak"]:
		paths.append("user://idle_rpg_online.json" + suffix)
	for path_ in paths:
		if FileAccess.file_exists(path_ + ".guild_aside"):
			push_error("Restore the previous isolated capture before retrying")
			quit(1)
			return
	for path_ in paths:
		if FileAccess.file_exists(path_):
			DirAccess.rename_absolute(path_, path_ + ".guild_aside")
			aside.append(path_)
	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.game.presentation.larger_text = true
	main.game.presentation.reduced_motion = true
	main.presentation_controller.apply()
	main.sim.identity.rename("Moss Walker")
	main._open_chronicle_destination("guild", "")
	panel = main.guild_panel
	panel.online.connect_service(OS.get_environment("IDLE_TEST_URL"))
	panel.fields["name"].text = "Amber"
	await press("create")
	await press("saved_recovery")
	panel.fields["guild_name"].text = "Lamplighters"
	await press("create_guild")
	var invite: String = panel.online.guild["invite"]
	var peers: Array[Node] = []
	for name_ in ["Birch", "Cedar"]:
		var client := Client.new()
		main.add_child(client)
		client.configure(OS.get_environment("IDLE_TEST_URL"))
		await client.create_account(name_)
		await client.call_api(HTTPClient.METHOD_POST, "/v1/guild/join", {"invite": invite}, "join-guild")
		peers.append(client)
	await panel.online.sync()
	await snap("guild_01_roster")
	await press("go_raid")
	await press("start_raid")
	var path_ := "/v1/raids/" + str(panel.online.raids[0]["id"])
	await press("role_damage")
	await peers[0].call_api(HTTPClient.METHOD_POST, path_ + "/enroll", {"role": "protection", "build": "trail"}, "prepare-role")
	await peers[1].call_api(HTTPClient.METHOD_POST, path_ + "/enroll", {"role": "preparation", "build": "trail"}, "prepare-role")
	await panel.online.sync()
	await snap("guild_02_prepared")
	for attempt in range(100):
		await panel.online.sync()
		if panel.online.raids[0].get("result") is Dictionary:
			break
		await create_timer(.2).timeout
	await snap("guild_03_chest")
	await press("raid_open")
	await snap("guild_04_reveal")
	await press("wear")
	main._open_chronicle_destination("wardrobe", "")
	main.wardrobe_panel.slot = "weapon"
	main.wardrobe_panel.select("warden_lantern")
	await process_frame
	main.wardrobe_panel.list.scroll_to(main.wardrobe_panel.list.max_offset())
	await snap("guild_05_wearing")
	main.free()
	await create_timer(.3).timeout
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for path in aside:
		DirAccess.rename_absolute(path + ".guild_aside", path)
	quit()

func snap(id: String) -> void:
	main._refresh_sim_ui()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/review/" + id + ".png")
	print("Captured ", id)
