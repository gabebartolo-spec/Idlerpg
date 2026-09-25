extends RefCounted

const ContentRepository = preload("res://src/sim/content_repository.gd")
const Simulator = preload("res://src/sim/expedition_simulator.gd")
const SaveRepository = preload("res://src/persistence/save_repository.gd")
const GameStore = preload("res://src/state/game_store.gd")
const FakeClock = preload("res://tests/fake_clock.gd")

var failures: Array[String] = []


func run() -> int:
	_test_identical_seed_is_identical()
	_test_partial_elapsed_time_is_not_ready()
	_test_all_routes_resolve()
	_test_equipment_can_change_outcome()
	_test_fortune_can_change_discovery()
	_test_report_rewards_are_applied_once()
	_test_saved_active_expedition_resumes()
	if failures.is_empty():
		print("PASS: all simulation tests")
		return 0
	for failure in failures:
		push_error("FAIL: " + failure)
	print("FAIL: %d simulation test(s)" % failures.size())
	return 1


func _content():
	return ContentRepository.new()


func _simulator():
	return Simulator.new()


func _test_identical_seed_is_identical() -> void:
	var content = _content()
	var simulator = _simulator()
	var adventurer: Dictionary = simulator.create_new_adventurer("Sable")
	var first: Dictionary = simulator.create_expedition(
		adventurer, "gloamroot_cavern", 1000, 77, content
	)
	var second: Dictionary = simulator.create_expedition(
		adventurer, "gloamroot_cavern", 1000, 77, content
	)
	var first_result: Dictionary = simulator.resolve_expedition(first, 1300, content)
	var second_result: Dictionary = simulator.resolve_expedition(second, 1300, content)
	_assert(
		first_result == second_result,
		"same seed and starting state should produce identical results"
	)


func _test_partial_elapsed_time_is_not_ready() -> void:
	var content = _content()
	var simulator = _simulator()
	var adventurer: Dictionary = simulator.create_new_adventurer("Sable")
	var active: Dictionary = simulator.create_expedition(
		adventurer, "gloamroot_cavern", 1000, 12, content
	)
	var result: Dictionary = simulator.resolve_expedition(active, 1100, content)
	_assert(not bool(result.get("ready", true)), "an unfinished route must remain away")
	_assert(
		int(result.get("remaining_seconds", 0)) > 0, "unfinished route should report remaining time"
	)


func _test_all_routes_resolve() -> void:
	var content = _content()
	var simulator = _simulator()
	var adventurer: Dictionary = simulator.create_new_adventurer("Sable")
	for route in content.all_routes():
		var active: Dictionary = simulator.create_expedition(
			adventurer,
			str(route.get("id", "")),
			2000,
			int(route.get("duration_seconds", 0)) + 11,
			content
		)
		var result: Dictionary = simulator.resolve_expedition(
			active, 2000 + int(route.get("duration_seconds", 0)), content
		)
		_assert(
			bool(result.get("ready", false)), "route %s should resolve" % str(route.get("id", ""))
		)
		var report: Dictionary = result.get("report", {})
		_assert(
			not report.get("events", []).is_empty(),
			"route %s should produce meaningful events" % str(route.get("id", ""))
		)
		_assert(
			str(report.get("outcome", "")).is_empty() == false,
			"route %s should have an outcome" % str(route.get("id", ""))
		)


