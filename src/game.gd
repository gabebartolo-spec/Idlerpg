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
			"Common": ["Iron Sword", "Leather Hood", "Oak Buckler"],
			"Rare": ["Runed Longbow", "Knight Mail", "Ember Staff"],
			"Epic": ["Moonsteel Blade", "Wyrmhide Coat", "Stormcaller"],
			"Legendary": ["Crownblade"]
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
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for banner_id in BANNERS.keys():
		pity[banner_id] = 0

func set_seed(seed_value: int) -> void:
	rng.seed = seed_value

func banner_ids() -> Array:
	return BANNERS.keys()

func banner_label(banner_id: String) -> String:
	if not BANNERS.has(banner_id):
		return banner_id
	return str(BANNERS[banner_id]["label"])

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

func dev_reset_pity() -> void:
	if not dev_tools_available():
		return
	for banner_id in BANNERS.keys():
		pity[banner_id] = 0

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
	return {
		"name": item_name,
		"rarity": rarity,
		"banner": banner_id
	}

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
