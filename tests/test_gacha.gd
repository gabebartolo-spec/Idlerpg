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
	_check(bool(single.get("ok", false)), "single pull succeeds")
	_check(game.gacha_tokens == initial - game.SUMMON_COST, "normal pulls spend tokens")
	_check((single.get("results", []) as Array).size() == 1, "single pull returns one result")

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

		game.dev_reset_pity()
		game.pity["relics"] = 89
		var pity_pull: Dictionary = game.pull("relics", 1)
		var pity_results: Array = pity_pull.get("results", [])
		_check(not pity_results.is_empty() and str(pity_results[0].get("rarity", "")) == "Legendary", "90th pull is legendary pity")

	print("Gacha tests complete: %d failure(s)" % failures)
	quit(failures)
