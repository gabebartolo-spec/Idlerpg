extends Control

# Original vector chest illustration, drawn at any phone scale.
var opened: bool = false
var reduced_motion: bool = false
var progress: float = 0.0
var reward_texture: Texture2D:
	set(value):
		reward_texture = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 230)

func _process(delta: float) -> void:
	var next := 1.0 if opened else 0.0
	var before := progress
	progress = next if reduced_motion else move_toward(progress, next, delta * 2.5)
	if before != progress:
		queue_redraw()

func _draw() -> void:
	var center := size * Vector2(.5, .58)
	var scale_ := minf(size.x / 360.0, size.y / 230.0)
	draw_set_transform(center, 0, Vector2.ONE * scale_)
	if progress > 0:
		for i in 8:
			var direction := Vector2.from_angle(i * TAU / 8)
			draw_line(direction * 65, direction * (90 + 16 * progress), Color(.89, .71, .24, .35 * progress), 3)
	draw_ellipse_shadow()
	draw_colored_polygon(PackedVector2Array([Vector2(-85,-16),Vector2(54,-16),Vector2(82,0),Vector2(82,57),Vector2(-56,57),Vector2(-85,39)]), Color("#613f28"))
	draw_colored_polygon(PackedVector2Array([Vector2(-56,0),Vector2(82,0),Vector2(82,57),Vector2(-56,57)]), Color("#98643b"))
	for x in [-38, 48]:
		draw_rect(Rect2(x, 0, 13, 57), Color("#d5a546"))
	var rise := progress * 50
	draw_colored_polygon(PackedVector2Array([Vector2(-85,-16-rise),Vector2(-57,-39-rise),Vector2(54,-39-rise),Vector2(82,-16-rise),Vector2(82,-rise),Vector2(-56,-rise)]), Color("#b8844d"))
	draw_line(Vector2(-85,-16-rise),Vector2(82,-16-rise),Color("#edc67c"),5)
	draw_rect(Rect2(2, -9, 20, 27), Color("#edc67c"))
	draw_circle(Vector2(12, 5), 4, Color("#613f28"))
	if progress > 0:
		draw_circle(Vector2(12, -24), 15 * progress, Color(1,.86,.48,.6 * progress))
		if reward_texture != null:
			var extent := lerpf(70.0, 132.0, progress)
			var lift := lerpf(-70.0, -114.0, progress)
			draw_texture_rect(reward_texture, Rect2(-extent / 2, lift, extent, extent), false, Color(1, 1, 1, progress))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow() -> void:
	var points := PackedVector2Array()
	for i in 24:
		points.append(Vector2(cos(i * TAU / 24) * 106, 66 + sin(i * TAU / 24) * 12))
	draw_colored_polygon(points, Color(0,0,0,.2))
