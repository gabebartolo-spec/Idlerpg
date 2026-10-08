extends SceneTree

# Input and layout checks for the management UI, driven by synthetic touches.
# These prove the list logic and the layout. They do not prove how it feels on a phone.

const AdventureScreenScript = preload("res://src/ui/adventure_screen.gd")
const LoadoutScreenScript = preload("res://src/ui/loadout_screen.gd")
const RelicScreenScript = preload("res://src/ui/relic_screen.gd")
const ChronicleScreenScript = preload("res://src/ui/chronicle_screen.gd")
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
	await _test_management_batch()
	await _test_chronicle_screens()
	await _test_chronicle_screen()
	await _test_new_management()
	await _test_collection_pursuit()
	print("UI tests complete: %d failure(s)" % failures)
	quit(failures)

func _test_collection_pursuit() -> void:
	var sim: Node = AdventurerSimScript.new()
	var game: Node = GameStateScript.new()
	root.add_child(sim)
	root.add_child(game)
	var screen: Control = GachaScreenScript.new()
	root.add_child(screen)
	screen.setup(sim, game)
	screen.show_mode("pursuit")
	screen.open()
	await _settle()
	_check(screen.pursuit_detail.text.contains("maximum 300") and screen.pursuit_detail.text.contains("expected"), "a missing-item pursuit publishes its costs before drawing")
	_on_screen([screen.pursuit_button])
	_check(screen.pursuit_list.size.y >= 128.0, "pursuit browsing retains room for two touch rows")
	await _tap(screen.pursuit_button.get_global_rect().get_center())
	_check(not game.pursuits.get("gear", {}).is_empty(), "pursuit confirmation chooses the previewed item by touch")
	var chosen: String = game.pursuits["gear"]["target"]
	game.pursuits["gear"]["progress"] = 12
	screen.pursuit_selected = "Iron Sword" if chosen != "Iron Sword" else "Leather Hood"
	screen.refresh()
	await _settle()
	_check(screen.pursuit_button.text.contains("resets 12/30"), "switching pursuit warns of the lost progress before confirmation")
	for item in game.collection_items("gear"):
		game.collection["gear"][item] = 1
	game.pursuits.erase("gear")
	screen.refresh()
	await _settle()
	_check(screen.pursuit_button.disabled and screen.pursuit_detail.text.contains("Optional keepsake"), "a complete banner explains its cosmetic pursuit and blocks missing-item selection")
	_on_screen([screen.pursuit_button])
	screen.free()
	sim.free()
	game.free()

