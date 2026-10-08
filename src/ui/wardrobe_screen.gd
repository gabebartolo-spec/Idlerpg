extends "res://src/ui/sheet.gd"

signal changed
const Catalog = preload("res://src/data/appearance_catalog.gd")
const Character = preload("res://src/view/character_visual.gd")
const Art = preload("res://src/data/art_catalog.gd")
var sim: Node
var game: Node
var selected: String = ""
var slot: String = "head"
var tabs: Dictionary
var rows: Dictionary
var list: Control
var wear_button: Button
var clear_button: Button
var detail: Label
var preview: Node3D
var content_key: String = ""

func setup(sim_node: Node, game_node: Node) -> void:
	sim = sim_node
	game = game_node
	var column := build_sheet("Wardrobe", 0.20)
	subtitle_label.text = "Looks only · yours to keep"
	_build_preview(column)
	tabs = add_tabs(column, [["head", "Head"], ["weapon", "Weapon"], ["chest", "Chest"]], func(id: String) -> void:
		slot = id
		selected = ""
		refresh()
		list.scroll_to(0.0))
	list = add_list(column)
	list.row_tapped.connect(func(row: Control) -> void: select(str(row.get_meta("key", ""))))
	detail = Style.label("", 24)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	wear_button = Style.button("Choose a look", true)
	wear_button.pressed.connect(func() -> void:
		if sim.wardrobe.wear(selected):
			refresh()
			changed.emit())
	column.add_child(wear_button)
	clear_button = Style.button("Use equipment look")
	clear_button.pressed.connect(func() -> void:
		sim.wardrobe.clear(slot)
		refresh()
		changed.emit())
	column.add_child(clear_button)
	refresh()

func _build_preview(column: Control) -> void:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", Style.box(Style.RAISED, 12, 0))
	column.add_child(frame)
	var container := SubViewportContainer.new()
	container.custom_minimum_size.y = 245
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(680, 245)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	container.add_child(viewport)
	preview = Character.new()
	preview.setup("hero")
	preview.reduced_motion = true
	preview.set_process(false)
	preview.rotation.y = -0.35
	viewport.add_child(preview)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.25
	camera.position = Vector3(0, 1.1, 4)
	viewport.add_child(camera)
	camera.look_at(Vector3(0, 0.85, 0), Vector3.UP)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.5
	viewport.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	viewport.add_child(environment)

func select(id: String) -> void:
	if not Catalog.LOOKS.has(id) or Catalog.LOOKS[id]["slot"] != slot:
		return
	selected = id
	refresh()

func refresh() -> void:
	mark_tabs(tabs, slot)
	var key := JSON.stringify([slot, sim.wardrobe.owned, sim.wardrobe.equipped])
	if key != content_key:
		content_key = key
		clear_list(list)
		rows.clear()
		for id in Catalog.LOOKS:
			var entry: Dictionary = Catalog.LOOKS[id]
			if entry["slot"] != slot:
				continue
			var row := make_row(id, 90)
			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 12)
			row.add_child(line)
			var icon := TextureRect.new()
			icon.texture = Art.item_icon(entry["item"])
			icon.custom_minimum_size = Vector2(64, 64)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			line.add_child(icon)
			var active: bool = sim.wardrobe.equipped.get(slot, "") == id
			line.add_child(Style.label(entry["name"] + (" · Wearing" if active else (" · Owned" if sim.wardrobe.owned.has(id) else " · Locked")), 24))
			list.content.add_child(row)
			rows[id] = row
	restyle_rows(rows, selected)
	wear_button.disabled = selected.is_empty() or not sim.wardrobe.owned.has(selected) or sim.wardrobe.equipped.get(slot, "") == selected
	wear_button.text = "Wearing" if not selected.is_empty() and sim.wardrobe.equipped.get(slot, "") == selected else "Wear this look"
	clear_button.disabled = not sim.wardrobe.equipped.has(slot)
	detail.text = "Tap a look to preview" if selected.is_empty() else ("Owned · no stat changes" if sim.wardrobe.owned.has(selected) else "Collect " + str(Catalog.LOOKS[selected]["item"]))
	preview.show_identity(sim.identity.palette, sim.thornback_rank > 0)
	for equipment_slot in Character.SLOT_ATTACH:
		var item: String = sim.wardrobe.visible_item(equipment_slot, sim.equipped_item(equipment_slot))
		if not selected.is_empty() and Catalog.LOOKS[selected]["slot"] == equipment_slot:
			item = Catalog.LOOKS[selected]["item"]
		preview.set_equipment(equipment_slot, item)
