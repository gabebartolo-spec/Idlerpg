extends Control

# The restored bell-yard, drawn from the same bronze/ash palette as the bell.
const T = preload("res://src/ui/theme.gd")
var ranks := {"might": 0, "ward": 0, "luck": 0}


func _ready() -> void:
	custom_minimum_size.y = 150
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var cx := size.x * 0.5
	var ground := 128.0
	var bright := int(ranks["might"]) + int(ranks["ward"]) + int(ranks["luck"])
	for i in 5:
		draw_circle(Vector2(cx, 72), 28 + i * 14, Color(T.BRONZE, 0.012 + bright * 0.002))
	draw_line(Vector2(24, ground), Vector2(size.x - 24, ground), T.BRONZE_DEEP, 1.0)
	# Open belfry and its small suspended bell.
	draw_polyline(PackedVector2Array([
		Vector2(cx - 48, ground), Vector2(cx - 48, 47), Vector2(cx, 15),
		Vector2(cx + 48, 47), Vector2(cx + 48, ground)
	]), T.BRONZE_DEEP, 2.0, true)
	draw_line(Vector2(cx - 55, 47), Vector2(cx + 55, 47), T.BRONZE, 2.0)
	draw_line(Vector2(cx, 28), Vector2(cx, 57), T.BRONZE_DEEP, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 10, 57), Vector2(cx + 10, 57), Vector2(cx + 17, 81), Vector2(cx - 17, 81)
	]), T.BRONZE)
	draw_circle(Vector2(cx, 87), 3, T.BRONZE)
	# Anvil, brazier, and candles visibly light up as they are restored.
	var forge := T.BRONZE if int(ranks["might"]) > 0 else T.FAINT
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 160, 98), Vector2(cx - 102, 98), Vector2(cx - 113, 108),
		Vector2(cx - 132, 108), Vector2(cx - 128, 122), Vector2(cx - 148, 122),
		Vector2(cx - 144, 108), Vector2(cx - 160, 104)
	]), forge)
	var hearth := T.BRONZE if int(ranks["ward"]) > 0 else T.FAINT
	draw_arc(Vector2(cx, 107), 15, 0, PI, 16, hearth, 3.0, true)
	draw_line(Vector2(cx, 120), Vector2(cx, ground), hearth, 2.0)
	if int(ranks["ward"]) > 0:
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 8, 105), Vector2(cx - 2, 86), Vector2(cx + 2, 98), Vector2(cx + 7, 93), Vector2(cx + 8, 105)]), T.BRONZE)
	for i in 3:
		var x := cx + 115 + i * 15
		var y := 105 - (8 if i == 1 else 0)
		draw_rect(Rect2(x, y, 5, ground - y), T.BRONZE_DEEP)
		if int(ranks["luck"]) > 0:
			draw_circle(Vector2(x + 2.5, y - 6), 3, T.BRONZE)
	for i in bright:
		draw_circle(Vector2(cx - 28 + i * 8, 140), 1.5, T.BRONZE)