func _test_chronicle_screens() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	for i in 30:
		sim.chronicle.record("gear:%d" % i, "A real milestone with a management link.", "gear", i, "Iron Sword")
	var report: Control = load("res://src/ui/return_screen.gd").new()
	root.add_child(report)
	report.setup()
	report.talent_button.visible = true
	report.show_report({"highlights": sim.chronicle.highlights_since(0)}, "Totals\n".repeat(35))
	report.destination_requested.connect(func(route: String, target: String) -> void: _count("return" + route + target))
	await _settle()
	await _tap(report.list.content.get_child(0).get_global_rect().get_center())
	_check(int(presses.get("returngearIron Sword", 0)) == 1, "return highlight uses touch-owned navigation")
	_check(report.list.max_offset() > 0, "long return totals remain scrollable")
	_check(root.get_visible_rect().encloses(report.talent_button.get_global_rect()), "return talent action remains reachable in portrait")
	report.show_report({}, "No new milestones during this return.")
	await _settle()
	_check(report.list.content.get_child_count() == 1, "a no-event report clears old highlight rows")
	report.free()
	sim.free()

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
	presses.clear()
	await _swipe(top, top + Vector2(140.0, 0.0))
	_check(presses.is_empty(), "a sideways swipe never presses a row")
	_touch(top, true)
	_touch(top + Vector2(100.0, 0.0), false)
	_check(presses.is_empty(), "a moved release without drag events never presses a row")
	_touch(top, true)
	var canceled := InputEventScreenTouch.new()
	canceled.index = 0
	canceled.position = top
	canceled.canceled = true
	root.push_input(canceled, true)
	_check(presses.is_empty() and not list.is_scrolling(), "a cancelled touch does not select a row")
	await _tap(top)
	_check(not presses.is_empty(), "the next touch works after cancellation")
	presses.clear()
	_touch(top, true)
	list.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_touch(top, false)
	_check(presses.is_empty(), "losing focus cancels the pending tap")
	list.velocity = 500.0
	_touch(top, true)
	_touch(top, false)
	_check(presses.is_empty() and list.velocity == 0.0, "catching a flick stops it without pressing a row")
	await _tap(top)
	_check(not presses.is_empty(), "a second stationary tap selects after catching a flick")
	presses.clear()
	list.scroll_to(400.0)
	list.velocity = 500.0
	var wheel := InputEventMouseButton.new()
	wheel.position = top
	wheel.pressed = true
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.factor = 0.5
	root.push_input(wheel, true)
	_check(list.velocity == 0.0 and is_equal_approx(list.offset, 355.0), "wheel scrolling stops momentum and respects fractional wheel motion")

	list.scroll_to(400.0)
	_fill(list, 20)
	await _settle()
	_check(is_equal_approx(list.offset, 400.0), "rebuilding the rows keeps the scroll position")
	_fill(list, 3)
	await _settle()
	_check(list.offset == 0.0, "a list that now fits snaps back to the top")

	_fill(list, 20)
	await _settle()
	list.scroll_to(200.0)
	list.velocity = 1000.0
	_touch(top, true)
	list.velocity = 1000.0
	list.visible = false
	var hidden_offset: float = list.offset
	await _settle()
	_check(list.offset == hidden_offset and list.velocity == 0.0 and not list.is_scrolling(), "hiding a list stops momentum without moving its position")
	await _swipe(bottom, top)
	_check(list.offset == hidden_offset, "a hidden list ignores touches")
	list.visible = true
	await _tap(top)
	_check(not presses.is_empty(), "reopened lists accept a new gesture")
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
	_check(screen.caption_label.text.contains("Gold") and screen.caption_label.text.contains("Tokens"), "gear shows both disposal currencies")
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
	screen.select("Crownblade")
	screen.set_slot_filter("feet")
	_check(screen.selected.is_empty() and screen.equip_button.disabled and screen.sell_button.disabled, "filtering away a selection clears hidden-item actions")
	screen.select(screen.visible_items()[0])
	var selected_feet: String = screen.selected
	screen.set_slot_filter("")
	_check(screen.selected == selected_feet, "returning to All keeps a selection that remains visible")
	screen.set_slot_filter("")
	await _settle()
	list.scroll_to(300.0)
	screen.select("Crownblade")
	screen.set_slot_filter("")
	_check(screen.selected == "Crownblade" and list.offset == 300.0, "retapping the active gear filter preserves the browsing position")
	screen.lock_button.pressed.emit()
	await _settle()
	_check(game.is_locked("Crownblade") and screen.sell_button.disabled and screen.salvage_button.disabled, "gear can be locked directly and blocks both disposal actions")
	_check(screen.lock_button.text == "Unlock", "locked gear offers Unlock directly")
	var locked_row: Control = screen.rows["Crownblade"]
	_check(locked_row.get_child(0).get_child(1).get_child(1).text.begins_with("Locked"), "locked gear is marked while browsing")
	screen.lock_button.pressed.emit()
	await _settle()
	_check(not game.is_locked("Crownblade") and not screen.sell_button.disabled, "unlocking restores disposal actions")
	sim.equip_gear("Crownblade")
	screen.refresh()
	_check(screen.detail_compare.text.contains("last copy") and screen.sell_button.disabled, "last-copy equipment protection explains how to dispose of it")
	_on_screen([screen.lock_button])

	game.set_locked("Crownblade", true)
	screen.select("Crownblade")
	_check(screen.sell_button.disabled and screen.salvage_button.disabled, "locked gear cannot be sold or salvaged")
	var back := InputEventAction.new()
	back.action = "ui_cancel"
	back.pressed = true
	root.push_input(back, true)
	await _settle()
	_check(not screen.visible, "Cancel closes a management sheet")
	screen.open()
	await _settle()
	_check(screen.visible, "a management sheet can reopen after Cancel")

	screen.free()
	sim.free()
	game.free()