func _test_equipment_can_change_outcome() -> void:
	var content = _content()
	var simulator = _simulator()
	var weak: Dictionary = simulator.create_new_adventurer("Sable")
	var strong: Dictionary = simulator.create_new_adventurer("Sable")
	strong.equipment = {
		"weapon": "embercleft_axe", "armor": "brambleguard_jerkin", "trinket": "watchtower_ward"
	}
	var found_difference := false
	for seed in range(1, 160):
		var weak_active: Dictionary = simulator.create_expedition(
			weak, "thornwatch_ruins", 3000, seed, content
		)
		var strong_active: Dictionary = simulator.create_expedition(
			strong, "thornwatch_ruins", 3000, seed, content
		)
		var weak_result: Dictionary = simulator.resolve_expedition(weak_active, 3900, content)
		var strong_result: Dictionary = simulator.resolve_expedition(strong_active, 3900, content)
		var weak_outcome := str(weak_result.get("report", {}).get("outcome", ""))
		var strong_outcome := str(strong_result.get("report", {}).get("outcome", ""))
		if weak_outcome != strong_outcome:
			found_difference = true
			break
	_assert(
		found_difference,
		"relevant equipment should be able to change a dangerous expedition outcome"
	)


func _test_fortune_can_change_discovery() -> void:
	var content = _content()
	var simulator = _simulator()
	var ordinary: Dictionary = simulator.create_new_adventurer("Sable")
	var lucky: Dictionary = simulator.create_new_adventurer("Sable")
	lucky.equipment["trinket"] = "luckstone"
	var found_difference := false
	for seed in range(1, 200):
		var ordinary_active: Dictionary = simulator.create_expedition(
			ordinary, "lantern_road", 3500, seed, content
		)
		var lucky_active: Dictionary = simulator.create_expedition(
			lucky, "lantern_road", 3500, seed, content
		)
		var ordinary_result: Dictionary = simulator.resolve_expedition(
			ordinary_active, 3560, content
		)
		var lucky_result: Dictionary = simulator.resolve_expedition(lucky_active, 3560, content)
		var ordinary_report: Dictionary = ordinary_result.get("report", {})
		var lucky_report: Dictionary = lucky_result.get("report", {})
		var ordinary_items: Array = ordinary_report.get("items", [])
		var lucky_items: Array = lucky_report.get("items", [])
		if ordinary_items != lucky_items:
			found_difference = true
			break
	_assert(found_difference, "Fortune should be able to change a discovery outcome")


func _test_report_rewards_are_applied_once() -> void:
	var content = _content()
	var path := "user://bramblewild_test_once.json"
	var repository = SaveRepository.new(path)
	repository.delete_save()
	var clock = FakeClock.new(4000)
	var store = GameStore.new(content, repository, clock)
	store.create_adventurer("Sable")
	_assert(store.start_expedition("lantern_road"), "test expedition should start")
	clock.value = 4060
	_assert(store.refresh(), "completed expedition should create a report")
	var xp_after_first_refresh := int(store.get_adventurer().xp)
	var gold_after_first_refresh := int(store.get_adventurer().gold)
	var inventory_after_first_refresh: Array = store.get_adventurer().inventory.duplicate()
	store.refresh()
	_assert(
		int(store.get_adventurer().xp) == xp_after_first_refresh,
		"refreshing a pending report must not duplicate XP"
	)
	_assert(
		int(store.get_adventurer().gold) == gold_after_first_refresh,
		"refreshing a pending report must not duplicate gold"
	)
	_assert(
		store.get_adventurer().inventory == inventory_after_first_refresh,
		"refreshing a pending report must not duplicate loot"
	)
	repository.delete_save()


func _test_saved_active_expedition_resumes() -> void:
	var content = _content()
	var path := "user://bramblewild_test_resume.json"
	var repository = SaveRepository.new(path)
	repository.delete_save()
	var first_clock = FakeClock.new(5000)
	var first_store = GameStore.new(content, repository, first_clock)
	first_store.create_adventurer("Sable")
	_assert(first_store.start_expedition("lantern_road"), "resume test expedition should start")
	var second_clock = FakeClock.new(5060)
	var resumed_store = GameStore.new(content, repository, second_clock)
	_assert(resumed_store.refresh(), "saved active expedition should resolve after reopening")
	_assert(
		not resumed_store.get_pending_report().is_empty(),
		"resumed expedition should have a pending report"
	)
	_assert(int(resumed_store.get_adventurer().xp) > 0, "resumed expedition should grant XP")
	repository.delete_save()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
