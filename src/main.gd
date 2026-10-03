extends Node

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")

var game: Node
var sim: Node

var world: Node3D
var hero_visual: Node3D
var enemy_visual: Node3D
var companion_visual: Node3D
var camera: Camera3D
var weapon_visual: MeshInstance3D
var head_gear_visual: MeshInstance3D
var chest_gear_visual: MeshInstance3D
var legs_gear_visual: MeshInstance3D
var hands_gear_root: Node3D
var feet_gear_root: Node3D
var offhand_visual: MeshInstance3D
var accessory_visual: MeshInstance3D
var rendered_enemy_kind: String = ""
var rendered_companion_name: String = "__unset__"
var rendered_equipment_key: String = "__unset__"

var hero_label: Label
var activity_label: Label
var quest_label: Label
var event_label: Label

var selected_banner: String = "gear"
var token_label: Label
var banner_label: Label
var pity_label: Label
var results_label: RichTextLabel
var gacha_panel: VBoxContainer
var gacha_summon_view: VBoxContainer
var gacha_collection_view: VBoxContainer
var gacha_history_view: VBoxContainer
var collection_summary_label: Label
var collection_list: VBoxContainer
var collection_detail_label: Label
var collection_use_button: Button
var collection_favourite_button: Button
var collection_lock_button: Button
var history_label: RichTextLabel
var selected_collection_item: String = ""
var equipment_panel: VBoxContainer
var equipment_slots_label: Label
var gear_list: VBoxContainer
var selected_gear_name: String = ""
var gear_detail_label: Label
var gear_action_row: HBoxContainer
var equip_gear_button: Button
var sell_gear_button: Button
var salvage_gear_button: Button
var talent_panel: VBoxContainer
var talent_points_label: Label
var talent_list: VBoxContainer
var selected_talent_branch: String = "slayer"
var talent_proc_pulse: float = 0.0
var dev_panel: VBoxContainer
var return_panel: PanelContainer
var return_label: Label
var pending_return_report: Dictionary = {}
var autosave_clock: float = 0.0

func _ready() -> void:
	game = GameStateScript.new()
	add_child(game)
	game.wallet_changed.connect(_refresh_wallet)

	sim = AdventurerSimScript.new()
	add_child(sim)
	pending_return_report = PersistenceScript.load_and_advance(sim, game)
	if not sim.active_companion.is_empty() and game.collection_count("companions", sim.active_companion) <= 0:
		sim.clear_active_companion()
	sim.event_emitted.connect(_on_sim_event)

	_build_world()
	_build_ui()
	_refresh_wallet(game.gacha_tokens)
	_refresh_sim_ui()
	if bool(pending_return_report.get("loaded", false)) and int(pending_return_report.get("elapsed_actual", 0)) >= 5:
		_show_return_report(pending_return_report)

func _process(delta: float) -> void:
	sim.advance(delta)
	talent_proc_pulse = max(0.0, talent_proc_pulse - delta)
	_sync_world(delta)
	_refresh_sim_ui()

	autosave_clock += delta
	if autosave_clock >= 15.0:
		autosave_clock = 0.0
		_save_now()

func _notification(what: int) -> void:
	if sim == null or game == null:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_now()

func _build_world() -> void:
	world = Node3D.new()
	world.name = "Greenway"
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.shadow_enabled = true
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	fill.light_energy = 0.4
	world.add_child(fill)

	camera = Camera3D.new()
	camera.current = true
	camera.position = sim.hero_position + Vector3(7.0, 6.0, 8.0)
	world.add_child(camera)
	camera.look_at(sim.hero_position + Vector3(0.0, 0.8, 0.0), Vector3.UP)

	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(20.0, 0.35, 18.0)
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, -0.2, 0.0)
	ground.material_override = _material(Color(0.24, 0.36, 0.20))
	world.add_child(ground)

	_add_box(Vector3(-3.0, 0.02, 2.0), Vector3(5.2, 0.08, 1.2), Color(0.45, 0.40, 0.30))
	_add_box(Vector3(1.2, 0.02, -1.0), Vector3(7.0, 0.08, 1.0), Color(0.45, 0.40, 0.30))
	_add_box(Vector3(4.0, 0.02, -3.2), Vector3(4.0, 0.08, 0.9), Color(0.45, 0.40, 0.30))

	_build_town()
	_build_goblin_camp()
	_build_wolf_den()

	for pos in [
		Vector3(-6.8, 0.0, -2.5),
		Vector3(-3.2, 0.0, -4.5),
		Vector3(0.2, 0.0, 3.9),
		Vector3(3.1, 0.0, 3.6),
		Vector3(6.7, 0.0, 2.1),
		Vector3(6.9, 0.0, -5.2),
		Vector3(-1.0, 0.0, -6.1)
	]:
		_add_tree(pos)

	hero_visual = _build_hero()
	world.add_child(hero_visual)

	companion_visual = Node3D.new()
	companion_visual.name = "Companion"
	companion_visual.visible = false
	world.add_child(companion_visual)

	enemy_visual = Node3D.new()
	enemy_visual.name = "Encounter"
	enemy_visual.visible = false
	world.add_child(enemy_visual)

func _build_town() -> void:
	_add_box(sim.TOWN_POSITION + Vector3(-0.7, 0.65, -0.3), Vector3(2.7, 1.3, 2.0), Color(0.45, 0.34, 0.23))
	_add_box(sim.TOWN_POSITION + Vector3(1.2, 0.45, 0.8), Vector3(1.5, 0.9, 1.4), Color(0.38, 0.29, 0.21))

func _build_goblin_camp() -> void:
	_add_box(sim.GOBLIN_CAMP_POSITION + Vector3(0.0, 0.2, 0.0), Vector3(2.2, 0.4, 1.5), Color(0.32, 0.25, 0.17))
	_add_box(sim.GOBLIN_CAMP_POSITION + Vector3(0.8, 0.65, -0.4), Vector3(0.25, 1.3, 0.25), Color(0.30, 0.18, 0.12))

func _build_wolf_den() -> void:
	var den := MeshInstance3D.new()
	var den_mesh := SphereMesh.new()
	den_mesh.radius = 1.25
	den_mesh.height = 1.5
	den_mesh.radial_segments = 8
	den_mesh.rings = 4
	den.mesh = den_mesh
	den.position = sim.WOLF_DEN_POSITION + Vector3(0.0, 0.55, 0.0)
	den.scale = Vector3(1.3, 0.75, 1.0)
	den.material_override = _material(Color(0.28, 0.29, 0.27))
	world.add_child(den)

