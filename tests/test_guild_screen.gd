extends SceneTree
# Live, disposable service only. Drive the actual screen controls across accounts.
const Screen = preload("res://src/ui/guild_screen.gd")
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Session = preload("res://src/services/online_session.gd")
var failures := 0
var host: Control
var panels: Array[Control] = []
var paths: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle(panel: Control) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while panel.online.busy and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	if not panel.online.busy:
		return
	check(false, "Online screen remained busy")

func press(panel: Control, id: String) -> void:
	check(panel.buttons.has(id), "Missing action " + id)
	if panel.buttons.has(id):
		check(not panel.buttons[id].disabled, "Disabled action " + id)
		panel.buttons[id].pressed.emit()
		await settle(panel)

func _run() -> void:
	if OS.get_environment("IDLE_TEST_URL").is_empty():
		push_error("Use server.verify_client; this test needs a disposable listening server")
		quit(1)
		return
	root.size = Vector2i(405, 720)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	host = Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.theme = load("res://src/ui/game_theme.tres")
	root.add_child(host)
	for i in range(3):
		var sim := Sim.new()
		var game := Game.new()
		host.add_child(sim)
		host.add_child(game)
		game.presentation.larger_text = true
		game.presentation.reduced_motion = true
		var screen := Screen.new()
		host.add_child(screen)
		var path_ := "user://guild_screen_test_" + str(i) + ".json"
		paths.append(path_)
		var clean := Session.new()
		clean.path = path_
		clean.discard()
		screen.setup(sim, game.presentation, path_)
		screen.online.connect_service(OS.get_environment("IDLE_TEST_URL"))
		screen.fields["name"].text = ["Amber", "Birch", "Cedar"][i]
		await press(screen, "create")
		check(not screen.online.recovery_key.is_empty(), "Recovery details were not offered")
		var saved := Session.new()
		saved.path = path_
		saved.load_session()
		check(not saved.data.has("recovery_key"), "Recovery secret persisted")
		check(saved.data.get("token", "") == screen.online.client.token, "Session did not survive restart")
		await press(screen, "saved_recovery")
		check(screen.online.build_catalog.get("trail", {}).get("attack", 0) == 12, "Raid build details did not come from the server")
		panels.append(screen)
		check(screen.sim.gold == 0, "Online login changed the solo wallet")
	var first: Control = panels[0]
	first.fields["guild_name"].text = "UI Lamplighters"
	await press(first, "create_guild")
	var invite: String = first.online.guild["invite"]
	for index in [1, 2]:
		panels[index].fields["invite"].text = invite
		await press(panels[index], "join_guild")
	await first.online.sync()
	check(first.online.guild["members"].size() == 3, "Screen roster is not shared")
	await press(first, "go_raid")
	await press(first, "start_raid")
	var raid_id: String = first.online.raids[0]["id"]
	for index in range(3):
		var screen: Control = panels[index]
		await screen.online.sync()
		screen.page = "raid"
		screen.refresh()
		await press(screen, "role_" + ["damage", "protection", "preparation"][index])
		check(not screen.online.session.data.has("pending"), "Committed action was not cleared")
	# The test service clock alone is accelerated. No uploaded device time.
	for attempt in range(100):
		await first.online.sync()
		if first.online.raids[0].get("result") is Dictionary:
			break
		await create_timer(0.2).timeout
	for screen in panels:
		await screen.online.sync()
		screen.page = "raid"
		screen.refresh()
		check(screen.online.raids[0].get("result", {}).get("won", false), "Screen did not catch up the raid")
		await press(screen, "raid_open")
		check(screen.online.reveal.get("gold", 0) == 60, "Chest reveal showed wrong reward")
		check(screen.sim.wardrobe.owned.has("warden_lantern"), "Server ownership did not restore appearance")
		await press(screen, "wear")
		check(screen.sim.wardrobe.equipped.get("weapon", "") == "warden_lantern", "Wear did not equip actual appearance")
		check(screen.sim.gold == 0, "Raid currency entered the untrusted solo wallet")
		await screen.online.action("/v1/raids/" + raid_id + "/open")
		check(int(screen.online.profile["gold"]) == 60, "Screen replay duplicated reward")
	# Recreate a controller from the persisted session, then restore appearance.
	var restored := Screen.new()
	host.add_child(restored)
	restored.setup(first.sim, first.settings, paths[0])
	await restored.online.sync()
	check(restored.online.profile.get("id", "") == first.online.client.account_id, "Restart lost account identity")
	check(int(restored.online.profile.get("gold", 0)) == 60, "Restart lost server rewards")
	# A committed chest whose HTTP response was interrupted: reconstruct the
	# persisted action, restart, then use the actual Retry button with the same key.
	var committed: Dictionary = await first.online.client.call_api(HTTPClient.METHOD_POST, "/v1/raids/" + raid_id + "/open", {}, "raid-uncertain-response")
	check(committed.get("ok", false), "Could not stage a committed uncertain response")
	first.online.session.data["pending"] = {"account": first.online.client.account_id, "path": "/v1/raids/" + raid_id + "/open", "body": {}, "key": "raid-uncertain-response"}
	check(first.online.session.save_session(), "Could not persist uncertain action")
	var retry_screen := Screen.new()
	host.add_child(retry_screen)
	retry_screen.setup(first.sim, first.settings, paths[0])
	await press(retry_screen, "retry")
	check(int(retry_screen.online.profile.get("gold", 0)) == 60, "Restart retry duplicated a committed reward")
	check(not retry_screen.online.session.data.has("pending"), "Restart retry was not cleared")
	# Real connection refusal, not a mocked opponent or reward response.
	var endpoint: String = retry_screen.online.client.endpoint
	retry_screen.online.client.endpoint = "http://127.0.0.1:1"
	await retry_screen.online.action("/v1/outings")
	check(retry_screen.online.session.data.has("pending"), "Connection refusal discarded the action key")
	check(retry_screen.online.notice.begins_with("Offline"), "Offline status was hidden")
	retry_screen.online.client.endpoint = endpoint
	retry_screen.online.session.data["endpoint"] = endpoint
	retry_screen.online.session.save_session()
	var reconnect := Screen.new()
	host.add_child(reconnect)
	reconnect.setup(first.sim, first.settings, paths[0])
	await press(reconnect, "retry")
	check(not reconnect.online.session.data.has("pending"), "Reconnect left the retry unresolved")
	check(reconnect.online.profile.get("outing") is Dictionary, "Reconnect did not start the original outing")
	check(int(reconnect.online.profile["gold"]) == 60, "Connection interruption changed earned gold")
	for path_ in paths:
		var clean := Session.new()
		clean.path = path_
		clean.discard()
	host.queue_free()
	await process_frame
	print("Guild screen: three accounts used actual controls, shared raid, reward restore/Wear; failures=", failures)
	quit(1 if failures else 0)