func _test_management_batch() -> void:
	var game: Node = GameStateScript.new()
	var sim: Node = AdventurerSimScript.new()
	root.add_child(game)
	root.add_child(sim)
	for item_name in GearCatalogScript.ITEMS:
		sim.add_gear(item_name)
	sim.equip_gear("Iron Sword")
	sim.equip_gear("Leather Hood")
	var gear: Control = GearScreenScript.new()
	root.add_child(gear)
	gear.setup(sim, game)
	gear.open()
	await _settle()
	_on_screen([gear.sort_button, gear.worn_button, gear.favourite_button])
	gear.sort_button.pressed.emit()
	var first: String = gear.visible_items()[0]
	var worn: String = sim.equipped_item(GearCatalogScript.slot(first))
	_check(GearCatalogScript.attack_bonus(first) >= GearCatalogScript.attack_bonus(worn) and GearCatalogScript.hp_bonus(first) >= GearCatalogScript.hp_bonus(worn) and first != worn, "upgrade sorting puts an improvement before worn gear")
	gear.worn_button.pressed.emit()
	_check(gear.rows.size() == 2 and gear.rows.has("Iron Sword") and gear.rows.has("Leather Hood"), "worn-only browsing shows exactly equipped items")
	gear.worn_button.pressed.emit()
	gear.sort_button.pressed.emit()
	gear.select("Iron Sword")
	gear.favourite_button.pressed.emit()
	_check(game.is_favourite("Iron Sword") and gear.visible_items()[0] == "Iron Sword", "direct gear favourites persist in state and sort first")
	sim.add_gear("Iron Sword")
	gear.refresh()
	_check(gear.detail_name.text.contains("×2"), "selected gear states its copy count")
	gear.select("Briarhook")
	_check(gear.detail_compare.text.contains("Source:"), "world gear explains its source")
	var hook_count: int = sim.gear_count("Briarhook")
	gear._salvage_selected()
	_check(gear.salvage_button.disabled and sim.gear_count("Briarhook") == hook_count, "zero-token world salvage cannot destroy an item")
	gear.select("Crownblade")
	var gold: int = sim.gold
	gear._sell_selected()
	_check(sim.gear_count("Crownblade") == 1 and gear.sell_button.text == "Confirm sell", "a valuable sale requires confirmation before changing inventory")
	gear._sell_selected()
	_check(sim.gear_count("Crownblade") == 0 and sim.gold == gold + GearCatalogScript.sell_value("Crownblade"), "confirming a valuable sale pays and removes exactly one item")
	sim.add_gear("Crownblade")
	gear.refresh()
	gear.select("Crownblade")
	gear._sell_selected()
	gear.close()
	gear.open()
	gear._sell_selected()
	_check(sim.gear_count("Crownblade") == 1, "reopening cannot retain a pending disposal confirmation")
	gear._process(6.0)
	_check(gear.pending_disposal.is_empty(), "valuable-item confirmations expire")
	sim.gold = 4321
	game.gacha_tokens = 765
	await _settle()
	_check(gear.caption_label.text.contains("4321") and gear.caption_label.text.contains("765"), "gear balances update while the panel remains open")
	gear.set_slot_filter("feet")
	gear.select("Crownblade")
	_check(gear.selected.is_empty(), "hidden gear cannot be selected through an alternate entry point")
	gear.free()

	game.set_dev_infinite_tokens(true)
	var gacha: Control = GachaScreenScript.new()
	root.add_child(gacha)
	gacha.setup(sim, game)
	gacha.open()
	_check(gacha.banner_label.text.contains("68% common") and gacha.banner_label.text.contains("1% legendary"), "summon odds are published from the same data as the draw logic")
	gacha.summon(10)
	var result_row: Control = gacha.results_list.content.get_child(1)
	var result_name: String = result_row.get_meta("key")
	gacha._on_result_row(result_row)
	_check(gacha.mode == "collection" and gacha.selected_item == result_name, "a summon result opens its collection details")
	for item_name in game.collection_items("gear"):
		game.collection["gear"][item_name] = 1
	gacha.refresh()
	await _settle()
	gacha.collection_list.scroll_to(150.0)
	gacha.select_banner("companions")
	await _settle()
	gacha.select_banner("gear")
	await _settle()
	_check(is_equal_approx(gacha.collection_list.offset, 150.0), "each banner restores its own collection position")
	gacha._show_results("Duplicates", [{"name": "Iron Sword", "rarity": "Common", "copy": 2}])
	_check(gacha.results_list.content.get_child(1).get_child(0).get_child(1).text.contains("copy 2"), "summon results identify duplicate copy numbers")
	gacha.select_banner("relics")
	gacha.summon(1)
	gacha.show_mode("collection")
	gacha.select_item(game.recent_summons(1)[0]["name"])
	_check(gacha.use_button.visible and gacha.detail_text.text == load("res://src/data/relic_catalog.gd").description(gacha.selected_item), "relic details describe the implemented equip effect")
	gacha.show_mode("history")
	_check(gacha.history_list.content.get_child(0).get_child(0).get_child(0).get_child(1).text.contains("Relic Vault"), "summon history identifies its source banner")
	gacha.free()

	var talents: Control = TalentScreenScript.new()
	root.add_child(talents)
	sim.hero_level = 3
	talents.setup(sim)
	talents.select("heavy_hand")
	_check(talents.learn_button.text.contains("1 point"), "talent learning states its exact point cost")
	talents.unlock("heavy_hand")
	_check(talents.tabs["slayer"].text.contains("1/4"), "branch tabs show learned progress")
	talents.free()

	var boss: Control = BossScreenScript.new()
	root.add_child(boss)
	boss.setup(sim)
	boss.open()
	boss.select("hunt:carapace")
	_check(boss.act_button.text == "Equip Thornback Carapace" and not boss.act_button.disabled, "owned hunt rewards can be equipped directly from their hunt row")
	boss.act()
	_check(sim.equipped_item("chest") == "Thornback Carapace", "the hunt equip action uses the authoritative inventory")
	sim.hunt_progress["briarhook"] = 12
	boss._process(1.1)
	_check(boss.rows["hunt:briarhook"].get_child(0).get_child(2).text == "Owned", "boss updates preserve the owned reward state")
	sim.gear_inventory.erase("Briarhook")
	boss._process(1.1)
	_check(boss.rows["hunt:briarhook"].get_child(0).get_child(2).text.contains("12"), "hunt progress refreshes while the screen stays open")
	boss.free()
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
	_check(screen.reset_button.disabled, "Reset is disabled when no talents have been learned")

	var points: int = sim.talent_points_available()
	await _tap(_row_centre(screen.list, screen.rows[talents[0]]))
	_check(screen.selected == talents[0], "tapping a talent selects it")
	_check(sim.talent_points_available() == points and not sim.has_talent(talents[0]), "tapping a talent does not spend a point")
	_check(not screen.learn_button.disabled, "a talent that can be learned enables Learn")
	screen.show_branch(branch)
	_check(screen.selected == talents[0], "retapping the current talent branch preserves the selection")

	screen.learn_button.pressed.emit()
	await _settle()
	_check(sim.has_talent(talents[0]) and sim.talent_points_available() == points - 1, "Learn spends one point on the chosen talent")
	_check(screen.learn_button.disabled, "a learned talent cannot be learned again")
	_check(not screen.reset_button.disabled, "learned talents enable Reset")

	screen.reset_button.pressed.emit()
	await _settle()
	_check(not sim.has_talent(talents[0]) and sim.talent_points_available() == points, "Reset gives the points back")
	_check(screen.reset_button.disabled, "Reset disables again after refunding talents")

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
	game.set_dev_infinite_tokens(false)
	game.gacha_tokens = game.SUMMON_COST
	screen.refresh_wallet()
	_check(not screen.summon_one.disabled and screen.summon_ten.disabled, "summon buttons distinguish an affordable single from an unaffordable ten-pull")
	game.gacha_tokens = 0
	screen.refresh_wallet()
	_check(screen.summon_one.disabled and screen.summon_ten.disabled, "an empty wallet disables both summon buttons")
	game.set_dev_infinite_tokens(true)
	screen.refresh_wallet()
	_check(not screen.summon_one.disabled and not screen.summon_ten.disabled, "dev infinite tokens enable both summon buttons")
	_check(screen.summon_one.text.contains("tokens") and screen.summon_ten.text.contains("tokens"), "summon costs state their currency")
	var gear_before: int = sim.owned_gear_names().size()
	screen.summon_ten.pressed.emit()
	await _settle()
	_check(game.recent_summons(20).size() == 10, "Summon x10 makes ten pulls")
	_check(sim.owned_gear_names().size() > gear_before, "gear pulls reach the adventurer's inventory")
	_check(screen.results_list.content.get_child_count() >= 2, "the results list shows what was pulled")
	_check(screen.results_list.content.get_child_count() == 11, "normal ten-pulls show every result including common duplicates")
	var first_summary: String = screen.results_list.content.get_child(0).text
	screen.select_banner("relics")
	_check(screen.results_list.content.get_child_count() == 1, "a new banner does not show another banner's results")
	screen.select_banner("gear")
	_check(screen.results_list.content.get_child_count() == 11 and screen.results_list.content.get_child(0).text == first_summary, "switching back restores that banner's results")

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
	_check(screen.detail_text.text.contains("attack") and screen.detail_text.text.contains("health"), "collected gear explains its combat stats")
	if not missing.is_empty():
		screen._on_collection_row(screen.rows[missing])
		_check(screen.selected_item == owned, "an item not found yet cannot be selected")
		screen.select_item(missing)
		_check(screen.selected_item == owned, "programmatic selection cannot choose unowned collection items")
		screen.selected_item = missing
		screen.toggle_lock()
		screen.toggle_favourite()
		_check(not game.is_locked(missing) and not game.is_favourite(missing), "stale unowned selection cannot lock or favourite missing items")
		screen.select_item(owned)

	screen.lock_button.pressed.emit()
	await _settle()
	_check(game.is_locked(owned), "Lock protects the selected item")
	screen.favourite_button.pressed.emit()
	await _settle()
	_check(game.is_favourite(owned), "Favourite marks the selected item")
	_check(screen.content_order()[0] == owned, "favourite owned items move to the front of the collection")

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

