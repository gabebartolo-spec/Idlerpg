extends SceneTree

# Input and layout checks for the management UI, driven by synthetic touches.
# These prove the list logic and the layout. They do not prove how it feels on a phone.

const TouchListScript = preload("res://src/ui/touch_list.gd")
const GearScreenScript = preload("res://src/ui/gear_screen.gd")
const TalentScreenScript = preload("res://src/ui/talent_screen.gd")
const GachaScreenScript = preload("res://src/ui/gacha_screen.gd")
const BossScreenScript = preload("res://src/ui/boss_screen.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")
const Style = preload("res://src/ui/ui_style.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")

var failures: int = 0
var presses: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _settle(frames: int = 3) -> void:
	for i in frames:
		await process_frame

func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	root.push_input(event, true)

func _swipe(from: Vector2, to: Vector2) -> void:
	_touch(from, true)
	var last := from
	for step in range(1, 9):
		var at := from.lerp(to, step / 8.0)
		var event := InputEventScreenDrag.new()
		event.index = 0
		event.position = at
		event.relative = at - last
		root.push_input(event, true)
		last = at
	_touch(to, false)
	await _settle()

func _tap(at: Vector2) -> void:
	_touch(at, true)
	_touch(at, false)
	await _settle()

func _count(label: String) -> void:
	presses[label] = int(presses.get(label, 0)) + 1

func _fill(list: Control, count: int) -> void:
	for child in list.content.get_children():
		list.content.remove_child(child)
		child.queue_free()
	for index in count:
		var button := Button.new()
		button.text = "Row %d" % index
		button.custom_minimum_size = Vector2(0.0, 80.0)
		button.pressed.connect(_count.bind(button.text))
		list.content.add_child(button)

func _run() -> void:
	await _test_touch_list()
	await _test_gear_screen()
	await _test_talent_screen()
	await _test_gacha_screen()
	await _test_boss_screen()
	print("UI tests complete: %d failure(s)" % failures)
	quit(failures)

func _test_touch_list() -> void:
	var list: Control = TouchListScript.new()
	list.position = Vector2(40.0, 300.0)
	list.size = Vector2(600.0, 320.0)
	root.add_child(list)
	_fill(list, 20)
	await _settle()

	var top := list.position + Vector2(300.0, 40.0)
	var bottom := list.position + Vector2(300.0, 280.0)

	_check(list.max_offset() > 1000.0, "a long list has somewhere to scroll")
	await _swipe(bottom, top)
	var scrolled: float = list.offset
	_check(scrolled > 200.0, "swiping up scrolls the list down")
	await _swipe(top, bottom)
	_check(list.offset < 5.0, "swiping down scrolls the list back up")
	_check(presses.is_empty(), "swiping across buttons presses none of them")

	list.scroll_to(list.max_offset())
	await _swipe(bottom, top)
	_check(is_equal_approx(list.offset, list.max_offset()), "the list stops at its end")
	await _swipe(top, bottom)
	_check(list.offset < list.max_offset() - 200.0, "the list scrolls back up from its very end")

	list.scroll_to(160.0)
	await _tap(list.position + Vector2(300.0, 40.0))
	_check(presses == {"Row 2": 1}, "a tap presses exactly the row under the finger, once %s" % str(presses))

	list.scroll_to(400.0)
	_fill(list, 20)
	await _settle()
	_check(is_equal_approx(list.offset, 400.0), "rebuilding the rows keeps the scroll position")
	_fill(list, 3)
	await _settle()
	_check(list.offset == 0.0, "a list that now fits snaps back to the top")

	_fill(list, 20)
	await _settle()
	list.visible = false
	await _swipe(bottom, top)
	_check(list.offset == 0.0, "a hidden list ignores touches")
	list.free()

