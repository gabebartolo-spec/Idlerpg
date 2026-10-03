class_name IdleGameState
extends Node

signal wallet_changed(tokens: int)
signal draw_finished(banner_id: String, results: Array)

const SUMMON_COST: int = 10
const STARTING_TOKENS: int = 250

const BANNERS: Dictionary = {
	"gear": {
		"label": "Gear Cache",
		"items": {
			"Common": ["Iron Sword", "Leather Hood", "Oak Buckler", "Rough Trousers", "Hide Gloves", "Trail Boots", "Copper Ring"],
			"Rare": ["Runed Longbow", "Knight Mail", "Ember Staff", "Steel Greaves", "Knight Gauntlets", "Ranger Boots", "Sapphire Charm"],
			"Epic": ["Moonsteel Blade", "Wyrmhide Coat", "Stormcaller", "Dragon Legguards", "Rune Grips", "Shadow Treads", "Phoenix Sigil"],
			"Legendary": ["Crownblade", "Starforged Helm", "Titanheart Plate", "Worldwalker Boots"]
		}
	},
	"companions": {
		"label": "Companion Pact",
		"items": {
			"Common": ["Pack Rat", "Stable Hound", "Torch Sprite"],
			"Rare": ["Hill Squire", "Marsh Witch", "Clockwork Raven"],
			"Epic": ["Frost Ranger", "Sun Cleric", "Grave Knight"],
			"Legendary": ["Ancient Warden"]
		}
	},
	"relics": {
		"label": "Relic Vault",
		"items": {
			"Common": ["Copper Charm", "Old Coin", "Hunter's Knot"],
			"Rare": ["Lucky Fang", "Glass Idol", "Pilgrim Bell"],
			"Epic": ["Phoenix Ash", "Void Compass", "Dragon Eye"],
			"Legendary": ["Worldstone Shard"]
		}
	}
}

var gacha_tokens: int = STARTING_TOKENS
var dev_infinite_tokens: bool = false
var pity: Dictionary = {}
var collection: Dictionary = {}
var favourites: Dictionary = {}
var locked_items: Dictionary = {}
var summon_history: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for banner_id in BANNERS.keys():
		pity[banner_id] = 0
		collection[banner_id] = {}

func set_seed(seed_value: int) -> void:
	rng.seed = seed_value

func banner_ids() -> Array:
	return BANNERS.keys()

func banner_label(banner_id: String) -> String:
	if not BANNERS.has(banner_id):
		return banner_id
	return str(BANNERS[banner_id]["label"])

func pity_remaining(banner_id: String) -> int:
	if not BANNERS.has(banner_id):
		return 0
	return max(1, 90 - int(pity.get(banner_id, 0)))

func collection_count(banner_id: String, item_name: String) -> int:
	var banner_collection: Dictionary = collection.get(banner_id, {})
	return max(0, int(banner_collection.get(item_name, 0)))

func collected_unique(banner_id: String) -> int:
	var banner_collection: Dictionary = collection.get(banner_id, {})
	var count := 0
	for item_name in banner_collection.keys():
		if int(banner_collection.get(item_name, 0)) > 0:
			count += 1
	return count

func banner_item_count(banner_id: String) -> int:
	if not BANNERS.has(banner_id):
		return 0
	var total := 0
	var items_by_rarity: Dictionary = BANNERS[banner_id]["items"]
	for rarity in items_by_rarity.keys():
		total += (items_by_rarity[rarity] as Array).size()
	return total

func collection_items(banner_id: String) -> Array[String]:
	var names: Array[String] = []
	if not BANNERS.has(banner_id):
		return names
	var items_by_rarity: Dictionary = BANNERS[banner_id]["items"]
	for rarity in ["Legendary", "Epic", "Rare", "Common"]:
		for item_name in items_by_rarity.get(rarity, []):
			names.append(str(item_name))
	return names

func item_rarity(banner_id: String, item_name: String) -> String:
	if not BANNERS.has(banner_id):
		return ""
	var items_by_rarity: Dictionary = BANNERS[banner_id]["items"]
	for rarity in items_by_rarity.keys():
		if item_name in (items_by_rarity[rarity] as Array):
			return str(rarity)
	return ""

func is_favourite(item_name: String) -> bool:
	return bool(favourites.get(item_name, false))

func set_favourite(item_name: String, enabled: bool) -> void:
	if enabled:
		favourites[item_name] = true
	else:
		favourites.erase(item_name)

func is_locked(item_name: String) -> bool:
	return bool(locked_items.get(item_name, false))

func set_locked(item_name: String, enabled: bool) -> void:
	if enabled:
		locked_items[item_name] = true
	else:
		locked_items.erase(item_name)

func recent_summons(limit: int = 20) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var capped := mini(max(0, limit), summon_history.size())
	for i in range(capped):
		result.append(summon_history[i].duplicate(true))
	return result

