extends SceneTree
const Session = preload("res://src/services/online_session.gd")
const PATH := "user://online_session_test.json"
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func write(path_: String, data: Dictionary) -> void:
	var file := FileAccess.open(path_, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _initialize() -> void:
	var session := Session.new()
	session.path = PATH
	session.discard()
	session.data = {"endpoint": "https://playtest.invalid", "account_id": "account", "token": "private-session", "recovery_key": "never-save-this", "pending": {"account": "account", "path": "/v1/outings", "key": "same-request-key", "body": {}}}
	check(session.save_session(), "Session write failed")
	check(not FileAccess.get_file_as_string(PATH).contains("never-save-this"), "Recovery key leaked into storage")
	var restored := Session.new()
	restored.path = PATH
	restored.load_session()
	check(restored.data["pending"] == session.data["pending"], "Interruption changed retry body or key")
	check(restored.data["token"] == "private-session", "Session identity was not restored")
	check(restored.save_session(), "Backup write failed")
	write(PATH, {"version": []})
	restored.load_session()
	check(restored.data.get("token", "") == "private-session", "Malformed main did not use valid backup")
	write(PATH, {"version": 1, "pending": []})
	restored.load_session()
	check(not restored.data.has("pending"), "Malformed optional retry survived validation")
	write(PATH, {"version": 99, "token": "future-token"})
	restored.load_session()
	check(restored.newer and not restored.save_session(), "Older build overwrote newer session")
	check(FileAccess.get_file_as_string(PATH).contains("future-token"), "Future session was replaced")
	restored.discard()
	for suffix in ["", ".tmp", ".bak"]:
		check(not FileAccess.file_exists(PATH + suffix), "Sign-out left a credential companion")
	write(PATH + ".tmp", {"version": 1, "token": "interrupted-token"})
	restored.load_session()
	check(restored.data.get("token", "") == "interrupted-token", "Interrupted first write was not recovered")
	restored.discard()
	print("Online session: identity/retry recovery and secret cleanup; failures=", failures)
	quit(1 if failures else 0)
