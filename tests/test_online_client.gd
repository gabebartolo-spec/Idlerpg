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
	var outgoing: Dictionary = await clients[0].call_api(HTTPClient.METHOD_POST, "/v1/guild/leave", {}, "leave-guild")
	check(outgoing.get("ok", false), "Leave guild failed")
	var remaining: Dictionary = await clients[1].call_api(HTTPClient.METHOD_GET, "/v1/guild")
	check(remaining["data"]["guild"]["members"].size() == 2, "Membership not shared")
	check(remaining["data"]["guild"]["leader"] != ids[0], "Leadership not transferred")
	for client in clients:
		client.queue_free()
	await process_frame
	print("Online client: three independent Godot accounts shared one HTTP guild; failures=", failures)
	quit(1 if failures else 0)
