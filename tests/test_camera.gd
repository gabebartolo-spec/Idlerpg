extends SceneTree

# Swipe to orbit, pinch or wheel to zoom the watch camera (issue #43).

const CameraRigScript = preload("res://src/view/camera_rig.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

# The rig takes events directly; the main scene takes them through its own _input.
func _send(target: Object, event: InputEvent) -> void:
	if target.has_method("handle_event"):
		target.call("handle_event", event)
	else:
		target.call("_input", event)

func _touch(target: Object, index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	_send(target, event)

func _drag(target: Object, index: int, from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	event.relative = to - from
	_send(target, event)

# A one-finger swipe in steps, finger lifted at the end.
func _swipe(target: Object, from: Vector2, to: Vector2, lift: bool = true) -> void:
	_touch(target, 0, from, true)
	var last := from
	for step in range(1, 9):
		var at := from.lerp(to, step / 8.0)
		_drag(target, 0, last, at)
		last = at
	if lift:
		_touch(target, 0, to, false)

func _wheel(target: Object, at: Vector2, up: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	event.position = at
	event.factor = 1.0
	_send(target, event)

func _remove_saves() -> void:
	for path in PersistenceScript.files_for():
		if FileAccess.file_exists(path) and not path.ends_with(PersistenceScript.UNREADABLE_SUFFIX):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	_rig_tests()
	await _scene_tests()
	print("Camera tests complete: %d failure(s)" % failures)
	quit(failures)

func _rig_tests() -> void:
	var rig: RefCounted = CameraRigScript.new()
	var open_world := func(at: Vector2) -> bool: return at.y > 200.0
	rig.start_allowed = open_world

	_swipe(rig, Vector2(300, 600), Vector2(500, 600))
	var turned: float = rig.yaw
	_check(turned < 0.0 and absf(turned) > 0.5, "swiping right turns the camera, and the finger drags the world with it")
	_swipe(rig, Vector2(500, 600), Vector2(300, 600))
	_check(is_zero_approx(rig.yaw) or absf(rig.yaw) < 0.2, "swiping back turns it back by the same amount")
	_check(is_equal_approx(rig.zoom, 1.0), "a swipe never changes the zoom")

	rig.set_view(0.0, 1.0)
	_swipe(rig, Vector2(300, 600), Vector2(302, 603))
	_check(is_zero_approx(rig.yaw), "a tap or tiny wobble does not turn the camera")
	_swipe(rig, Vector2(300, 400), Vector2(300, 900))
	_check(is_zero_approx(rig.yaw), "a purely vertical swipe does not turn the camera")

	rig.set_view(0.0, 1.0)
	for _i in 12:
		_swipe(rig, Vector2(100, 600), Vector2(600, 600))
	_check(rig.yaw >= -PI and rig.yaw <= PI, "turning keeps the angle in one turn so it never grows without bound")

	# Pinch: fingers apart brings the camera closer, fingers together moves it back.
	rig.set_view(0.4, 1.0)
	_touch(rig, 0, Vector2(300, 600), true)
	_touch(rig, 1, Vector2(420, 600), true)
	_drag(rig, 0, Vector2(300, 600), Vector2(200, 600))
	_drag(rig, 1, Vector2(420, 600), Vector2(520, 600))
	_check(rig.zoom < 1.0 and rig.zoom >= rig.MIN_ZOOM, "spreading two fingers zooms in")
	_check(is_equal_approx(rig.yaw, 0.4), "a pinch never also orbits")
	var zoomed_in: float = rig.zoom
	_drag(rig, 0, Vector2(200, 600), Vector2(400, 600))
	_drag(rig, 1, Vector2(520, 600), Vector2(430, 600))
	_check(rig.zoom > zoomed_in, "bringing two fingers together zooms out")
	_drag(rig, 0, Vector2(400, 600), Vector2(10, 600))
	_drag(rig, 1, Vector2(430, 600), Vector2(710, 600))
	_check(is_equal_approx(rig.zoom, rig.MIN_ZOOM), "zoom stops at the closest allowed distance")
	_drag(rig, 0, Vector2(10, 600), Vector2(360, 600))
	_drag(rig, 1, Vector2(710, 600), Vector2(361, 600))
	_check(is_equal_approx(rig.zoom, rig.MAX_ZOOM), "zoom stops at the furthest allowed distance")

	# Lifting one finger leaves the other one unable to turn the camera until it is lifted too.
	_touch(rig, 0, Vector2(360, 600), false)
	var held_yaw: float = rig.yaw
	_drag(rig, 1, Vector2(361, 600), Vector2(600, 600))
	_check(is_equal_approx(rig.yaw, held_yaw), "the finger left after a pinch does not start an orbit")
	_touch(rig, 1, Vector2(600, 600), false)
	_check(not rig.is_active(), "lifting every finger ends the gesture")
	_swipe(rig, Vector2(300, 600), Vector2(400, 600))
	_check(not is_equal_approx(rig.yaw, held_yaw), "a fresh swipe turns the camera again")

	# Desktop mouse wheel.
	rig.set_view(0.0, 1.0)
	_wheel(rig, Vector2(360, 600), true)
	_check(rig.zoom < 1.0, "wheel up zooms in")
	_wheel(rig, Vector2(360, 600), false)
	_wheel(rig, Vector2(360, 600), false)
	_check(rig.zoom > 1.0, "wheel down zooms out")
	for _i in 60:
		_wheel(rig, Vector2(360, 600), true)
	_check(is_equal_approx(rig.zoom, rig.MIN_ZOOM), "wheel zoom stops at the closest allowed distance")
	rig.set_view(0.0, 1.0)
	_wheel(rig, Vector2(360, 50), true)
	_check(is_equal_approx(rig.zoom, 1.0), "the wheel over a blocked area does not zoom")

	# Touches that begin on a control are never the camera's.
	rig.set_view(0.0, 1.0)
	_swipe(rig, Vector2(300, 100), Vector2(600, 600))
	_check(is_zero_approx(rig.yaw) and not rig.is_active(), "a swipe that starts on a control does not orbit, even when it ends in the world")
	_touch(rig, 0, Vector2(300, 600), true)
	_touch(rig, 1, Vector2(420, 100), true)
	_drag(rig, 1, Vector2(420, 100), Vector2(600, 100))
	_check(is_equal_approx(rig.zoom, 1.0), "a second finger on a control does not start a pinch")
	_touch(rig, 0, Vector2(300, 600), false)
	_touch(rig, 1, Vector2(420, 100), false)

	# Cancelling (focus lost, a sheet opening) drops the gesture and keeps the chosen view.
	rig.set_view(1.0, 0.8)
	_touch(rig, 0, Vector2(300, 600), true)
	rig.cancel()
	_drag(rig, 0, Vector2(300, 600), Vector2(500, 600))
	_check(is_equal_approx(rig.yaw, 1.0) and is_equal_approx(rig.zoom, 0.8), "cancelling keeps the player's angle and distance and ignores the rest of the gesture")

	var base := Vector3(7.0, 6.0, 8.0)
	rig.set_view(0.0, 1.0)
	_check(rig.offset(base).is_equal_approx(base), "the default view is the old fixed camera")
	rig.set_view(PI / 2.0, 0.6)
	var moved: Vector3 = rig.offset(base)
	_check(is_equal_approx(moved.y, 3.6) and is_equal_approx(moved.length(), base.length() * 0.6), "zoom scales the offset and a turn keeps the camera's height")

func _scene_tests() -> void:
	_remove_saves()
	var packed: PackedScene = load("res://main.tscn")
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	instance.set_process(false)

	var sim: Node = instance.get("sim")
	var hero: Node3D = instance.get("hero_visual")
	var camera: Camera3D = instance.get("camera")
	var rig: RefCounted = instance.get("camera_rig")
	_check(rig != null and camera != null, "main scene creates the camera and its rig")

	instance.call("_sync_world", 10.0)
	var default_offset: Vector3 = camera.position - hero.position
	_check(default_offset.is_equal_approx(Vector3(7.0, 6.0, 8.0)), "with no player input the camera sits where it always did")

	var before: Dictionary = sim.to_save_dict()
	var hero_before: Vector3 = hero.position
	var free_spot := Vector2(360.0, 620.0)

	_swipe(instance, free_spot, free_spot + Vector2(-150.0, 0.0))
	instance.call("_sync_world", 0.0)
	var turned_offset: Vector3 = camera.position - hero.position
	_check(not turned_offset.is_equal_approx(default_offset), "a swipe on the open world turns the real camera")
	_check(is_equal_approx(turned_offset.y, default_offset.y) and is_equal_approx(turned_offset.length(), default_offset.length()), "turning keeps the camera's height and distance")
	_check(hero.position == hero_before and sim.to_save_dict() == before, "turning the camera moves neither the adventurer nor the simulation")

	_touch(instance, 0, free_spot, true)
	_touch(instance, 1, free_spot + Vector2(100.0, 0.0), true)
	_drag(instance, 0, free_spot, free_spot + Vector2(-80.0, 0.0))
	_drag(instance, 1, free_spot + Vector2(100.0, 0.0), free_spot + Vector2(180.0, 0.0))
	_touch(instance, 0, free_spot, false)
	_touch(instance, 1, free_spot, false)
	instance.call("_sync_world", 0.0)
	_check((camera.position - hero.position).length() < turned_offset.length(), "a pinch on the open world brings the real camera closer")

	# The chosen view survives the hero walking somewhere else and the scene changing.
	var chosen_yaw: float = rig.yaw
	var chosen_zoom: float = rig.zoom
	sim.hero_position = Vector3(20.0, 0.0, 12.0)
	for _i in 30:
		instance.call("_sync_world", 0.1)
	_check(is_equal_approx(rig.yaw, chosen_yaw) and is_equal_approx(rig.zoom, chosen_zoom), "walking elsewhere keeps the angle and distance")
	var follow: Vector3 = camera.position - hero.position
	_check(follow.length() < default_offset.length() * chosen_zoom + 0.5 and follow.length() > default_offset.length() * chosen_zoom - 0.5, "the camera still follows the hero at the chosen distance")
	sim.activity = "expedition"
	sim.expedition.route = "hollow"
	for _i in 60:
		instance.call("_sync_world", 0.1)
	_check(is_equal_approx(rig.yaw, chosen_yaw) and is_equal_approx(rig.zoom, chosen_zoom), "changing activity or route keeps the angle and distance")
	var woodland_offset: Vector3 = camera.position - hero.position
	_check(is_equal_approx(woodland_offset.length(), Vector3(5.6, 4.8, 6.4).length() * chosen_zoom), "the woodland camera still settles closer, scaled by the chosen zoom")

	# HUD controls keep their touches.
	rig.set_view(0.0, 1.0)
	for blocker in instance.get("hud_blockers"):
		var spot: Vector2 = (blocker as Control).get_global_rect().get_center()
		_swipe(instance, spot, spot + Vector2(-150.0, 300.0))
	_check(is_zero_approx(rig.yaw), "swiping on the HUD card or the action buttons never turns the camera")
	_check(instance.get("hud_blockers").size() == 2, "the HUD card and the Gear, Talents, Summon and More row are both protected")

	# Sheets and reports keep their touches.
	instance.call("_toggle_equipment")
	_swipe(instance, free_spot, free_spot + Vector2(-150.0, 0.0))
	_check(is_zero_approx(rig.yaw), "swipes do nothing to the camera while the Gear sheet is open")
	instance.call("_toggle_equipment")
	instance.call("_toggle_sheet", instance.get("menu_panel"))
	_swipe(instance, free_spot, free_spot + Vector2(-150.0, 0.0))
	_check(is_zero_approx(rig.yaw), "swipes do nothing to the camera while the More menu is open")
	instance.call("_toggle_sheet", instance.get("menu_panel"))
	_swipe(instance, free_spot, free_spot + Vector2(-150.0, 0.0))
	_check(not is_zero_approx(rig.yaw), "closing the sheet gives the world its swipes back")

	# A sheet opening mid-gesture drops the gesture.
	rig.set_view(0.0, 1.0)
	_touch(instance, 0, free_spot, true)
	instance.call("_toggle_equipment")
	var swipe_event := InputEventScreenDrag.new()
	swipe_event.index = 0
	swipe_event.position = free_spot + Vector2(100.0, 0.0)
	swipe_event.relative = Vector2(100.0, 0.0)
	instance.call("_input", swipe_event)
	instance.call("_toggle_equipment")
	_check(is_zero_approx(rig.yaw), "opening a sheet in the middle of a swipe ends the swipe")

	# Mouse wheel on desktop.
	rig.set_view(0.0, 1.0)
	_wheel(instance, free_spot, true)
	_check(rig.zoom < 1.0, "the mouse wheel zooms the real camera on desktop")

	# The same through the engine's own input path, as a real touch screen would deliver it.
	rig.set_view(0.0, 1.0)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = free_spot
	press.pressed = true
	root.push_input(press, true)
	for step in range(1, 7):
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = free_spot + Vector2(-25.0 * step, 0.0)
		drag.relative = Vector2(-25.0, 0.0)
		root.push_input(drag, true)
	var lift := InputEventScreenTouch.new()
	lift.index = 0
	lift.position = free_spot + Vector2(-150.0, 0.0)
	lift.pressed = false
	root.push_input(lift, true)
	_check(rig.yaw > 0.3, "a swipe delivered through the viewport reaches the camera")
	var tap_before: float = rig.yaw
	var action_row: Control = instance.get("hud_blockers")[1]
	var button_spot: Vector2 = action_row.get_child(0).get_global_rect().get_center()
	var button_press := InputEventScreenTouch.new()
	button_press.index = 0
	button_press.position = button_spot
	button_press.pressed = true
	root.push_input(button_press, true)
	var button_drag := InputEventScreenDrag.new()
	button_drag.index = 0
	button_drag.position = button_spot + Vector2(-120.0, -200.0)
	button_drag.relative = Vector2(-120.0, -200.0)
	root.push_input(button_drag, true)
	var button_lift := InputEventScreenTouch.new()
	button_lift.index = 0
	button_lift.position = button_spot + Vector2(-120.0, -200.0)
	button_lift.pressed = false
	root.push_input(button_lift, true)
	_check(is_equal_approx(rig.yaw, tap_before), "a swipe that starts on the Gear button never reaches the camera through the viewport either")

	instance.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	_remove_saves()
