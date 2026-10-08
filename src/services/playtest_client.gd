class_name PlaytestClient
extends Node

# Online accounts have their own server-owned state. This client never uploads a
# local save, wallet, device clock, equipment stats or reward contents.
# Credentials stay in memory until the account UI implements explicit recovery.
var account_id := ""
var token := ""
var endpoint := ""
var _busy := false
var _http: HTTPRequest

func configure(url: String) -> bool:
	var candidate := url.trim_suffix("/")
	# Plain HTTP is permitted only for loopback development.
	var loopback := RegEx.new()
	loopback.compile("^http://127\\.0\\.0\\.1:[0-9]{1,5}$")
	if not candidate.begins_with("https://") and loopback.search(candidate) == null:
		return false
	endpoint = candidate
	return true

func create_account(display_name: String) -> Dictionary:
	var result := await call_api(HTTPClient.METHOD_POST, "/v1/accounts", {"name": display_name})
	_accept_credentials(result)
	return result

func recover(id: String, recovery_key: String) -> Dictionary:
	var result := await call_api(HTTPClient.METHOD_POST, "/v1/recover", {"account_id": id, "recovery_key": recovery_key})
	_accept_credentials(result)
	return result

func _accept_credentials(result: Dictionary) -> void:
	if result.get("ok", false):
		var data: Dictionary = result["data"]
		account_id = str(data.get("account_id", ""))
		token = str(data.get("token", ""))

func call_api(method: int, path: String, payload: Dictionary = {}, retry_key: String = "") -> Dictionary:
	if endpoint.is_empty() or _busy or not (path.begins_with("/v1/") or path == "/health"):
		return {"ok": false, "status": 0, "error": "Service unavailable or request in progress"}
	if not is_instance_valid(_http):
		_http = HTTPRequest.new()
		_http.timeout = 10.0
		_http.body_size_limit = 65536
		add_child(_http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	if not retry_key.is_empty():
		headers.append("Idempotency-Key: " + retry_key)
	_busy = true
	var error := _http.request(endpoint + path, headers, method, "" if method == HTTPClient.METHOD_GET else JSON.stringify(payload))
	if error != OK:
		_busy = false
		return {"ok": false, "status": 0, "error": "Could not contact service"}
	var response: Array = await _http.request_completed
	_busy = false
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		# The caller retains its action key across uncertain responses. Never issue
		# an automatic new key after a timeout: the server may have committed.
		return {"ok": false, "status": 0, "error": "Connection interrupted; retry the same action"}
	var status := int(response[1])
	var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok": false, "status": status, "error": "Unexpected service response"}
	if status == 401 and path != "/v1/recover":
		token = ""
	return {"ok": status >= 200 and status < 300, "status": status, "data": parsed}