func dev_tools_available() -> bool:
	return OS.is_debug_build() or Engine.is_editor_hint()

func set_dev_infinite_tokens(enabled: bool) -> void:
	if not dev_tools_available():
		return
	dev_infinite_tokens = enabled
	wallet_changed.emit(gacha_tokens)

func dev_add_tokens(amount: int = 10000) -> void:
	if not dev_tools_available():
		return
	gacha_tokens = max(0, gacha_tokens + amount)
	wallet_changed.emit(gacha_tokens)

func grant_tokens(amount: int) -> void:
	if amount <= 0:
		return
	gacha_tokens += amount
	wallet_changed.emit(gacha_tokens)

func dev_reset_pity() -> void:
	if not dev_tools_available():
		return
	for banner_id in BANNERS.keys():
		pity[banner_id] = 0

func to_save_dict() -> Dictionary:
	return {
		"gacha_tokens": gacha_tokens,
		"pity": pity.duplicate(true),
		"collection": collection.duplicate(true),
		"favourites": favourites.duplicate(true),
		"locked_items": locked_items.duplicate(true),
		"summon_history": summon_history.duplicate(true)
	}

func load_save_dict(data: Dictionary) -> void:
	gacha_tokens = max(0, int(data.get("gacha_tokens", STARTING_TOKENS)))
	var saved_pity: Dictionary = data.get("pity", {})
	var saved_collection: Dictionary = data.get("collection", {})
	collection = {}
	for banner_id in BANNERS.keys():
		pity[banner_id] = max(0, int(saved_pity.get(banner_id, 0)))
		var banner_saved: Dictionary = saved_collection.get(banner_id, {})
		var banner_collection: Dictionary = {}
		for item_name in collection_items(str(banner_id)):
			var count: int = maxi(0, int(banner_saved.get(item_name, 0)))
			if count > 0:
				banner_collection[item_name] = count
		collection[banner_id] = banner_collection

	favourites = {}
	var saved_favourites: Dictionary = data.get("favourites", {})
	for item_name in saved_favourites.keys():
		if bool(saved_favourites[item_name]):
			favourites[str(item_name)] = true

	locked_items = {}
	var saved_locked: Dictionary = data.get("locked_items", {})
	for item_name in saved_locked.keys():
		if bool(saved_locked[item_name]):
			locked_items[str(item_name)] = true

	summon_history = []
	for raw_entry in data.get("summon_history", []):
		if raw_entry is Dictionary:
			summon_history.append((raw_entry as Dictionary).duplicate(true))
	if summon_history.size() > 50:
		summon_history.resize(50)

	dev_infinite_tokens = false
	wallet_changed.emit(gacha_tokens)

func pull(banner_id: String, count: int = 1) -> Dictionary:
	if not BANNERS.has(banner_id):
		return {"ok": false, "error": "Unknown banner", "results": []}
	if count <= 0:
		return {"ok": false, "error": "Pull count must be positive", "results": []}

	var cost: int = SUMMON_COST * count
	if not dev_infinite_tokens and gacha_tokens < cost:
		return {"ok": false, "error": "Not enough gacha tokens", "results": []}

	if not dev_infinite_tokens:
		gacha_tokens -= cost
		wallet_changed.emit(gacha_tokens)

	var results: Array = []
	for _i in range(count):
		results.append(_roll_one(banner_id))

	draw_finished.emit(banner_id, results)
	return {
		"ok": true,
		"cost": 0 if dev_infinite_tokens else cost,
		"results": results
	}

func _roll_one(banner_id: String) -> Dictionary:
	var pity_count: int = int(pity.get(banner_id, 0))
	var rarity: String = _roll_rarity(pity_count)
	pity[banner_id] = 0 if rarity == "Legendary" else pity_count + 1

	var items: Array = BANNERS[banner_id]["items"][rarity]
	var item_name: String = str(items[rng.randi_range(0, items.size() - 1)])
	var previous_count := collection_count(banner_id, item_name)
	var new_count := previous_count + 1
	var banner_collection: Dictionary = collection.get(banner_id, {})
	banner_collection[item_name] = new_count
	collection[banner_id] = banner_collection

	var result := {
		"name": item_name,
		"rarity": rarity,
		"banner": banner_id,
		"is_new": previous_count == 0,
		"copy": new_count
	}
	summon_history.push_front(result.duplicate(true))
	if summon_history.size() > 50:
		summon_history.resize(50)
	return result

func _roll_rarity(pity_count: int) -> String:
	# Hard legendary pity on pull 90. Rates are intentionally simple for the prototype.
	if pity_count >= 89:
		return "Legendary"

	var roll: float = rng.randf()
	if roll < 0.01:
		return "Legendary"
	if roll < 0.10:
		return "Epic"
	if roll < 0.32:
		return "Rare"
	return "Common"