func _test_gear_screen() -> void:
	var game: Node = GameStateScript.new()
	root.add_child(game)
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	for item_name in GearCatalogScript.ITEMS:
		sim.add_gear(item_name)

	var screen: Control = GearScreenScript.new()
	root.add_child(screen)
	screen.setup(sim, game)
	screen.open()
	await _settle()

	var view := root.get_visible_rect()
	var list: Control = screen.list
	_check(screen.rows.size() == GearCatalogScript.ITEMS.size(), "every owned item has a row")
	_check(list.max_offset() > 0.0, "a full inventory needs scrolling")
	_check(list.size.y >= screen.ROW_HEIGHT * 2.0, "at least two rows are visible at once")
	_check(is_equal_approx(list.get_global_rect().size.x, view.size.x - 40.0), "the sheet spans the screen width")
	_check(list.get_global_rect().position.y > view.size.y * screen.WORLD_SHARE, "the sheet leaves the top of the screen to the world")

	for button in [screen.equip_button, screen.sell_button, screen.salvage_button]:
		var rect: Rect2 = button.get_global_rect()
		_check(view.encloses(rect) and rect.size.y >= Style.TOUCH, "%s stays on screen at touch size" % button.text)

	var rect := list.get_global_rect()
	var low := rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 30.0)
	var high := rect.position + Vector2(rect.size.x * 0.5, 30.0)
	await _swipe(low, high)
	var scrolled: float = list.offset
	_check(scrolled > 100.0, "the gear list scrolls down")
	await _swipe(high, low)
	_check(list.offset < scrolled - 100.0, "the gear list scrolls back up")

	list.scroll_to(300.0)
	await _tap(high)
	var chosen: String = screen.selected
	_check(not chosen.is_empty(), "tapping a row selects its item")
	_check(not screen.equip_button.disabled, "a selected item can be equipped")
	screen.equip_button.pressed.emit()
	await _settle()
	_check(sim.equipped_item(GearCatalogScript.slot(chosen)) == chosen, "Equip puts the selected item on")
	_check(is_equal_approx(list.offset, 300.0), "equipping keeps the list where it was")

	screen.close()
	screen.open()
	await _settle()
	_check(is_equal_approx(list.offset, 300.0) and screen.selected == chosen, "closing and reopening keeps position and selection")

	screen.set_slot_filter("feet")
	await _settle()
	_check(screen.rows.size() == 4 and list.offset == 0.0, "a slot filter shows only that slot, from the top")
	screen.set_slot_filter("")
	await _settle()

	game.set_locked("Crownblade", true)
	screen.select("Crownblade")
	_check(screen.sell_button.disabled and screen.salvage_button.disabled, "locked gear cannot be sold or salvaged")

	screen.free()
	sim.free()
	game.free()

func _on_screen(buttons: Array) -> void:
	var view := root.get_visible_rect()
	for button in buttons:
		var rect: Rect2 = button.get_global_rect()
		_check(view.encloses(rect) and rect.size.y >= Style.TOUCH, "%s stays on screen at touch size" % button.text)

func _row_centre(screen_list: Control, row: Control) -> Vector2:
	return row.get_global_rect().get_center()

func _test_talent_screen() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	sim.hero_level = 3

	var screen: Control = TalentScreenScript.new()
	root.add_child(screen)
	screen.setup(sim)
	screen.open()
	await _settle()

	var branch: String = screen.branch
	var talents: Array[String] = TalentCatalogScript.nodes_for_branch(branch)
	_check(screen.rows.size() == talents.size(), "every talent in the branch has a row")
	_on_screen([screen.learn_button, screen.reset_button])
	_check(screen.learn_button.disabled, "nothing can be learned before a talent is chosen")

	var points: int = sim.talent_points_available()
	await _tap(_row_centre(screen.list, screen.rows[talents[0]]))
	_check(screen.selected == talents[0], "tapping a talent selects it")
	_check(sim.talent_points_available() == points and not sim.has_talent(talents[0]), "tapping a talent does not spend a point")
	_check(not screen.learn_button.disabled, "a talent that can be learned enables Learn")

	screen.learn_button.pressed.emit()
	await _settle()
	_check(sim.has_talent(talents[0]) and sim.talent_points_available() == points - 1, "Learn spends one point on the chosen talent")
	_check(screen.learn_button.disabled, "a learned talent cannot be learned again")

	screen.reset_button.pressed.emit()
	await _settle()
	_check(not sim.has_talent(talents[0]) and sim.talent_points_available() == points, "Reset gives the points back")

	var other: String = TalentCatalogScript.branch_ids()[1]
	screen.tabs[other].pressed.emit()
	await _settle()
	_check(screen.branch == other and screen.selected.is_empty(), "a branch tab shows that branch with nothing selected")
	_check(screen.rows.has(TalentCatalogScript.nodes_for_branch(other)[0]), "the list shows the new branch's talents")

	screen.free()
	sim.free()

