extends RefCounted

# The player's say over the watch camera: swipe sideways to orbit the adventurer, pinch (or
# mouse wheel) to move closer or further away. Issue #43.
#
# This only ever changes how the camera looks at the world. The camera keeps following the
# adventurer on its own, nothing here moves the hero, and the simulation never hears of it.
# The chosen angle and distance live here, apart from where the camera currently is, so
# walking somewhere else or switching activity never puts them back to the default.
#
# main.gd feeds every input event in. A touch only counts as a camera gesture if
# `start_allowed` says the spot it landed on is open world, so buttons, sheets and lists
# keep their touches. Events are never marked as handled; a gesture that did not start in
# the world is simply not ours.

const YAW_PER_PIXEL := 0.005
# A touch that barely moves is a tap, not a swipe.
const SWIPE_SLOP := 10.0
const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.6
const WHEEL_ZOOM := 0.9
# Two fingers closer than this are treated as this far apart, so a pinch never divides by zero.
const MIN_SPAN := 24.0

# Turn (radians) and distance multiplier relative to the default camera offset.
var yaw: float = 0.0
var zoom: float = 1.0
# Given a screen position, may a camera gesture begin there?
var start_allowed: Callable = Callable()

var _touches: Dictionary = {}
var _starts: Dictionary = {}
# Fingers that are part of (or were left over from) a pinch: they never turn into an orbit.
var _spent: Dictionary = {}
var _swiping: bool = false
var _pinch_span: float = 0.0
var _pinch_zoom: float = 1.0

func is_active() -> bool:
	return not _touches.is_empty()

# Gesture state only. The chosen angle and distance stay.
func cancel() -> void:
	_touches.clear()
	_starts.clear()
	_spent.clear()
	_swiping = false

func set_view(new_yaw: float, new_zoom: float) -> void:
	yaw = wrapf(new_yaw, -PI, PI)
	zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)

# The camera's offset from what it follows, given the default offset for this scene.
func offset(base: Vector3) -> Vector3:
	return base.rotated(Vector3.UP, yaw) * zoom

func handle_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_press(touch.index, touch.position)
		else:
			_release(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_move(drag.index, drag.position, drag.relative)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and _allowed(button.position):
			var change: float = pow(WHEEL_ZOOM, maxf(button.factor, 1.0))
			zoom = clampf(zoom * (change if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / change), MIN_ZOOM, MAX_ZOOM)

func _allowed(at: Vector2) -> bool:
	return start_allowed.is_valid() and bool(start_allowed.call(at))

func _press(index: int, at: Vector2) -> void:
	if _touches.has(index) or _touches.size() >= 2 or not _allowed(at):
		return
	_touches[index] = at
	_starts[index] = at
	if _touches.size() == 2:
		# Two fingers is a pinch. Neither finger may start turning the camera afterwards.
		for key in _touches:
			_spent[key] = true
		_swiping = false
		_pinch_span = _span()
		_pinch_zoom = zoom

func _release(index: int) -> void:
	_touches.erase(index)
	_starts.erase(index)
	_spent.erase(index)
	if _touches.is_empty():
		_swiping = false

func _move(index: int, at: Vector2, relative: Vector2) -> void:
	if not _touches.has(index):
		return
	_touches[index] = at
	if _touches.size() == 2:
		# Fingers apart means closer: the distance changes by the opposite ratio.
		zoom = clampf(_pinch_zoom * _pinch_span / _span(), MIN_ZOOM, MAX_ZOOM)
		return
	if _spent.has(index):
		return
	if not _swiping:
		if at.distance_to(_starts[index]) < SWIPE_SLOP:
			return
		_swiping = true
	# Only the sideways part turns the camera. Dragging right pulls the world with the finger.
	yaw = wrapf(yaw - relative.x * YAW_PER_PIXEL, -PI, PI)

func _span() -> float:
	var points: Array = _touches.values()
	return maxf((points[0] as Vector2).distance_to(points[1] as Vector2), MIN_SPAN)
