extends SceneTree

# Input and layout checks for the management UI, driven by synthetic touches.
# These prove the list logic and the layout. They do not prove how it feels on a phone.

const TouchListScript = preload("res://src/ui/touch_list.gd")
const GearScreenScript = preload("res://src/ui/gear_screen.gd")
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