func _test_gacha_screen() -> void:
	var game: Node = GameStateScript.new()
	root.add_child(game)
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	game.set_dev_infinite_tokens(true)

	var screen: Control = GachaScreenScript.new()
	root.add_child(screen)
	screen.setup(sim, game)
	screen.open()
	await _settle()

	_on_screen([screen.summon_one, screen.summon_ten])
	var gear_before: int = sim.owned_gear_names().size()
	screen.summon_ten.pressed.emit()
	await _settle()
	_check(game.recent_summons(20).size() == 10, "Summon x10 makes ten pulls")
	_check(sim.owned_gear_names().size() > gear_before, "gear pulls reach the adventurer's inventory")
	_check(screen.results_list.content.get_child_count() >= 2, "the results list shows what was pulled")

	screen.mode_tabs["collection"].pressed.emit()
	await _settle()
	_check(screen.collection_view.visible and not screen.summon_view.visible, "the Collection tab shows the collection")
	_check(screen.rows.size() == game.banner_item_count("gear"), "every banner item has a collection row")
	_on_screen([screen.favourite_button, screen.lock_button])

	var list: Control = screen.collection_list
	var rect := list.get_global_rect()
	var low := rect.position + Vector2(rect.size.x * 0.5, rect.size.y - 20.0)
	var high := rect.position + Vector2(rect.size.x * 0.5, 20.0)
	await _swipe(low, high)
	var scrolled: float = list.offset
	_check(scrolled > 50.0, "the collection list scrolls down")
	await _swipe(high, low)
	_check(list.offset < scrolled - 50.0, "the collection list scrolls back up")

	var owned := ""
	var missing := ""
	for item_name in game.collection_items("gear"):
		if game.collection_count("gear", item_name) > 0 and owned.is_empty():
			owned = item_name
		elif game.collection_count("gear", item_name) <= 0 and missing.is_empty():
			missing = item_name
	list.scroll_to(0.0)
	await _settle()
	_check(screen.content_order()[0] == owned or game.collection_count("gear", screen.content_order()[0]) > 0, "owned items are listed first")
	await _tap(_row_centre(list, screen.rows[owned]))
	_check(screen.selected_item == owned, "tapping an owned item selects it")
	if not missing.is_empty():
		screen._on_collection_row(screen.rows[missing])
		_check(screen.selected_item == owned, "an item not found yet cannot be selected")

	screen.lock_button.pressed.emit()
	await _settle()
	_check(game.is_locked(owned), "Lock protects the selected item")
	screen.favourite_button.pressed.emit()
	await _settle()
	_check(game.is_favourite(owned), "Favourite marks the selected item")

	screen.banner_tabs["companions"].pressed.emit()
	await _settle()
	_check(screen.banner == "companions" and screen.selected_item.is_empty(), "changing banner clears the selection")
	screen.show_mode("summon")
	screen.summon_one.pressed.emit()
	await _settle()
	var companion: String = str(game.recent_summons(1)[0].get("name", ""))
	screen.show_mode("collection")
	await _settle()
	screen.select_item(companion)
	_check(screen.use_button.visible, "a collected companion can be asked to travel")
	screen.use_button.pressed.emit()
	await _settle()
	_check(sim.active_companion == companion, "Travel together makes it the active companion")
	_on_screen([screen.use_button])

	screen.mode_tabs["history"].pressed.emit()
	await _settle()
	_check(screen.history_view.visible and screen.history_list.content.get_child_count() == 11, "History lists every recent summon")

	screen.free()
	sim.free()
	game.free()

func _test_boss_screen() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	sim.hunt_target = "carapace"
	sim.add_gear("Briarheart Charm")
	# A lost fight to explain: rank 30 against a level 1 adventurer.
	sim.thornback_rank = 30
	sim.quest_kind = "briarfen"
	sim._start_fight("thornback")
	while sim.activity == "fighting":
		sim.advance(0.1)

	var screen: Control = BossScreenScript.new()
	root.add_child(screen)
	screen.setup(sim)
	screen.open()
	await _settle()

	var view := root.get_visible_rect()
	_check(screen.subtitle_label.text.contains("rank 30"), "the boss screen names the boss's rank")
	_check(screen.rows.has("hunt:briarhook") and screen.rows.has("hunt:carapace"), "both hunts have a row")
	_check(screen.act_button.disabled, "nothing happens until a row is chosen")
	var rect: Rect2 = screen.act_button.get_global_rect()
	_check(view.encloses(rect) and rect.size.y >= Style.TOUCH, "the action button stays on screen at touch size")

	var equip_key := ""
	for key in screen.row_actions:
		if screen.row_actions[key]["action"] == "equip" and screen.row_actions[key]["target"] == "Briarheart Charm":
			equip_key = key
	_check(not equip_key.is_empty(), "the owned counter is offered as a suggestion")
	screen.list.scroll_to(0.0)
	await _settle()
	await _tap((screen.rows[equip_key] as Control).get_global_rect().get_center())
	_check(screen.selected == equip_key and sim.equipped_item("accessory").is_empty(), "tapping a suggestion selects it without acting")
	await _tap(screen.act_button.get_global_rect().get_center())
	_check(sim.equipped_item("accessory") == "Briarheart Charm", "the button carries the suggestion out")
	_check(sim.will_challenge_boss(), "and the adventurer will now try the boss again")

	screen.select("hunt:briarhook")
	_check(not screen.act_button.disabled and screen.act_button.text == "Hunt Briarhook", "a hunt that is not active can be chosen")
	screen.act()
	_check(sim.hunt_target == "briarhook", "choosing it changes the hunt")
	screen.select("hunt:briarhook")
	_check(screen.act_button.disabled, "the active hunt has nothing left to choose")

	screen.list.scroll_to(screen.list.max_offset())
	await _settle()
	var before: float = screen.list.offset
	if before > 60.0:
		var area: Rect2 = screen.list.get_global_rect()
		await _swipe(area.position + Vector2(300.0, 40.0), area.position + Vector2(300.0, area.size.y - 20.0))
		_check(screen.list.offset < before - 40.0, "the boss screen scrolls back up")

	screen.free()
	sim.free()
