extends Control

# Shared frame for management screens: a sheet over the lower part of the portrait screen
# with the world still visible above it. Tap the world, or Back, to return to it.
# Touch rules and layout: docs/UI_GEAR_SCREEN.md.

signal closed

const TouchListScript = preload("res://src/ui/touch_list.gd")
const Style = preload("res://src/ui/ui_style.gd")

# The sheet leaves this much of the screen to the world.
const WORLD_SHARE := 0.34
const ROW_HEIGHT := 96.0

var subtitle_label: Label

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	if visible:
		visible = false
		closed.emit()

# Screens rebuild their contents here.
func refresh() -> void:
	pass

# Builds the frame and returns the column a screen fills, top to bottom.
func build_sheet(title: String, world_share: float = WORLD_SHARE) -> VBoxContainer:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var world_area := Button.new()
	world_area.flat = true
	world_area.focus_mode = Control.FOCUS_NONE
	world_area.anchor_right = 1.0
	world_area.anchor_bottom = world_share
	for state in ["normal", "hover", "pressed"]:
		world_area.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	world_area.pressed.connect(close)
	add_child(world_area)

	var sheet := PanelContainer.new()
	sheet.anchor_top = world_share
	sheet.anchor_right = 1.0
	sheet.anchor_bottom = 1.0
	# Font metrics or small safe areas can force the sheet above its requested
	# height. Expand toward the world, keeping bottom actions inside safe bounds.
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var surface := Style.box(Style.SURFACE, 22.0, 20.0)
	surface.corner_radius_bottom_left = 0
	surface.corner_radius_bottom_right = 0
	# Keep the last controls clear of the phone's gesture bar.
	surface.content_margin_bottom = 36.0
	sheet.add_theme_stylebox_override("panel", surface)
	add_child(sheet)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	sheet.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	header.add_child(titles)
	titles.add_child(Style.label(title, 32))
	subtitle_label = Style.label("", 20, Style.MUTED)
	subtitle_label.clip_text = true
	titles.add_child(subtitle_label)

	var back := Style.button("Back")
	back.custom_minimum_size = Vector2(112.0, Style.TOUCH)
	back.pressed.connect(close)
	header.add_child(back)
	return column

# A row of equal tabs. `entries` is [[id, label], ...]; returns the buttons by id.
func add_tabs(parent: Control, entries: Array, on_pick: Callable) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var tabs := {}
	for entry in entries:
		var tab := Style.button(str(entry[1]))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(on_pick.bind(entry[0]))
		row.add_child(tab)
		tabs[entry[0]] = tab
	return tabs

func mark_tabs(tabs: Dictionary, chosen: Variant) -> void:
	for id in tabs:
		var style := Style.row_box(id == chosen)
		for state in ["normal", "hover", "pressed"]:
			(tabs[id] as Button).add_theme_stylebox_override(state, style)

# The scrolling part of a screen. It takes whatever height is left.
func add_list(parent: Control) -> Control:
	var list: Control = TouchListScript.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0.0, ROW_HEIGHT * 2.0)
	parent.add_child(list)
	return list

func add_line(parent: Control) -> void:
	var line := ColorRect.new()
	line.color = Style.LINE
	line.custom_minimum_size = Vector2(0.0, 2.0)
	parent.add_child(line)

func clear_list(list: Control) -> void:
	for child in list.content.get_children():
		list.content.remove_child(child)
		child.queue_free()

# A row panel for a list, tagged with what it stands for.
func make_row(key: String, height: float = ROW_HEIGHT) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0.0, height)
	row.set_meta("key", key)
	row.add_theme_stylebox_override("panel", Style.row_box(false))
	return row

func restyle_rows(rows: Dictionary, chosen: String) -> void:
	for key in rows:
		(rows[key] as PanelContainer).add_theme_stylebox_override("panel", Style.row_box(key == chosen))

func add_icon(parent: Control, texture: Texture2D) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(72.0, 72.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(icon)
