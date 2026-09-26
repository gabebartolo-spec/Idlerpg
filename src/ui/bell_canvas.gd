extends Control

# The bell of Vesperbell, drawn in code: a bronze silhouette that swings from
# its hanging ring when rung. No assets, one polygon, one accent of light.

const ThemeLib = preload("res://src/ui/theme.gd")

var _swing_amp := 0.0
var _swing_phase := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(300, 330)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = Vector2(150, 14)


func ring(strength: float = 1.0) -> void:
	_swing_amp = 7.0 * strength
	_swing_phase = 0.0


func _process(delta: float) -> void:
	if _swing_amp > 0.05:
		_swing_phase += delta * 8.0
		rotation = sin(_swing_phase) * deg_to_rad(_swing_amp)
		_swing_amp = lerpf(_swing_amp, 0.0, delta * 0.9)
	elif rotation != 0.0:
		rotation = 0.0


func _draw() -> void:
	var cx := size.x / 2.0
	# faint halo
	for i in 9:
		var r := 60.0 + float(i) * 22.0
		draw_circle(Vector2(cx, 150), r, Color(ThemeLib.BRONZE, 0.012))
	var bronze := ThemeLib.BRONZE
	var deep := ThemeLib.BRONZE_DEEP
	var top_y := 46.0
	var skirt_y := 234.0
	var half := 88.0
	var pts := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var f := float(i) / float(n)
		pts.push_back(Vector2(cx - half * pow(f, 1.65), top_y + (skirt_y - top_y) * f))
	for i in n + 1:
		var f := 1.0 - float(i) / float(n)
		pts.push_back(Vector2(cx + half * pow(f, 1.65), top_y + (skirt_y - top_y) * f))
	draw_colored_polygon(pts, bronze)
	draw_rect(Rect2(cx - half - 7.0, skirt_y, (half + 7.0) * 2.0, 13.0), bronze.darkened(0.18))
	draw_circle(Vector2(cx, skirt_y + 26.0), 8.0, deep)
	draw_arc(Vector2(cx, top_y - 9.0), 8.0, 0.0, TAU, 16, deep, 3.0)
	draw_line(Vector2(cx - 28.0, top_y + 44.0), Vector2(cx - 50.0, skirt_y - 12.0), Color(1, 1, 1, 0.08), 6.0)
