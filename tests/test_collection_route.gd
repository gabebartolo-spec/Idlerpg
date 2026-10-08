extends SceneTree
const Game = preload("res://src/game.gd")
const Gear = preload("res://src/data/gear_catalog.gd")
const Persistence = preload("res://src/state/persistence.gd")
const Sim = preload("res://src/sim/adventurer_sim.gd")

class UnluckyGame extends "res://src/game.gd":
	func _roll_rarity(pity_count: int) -> String:
		return "Legendary" if pity_count >= 89 else "Common"

var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)
func game(unlucky: bool = false) -> Node:
	var node: Node = UnluckyGame.new() if unlucky else Game.new()
	root.add_child(node)
	node.gacha_tokens = 10000
	node.set_seed(123)
	return node
func _run() -> void:
	var worst := game(true)
	check(not worst.choose_pursuit("gear", "Briarhook") and not worst.choose_pursuit("bad", "Crownblade"), "world items and unknown banners cannot be routed through summons")
	check(worst.choose_pursuit("gear", "Crownblade"), "a missing banner item can be selected")
	var quote: Dictionary = worst.pursuit_quote("gear")
	check(quote["maximum_cost"] == 300 and quote["expected_cost"] > 0 and quote["expected_cost"] <= 300, "gross expected and guaranteed maximum costs are published")
	var common: Dictionary = worst.pursuit_quote("gear", "Iron Sword")
	var probability := 0.68 / 7.0
	var exact := (1.0 - pow(1.0 - probability, 30)) / probability * Game.SUMMON_COST
	check(abs(common["expected_cost"] - exact) < 0.00001, "expected cost matches the capped geometric distribution before pity can occur")
	worst.pity["relics"] = 89
	var unique_legendary: Dictionary = worst.pursuit_quote("relics", "Worldstone Shard")
	check(unique_legendary["maximum_cost"] == 10 and is_equal_approx(unique_legendary["expected_cost"], 10.0), "single-item Legendary pity tightens the displayed cost to one draw")
	worst.pull("gear", 29)
	check(worst.collection_count("gear", "Crownblade") == 0 and worst.pursuit_quote("gear")["remaining"] == 1, "the worst-luck route reaches its last paid pull")
	var last: Dictionary = worst.pull("gear", 1)
	check(last["results"].size() == 2 and last["results"][1].get("route_bonus", false) and worst.collection_count("gear", "Crownblade") == 1, "pull thirty grants the selected bonus in addition to its real roll")
	check(worst.pity["gear"] == 30 and worst.pursuit_quote("gear").is_empty(), "a bonus does not reset rarity pity and completes its route once")
	check(not worst.choose_pursuit("gear", "Crownblade"), "owned items cannot farm repeat guarantees")
	var simultaneous := game(true)
	simultaneous.pity["gear"] = 89
	simultaneous.choose_pursuit("gear", "Runed Longbow")
	simultaneous.pursuits["gear"]["progress"] = 29
	var boundary: Dictionary = simultaneous.pull("gear", 1)
	check(boundary["results"].size() == 2 and boundary["results"][0]["rarity"] == "Legendary" and boundary["results"][1]["name"] == "Runed Longbow", "simultaneous selected-item and Legendary guarantees both pay")
	var bulk := game()
	var singles := game()
	bulk.choose_pursuit("gear", "Crownblade")
	singles.choose_pursuit("gear", "Crownblade")
	bulk.pull("gear", 30)
	for i in 30:
		singles.pull("gear", 1)
	check(bulk.to_save_dict() == singles.to_save_dict(), "multi-pulls preserve serial RNG, wallet, history and route boundaries")
	var saved: Dictionary = singles.to_save_dict()
	var restored := game()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(saved)))
	check(restored.pursuits == singles.pursuits and restored.duplicate_counts == singles.duplicate_counts, "route and duplicate keepsakes survive JSON reload")
	var chosen := game(true)
	chosen.choose_pursuit("gear", "Crownblade")
	chosen.pull("gear", 12)
	chosen.choose_pursuit("gear", "Crownblade")
	check(chosen.pursuit_quote("gear")["progress"] == 12, "reselecting the same target preserves its progress")
	chosen.choose_pursuit("gear", "Starforged Helm")
	check(chosen.pursuit_quote("gear")["progress"] == 0, "switching targets resets progress explicitly")
	chosen.gacha_tokens = 0
	var before: Dictionary = chosen.to_save_dict()
	chosen.pull("gear", 10)
	check(chosen.to_save_dict() == before, "unaffordable multi-pulls change neither pursuit nor random state")
	var natural := game()
	natural.choose_pursuit("gear", "Crownblade")
	natural._grant_item("gear", "Crownblade", "Legendary")
	natural.pull("gear", 1)
	check(natural.pursuits.is_empty(), "an acquired target clears its guarantee rather than granting another copy")
	var saturated := game()
	for banner in Game.BANNERS:
		for item in saturated.collection_items(banner):
			saturated.collection[banner][item] = 1
	var balance: int = saturated.gacha_tokens
	var receipt: Dictionary = saturated.pull("gear", 100)
	var salvaged := 0
	for result in receipt["results"]:
		salvaged += Gear.salvage_tokens(result["name"])
	check(receipt["refunds"] == 100 and saturated.gacha_tokens == balance - 900, "complete banners refund exactly one token per paid duplicate")
	check(salvaged + receipt["refunds"] < receipt["cost"], "duplicate refunds plus maximum gear salvage cannot fund a profitable draw loop")
	for rarity in Gear.SALVAGE_TOKENS:
		check(Gear.SALVAGE_TOKENS[rarity] + Game.DUPLICATE_REFUND < Game.SUMMON_COST, "%s duplicates remain a token sink even when salvaged" % rarity)
	check(saturated.keepsake_text("gear") == "Keepsake: Cache Curator", "saturated duplicates unlock a permanent cosmetic banner keepsake")
	var dev_balance: int = saturated.gacha_tokens
	saturated.set_dev_infinite_tokens(true)
	saturated.pull("gear", 10)
	check(saturated.gacha_tokens == dev_balance, "free developer pulls cannot generate refund tokens")
	var path := "user://test_collection_route.json"
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var sim := Sim.new()
	root.add_child(sim)
	chosen.gacha_tokens = 1000
	chosen.pull("gear", 5)
	Persistence.save(sim, chosen, 1000, path)
	var reload_sim := Sim.new()
	root.add_child(reload_sim)
	var reload_game := game()
	Persistence.load_and_advance(reload_sim, reload_game, 1000, path)
	check(reload_game.pursuits == chosen.pursuits, "an actual checkpoint restores partial route progress")
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Collection route tests complete: %d failure(s)" % failures)
	quit(failures)