func _build_hero() -> Node3D:
	var hero := Node3D.new()
	hero.name = "Adventurer"

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.38
	body_mesh.height = 1.25
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.65, 0.0)
	body.material_override = _material(Color(0.56, 0.29, 0.16))
	hero.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.28
	head_mesh.height = 0.56
	head_mesh.radial_segments = 8
	head_mesh.rings = 4
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.45, 0.0)
	head.material_override = _material(Color(0.75, 0.59, 0.43))
	hero.add_child(head)

	head_gear_visual = MeshInstance3D.new()
	head_gear_visual.name = "HeadGear"
	head_gear_visual.visible = false
	hero.add_child(head_gear_visual)

	chest_gear_visual = MeshInstance3D.new()
	chest_gear_visual.name = "ChestGear"
	chest_gear_visual.visible = false
	hero.add_child(chest_gear_visual)

	legs_gear_visual = MeshInstance3D.new()
	legs_gear_visual.name = "LegGear"
	legs_gear_visual.visible = false
	hero.add_child(legs_gear_visual)

	hands_gear_root = _build_pair_gear(
		hero,
		"HandGear",
		Vector3(-0.43, 0.73, -0.01),
		Vector3(0.43, 0.73, -0.01),
		Vector3(0.18, 0.28, 0.20)
	)
	feet_gear_root = _build_pair_gear(
		hero,
		"FootGear",
		Vector3(-0.20, 0.10, 0.0),
		Vector3(0.20, 0.10, 0.0),
		Vector3(0.22, 0.20, 0.34)
	)

	offhand_visual = MeshInstance3D.new()
	offhand_visual.name = "Offhand"
	offhand_visual.visible = false
	hero.add_child(offhand_visual)

	accessory_visual = MeshInstance3D.new()
	accessory_visual.name = "Accessory"
	accessory_visual.visible = false
	hero.add_child(accessory_visual)

	weapon_visual = MeshInstance3D.new()
	weapon_visual.name = "Weapon"
	weapon_visual.position = Vector3(0.48, 0.78, -0.25)
	hero.add_child(weapon_visual)
	_sync_equipment_visual()

	return hero

func _sync_world(delta: float) -> void:
	var fight_bob := 0.0
	if sim.activity == "fighting":
		fight_bob = sin(Time.get_ticks_msec() * 0.018) * 0.05

	hero_visual.position = sim.hero_position + Vector3(0.0, fight_bob, 0.0)
	var pulse_scale := 1.08 if talent_proc_pulse > 0.0 else 1.0
	hero_visual.scale = Vector3.ONE * pulse_scale
	_sync_equipment_visual()
	_sync_companion_visual(delta)

	if sim.activity == "fighting" and not sim.enemy_kind.is_empty():
		if rendered_enemy_kind != sim.enemy_kind:
			_rebuild_enemy(sim.enemy_kind)
		enemy_visual.visible = true
		enemy_visual.position = sim.hero_position + Vector3(1.15, 0.0, -0.45)
		enemy_visual.rotation.y = sin(Time.get_ticks_msec() * 0.012) * 0.08
	else:
		enemy_visual.visible = false
		rendered_enemy_kind = ""

	var desired_camera: Vector3 = hero_visual.position + Vector3(7.0, 6.0, 8.0)
	camera.position = camera.position.lerp(desired_camera, min(1.0, delta * 2.0))
	camera.look_at(hero_visual.position + Vector3(0.0, 0.7, 0.0), Vector3.UP)

func _sync_companion_visual(delta: float) -> void:
	if companion_visual == null or sim == null:
		return

	var companion_name: String = str(sim.active_companion)
	if companion_name.is_empty():
		companion_visual.visible = false
		rendered_companion_name = ""
		return

	if rendered_companion_name != companion_name:
		_rebuild_companion_visual(companion_name)

	companion_visual.visible = true
	var desired := hero_visual.position + Vector3(-0.95, 0.0, 0.75)
	if companion_name == "Torch Sprite":
		desired.y += 0.65 + sin(Time.get_ticks_msec() * 0.006) * 0.08
	companion_visual.position = companion_visual.position.lerp(desired, min(1.0, delta * 4.0))

func _rebuild_companion_visual(companion_name: String) -> void:
	rendered_companion_name = companion_name
	for child in companion_visual.get_children():
		child.queue_free()

	var colour := _companion_colour(companion_name)
	if companion_name == "Torch Sprite":
		var sprite := MeshInstance3D.new()
		var sprite_mesh := SphereMesh.new()
		sprite_mesh.radius = 0.22
		sprite_mesh.height = 0.44
		sprite_mesh.radial_segments = 8
		sprite_mesh.rings = 4
		sprite.mesh = sprite_mesh
		sprite.position = Vector3(0.0, 0.35, 0.0)
		sprite.material_override = _material(colour)
		companion_visual.add_child(sprite)
	elif companion_name in ["Pack Rat", "Stable Hound", "Clockwork Raven"]:
		var body := MeshInstance3D.new()
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(0.65, 0.35, 0.34)
		if companion_name == "Stable Hound":
			body_mesh.size = Vector3(0.82, 0.48, 0.42)
		elif companion_name == "Clockwork Raven":
			body_mesh.size = Vector3(0.58, 0.22, 0.34)
		body.mesh = body_mesh
		body.position = Vector3(0.0, 0.30, 0.0)
		body.material_override = _material(colour)
		companion_visual.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := BoxMesh.new()
		head_mesh.size = Vector3(0.30, 0.30, 0.30)
		head.mesh = head_mesh
		head.position = Vector3(-0.42, 0.42, 0.0)
		head.material_override = _material(colour.lightened(0.08))
		companion_visual.add_child(head)

		if companion_name == "Clockwork Raven":
			for wing_x in [-0.36, 0.36]:
				var wing := MeshInstance3D.new()
				var wing_mesh := BoxMesh.new()
				wing_mesh.size = Vector3(0.12, 0.04, 0.70)
				wing.mesh = wing_mesh
				wing.position = Vector3(0.0, 0.35, wing_x)
				wing.material_override = _material(colour.darkened(0.08))
				companion_visual.add_child(wing)
	else:
		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.25
		body_mesh.height = 0.85
		body.mesh = body_mesh
		body.position = Vector3(0.0, 0.43, 0.0)
		body.material_override = _material(colour)
		companion_visual.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.19
		head_mesh.height = 0.38
		head_mesh.radial_segments = 8
		head_mesh.rings = 4
		head.mesh = head_mesh
		head.position = Vector3(0.0, 1.00, 0.0)
		head.material_override = _material(colour.lightened(0.12))
		companion_visual.add_child(head)

		if companion_name == "Ancient Warden":
			companion_visual.scale = Vector3.ONE * 1.15
		else:
			companion_visual.scale = Vector3.ONE

	companion_visual.position = hero_visual.position + Vector3(-0.95, 0.0, 0.75)

