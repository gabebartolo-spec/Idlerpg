extends SceneTree

# Exercise the real main scene, not just the simulation preloads.
# Run via scripts/run_tests.sh so user:// is isolated from the player's save.

const SaveRepo = preload("res://src/state/save.gd")
var _failures := 0
var _checks := 0


func _init() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		print("FAIL [launch] " + message)
	return condition


func _run() -> void:
	# The dummy headless window otherwise defaults to a 64x64 square.
	root.size = Vector2i(720, 1280)
	if FileAccess.file_exists(SaveRepo.SAVE_PATH):
		DirAccess.remove_absolute(SaveRepo.SAVE_PATH)
	var scene = load(ProjectSettings.get_setting("application/run/main_scene"))
	if not _check(scene is PackedScene, "main scene loads"):
		quit(1)
		return
	var app = scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not _check(app.has_method("current_id"), "main script is attached"):
		app.queue_free()
		quit(1)
		return
	_check(app.current_id() == "create", "fresh install opens character creation")
	_check(not app._nav.visible, "navigation is hidden during creation")
	var create = app._stack[-1]["node"]
	create._name_edit.text = "Launch Test"
	create._on_begin()
	await process_frame
	await process_frame
	_check(app.current_id() == "bell", "creating a hero opens the bell")
	_check(app._nav.visible, "navigation is available after creation")
	_check(app._nav.get_global_rect().end.y <= app.size.y + 1, "bottom navigation fits the portrait viewport")
	_check(app._bell_tab.text == "THE BELL" and app._satchel_tab.text == "SATCHEL", "both tabs initialize")

	var home = app._stack[-1]["node"]
	_check(home._belfry_hint.text.contains("FIRST TOLL"), "home presents the next milestone")
	app.push_screen("zone")
	await process_frame
	var zone = app._stack[-1]["node"]
	_check(not home.visible and zone.visible, "pushed screens hide the underlying home")
	_check(not zone._send_button.disabled, "starting road is selectable")
	zone._on_send()
	await process_frame
	await process_frame
	_check(app.current_id() == "bell" and app.game.has_expedition(), "sending out returns to the bell")
	_check(home.visible, "popping a screen restores the home")
	_check(app._stack[-1]["node"]._state_key == "out", "countdown screen initializes")

	app.open_overlay(app.DeskSheet.new(app.game, app))
	await process_frame
	_check(app.has_overlay(), "debug desk opens")
	app.game.debug_advance(600)
	app.close_overlay()
	await process_frame
	await process_frame
	_check(app.game.has_report(), "completed expedition produces a report")
	app.push_screen("report")
	await process_frame
	_check(app.current_id() == "report", "return report opens")
	app._stack[-1]["node"]._on_continue()
	await process_frame
	_check(not app.game.has_report(), "report can be acknowledged")

	# Deterministic fixtures ensure the item sheet and vow branches are exercised.
	app.game.hero()["inventory"].append({"uid": 9999, "id": "marsh_reaver", "temper": 0})
	app.game.hero()["shards"] = 20
	app.switch_tab("satchel")
	await process_frame
	await process_frame
	var satchel = app._stack[-1]["node"]
	var before_stats: String = satchel._stats_label.text
	satchel._open_item(app.game.find_instance(9999), "weapon", false)
	await process_frame
	_check(app.has_overlay(), "inventory item sheet opens")
	app._overlay._on_equip()
	await process_frame
	await process_frame
	_check(int(app.game.equipped()["weapon"]["uid"]) == 9999, "item sheet equips gear")
	_check(satchel._stats_label.text != before_stats, "equipping refreshes the stat header")
	satchel._worn_box.get_child(0).pressed.emit()
	_check(app.has_overlay(), "refreshed worn slot opens the equipped item")
	await process_frame
	app._overlay._on_temper()
	await process_frame
	await process_frame
	_check(int(app.game.equipped()["weapon"]["temper"]) == 1, "equipped item sheet tempers gear")

	app.open_belfry("milestones")
	await process_frame
	await process_frame
	var belfry = app._stack[-1]["node"]
	_check(app.current_id() == "belfry", "Belfry navigation opens the new hub")
	_check(not belfry._claim_buttons["first_road"].disabled, "first milestone is claimable through UI")
	var gold_before := int(app.game.hero()["gold"])
	belfry._claim_buttons["first_road"].pressed.emit()
	await process_frame
	_check(app.game.hero()["gold"] == gold_before + 30, "milestone button pays its reward")
	_check(belfry._claim_buttons["first_road"].disabled, "collected reward button is disabled")
	belfry._tabs["workshop"].pressed.emit()
	await process_frame
	# Exact fixture funds make affordability and purchase deterministic.
	app.game.hero()["gold"] = 60
	belfry._refresh()
	_check(not belfry._upgrade_buttons["anvil"].disabled, "affordable upgrade can be bought")
	var might_before := int(app.game.stats()["might"])
	belfry._upgrade_buttons["anvil"].pressed.emit()
	await process_frame
	_check(app.game.stats()["might"] == might_before + 1, "workshop button upgrades the hero")
	_check(app.game.hero()["gold"] == 0, "workshop button charges the listed price")
	_check(belfry._upgrade_buttons["anvil"].disabled, "unaffordable next rank is disabled")
	_check(belfry._notice.visible, "purchase confirmation is visible")
	belfry._tabs["ledger"].pressed.emit()
	await process_frame
	_check(belfry._body.get_child_count() == app.game.content.all_items().size() + 2, "ledger shows every discovered or mystery entry")
	_check(belfry._scroll.size.y > 0, "hub content has a scrollable viewport")
	_check(belfry._scroll.get_global_rect().end.y <= app._holder.get_global_rect().end.y + 1, "Belfry content stays above navigation")

	app.game.state["pending_vows"] = [3]
	app.switch_tab("bell")
	app.after_report()
	await process_frame
	_check(app.has_overlay(), "vow choice opens")
	app._overlay._choose("wrath")
	await process_frame
	_check("wrath" in app.game.vows(), "vow choice is saved")
	app.queue_free()
	await process_frame
	await process_frame

	# A second launch must resume rather than returning to character creation.
	app = scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	_check(app.current_id() == "bell", "saved hero resumes on launch")
	_check(app.game.hero()["name"] == "Launch Test", "saved name survives relaunch")
	_check(app.game.belfry_bonuses()["might"] == 1, "workshop purchase survives relaunch")
	_check(app.game.claim_milestone("first_road") != "", "claimed milestone stays collected on relaunch")
	app.open_belfry("workshop")
	await process_frame
	_check(app._stack[-1]["node"]._art.ranks["might"] == 1, "Belfry illustration reflects saved restoration")
	app.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(SaveRepo.SAVE_PATH)
	if _failures == 0:
		print("LAUNCH TESTS PASSED — %d checks" % _checks)
	else:
		print("LAUNCH TESTS FAILED — %d of %d checks" % [_failures, _checks])
	quit(1 if _failures > 0 else 0)