func _test_chronicle_screen() -> void:
	var sim: Node = AdventurerSimScript.new()
	root.add_child(sim)
	for index in 40:
		sim.chronicle.record("fixture:%d" % index, "A useful find to remember %d." % index, "gear", 80)
	var screen: Control = ChronicleScreenScript.new()
	root.add_child(screen)
	screen.setup(sim)
	screen.open()
	await _settle()
	_on_screen([screen.act_button])
	var area: Rect2 = screen.list.get_global_rect()
	var low := area.position + Vector2(area.size.x * 0.5, area.size.y - 20.0)
	var high := area.position + Vector2(area.size.x * 0.5, 20.0)
	await _swipe(low, high)
	var offset: float = screen.list.offset
	_check(offset > 50.0 and screen.selected.is_empty(), "journal swipes scroll without selecting a milestone")
	await _swipe(high, low)
	_check(screen.list.offset < offset - 50.0, "journal scrolls back upward")
	screen.list.scroll_to(0.0)
	await _settle()
	await _tap(_row_centre(screen.list, screen.rows["40"]))
	_check(screen.selected == "40" and not screen.act_button.disabled, "milestone tap selects a reachable review action")
	screen.route_requested.connect(func(route: String) -> void: _count(route))
	await _tap(screen.act_button.get_global_rect().get_center())
	_check(int(presses.get("gear", 0)) == 1, "journal review links to the recorded management route once")
	screen.free()
	sim.free()

