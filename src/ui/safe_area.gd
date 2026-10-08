extends Control

# Keep the world edge-to-edge while every HUD and sheet uses the unobscured
# display area. Godot reports physical screen pixels; controls use viewport units.
var refresh_clock: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(refresh)
	refresh()

func _process(delta: float) -> void:
	refresh_clock -= delta
	if refresh_clock <= 0.0:
		refresh_clock = 0.5
		refresh()

func refresh() -> void:
	var viewport := get_viewport()
	var bounds := viewport.get_visible_rect()
	if OS.get_name() in ["Android", "iOS"]:
		apply_display_area(Rect2(DisplayServer.get_display_safe_area()), viewport.get_screen_transform(), bounds)
	else:
		# Desktop usable-display bounds include the taskbar and window position;
		# they should not shrink the game's own window.
		position = bounds.position
		size = bounds.size

func apply_display_area(display_area: Rect2, screen_transform: Transform2D, bounds: Rect2) -> void:
	var safe := bounds
	if display_area.has_area() and not is_zero_approx(screen_transform.determinant()):
		var mapped: Rect2 = screen_transform.affine_inverse() * display_area
		var clipped := bounds.intersection(mapped)
		if clipped.has_area():
			safe = clipped
	position = safe.position
	size = safe.size
