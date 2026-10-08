extends Control

# A vertical list that owns its own touches, so scrolling behaves the same on a phone
# and on a desktop and can be tested with synthetic input.
#
# Godot's ScrollContainer only drag-scrolls on a real touchscreen, and buttons inside it
# compete with it for the same touch. Here the list takes every touch that starts inside
# it: a touch that moves is a scroll (either direction), a touch that does not is a tap.
# Rows never see input themselves, so nothing can intercept a swipe half way.
#
# Add rows to `content`. A tap presses the Button under the finger, if any, and always
# reports the row through `row_tapped`.

signal row_tapped(row: Control)

const DRAG_THRESHOLD := 16.0
const FRICTION := 5.0
const WHEEL_STEP := 90.0
const BAR_WIDTH := 6.0

var content: VBoxContainer
var offset: float = 0.0
var velocity: float = 0.0

var _touch: int = -1
var _touch_start: Vector2 = Vector2.ZERO
var _dragging: bool = false

func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	content = VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	content.child_entered_tree.connect(_mute)
	content.minimum_size_changed.connect(_layout)
	add_child(content)
	resized.connect(_layout)
	visibility_changed.connect(_cancel_gesture)

func _cancel_gesture() -> void:
	_touch = -1
	_dragging = false
	velocity = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_cancel_gesture()

func max_offset() -> float:
	return max(0.0, content.size.y - size.y)

func scroll_to(value: float) -> void:
	offset = clampf(value, 0.0, max_offset())
	content.position = Vector2(0.0, -offset)
	queue_redraw()

func is_scrolling() -> bool:
	return _dragging

func is_interacting() -> bool:
	return _touch != -1 or abs(velocity) >= 8.0

# Rows must not handle input themselves: the list decides what each touch means.
func _mute(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_mute(child)

func _layout() -> void:
	content.size = Vector2(size.x, content.get_combined_minimum_size().y)
	scroll_to(offset)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_cancel_gesture()
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch == -1 and get_global_rect().has_point(touch.position):
				_touch = touch.index
				_touch_start = touch.position
				# A touch catches a moving list; it must not also select the row.
				_dragging = abs(velocity) >= 8.0
				velocity = 0.0
				get_viewport().set_input_as_handled()
		elif touch.index == _touch:
			_touch = -1
			if touch.canceled:
				_cancel_gesture()
			elif not _dragging and touch.position.distance_to(_touch_start) <= DRAG_THRESHOLD:
				velocity = 0.0
				_tap(touch.position)
			_dragging = false
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index != _touch:
			return
		if not _dragging and drag.position.distance_to(_touch_start) > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			scroll_to(offset - drag.relative.y)
			velocity = -drag.velocity.y
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and get_global_rect().has_point(button.position):
			if button.button_index not in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
				return
			velocity = 0.0
			if button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				scroll_to(offset + WHEEL_STEP * button.factor)
			elif button.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll_to(offset - WHEEL_STEP * button.factor)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# Carry a flick on after the finger lifts.
	if not is_visible_in_tree():
		_cancel_gesture()
		return
	if _touch != -1 or abs(velocity) < 8.0:
		return
	var before := offset
	scroll_to(offset + velocity * delta)
	velocity *= exp(-FRICTION * delta)
	if is_equal_approx(before, offset):
		velocity = 0.0

func _tap(at: Vector2) -> void:
	if not get_global_rect().has_point(at):
		return
	for row in content.get_children():
		var control := row as Control
		if control == null or not control.visible or not control.get_global_rect().has_point(at):
			continue
		var button := _button_at(control, at)
		if button != null:
			button.pressed.emit()
		row_tapped.emit(control)
		return

func _button_at(node: Control, at: Vector2) -> BaseButton:
	for child in node.get_children():
		var control := child as Control
		if control != null and control.visible and control.get_global_rect().has_point(at):
			var inner := _button_at(control, at)
			if inner != null:
				return inner
	var button := node as BaseButton
	if button != null and not button.disabled:
		return button
	return null

func _draw() -> void:
	if max_offset() <= 0.0:
		return
	var length: float = max(40.0, size.y * size.y / content.size.y)
	var top: float = (size.y - length) * offset / max_offset()
	draw_rect(Rect2(size.x - BAR_WIDTH, top, BAR_WIDTH, length), Color(1.0, 1.0, 1.0, 0.28))
