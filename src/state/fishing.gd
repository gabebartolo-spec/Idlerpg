extends RefCounted
const Catalog = preload("res://src/data/fishing_catalog.gd")
var requested: bool = false
var progress_usec: int = 0
var catches: int = 0
var stock: Dictionary = {}
var prepared: int = 0
var last_attempt: int = -1
var successful_reels: int = 0
var bonus_catches: int = 0

func advance(seconds: float) -> Dictionary:
	var elapsed: int = progress_usec + int(round(seconds * 1000000.0))
	var count: int = elapsed / Catalog.INTERVAL_USEC
	progress_usec = elapsed % Catalog.INTERVAL_USEC
	var gained := {}
	# Count a deterministic three-catch rotation in constant time, including long returns.
	for index in Catalog.CATCHES.size():
		var first: int = posmod(index - catches, Catalog.CATCHES.size())
		var amount: int = 0 if first >= count else 1 + (count - first - 1) / Catalog.CATCHES.size()
		if amount > 0:
			var item: String = Catalog.CATCHES[index]
			stock[item] = int(stock.get(item, 0)) + amount
			gained[item] = amount
	catches += count
	return gained

func reel() -> Dictionary:
	if last_attempt == catches:
		return {"ok": false, "message": "One optional reel attempt per cast."}
	last_attempt = catches
	if progress_usec < 7000000 or progress_usec > 9000000:
		return {"ok": false, "message": "Missed the green window. The passive catch is still safe."}
	successful_reels += 1
	if successful_reels % 10 == 0:
		stock["Pond Perch"] = int(stock.get("Pond Perch", 0)) + 1
		bonus_catches += 1
		return {"ok": true, "message": "Ten timely reels: one bonus Pond Perch."}
	return {"ok": true, "message": "Timely reel! %d/10 toward one bonus perch." % (successful_reels % 10)}

func can_prepare() -> bool:
	for item in Catalog.RECIPE:
		if int(stock.get(item, 0)) < Catalog.RECIPE[item]:
			return false
	return true

func prepare() -> bool:
	if not can_prepare():
		return false
	for item in Catalog.RECIPE:
		stock[item] = int(stock[item]) - Catalog.RECIPE[item]
		if stock[item] == 0:
			stock.erase(item)
	prepared += 1
	return true

func to_save_dict() -> Dictionary:
	return {"requested": requested, "progress_usec": progress_usec, "catches": catches,
		"stock": stock.duplicate(), "prepared": prepared, "last_attempt": last_attempt,
		"successful_reels": successful_reels, "bonus_catches": bonus_catches}

func load_save_dict(data: Dictionary) -> void:
	requested = bool(data.get("requested", false))
	progress_usec = clampi(int(data.get("progress_usec", 0)), 0, Catalog.INTERVAL_USEC - 1)
	catches = maxi(0, int(data.get("catches", 0)))
	stock.clear()
	for item in Catalog.CATCHES:
		var amount := maxi(0, int(data.get("stock", {}).get(item, 0)))
		if amount > 0:
			stock[item] = amount
	prepared = maxi(0, int(data.get("prepared", 0)))
	last_attempt = clampi(int(data.get("last_attempt", -1)), -1, catches)
	successful_reels = clampi(int(data.get("successful_reels", 0)), 0, catches + 1)
	bonus_catches = clampi(int(data.get("bonus_catches", 0)), 0, successful_reels / 10)
