extends SceneTree

# Checks on the IRPG-R01 economy baseline tool, on a small fast configuration:
# the same inputs give the same results, the token and gold ledgers balance, and a few
# properties that follow directly from the implemented economy hold.

const ModelScript = preload("res://tools/economy/baseline_model.gd")

const QUICK := {
	"seed": 7,
	"days": 9,
	"sim_hours": 3,
	"collection_accounts": 16,
	"sim_accounts": 1,
	"checkpoints": [1.0, 7.0, 9.0],
	"windows": [[1, 1], [2, 7], [8, 9]],
	"sim_checkpoint_hours": [1.0, 2.0, 3.0],
	"pull_pattern": ["gear", "gear", "companions", "gear", "relics", "companions"],
	"target_item": "Crownblade",
	"upgrade_score": {"attack": 2, "hp": 1},
	"income_scenarios": {"implemented": 0, "proposed_120_per_day": 120},
	"cohorts": {
		"free": {"purchases": []},
		"high": {"purchases": [{"first_day": 1, "every_days": 7, "tokens": 400}]}
	}
}

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
	var first_model := ModelScript.new()
	var first: Dictionary = first_model.run(QUICK.duplicate(true), root)
	var second: Dictionary = ModelScript.new().run(QUICK.duplicate(true), root)
	_check(JSON.stringify(first) == JSON.stringify(second), "the same seed and inputs give identical results")

	var reseeded_inputs := QUICK.duplicate(true)
	reseeded_inputs["seed"] = 8
	reseeded_inputs["sim_accounts"] = 0
	var reseeded: Dictionary = ModelScript.new().run(reseeded_inputs, root)
	_check(JSON.stringify(first["cells"]["free/implemented"]["collection"]) != JSON.stringify(reseeded["cells"]["free/implemented"]["collection"]), "a different seed gives different draws")

	_check(first_model.ledger_failures.is_empty(), "token and gold ledgers balance for every account %s" % str(first_model.ledger_failures.slice(0, 3)))

	var free: Dictionary = first["cells"]["free/implemented"]["collection"]
	var ledger: Dictionary = free["token_ledger"]
	_check(ledger["tokens_income"] == 0.0 and ledger["tokens_purchased"] == 0.0, "the implemented free economy has no token income")
	_check(ledger["tokens_spent"] >= 250.0 and ledger["tokens_spent"] < 400.0, "a free account spends its starting tokens plus a little salvage %s" % str(ledger["tokens_spent"]))
	_check(free["windows"]["days_2_7"]["draws_per_account_per_day"] == 0.0, "a free account has nothing to draw with after the first day")

	var income: Dictionary = first["cells"]["free/proposed_120_per_day"]["collection"]
	_check(income["windows"]["days_2_7"]["draws_per_account_per_day"] >= 12.0, "120 tokens a day buys at least twelve draws a day")
	_check(income["windows"]["days_2_7"]["useful_share"] <= income["windows"]["days_2_7"]["new_item_share"], "a draw is useful no more often than it is new")
	_check(income["checkpoints"]["day_9"]["gear"]["mean"] > free["checkpoints"]["day_9"]["gear"]["mean"], "income grows the collection past the free baseline")

	var high: Dictionary = first["cells"]["high/implemented"]["collection"]
	_check(high["token_ledger"]["tokens_purchased"] == 800.0, "purchases arrive on their schedule (days 1 and 8)")

	var progression: Dictionary = first["cells"]["free/implemented"]["progression"]
	_check(progression["points"].has("hour_3"), "the progression sample records its checkpoints")
	_check(progression["points"]["hour_3"]["level"]["mean"] > progression["points"]["hour_1"]["level"]["mean"], "the simulated adventurer keeps levelling")
	_check(progression["seconds_to_first_boss_kill"][0] > 0.0, "the first boss kill is timed")
	_check(first["power_gaps"].has("high/implemented"), "paying cohorts are compared with the free cohort")

	print("Economy tests complete: %d failure(s)" % failures)
	quit(failures)