func _companion_colour(companion_name: String) -> Color:
	match companion_name:
		"Pack Rat":
			return Color(0.42, 0.29, 0.19)
		"Stable Hound":
			return Color(0.58, 0.43, 0.27)
		"Torch Sprite":
			return Color(0.90, 0.55, 0.18)
		"Hill Squire":
			return Color(0.38, 0.43, 0.48)
		"Marsh Witch":
			return Color(0.43, 0.34, 0.46)
		"Clockwork Raven":
			return Color(0.25, 0.27, 0.30)
		"Frost Ranger":
			return Color(0.32, 0.48, 0.62)
		"Sun Cleric":
			return Color(0.78, 0.65, 0.38)
		"Grave Knight":
			return Color(0.34, 0.34, 0.38)
		"Ancient Warden":
			return Color(0.36, 0.52, 0.55)
		_:
			return Color(0.45, 0.40, 0.34)

func _build_pair_gear(parent: Node3D, node_name: String, left_pos: Vector3, right_pos: Vector3, size: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	root.visible = false
	parent.add_child(root)

	for pos in [left_pos, right_pos]:
		var piece := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = size
		piece.mesh = mesh
		piece.position = pos
		root.add_child(piece)

	return root

func _sync_equipment_visual() -> void:
	if weapon_visual == null or sim == null:
		return

	var slots: Array[String] = ["weapon", "head", "chest", "legs", "hands", "feet", "offhand", "accessory"]
	var equipped_names: Array[String] = []
	for slot_name in slots:
		equipped_names.append(str(sim.equipped_item(slot_name)))
	var equipment_key := "|".join(equipped_names)
	if equipment_key == rendered_equipment_key:
		return
	rendered_equipment_key = equipment_key

	_sync_weapon_visual(equipped_names[0])
	_sync_head_visual(equipped_names[1])
	_sync_box_visual(chest_gear_visual, equipped_names[2], Vector3(0.80, 0.70, 0.48), Vector3(0.0, 0.72, 0.0))
	_sync_box_visual(legs_gear_visual, equipped_names[3], Vector3(0.58, 0.44, 0.42), Vector3(0.0, 0.31, 0.0))
	_sync_pair_visual(hands_gear_root, equipped_names[4])
	_sync_pair_visual(feet_gear_root, equipped_names[5])
	_sync_box_visual(offhand_visual, equipped_names[6], Vector3(0.38, 0.56, 0.12), Vector3(-0.48, 0.72, -0.16))
	_sync_accessory_visual(equipped_names[7])

func _sync_weapon_visual(item_name: String) -> void:
	var mesh := BoxMesh.new()
	var colour := Color(0.62, 0.64, 0.66)
	weapon_visual.position = Vector3(0.48, 0.78, -0.25)
	weapon_visual.rotation_degrees = Vector3(0.0, 0.0, -28.0)

	if item_name.is_empty():
		mesh.size = Vector3(0.10, 0.10, 0.85)
	elif item_name.contains("Longbow"):
		mesh.size = Vector3(0.08, 0.08, 1.35)
		weapon_visual.rotation_degrees = Vector3(0.0, 0.0, 12.0)
		colour = Color(0.45, 0.31, 0.18)
	elif item_name.contains("Staff") or item_name == "Stormcaller":
		mesh.size = Vector3(0.11, 0.11, 1.45)
		weapon_visual.rotation_degrees = Vector3(0.0, 0.0, 2.0)
		colour = _gear_colour(item_name)
	elif item_name == "Crownblade":
		mesh.size = Vector3(0.16, 0.10, 1.30)
		colour = _gear_colour(item_name)
	elif item_name == "Moonsteel Blade":
		mesh.size = Vector3(0.14, 0.10, 1.20)
		colour = _gear_colour(item_name)
	elif item_name == "Goblin Cleaver":
		mesh.size = Vector3(0.20, 0.11, 0.95)
		weapon_visual.rotation_degrees = Vector3(0.0, 0.0, -38.0)
		colour = Color(0.48, 0.50, 0.46)
	else:
		mesh.size = Vector3(0.12, 0.10, 1.05)
		colour = _gear_colour(item_name)

	weapon_visual.mesh = mesh
	weapon_visual.material_override = _material(colour)

func _sync_head_visual(item_name: String) -> void:
	head_gear_visual.visible = not item_name.is_empty()
	if item_name.is_empty():
		return

	var mesh := SphereMesh.new()
	mesh.radius = 0.33
	mesh.height = 0.38 if item_name.contains("Hood") else 0.48
	mesh.radial_segments = 8
	mesh.rings = 4
	head_gear_visual.mesh = mesh
	head_gear_visual.position = Vector3(0.0, 1.55, 0.0)
	head_gear_visual.scale = Vector3(1.10, 0.72 if item_name.contains("Hood") else 0.88, 1.08)
	head_gear_visual.material_override = _material(_gear_colour(item_name))

func _sync_box_visual(visual: MeshInstance3D, item_name: String, size: Vector3, position: Vector3) -> void:
	visual.visible = not item_name.is_empty()
	if item_name.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.material_override = _material(_gear_colour(item_name))

func _sync_pair_visual(root: Node3D, item_name: String) -> void:
	root.visible = not item_name.is_empty()
	if item_name.is_empty():
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = _material(_gear_colour(item_name))

func _sync_accessory_visual(item_name: String) -> void:
	accessory_visual.visible = not item_name.is_empty()
	if item_name.is_empty():
		return
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.18
	mesh.radial_segments = 8
	mesh.rings = 4
	accessory_visual.mesh = mesh
	accessory_visual.position = Vector3(0.0, 0.88, -0.28)
	accessory_visual.material_override = _material(_gear_colour(item_name))

func _gear_colour(item_name: String) -> Color:
	if item_name == "Wolfskin Hood":
		return Color(0.38, 0.40, 0.40)
	match GearCatalogScript.rarity(item_name):
		"Rare":
			return Color(0.34, 0.46, 0.58)
		"Epic":
			return Color(0.46, 0.36, 0.58)
		"Legendary":
			return Color(0.72, 0.58, 0.30)
		_:
			return Color(0.40, 0.32, 0.23)

func _rebuild_enemy(kind: String) -> void:
	rendered_enemy_kind = kind
	for child in enemy_visual.get_children():
		child.queue_free()

	if kind == "goblin":
		var body := MeshInstance3D.new()
		var body_mesh := CapsuleMesh.new()
		body_mesh.radius = 0.32
		body_mesh.height = 1.0
		body.mesh = body_mesh
		body.position = Vector3(0.0, 0.50, 0.0)
		body.material_override = _material(Color(0.28, 0.52, 0.20))
		enemy_visual.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.25
		head_mesh.height = 0.50
		head_mesh.radial_segments = 8
		head_mesh.rings = 4
		head.mesh = head_mesh
		head.position = Vector3(0.0, 1.13, 0.0)
		head.material_override = _material(Color(0.36, 0.62, 0.24))
		enemy_visual.add_child(head)
	else:
		var body := MeshInstance3D.new()
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(1.1, 0.55, 0.52)
		body.mesh = body_mesh
		body.position = Vector3(0.0, 0.48, 0.0)
		body.material_override = _material(Color(0.36, 0.38, 0.40))
		enemy_visual.add_child(body)

		var head := MeshInstance3D.new()
		var head_mesh := BoxMesh.new()
		head_mesh.size = Vector3(0.50, 0.48, 0.48)
		head.mesh = head_mesh
		head.position = Vector3(-0.62, 0.58, 0.0)
		head.material_override = _material(Color(0.42, 0.44, 0.46))
		enemy_visual.add_child(head)

func _add_box(pos: Vector3, size: Vector3, colour: Color) -> void:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = _material(colour)
	world.add_child(item)

func _add_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.23
	trunk_mesh.height = 1.6
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0.0, 0.8, 0.0)
	trunk.material_override = _material(Color(0.32, 0.22, 0.14))
	world.add_child(trunk)

	var crown := MeshInstance3D.new()
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.82
	crown_mesh.height = 1.45
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 4
	crown.mesh = crown_mesh
	crown.position = pos + Vector3(0.0, 1.85, 0.0)
	crown.material_override = _material(Color(0.17, 0.41, 0.19))
	world.add_child(crown)

