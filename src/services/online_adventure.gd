extends Node
signal updated
signal appearance_changed
const Client = preload("res://src/services/playtest_client.gd")
const Session = preload("res://src/services/online_session.gd")
const Looks = preload("res://src/data/appearance_catalog.gd")
var client: Node
var session = Session.new()
var sim: Node
var profile: Dictionary = {}
var guild: Dictionary = {}
var raids: Array = []
var build_catalog: Dictionary = {}
var build_costs: Dictionary = {}
var busy := false
var notice := ""
var recovery_key := ""
var reveal: Dictionary = {}

func setup(sim_node: Node, storage_path: String = Session.DEFAULT_PATH) -> void:
	sim = sim_node
	session.path = storage_path
	session.load_session()
	client = Client.new()
	add_child(client)
	if session.newer:
		notice = "Online session needs a newer build"
		return
	var configured := str(session.data.get("endpoint", ""))
	if configured.is_empty():
		configured = OS.get_environment("IDLE_SERVICE_URL")
	if configured.is_empty():
		configured = str(ProjectSettings.get_setting("online/service_url", ""))
	if client.configure(configured):
		client.account_id = str(session.data.get("account_id", ""))
		client.token = str(session.data.get("token", ""))

func connect_service(url: String) -> bool:
	if busy or not client.configure(url):
		notice = "Use the playtest's secure connection address"
		updated.emit()
		return false
	client.account_id = ""
	client.token = ""
	profile.clear()
	guild.clear()
	raids.clear()
	build_catalog.clear()
	build_costs.clear()
	recovery_key = ""
	reveal.clear()
	session.discard()
	session.data = {"endpoint": client.endpoint}
	var saved: bool = session.save_session()
	notice = "Connected · sign in below" if saved else "Connection could not be saved"
	updated.emit()
	return saved

func _save_credentials() -> bool:
	session.data["endpoint"] = client.endpoint
	session.data["account_id"] = client.account_id
	session.data["token"] = client.token
	return session.save_session()

func create_account(display_name: String) -> void:
	if busy or not client.token.is_empty():
		return
	busy = true
	updated.emit()
	var result: Dictionary = await client.create_account(display_name)
	if result.get("ok", false):
		profile.clear()
		guild.clear()
		raids.clear()
		reveal.clear()
		recovery_key = str(result["data"].get("recovery_key", ""))
		if not _save_credentials():
			notice = "Session save failed · keep your recovery details"
	else:
		_error(result)
	busy = false
	if result.get("ok", false):
		await sync()
	updated.emit()

func recover(id: String, key: String) -> void:
	if busy:
		return
	busy = true
	var previous_account: String = client.account_id
	updated.emit()
	var result: Dictionary = await client.recover(id.strip_edges(), key.strip_edges())
	if result.get("ok", false):
		if previous_account != client.account_id:
			profile.clear()
			guild.clear()
			raids.clear()
			reveal.clear()
		if str(session.data.get("pending", {}).get("account", "")) != client.account_id:
			session.data.erase("pending")
		_save_credentials()
		recovery_key = ""
	else:
		_error(result)
	busy = false
	if result.get("ok", false):
		await sync()
	updated.emit()

func _error(result: Dictionary) -> void:
	if int(result.get("status", 0)) == 401:
		notice = "Recover your account to sign in again"
	elif int(result.get("status", 0)) == 0:
		notice = "Offline · your solo adventure continues"
	else:
		var detail: Variant = result.get("data", {}).get("detail", "Try again")
		notice = str(detail) if detail is String else "Check the details and try again"

func sync() -> void:
	if busy or client.token.is_empty():
		updated.emit()
		return
	busy = true
	notice = ""
	updated.emit()
	for path_ in ["/v1/profile", "/v1/guild", "/v1/raids", "/v1/builds"]:
		var result: Dictionary = await client.call_api(HTTPClient.METHOD_GET, path_)
		if not result.get("ok", false):
			_error(result)
			_save_credentials()
			break
		match path_:
			"/v1/profile":
				profile = result["data"]
				var restored := false
				for look in profile.get("looks", []):
					if Looks.LOOKS.has(str(look)):
						var before: Dictionary = sim.wardrobe.owned.get(str(look), {}).duplicate(true)
						sim.wardrobe.grant(str(look), "online:" + client.account_id)
						restored = restored or before != sim.wardrobe.owned.get(str(look), {})
				if restored:
					appearance_changed.emit()
			"/v1/guild":
				var value: Variant = result["data"].get("guild")
				guild = value if value is Dictionary else {}
			"/v1/raids":
				raids = result["data"].get("raids", [])
			"/v1/builds":
				build_catalog = result["data"].get("builds", {})
				build_costs = result["data"].get("costs", {})
	busy = false
	updated.emit()
	# Catch up after the server deadline without requiring a live attendance.
	if notice.is_empty() and not session.data.has("pending"):
		for raid in raids:
			if raid.get("result") == null and int(raid["server_time"]) >= int(raid["ready"]):
				await action("/v1/raids/" + str(raid["id"]) + "/resolve")
				break

func action(path_: String, body: Dictionary = {}) -> void:
	if busy or client.token.is_empty():
		return
	if session.data.has("pending"):
		notice = "Retry your interrupted action first"
		updated.emit()
		return
	var key: String = Crypto.new().generate_random_bytes(16).hex_encode()
	session.data["pending"] = {"account": client.account_id, "path": path_, "body": body, "key": key}
	if not session.save_session():
		session.data.erase("pending")
		notice = "Could not save this action · try again"
		updated.emit()
		return
	await retry()

func retry() -> void:
	if busy or client.token.is_empty() or not session.data.has("pending"):
		return
	var pending: Dictionary = session.data["pending"]
	if str(pending.get("account", "")) != client.account_id:
		notice = "Recover the account that started this action"
		updated.emit()
		return
	busy = true
	updated.emit()
	var result: Dictionary = await client.call_api(HTTPClient.METHOD_POST, str(pending["path"]), pending["body"], str(pending["key"]))
	if result.get("ok", false):
		if str(pending["path"]).ends_with("/open"):
			reveal = result["data"].duplicate(true)
		session.data.erase("pending")
	elif int(result.get("status", 0)) > 0 and int(result.get("status", 0)) != 401 and int(result.get("status", 0)) < 500:
		# Definitive server rejection did not commit; the action can be changed.
		session.data.erase("pending")
		_error(result)
	else:
		_error(result)
	_save_credentials()
	busy = false
	if result.get("ok", false):
		await sync()
	updated.emit()

func sign_out() -> void:
	if busy:
		return
	busy = true
	updated.emit()
	await client.call_api(HTTPClient.METHOD_POST, "/v1/logout")
	client.token = ""
	client.account_id = ""
	profile.clear()
	guild.clear()
	raids.clear()
	build_catalog.clear()
	build_costs.clear()
	reveal.clear()
	recovery_key = ""
	session.discard()
	session.data = {"endpoint": client.endpoint}
	session.save_session()
	busy = false
	notice = "Signed out · keep your recovery details"
	updated.emit()
