extends Node

const GameStateScript = preload("res://src/game.gd")

var game: Node
var selected_banner: String = "gear"
var token_label: Label
var banner_label: Label
var results_label: RichTextLabel
var dev_panel: VBoxContainer

func _ready() -> void:
	game = GameStateScript.new()
	add_child(game)
	game.wallet_changed.connect(_refresh_wallet)

	_build_low_poly_world()
	_build_ui()
	_refresh_wallet(game.gacha_tokens)

func _build_low_poly_world() -> void:
	var world := Node3D.new()
	world.name = "PrototypeWorld"
	add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	light.shadow_enabled = true
	world.add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(8.5, 7.5, 10.5)
	world.add_child(camera)
	camera.look_at(Vector3(0.0, 0.7, 0.0), Vector3.UP)

	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(18.0, 0.35, 18.0)
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, -0.2, 0.0)
	ground.material_override = _material(Color(0.25, 0.34, 0.20))
	world.add_child(ground)

	_add_box(world, Vector3(-2.7, 0.5, -1.8), Vector3(3.2, 1.0, 2.4), Color(0.38, 0.31, 0.22))
	_add_box(world, Vector3(3.4, 0.35, 1.0), Vector3(2.0, 0.7, 2.0), Color(0.32, 0.29, 0.24))
	_add_tree(world, Vector3(-5.0, 0.0, 2.5))
	_add_tree(world, Vector3(5.2, 0.0, -2.7))
	_add_tree(world, Vector3(1.2, 0.0, -4.6))
	_add_tree(world, Vector3(-4.8, 0.0, -4.0))

	var hero := MeshInstance3D.new()
	var hero_mesh := CapsuleMesh.new()
	hero_mesh.radius = 0.45
	hero_mesh.height = 1.8
	hero.mesh = hero_mesh
	hero.position = Vector3(0.0, 0.9, 0.0)
	hero.material_override = _material(Color(0.62, 0.35, 0.20))
	world.add_child(hero)

func _add_box(parent: Node3D, pos: Vector3, size: Vector3, colour: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = pos
	mesh_instance.material_override = _material(colour)
	parent.add_child(mesh_instance)

func _add_tree(parent: Node3D, pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.18
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 1.8
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0.0, 0.9, 0.0)
	trunk.material_override = _material(Color(0.34, 0.23, 0.15))
	parent.add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.9
	crown_mesh.height = 1.6
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 4
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0.0, 2.0, 0.0)
	crown.material_override = _material(Color(0.18, 0.42, 0.20))
	parent.add_child(crown)

func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	return material

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 22)
	root.add_theme_constant_override("margin_right", 22)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 24)
	canvas.add_child(root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	root.add_child(column)

	var title := Label.new()
	title.text = "Idle RPG — fresh prototype"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Low-poly 3D world + gacha foundation"
	column.add_child(subtitle)

	token_label = Label.new()
	token_label.add_theme_font_size_override("font_size", 22)
	column.add_child(token_label)

	banner_label = Label.new()
	banner_label.add_theme_font_size_override("font_size", 20)
	column.add_child(banner_label)

	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 8)
	column.add_child(banner_row)
	for banner_id in game.banner_ids():
		var id := str(banner_id)
		var button := Button.new()
		button.text = game.banner_label(id)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: _select_banner(id))
		banner_row.add_child(button)

	var summon_row := HBoxContainer.new()
	summon_row.add_theme_constant_override("separation", 8)
	column.add_child(summon_row)

	var one := Button.new()
	one.text = "Summon x1"
	one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	one.pressed.connect(func() -> void: _summon(1))
	summon_row.add_child(one)

	var ten := Button.new()
	ten.text = "Summon x10"
	ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ten.pressed.connect(func() -> void: _summon(10))
	summon_row.add_child(ten)

	results_label = RichTextLabel.new()
	results_label.fit_content = true
	results_label.custom_minimum_size = Vector2(0.0, 170.0)
	results_label.bbcode_enabled = true
	results_label.text = "Pick a banner and summon."
	column.add_child(results_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	if game.dev_tools_available():
		_build_dev_tools(column)

	_select_banner(selected_banner)

func _build_dev_tools(parent: VBoxContainer) -> void:
	var dev_button := Button.new()
	dev_button.text = "Dev tools"
	dev_button.pressed.connect(func() -> void: dev_panel.visible = not dev_panel.visible)
	parent.add_child(dev_button)

	dev_panel = VBoxContainer.new()
	dev_panel.visible = false
	dev_panel.add_theme_constant_override("separation", 8)
	parent.add_child(dev_panel)

	var infinite := CheckButton.new()
	infinite.text = "Infinite gacha tokens"
	infinite.toggled.connect(func(enabled: bool) -> void:
		game.set_dev_infinite_tokens(enabled)
		_refresh_wallet(game.gacha_tokens)
	)
	dev_panel.add_child(infinite)

	var token_button := Button.new()
	token_button.text = "+10,000 tokens"
	token_button.pressed.connect(func() -> void: game.dev_add_tokens(10000))
	dev_panel.add_child(token_button)

	var stress := Button.new()
	stress.text = "100-pull stress test"
	stress.pressed.connect(func() -> void: _summon(100))
	dev_panel.add_child(stress)

	var reset := Button.new()
	reset.text = "Reset pity counters"
	reset.pressed.connect(func() -> void:
		game.dev_reset_pity()
		results_label.text = "Pity counters reset."
	)
	dev_panel.add_child(reset)

func _select_banner(banner_id: String) -> void:
	selected_banner = banner_id
	banner_label.text = "Banner: %s" % game.banner_label(banner_id)

func _summon(count: int) -> void:
	var response: Dictionary = game.pull(selected_banner, count)
	if not bool(response.get("ok", false)):
		results_label.text = str(response.get("error", "Summon failed"))
		return

	var results: Array = response.get("results", [])
	var rarity_counts := {"Common": 0, "Rare": 0, "Epic": 0, "Legendary": 0}
	var highlights: Array[String] = []
	for result in results:
		var rarity: String = str(result.get("rarity", "Common"))
		rarity_counts[rarity] = int(rarity_counts.get(rarity, 0)) + 1
		if rarity == "Epic" or rarity == "Legendary":
			highlights.append("%s — %s" % [rarity, result.get("name", "?")])

	var summary := "Pulled %d\nC %d   R %d   E %d   L %d" % [
		results.size(),
		rarity_counts["Common"],
		rarity_counts["Rare"],
		rarity_counts["Epic"],
		rarity_counts["Legendary"]
	]
	if not highlights.is_empty():
		summary += "\n\n" + "\n".join(highlights)
	results_label.text = summary

func _refresh_wallet(tokens: int) -> void:
	if game != null and game.dev_infinite_tokens:
		token_label.text = "Gacha tokens: ∞  (dev)"
	else:
		token_label.text = "Gacha tokens: %d" % tokens