func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	return material

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var top := MarginContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 16.0
	top.offset_right = -16.0
	top.offset_top = 18.0
	top.offset_bottom = 165.0
	canvas.add_child(top)

	var top_column := VBoxContainer.new()
	top_column.add_theme_constant_override("separation", 4)
	top.add_child(top_column)

	hero_label = Label.new()
	hero_label.add_theme_font_size_override("font_size", 22)
	top_column.add_child(hero_label)

	activity_label = Label.new()
	activity_label.add_theme_font_size_override("font_size", 18)
	top_column.add_child(activity_label)

	quest_label = Label.new()
	top_column.add_child(quest_label)

	event_label = Label.new()
	event_label.text = "The adventure begins."
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_column.add_child(event_label)

	var bottom := MarginContainer.new()
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 16.0
	bottom.offset_right = -16.0
	bottom.offset_top = -455.0
	bottom.offset_bottom = -16.0
	canvas.add_child(bottom)

	var bottom_column := VBoxContainer.new()
	bottom_column.alignment = BoxContainer.ALIGNMENT_END
	bottom_column.add_theme_constant_override("separation", 8)
	bottom.add_child(bottom_column)

	return_panel = PanelContainer.new()
	return_panel.visible = false
	bottom_column.add_child(return_panel)

	var return_column := VBoxContainer.new()
	return_column.add_theme_constant_override("separation", 6)
	return_panel.add_child(return_column)

	var return_title := Label.new()
	return_title.text = "While you were away"
	return_title.add_theme_font_size_override("font_size", 20)
	return_column.add_child(return_title)

	return_label = Label.new()
	return_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return_column.add_child(return_label)

	var return_close := Button.new()
	return_close.text = "Back to the adventure"
	return_close.pressed.connect(_close_return_report)
	return_column.add_child(return_close)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	bottom_column.add_child(actions)

	var equipment_button := Button.new()
	equipment_button.text = "Gear"
	equipment_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_button.pressed.connect(_toggle_equipment)
	actions.add_child(equipment_button)

	var talent_button := Button.new()
	talent_button.text = "Talents"
	talent_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talent_button.pressed.connect(_toggle_talents)
	actions.add_child(talent_button)

	var gacha_button := Button.new()
	gacha_button.text = "Gacha"
	gacha_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_button.pressed.connect(_toggle_gacha)
	actions.add_child(gacha_button)

	if game.dev_tools_available():
		var dev_button := Button.new()
		dev_button.text = "Dev"
		dev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dev_button.pressed.connect(_toggle_dev_tools)
		actions.add_child(dev_button)

	equipment_panel = VBoxContainer.new()
	equipment_panel.visible = false
	equipment_panel.add_theme_constant_override("separation", 6)
	bottom_column.add_child(equipment_panel)
	_build_equipment_panel(equipment_panel)

	talent_panel = VBoxContainer.new()
	talent_panel.visible = false
	talent_panel.add_theme_constant_override("separation", 6)
	bottom_column.add_child(talent_panel)
	_build_talent_panel(talent_panel)

	gacha_panel = VBoxContainer.new()
	gacha_panel.visible = false
	gacha_panel.add_theme_constant_override("separation", 6)
	bottom_column.add_child(gacha_panel)
	_build_gacha_panel(gacha_panel)

	if game.dev_tools_available():
		dev_panel = VBoxContainer.new()
		dev_panel.visible = false
		dev_panel.add_theme_constant_override("separation", 6)
		bottom_column.add_child(dev_panel)
		_build_dev_tools(dev_panel)

