extends SceneTree

# Optional live-service suite, not part of offline tests. Three independent
# Godot clients must share a real listening service; no mock responses.
const Client := preload("res://src/services/playtest_client.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var url := OS.get_environment("IDLE_TEST_URL")
	if url.is_empty():
		push_error("IDLE_TEST_URL is required; this suite creates disposable online accounts")
		quit(1)
		return
	var clients: Array[Node] = []
	var ids: Array[String] = []
	for label in ["Amber", "Birch", "Cedar"]:
		var client := Client.new()
		root.add_child(client)
		clients.append(client)
		check(not client.configure("http://example.com"), "Public plaintext endpoint accepted")
		check(not client.configure("http://127.0.0.1:123@other.example"), "Plaintext user-info endpoint accepted")
		check(client.configure(url), "Invalid service endpoint")
		var created: Dictionary = await client.create_account(label)
		check(created.get("ok", false), "Account creation failed")
		ids.append(client.account_id)
	if failures > 0:
		quit(1)
		return
	var first: Dictionary = await clients[0].call_api(HTTPClient.METHOD_POST, "/v1/guilds", {"name": "Godot Lamplighters"}, "create-guild")
	check(first.get("ok", false), "Create guild failed")
	if not first.get("ok", false):
		quit(1)
		return
	var invite: String = first["data"]["guild"]["invite"]
	for index in [1, 2]:
		var joined: Dictionary = await clients[index].call_api(HTTPClient.METHOD_POST, "/v1/guild/join", {"invite": invite}, "join-guild")
		check(joined.get("ok", false), "Join guild failed")
	for client in clients:
		var roster: Dictionary = await client.call_api(HTTPClient.METHOD_GET, "/v1/guild")
		check(roster.get("ok", false), "Read roster failed")
		var members: Array = roster.get("data", {}).get("guild", {}).get("members", [])
		check(members.size() == 3, "Real shared roster missing a client")
		for id in ids:
			check(members.any(func(member: Dictionary) -> bool: return member["id"] == id), "Different server roster")
		var profile: Dictionary = await client.call_api(HTTPClient.METHOD_GET, "/v1/profile")
		check(profile["data"]["id"] == client.account_id, "Private profile crossed accounts")
	var started: Dictionary = await clients[0].call_api(HTTPClient.METHOD_POST, "/v1/raids", {}, "create-raid")
	check(started.get("ok", false), "Start shared raid failed")
	if not started.get("ok", false):
		quit(1)
		return
	var raid_path: String = "/v1/raids/" + started["data"]["raid"]["id"]
	var roles := ["damage", "protection", "preparation"]
	for index in range(3):
		var enrolled: Dictionary = await clients[index].call_api(HTTPClient.METHOD_POST, raid_path + "/enroll", {"role": roles[index], "build": "trail"}, "prepare-role")
		check(enrolled.get("ok", false), "Prepare role failed")
	var outgoing: Dictionary = await clients[0].call_api(HTTPClient.METHOD_POST, "/v1/guild/leave", {}, "leave-guild")
	check(outgoing.get("ok", false), "Leave guild failed")
	var remaining: Dictionary = await clients[1].call_api(HTTPClient.METHOD_GET, "/v1/guild")
	check(remaining["data"]["guild"]["members"].size() == 2, "Membership not shared")
	check(remaining["data"]["guild"]["leader"] != ids[0], "Leadership not transferred")
	# The disposable verification server alone accelerates its clock. Poll its
	# timestamp rather than uploading time or changing game-side readiness.
	for attempt in range(100):
		var raid_state: Dictionary = await clients[1].call_api(HTTPClient.METHOD_GET, raid_path)
		if raid_state["data"]["raid"]["server_time"] >= raid_state["data"]["raid"]["ready"]:
			break
		await create_timer(0.2).timeout
	var resolved: Dictionary = await clients[1].call_api(HTTPClient.METHOD_POST, raid_path + "/resolve", {}, "resolve-raid")
	check(resolved.get("ok", false), "Resolve shared raid failed")
	if resolved.get("ok", false):
		check(resolved["data"]["raid"]["result"]["won"], "Starter trio did not win")
		for client in clients:
			var chest: Dictionary = await client.call_api(HTTPClient.METHOD_POST, raid_path + "/open", {}, "open-raid-chest")
			check(chest.get("ok", false), "Participant chest failed")
			check(chest.get("data", {}).get("profile", {}).get("gold", 0) == 60, "Shared raid gold not settled")
			var replay: Dictionary = await client.call_api(HTTPClient.METHOD_POST, raid_path + "/open", {}, "open-raid-chest-again")
			check(replay.get("data", {}).get("profile", {}).get("gold", 0) == 60, "Raid replay duplicated reward")
	for client in clients:
		client.queue_free()
	await process_frame
	print("Online client: three independent Godot accounts shared guild, won raid, opened duplicate-safe rewards; failures=", failures)
	quit(1 if failures else 0)