func _test_new_management() -> void:
	var sim: Node = AdventurerSimScript.new()
	var game: Node = GameStateScript.new()
	root.add_child(sim)
	root.add_child(game)
	var adventure: Control = AdventureScreenScript.new()
	root.add_child(adventure)
	adventure.setup(sim)
	adventure.open()
	await _settle()
	_on_screen([adventure.track_button, adventure.review_button])
	await _tap(_row_centre(adventure.list, adventure.rows["boss"]))
	await _tap(adventure.track_button.get_global_rect().get_center())
	_check(sim.goals.tracked == "boss", "adventure board tracks the goal chosen by touch")
	adventure.tabs["policies"].pressed.emit()
	await _settle()
	await _tap(_row_centre(adventure.list, adventure.rows["safe"]))
	await _tap(adventure.track_button.get_global_rect().get_center())
	_check(sim.adventure_policy == "safe", "policy tab selects the next outing by touch")
	_on_screen([adventure.track_button, adventure.review_button])
	adventure.free()
	sim.add_gear("Goblin Cleaver")
	sim.equip_gear("Goblin Cleaver")
	sim.loadouts.save_current(0, "My trail build", sim)
	sim.unequip_gear("Goblin Cleaver")
	var builds: Control = LoadoutScreenScript.new()
	root.add_child(builds)
	builds.setup(sim, game)
	builds.open()
	await _settle()
	_on_screen([builds.apply_button, builds.name_input])
	await _tap(builds.apply_button.get_global_rect().get_center())
	_check(sim.equipped_item("weapon") == "Goblin Cleaver", "build apply touch restores the saved equipment")
	sim.unequip_gear("Goblin Cleaver")
	sim.sell_gear("Goblin Cleaver")
	builds.refresh()
	await _settle()
	_check(builds.apply_button.disabled and builds.available_button.visible, "missing preset gear blocks complete apply and exposes explicit fallback")
	_on_screen([builds.available_button, builds.apply_button])
	builds.free()
	sim._earn_relic("Hunter's Knot")
	var relics: Control = RelicScreenScript.new()
	root.add_child(relics)
	relics.setup(sim, game)
	relics.open()
	await _settle()
	_on_screen([relics.equip_button, relics.clear_button])
	await _tap(_row_centre(relics.list, relics.rows["Hunter's Knot"]))
	await _tap(relics.equip_button.get_global_rect().get_center())
	_check(sim.active_relic == "Hunter's Knot", "free earned relic can be equipped by touch")
	await _tap(relics.clear_button.get_global_rect().get_center())
	_check(sim.active_relic.is_empty(), "unequip removes the relic by touch")
	relics.free()
	var gacha: Control = GachaScreenScript.new()
	root.add_child(gacha)
	gacha.setup(sim, game)
	gacha.select_banner("relics")
	gacha.show_mode("collection")
	gacha.select_item("Hunter's Knot")
	gacha.open()
	await _settle()
	_check(gacha.use_button.visible and gacha.detail_text.text.contains("travel"), "earned relic ownership and effect appear in the existing collection")
	gacha.use_button.pressed.emit()
	_check(sim.active_relic == "Hunter's Knot", "collection action equips the owned relic")
	gacha.free()
	sim.free()
	game.free()