func _build_equipment_panel(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Equipment"
	title.add_theme_font_size_override("font_size", 20)
	parent.add_child(title)

	equipment_slots_label = Label.new()
	equipment_slots_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(equipment_slots_label)

	gear_detail_label = Label.new()
	gear_detail_label.text = "Tap an item to inspect it."
	gear_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(gear_detail_label)

	gear_action_row = HBoxContainer.new()
	gear_action_row.visible = false
	gear_action_row.add_theme_constant_override("separation", 6)
	parent.add_child(gear_action_row)

	equip_gear_button = Button.new()
	equip_gear_button.text = "Equip"
	equip_gear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_gear_button.pressed.connect(_equip_selected_gear)
	gear_action_row.add_child(equip_gear_button)

	sell_gear_button = Button.new()
	sell_gear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_gear_button.pressed.connect(_sell_selected_gear)
	gear_action_row.add_child(sell_gear_button)

	salvage_gear_button = Button.new()
	salvage_gear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salvage_gear_button.pressed.connect(_salvage_selected_gear)
	gear_action_row.add_child(salvage_gear_button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 160.0)
	parent.add_child(scroll)

	gear_list = VBoxContainer.new()
	gear_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_list.add_theme_constant_override("separation", 4)
	scroll.add_child(gear_list)

	_rebuild_equipment_panel()

func _rebuild_equipment_panel() -> void:
	if equipment_slots_label == null or gear_list == null:
		return

	var weapon: String = str(sim.equipped_item("weapon"))
	var equipped_count := 0
	for slot_name in ["head", "chest", "legs", "hands", "feet", "offhand", "accessory"]:
		if not str(sim.equipped_item(slot_name)).is_empty():
			equipped_count += 1

	equipment_slots_label.text = "ATK %d · HP %d\nWeapon: %s · Other slots %d/7" % [
		sim.effective_attack(),
		sim.effective_max_hp(),
		weapon if not weapon.is_empty() else "Starter sword",
		equipped_count
	]

	for child in gear_list.get_children():
		child.queue_free()

	var names: Array[String] = sim.owned_gear_names()
	if names.is_empty():
		selected_gear_name = ""
		var empty := Label.new()
		empty.text = "No gear yet. Keep questing or try the Gear banner."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gear_list.add_child(empty)
		_refresh_gear_detail()
		return

	if not selected_gear_name.is_empty() and sim.gear_count(selected_gear_name) <= 0:
		selected_gear_name = ""

	for item_name in names:
		var button := Button.new()
		var count: int = sim.gear_count(item_name)
		button.text = GearCatalogScript.summary(item_name)
		if count > 1:
			button.text += " · ×%d" % count
		var slot_name: String = GearCatalogScript.slot(item_name)
		if sim.equipped_item(slot_name) == item_name:
			button.text += " · Equipped"
		button.pressed.connect(_select_gear_item.bind(item_name))
		gear_list.add_child(button)

	_refresh_gear_detail()

func _select_gear_item(item_name: String) -> void:
	selected_gear_name = item_name
	_refresh_gear_detail()

func _refresh_gear_detail() -> void:
	if gear_detail_label == null or gear_action_row == null:
		return
	if selected_gear_name.is_empty() or sim.gear_count(selected_gear_name) <= 0:
		gear_detail_label.text = "Tap an item to inspect it."
		gear_action_row.visible = false
		return

	var slot_name: String = GearCatalogScript.slot(selected_gear_name)
	var equipped_name: String = str(sim.equipped_item(slot_name))
	var comparison: String = GearCatalogScript.comparison(selected_gear_name, equipped_name)
	var lines: Array[String] = [GearCatalogScript.summary(selected_gear_name)]
	lines.append("Owned ×%d" % sim.gear_count(selected_gear_name))
	if equipped_name == selected_gear_name:
		lines.append("Currently equipped.")
	else:
		lines.append("vs %s: %s" % [equipped_name if not equipped_name.is_empty() else "empty slot", comparison])
	gear_detail_label.text = "\n".join(lines)

	gear_action_row.visible = true
	equip_gear_button.text = "Unequip" if equipped_name == selected_gear_name else "Equip"
	equip_gear_button.disabled = false
	sell_gear_button.text = "Sell +%dg" % GearCatalogScript.sell_value(selected_gear_name)
	salvage_gear_button.text = "Salvage +%d token%s" % [
		GearCatalogScript.salvage_tokens(selected_gear_name),
		"" if GearCatalogScript.salvage_tokens(selected_gear_name) == 1 else "s"
	]
	var can_dispose: bool = sim.can_dispose_gear(selected_gear_name) and not game.is_locked(selected_gear_name)
	sell_gear_button.disabled = not can_dispose
	salvage_gear_button.disabled = not can_dispose
	if game.is_locked(selected_gear_name):
		gear_detail_label.text += "\nLocked from disposal."

func _equip_selected_gear() -> void:
	if selected_gear_name.is_empty():
		return
	var slot_name: String = GearCatalogScript.slot(selected_gear_name)
	var changed := false
	if sim.equipped_item(slot_name) == selected_gear_name:
		changed = sim.unequip_gear(selected_gear_name)
	else:
		changed = sim.equip_gear(selected_gear_name)
	if changed:
		_rebuild_equipment_panel()
		_sync_equipment_visual()
		_save_now()

func _sell_selected_gear() -> void:
	if selected_gear_name.is_empty() or game.is_locked(selected_gear_name):
		return
	var result: Dictionary = sim.sell_gear(selected_gear_name)
	if not bool(result.get("ok", false)):
		return
	if sim.gear_count(selected_gear_name) <= 0:
		selected_gear_name = ""
	_rebuild_equipment_panel()
	_save_now()

func _salvage_selected_gear() -> void:
	if selected_gear_name.is_empty() or game.is_locked(selected_gear_name):
		return
	var result: Dictionary = sim.salvage_gear(selected_gear_name)
	if not bool(result.get("ok", false)):
		return
	game.grant_tokens(int(result.get("tokens", 0)))
	if sim.gear_count(selected_gear_name) <= 0:
		selected_gear_name = ""
	_rebuild_equipment_panel()
	_save_now()

func _build_talent_panel(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "%s talents" % TalentCatalogScript.CLASS_NAME
	title.add_theme_font_size_override("font_size", 20)
	parent.add_child(title)

	talent_points_label = Label.new()
	parent.add_child(talent_points_label)

	var branches := HBoxContainer.new()
	branches.add_theme_constant_override("separation", 6)
	parent.add_child(branches)
	for branch_id in TalentCatalogScript.branch_ids():
		var button := Button.new()
		button.text = TalentCatalogScript.branch_label(branch_id)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_talent_branch.bind(branch_id))
		branches.add_child(button)

	talent_list = VBoxContainer.new()
	talent_list.add_theme_constant_override("separation", 5)
	parent.add_child(talent_list)

	var reset := Button.new()
	reset.text = "Reset talents"
	reset.pressed.connect(_reset_talents)
	parent.add_child(reset)

	_rebuild_talent_panel()

func _select_talent_branch(branch_id: String) -> void:
	selected_talent_branch = branch_id
	_rebuild_talent_panel()

func _rebuild_talent_panel() -> void:
	if talent_points_label == null or talent_list == null:
		return

	talent_points_label.text = "%d point%s available\nBuild: %s\nViewing %s" % [
		sim.talent_points_available(),
		"" if sim.talent_points_available() == 1 else "s",
		sim.build_summary(),
		TalentCatalogScript.branch_label(selected_talent_branch)
	]

	for child in talent_list.get_children():
		child.queue_free()

	for talent_id in TalentCatalogScript.nodes_for_branch(selected_talent_branch):
		var button := Button.new()
		var unlocked: bool = sim.has_talent(talent_id)
		var requirement: String = TalentCatalogScript.requirement(talent_id)
		var prefix := "✓" if unlocked else "○"
		button.text = "%s %s\n%s" % [
			prefix,
			TalentCatalogScript.talent_name(talent_id),
			TalentCatalogScript.description(talent_id)
		]
		button.custom_minimum_size = Vector2(0.0, 54.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = unlocked or not sim.can_unlock_talent(talent_id)
		if not unlocked and not requirement.is_empty() and not sim.has_talent(requirement):
			button.tooltip_text = "Requires %s" % TalentCatalogScript.talent_name(requirement)
		button.pressed.connect(_unlock_talent.bind(talent_id))
		talent_list.add_child(button)

func _unlock_talent(talent_id: String) -> void:
	if sim.unlock_talent(talent_id):
		_rebuild_talent_panel()
		_rebuild_equipment_panel()
		_save_now()

func _reset_talents() -> void:
	sim.reset_talents()
	_rebuild_talent_panel()
	_rebuild_equipment_panel()
	_save_now()

func _build_gacha_panel(parent: VBoxContainer) -> void:
	token_label = Label.new()
	token_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(token_label)

	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 6)
	parent.add_child(mode_row)

	var summon_mode := Button.new()
	summon_mode.text = "Summon"
	summon_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summon_mode.pressed.connect(_show_gacha_mode.bind("summon"))
	mode_row.add_child(summon_mode)

	var collection_mode := Button.new()
	collection_mode.text = "Collection"
	collection_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_mode.pressed.connect(_show_gacha_mode.bind("collection"))
	mode_row.add_child(collection_mode)

	var history_mode := Button.new()
	history_mode.text = "History"
	history_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_mode.pressed.connect(_show_gacha_mode.bind("history"))
	mode_row.add_child(history_mode)

	gacha_summon_view = VBoxContainer.new()
	gacha_summon_view.add_theme_constant_override("separation", 6)
	parent.add_child(gacha_summon_view)

	banner_label = Label.new()
	gacha_summon_view.add_child(banner_label)

	pity_label = Label.new()
	gacha_summon_view.add_child(pity_label)

	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 6)
	gacha_summon_view.add_child(banner_row)
	_add_banner_button(banner_row, "gear", "Gear")
	_add_banner_button(banner_row, "companions", "Companions")
	_add_banner_button(banner_row, "relics", "Relics")

	var summon_row := HBoxContainer.new()
	summon_row.add_theme_constant_override("separation", 6)
	gacha_summon_view.add_child(summon_row)

	var one := Button.new()
	one.text = "Summon x1"
	one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	one.pressed.connect(_summon.bind(1))
	summon_row.add_child(one)

	var ten := Button.new()
	ten.text = "Summon x10"
	ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ten.pressed.connect(_summon.bind(10))
	summon_row.add_child(ten)

	results_label = RichTextLabel.new()
	results_label.fit_content = true
	results_label.custom_minimum_size = Vector2(0.0, 90.0)
	results_label.text = "Pick a banner and summon."
	gacha_summon_view.add_child(results_label)

	gacha_collection_view = VBoxContainer.new()
	gacha_collection_view.visible = false
	gacha_collection_view.add_theme_constant_override("separation", 6)
	parent.add_child(gacha_collection_view)

	collection_summary_label = Label.new()
	gacha_collection_view.add_child(collection_summary_label)

	collection_detail_label = Label.new()
	collection_detail_label.text = "Tap a collected item."
	collection_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gacha_collection_view.add_child(collection_detail_label)

	collection_use_button = Button.new()
	collection_use_button.text = "Travel together"
	collection_use_button.visible = false
	collection_use_button.pressed.connect(_use_collection_item)
	gacha_collection_view.add_child(collection_use_button)

	var collection_actions := HBoxContainer.new()
	collection_actions.add_theme_constant_override("separation", 6)
	gacha_collection_view.add_child(collection_actions)

	collection_favourite_button = Button.new()
	collection_favourite_button.text = "Favourite"
	collection_favourite_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_favourite_button.pressed.connect(_toggle_collection_favourite)
	collection_actions.add_child(collection_favourite_button)

	collection_lock_button = Button.new()
	collection_lock_button.text = "Lock"
	collection_lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_lock_button.pressed.connect(_toggle_collection_lock)
	collection_actions.add_child(collection_lock_button)

	var collection_scroll := ScrollContainer.new()
	collection_scroll.custom_minimum_size = Vector2(0.0, 180.0)
	gacha_collection_view.add_child(collection_scroll)

	collection_list = VBoxContainer.new()
	collection_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_list.add_theme_constant_override("separation", 4)
	collection_scroll.add_child(collection_list)

	gacha_history_view = VBoxContainer.new()
	gacha_history_view.visible = false
	parent.add_child(gacha_history_view)

	history_label = RichTextLabel.new()
	history_label.fit_content = true
	history_label.custom_minimum_size = Vector2(0.0, 230.0)
	gacha_history_view.add_child(history_label)

	_select_banner(selected_banner)
	_show_gacha_mode("summon")

