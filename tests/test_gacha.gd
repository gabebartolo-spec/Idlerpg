extends SceneTree

const GameStateScript = preload("res://src/game.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var game: Node = GameStateScript.new()
	root.add_child(game)
	game.set_seed(123456)

	var initial: int = game.gacha_tokens
	var single: Dictionary = game.pull("gear", 1)
	var first_results: Array = single.get("results", [])
	_check(bool(single.get("ok", false)), "single pull succeeds")
	_check(game.gacha_tokens == initial - game.SUMMON_COST, "normal pulls spend tokens")
	_check(first_results.size() == 1, "single pull returns one result")
	_check(bool(first_results[0].get("is_new", false)), "first collected item is marked new")
	_check(int(first_results[0].get("copy", 0)) == 1, "first collected item records copy one")

	var first_name: String = str(first_results[0].get("name", ""))
	_check(game.collection_count("gear", first_name) == 1, "first pull enters persistent collection")
	_check(game.collected_unique("gear") == 1, "unique collection count is tracked")
	_check(game.pity_remaining("gear") == 89, "visible pity counts down from the hard guarantee")
	_check(game.recent_summons(1).size() == 1, "summon history records pulls")

	game.set_favourite(first_name, true)
	game.set_locked(first_name, true)
	_check(game.is_favourite(first_name), "collection items can be favourited")
	_check(game.is_locked(first_name), "collection items can be locked")

	var saved: Dictionary = game.to_save_dict()
	var restored: Node = GameStateScript.new()
	root.add_child(restored)
	restored.load_save_dict(saved)
	_check(restored.collection_count("gear", first_name) == 1, "collection survives save/load")
	_check(restored.is_favourite(first_name), "favourites survive save/load")
	_check(restored.is_locked(first_name), "locks survive save/load")
	_check(restored.recent_summons(1).size() == 1, "summon history survives save/load")

	game.gacha_tokens = 0
	var blocked: Dictionary = game.pull("gear", 1)
	_check(not bool(blocked.get("ok", true)), "wallet blocks unaffordable pulls")

	if game.dev_tools_available():
		game.set_dev_infinite_tokens(true)
		var before: int = game.gacha_tokens
		var stress: Dictionary = game.pull("companions", 100)
		_check(bool(stress.get("ok", false)), "dev infinite mode allows 100 pulls")
		_check(game.gacha_tokens == before, "dev infinite mode never spends tokens")
		_check((stress.get("results", []) as Array).size() == 100, "stress pull returns 100 results")
		_check(game.recent_summons(100).size() == 50, "summon history is capped at 50 entries")

		game.dev_reset_pity()
		game.pity["relics"] = 89
		var pity_pull: Dictionary = game.pull("relics", 1)
		var pity_results: Array = pity_pull.get("results", [])
		_check(not pity_results.is_empty() and str(pity_results[0].get("rarity", "")) == "Legendary", "90th pull is legendary pity")
		_check(game.pity_remaining("relics") == 90, "legendary resets visible pity")

	var deterministic: Node = GameStateScript.new()
	root.add_child(deterministic)
	deterministic.set_seed(42)
	deterministic.set_dev_infinite_tokens(true)
	var duplicate_seen := false
	for _i in range(500):
		var pull: Dictionary = deterministic.pull("relics", 1)
		var result: Dictionary = (pull.get("results", []) as Array)[0]
		if not bool(result.get("is_new", true)):
			duplicate_seen = true
			_check(int(result.get("copy", 0)) >= 2, "duplicate pull increments collection copy count")
			break
	_check(duplicate_seen, "duplicate collection state is observable")

	print("Gacha tests complete: %d failure(s)" % failures)
	quit(failures)
