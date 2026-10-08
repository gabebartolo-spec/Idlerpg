extends RefCounted

# Earned local receipts. Multiplayer rewards must come from a trusted server later.
const Trails = preload("res://src/data/expedition_catalog.gd")
const Looks = preload("res://src/data/appearance_catalog.gd")
var last_run: int = 0
var pending: Array[Dictionary] = []
var last_opened: Dictionary = {}

func issue(run: int, route: String, gold: int, look: String) -> bool:
	if run <= last_run or not Trails.ROUTES.has(route) or gold < 0:
		return false
	last_run = run
	for receipt in pending:
		if receipt["look"] == look:
			look = ""
	pending.append({"id": "trail:%d" % run, "run": run, "route": route, "gold": gold, "look": look if Looks.LOOKS.has(look) else ""})
	return true

func take(id: String) -> Dictionary:
	for i in pending.size():
		if pending[i]["id"] == id:
			last_opened = pending[i].duplicate(true)
			pending.remove_at(i)
			return last_opened.duplicate(true)
	return {}

func to_save_dict() -> Dictionary:
	return {"last_run": last_run, "pending": pending.duplicate(true), "last_opened": last_opened.duplicate(true)}

func load_save_dict(raw: Variant) -> void:
	last_run = 0
	pending.clear()
	last_opened.clear()
	if not raw is Dictionary:
		return
	last_run = maxi(0, int(raw.get("last_run", 0)))
	var seen := {}
	var saved_pending: Variant = raw.get("pending", [])
	for receipt in saved_pending if saved_pending is Array else []:
		var valid := _receipt(receipt)
		if valid.is_empty() or seen.has(valid["id"]):
			continue
		seen[valid["id"]] = true
		last_run = maxi(last_run, valid["run"])
		pending.append(valid)
	last_opened = _receipt(raw.get("last_opened", {}))
	if not last_opened.is_empty():
		last_run = maxi(last_run, last_opened["run"])
		# A contradictory local record must never repay an already opened receipt.
		for i in range(pending.size() - 1, -1, -1):
			if pending[i]["id"] == last_opened["id"]:
				pending.remove_at(i)

func _receipt(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var run := int(raw.get("run", 0))
	var route := str(raw.get("route", ""))
	if run <= 0 or not Trails.ROUTES.has(route) or str(raw.get("id", "")) != "trail:%d" % run:
		return {}
	var look := str(raw.get("look", ""))
	return {"id": "trail:%d" % run, "run": run, "route": route, "gold": maxi(0, int(raw.get("gold", 0))), "look": look if Looks.LOOKS.has(look) else ""}