func _show_gacha_mode(mode: String) -> void:
	gacha_summon_view.visible = mode == "summon"
	gacha_collection_view.visible = mode == "collection"
	gacha_history_view.visible = mode == "history"
	if mode == "collection":
		_rebuild_collection_view()
	elif mode == "history":
		_rebuild_history_view()

func _rebuild_collection_view() -> void:
	if collection_list == null or collection_summary_label == null:
		return

	collection_summary_label.text = "%s · %d/%d collected" % [
		game.banner_label(selected_banner),
		game.collected_unique(selected_banner),
		game.banner_item_count(selected_banner)
	]

	for child in collection_list.get_children():
		child.queue_free()

	for item_name in game.collection_items(selected_banner):
		var rarity: String = game.item_rarity(selected_banner, item_name)
		var count: int = game.collection_count(selected_banner, item_name)
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if count <= 0:
			button.text = "— %s · %s" % [item_name, rarity]
			button.disabled = true
		else:
			var markers: Array[String] = []
			if game.is_favourite(item_name):
				markers.append("Favourite")
			if game.is_locked(item_name):
				markers.append("Locked")
			if selected_banner == "companions" and sim.active_companion == item_name:
				markers.append("Active")
			button.text = "%s · %s · ×%d" % [item_name, rarity, count]
			if not markers.is_empty():
				button.text += " · " + " · ".join(markers)
			button.pressed.connect(_select_collection_item.bind(item_name))
		collection_list.add_child(button)

	_refresh_collection_detail()

