extends SceneTree

var failures := 0
var presses := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _settle() -> void:
	for i in 4:
		await process_frame

func _run() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var safe: Control = preload("res://src/ui/safe_area.gd").new()
	layer.add_child(safe)
	safe.set_process(false)
	var menu: Control = preload("res://src/ui/menu_screen.gd").new()
	safe.add_child(menu)
	menu.setup(false)
	menu.open()
	menu.route_requested.connect(func(_route: String) -> void: presses += 1)
	var bounds := root.get_visible_rect()
	var transform := Transform2D(Vector2(0.5625, 0), Vector2(0, 0.5625), Vector2(100, 200))
	var inset := Rect2(bounds.position + Vector2(24, 64), bounds.size - Vector2(48, 112))
	safe.apply_display_area(transform * inset, transform, bounds)
	await _settle()
	_check(safe.get_global_rect().is_equal_approx(inset), "physical safe pixels map through stretch and screen origin")
	_check(inset.encloses(menu.options_button.get_global_rect()), "bottom Options action clears the simulated gesture bar")
	_check(inset.encloses(menu.routes["rewards"].get_global_rect()), "first menu action stays within inset sheet")
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = menu.options_button.get_global_rect().get_center()
		touch.pressed = pressed
		root.push_input(touch, true)
	await _settle()
	_check(presses == 1, "inset action accepts a touch in viewport coordinates")
	menu.close()
	var game: Node = preload("res://src/game.gd").new()
	root.add_child(game)
	game.presentation.larger_text = true
	var presentation: Node = preload("res://src/ui/presentation_controller.gd").new()
	root.add_child(presentation)
	presentation.setup(game.presentation, root)
	var sim: Node = preload("res://src/sim/adventurer_sim.gd").new()
	root.add_child(sim)
	sim.add_gear("Mothglass Spear")
	var gear: Control = preload("res://src/ui/gear_screen.gd").new()
	safe.add_child(gear)
	gear.setup(sim, game)
	gear.open()
	gear.select("Mothglass Spear")
	await _settle()
	for button in [gear.equip_button, gear.sell_button, gear.salvage_button]:
		_check(inset.encloses(button.get_global_rect()), "large-text %s action clears cutouts and bars" % button.text)
	_check(inset.encloses(gear.list.get_global_rect()), "large-text inventory remains inside safe bounds")
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = gear.equip_button.get_global_rect().get_center()
		touch.pressed = pressed
		root.push_input(touch, true)
	await _settle()
	_check(sim.equipped_item("weapon") == "Mothglass Spear", "safe-area Equip touch changes actual adventurer equipment")
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://art/review")
		root.get_texture().get_image().save_png("res://art/review/ui_safe_area.png")
	var changed := Rect2(bounds.position + Vector2(0, 32), bounds.size - Vector2(0, 96))
	safe.apply_display_area(transform * changed, transform, bounds)
	await _settle()
	_check(changed.encloses(gear.equip_button.get_global_rect()), "sheet anchors follow changed display insets")
	safe.apply_display_area(Rect2(), transform, bounds)
	await _settle()
	_check(safe.get_global_rect().is_equal_approx(bounds), "missing safe-area report retains usable full viewport")
	safe.apply_display_area(Rect2(9000, 9000, 1, 1), transform, bounds)
	_check(safe.get_global_rect().is_equal_approx(bounds), "invalid offscreen safe area cannot hide all controls")
	layer.queue_free()
	presentation.queue_free()
	sim.queue_free()
	game.queue_free()
	await _settle()
	quit(failures)