func _select_collection_item(item_name: String) -> void:
	selected_collection_item = item_name
	_refresh_collection_detail()

func _refresh_collection_detail() -> void:
	if collection_detail_label == null:
		return
	if selected_collection_item.is_empty() or game.collection_count(selected_banner, selected_collection_item) <= 0:
		collection_detail_label.text = "Tap a collected item."
		collection_use_button.visible = false
		collection_favourite_button.disabled = true
		collection_lock_button.disabled = true
		return

	var detail_lines: Array[String] = [
		"%s · %s · Owned ×%d" % [
			selected_collection_item,
			game.item_rarity(selected_banner, selected_collection_item),
			game.collection_count(selected_banner, selected_collection_item)
		]
	]
	if selected_banner == "companions" and CompanionCatalogScript.has_companion(selected_collection_item):
		detail_lines.append("%s · Bond %d" % [
			CompanionCatalogScript.role(selected_collection_item),
			sim.companion_bond_level(selected_collection_item)
		])
		detail_lines.append(CompanionCatalogScript.description(selected_collection_item))
		collection_use_button.visible = true
		collection_use_button.text = "Rest companion" if sim.active_companion == selected_collection_item else "Travel together"
	else:
		collection_use_button.visible = false
	collection_detail_label.text = "\n".join(detail_lines)
	collection_favourite_button.disabled = false
	collection_lock_button.disabled = false
	collection_favourite_button.text = "Unfavourite" if game.is_favourite(selected_collection_item) else "Favourite"
	collection_lock_button.text = "Unlock" if game.is_locked(selected_collection_item) else "Lock"

func _use_collection_item() -> void:
	if selected_banner != "companions" or selected_collection_item.is_empty():
		return
	if game.collection_count("companions", selected_collection_item) <= 0:
		return

	if sim.active_companion == selected_collection_item:
		sim.clear_active_companion()
	else:
		sim.set_active_companion(selected_collection_item)

	_rebuild_collection_view()
	_sync_companion_visual(1.0)
	_save_now()

func _toggle_collection_favourite() -> void:
	if selected_collection_item.is_empty():
		return
	game.set_favourite(selected_collection_item, not game.is_favourite(selected_collection_item))
	_rebuild_collection_view()
	_save_now()

func _toggle_collection_lock() -> void:
	if selected_collection_item.is_empty():
		return
	game.set_locked(selected_collection_item, not game.is_locked(selected_collection_item))
	_rebuild_collection_view()
	if equipment_panel != null and equipment_panel.visible:
		_rebuild_equipment_panel()
	_save_now()

func _rebuild_history_view() -> void:
	if history_label == null:
		return
	var lines: Array[String] = ["Recent summons"]
	var history: Array[Dictionary] = game.recent_summons(12)
	if history.is_empty():
		lines.append("No summons yet.")
	else:
		for entry in history:
			var prefix := "NEW · " if bool(entry.get("is_new", false)) else ""
			lines.append("%s%s · %s · copy %d" % [
				prefix,
				entry.get("rarity", "Common"),
				entry.get("name", "?"),
				int(entry.get("copy", 1))
			])
	history_label.text = "\n".join(lines)

func _add_banner_button(parent: HBoxContainer, id: String, label: String) -> void:
	var button := Button.new()
	button.text = label
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_select_banner.bind(id))
	parent.add_child(button)

func _build_dev_tools(parent: VBoxContainer) -> void:
	var infinite := CheckButton.new()
	infinite.text = "Infinite gacha tokens"
	infinite.toggled.connect(_set_infinite_tokens)
	parent.add_child(infinite)

	var token_button := Button.new()
	token_button.text = "+10,000 tokens"
	token_button.pressed.connect(game.dev_add_tokens.bind(10000))
	parent.add_child(token_button)

	var stress := Button.new()
	stress.text = "100-pull stress test"
	stress.pressed.connect(_dev_stress_pull)
	parent.add_child(stress)

	var reset := Button.new()
	reset.text = "Reset pity counters"
	reset.pressed.connect(_reset_pity)
	parent.add_child(reset)

	var away := Button.new()
	away.text = "Simulate 10 min away"
	away.pressed.connect(_dev_simulate_away)
	parent.add_child(away)

func _toggle_equipment() -> void:
	equipment_panel.visible = not equipment_panel.visible
	if equipment_panel.visible:
		_rebuild_equipment_panel()
	talent_panel.visible = false
	gacha_panel.visible = false
	return_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _toggle_talents() -> void:
	talent_panel.visible = not talent_panel.visible
	if talent_panel.visible:
		_rebuild_talent_panel()
	equipment_panel.visible = false
	gacha_panel.visible = false
	return_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _toggle_gacha() -> void:
	gacha_panel.visible = not gacha_panel.visible
	if gacha_panel.visible:
		_show_gacha_mode("summon")
	equipment_panel.visible = false
	talent_panel.visible = false
	return_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _toggle_dev_tools() -> void:
	if dev_panel == null:
		return
	dev_panel.visible = not dev_panel.visible
	gacha_panel.visible = false
	equipment_panel.visible = false
	talent_panel.visible = false
	return_panel.visible = false

func _set_infinite_tokens(enabled: bool) -> void:
	game.set_dev_infinite_tokens(enabled)
	_refresh_wallet(game.gacha_tokens)

func _dev_stress_pull() -> void:
	gacha_panel.visible = true
	if dev_panel != null:
		dev_panel.visible = false
	_summon(100)

func _reset_pity() -> void:
	game.dev_reset_pity()
	event_label.text = "Dev: pity counters reset."

func _save_now(now_unix: int = -1) -> void:
	if sim == null or game == null:
		return
	PersistenceScript.save(sim, game, now_unix)

func _dev_simulate_away() -> void:
	var now_unix := int(Time.get_unix_time_from_system())
	PersistenceScript.save(sim, game, now_unix - 600)
	var report: Dictionary = PersistenceScript.load_and_advance(sim, game, now_unix)
	_show_return_report(report)
	if dev_panel != null:
		dev_panel.visible = false

func _show_return_report(report: Dictionary) -> void:
	if return_panel == null or return_label == null:
		return
	return_label.text = _format_return_report(report)
	return_panel.visible = true
	gacha_panel.visible = false
	equipment_panel.visible = false
	talent_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _close_return_report() -> void:
	if return_panel != null:
		return_panel.visible = false

func _format_return_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Away for %s." % _format_duration(int(report.get("elapsed_actual", 0))))

	var quests := int(report.get("quests", 0))
	var kills := int(report.get("kills", 0))
	var gold_gained := int(report.get("gold", 0))
	var levels := int(report.get("levels", 0))
	var deaths_while_away := int(report.get("deaths", 0))

	if quests > 0:
		lines.append("%d quest%s completed." % [quests, "" if quests == 1 else "s"])
	if kills > 0:
		lines.append("%d enemies defeated." % kills)
	if gold_gained > 0:
		lines.append("+%d gold." % gold_gained)
	if levels > 0:
		lines.append("Gained %d level%s." % [levels, "" if levels == 1 else "s"])
	if deaths_while_away > 0:
		lines.append("Defeated %d time%s, but recovered." % [deaths_while_away, "" if deaths_while_away == 1 else "s"])

	var loot: Dictionary = report.get("loot", {})
	var loot_parts: Array[String] = []
	for item_name in loot.keys():
		loot_parts.append("%s ×%d" % [item_name, int(loot[item_name])])
	if not loot_parts.is_empty():
		lines.append("Loot: %s." % ", ".join(loot_parts.slice(0, 4)))

	var gear_found: Dictionary = report.get("gear", {})
	var gear_parts: Array[String] = []
	for item_name in gear_found.keys():
		var count := int(gear_found[item_name])
		gear_parts.append("%s%s" % [item_name, " ×%d" % count if count > 1 else ""])
	if not gear_parts.is_empty():
		lines.append("New gear: %s." % ", ".join(gear_parts.slice(0, 4)))

	if bool(report.get("capped", false)):
		lines.append("Prototype catch-up is currently capped at 7 days per return.")

	if lines.size() == 1:
		lines.append("No major events. Your adventurer kept moving.")

	return "\n".join(lines)

func _format_duration(seconds: int) -> String:
	if seconds >= 86400:
		var days := seconds / 86400
		return "%dd %dh" % [days, (seconds % 86400) / 3600]
	if seconds >= 3600:
		return "%dh %dm" % [seconds / 3600, (seconds % 3600) / 60]
	if seconds >= 60:
		return "%dm" % (seconds / 60)
	return "%ds" % seconds

func _refresh_sim_ui() -> void:
	hero_label.text = "%s · Lv %d · HP %d/%d · %d gold" % [
		TalentCatalogScript.CLASS_NAME,
		sim.hero_level,
		sim.hero_hp,
		sim.effective_max_hp(),
		sim.gold
	]
	activity_label.text = sim.current_activity_text()
	quest_label.text = sim.current_quest_text()

func _on_sim_event(event: Dictionary) -> void:
	event_label.text = str(event.get("message", ""))
	var event_type := str(event.get("type", ""))

	if event_type == "talent_proc":
		talent_proc_pulse = 0.22

	if event_type in ["gear_obtained", "gear_equipped", "gear_unequipped", "gear_sold", "gear_salvaged", "talent_unlocked", "talents_reset"]:
		if equipment_panel != null and equipment_panel.visible:
			_rebuild_equipment_panel()

	if event_type in ["talent_unlocked", "talents_reset", "level_up"]:
		if talent_panel != null and talent_panel.visible:
			_rebuild_talent_panel()

	if event_type in ["companion_changed", "companion_bond_up"]:
		if gacha_collection_view != null and gacha_collection_view.visible:
			_rebuild_collection_view()

func _select_banner(banner_id: String) -> void:
	selected_banner = banner_id
	if banner_label != null:
		banner_label.text = "Banner: %s · Collection %d/%d" % [
			game.banner_label(banner_id),
			game.collected_unique(banner_id),
			game.banner_item_count(banner_id)
		]
	if pity_label != null:
		pity_label.text = "Legendary guaranteed within %d pull%s" % [
			game.pity_remaining(banner_id),
			"" if game.pity_remaining(banner_id) == 1 else "s"
		]
	if gacha_collection_view != null and gacha_collection_view.visible:
		selected_collection_item = ""
		_rebuild_collection_view()

func _summon(count: int) -> void:
	var response: Dictionary = game.pull(selected_banner, count)
	if not bool(response.get("ok", false)):
		results_label.text = str(response.get("error", "Summon failed"))
		return

	var results: Array = response.get("results", [])
	var rarity_counts := {"Common": 0, "Rare": 0, "Epic": 0, "Legendary": 0}
	var highlights: Array[String] = []
	var new_count := 0
	for result in results:
		var rarity: String = str(result.get("rarity", "Common"))
		var item_name: String = str(result.get("name", ""))
		var is_new: bool = bool(result.get("is_new", false))
		rarity_counts[rarity] = int(rarity_counts.get(rarity, 0)) + 1
		if is_new:
			new_count += 1
		if selected_banner == "gear":
			sim.add_gear(item_name)
		if is_new or rarity == "Epic" or rarity == "Legendary":
			highlights.append("%s%s — %s" % ["NEW · " if is_new else "", rarity, item_name])

	var summary := "Pulled %d · %d new · C %d · R %d · E %d · L %d" % [
		results.size(),
		new_count,
		rarity_counts["Common"],
		rarity_counts["Rare"],
		rarity_counts["Epic"],
		rarity_counts["Legendary"]
	]
	if not highlights.is_empty():
		summary += "\n" + "\n".join(highlights.slice(0, 5))
	results_label.text = summary
	_select_banner(selected_banner)
	if equipment_panel != null and equipment_panel.visible:
		_rebuild_equipment_panel()
	_save_now()

func _refresh_wallet(tokens: int) -> void:
	if token_label == null:
		return
	if game.dev_infinite_tokens:
		token_label.text = "Gacha tokens: ∞ (dev)"
	else:
		token_label.text = "Gacha tokens: %d" % tokens
