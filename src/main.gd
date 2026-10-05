extends Node

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")
const ArtCatalogScript = preload("res://src/data/art_catalog.gd")
const CharacterVisualScript = preload("res://src/view/character_visual.gd")
const GearScreenScript = preload("res://src/ui/gear_screen.gd")
const TouchListScript = preload("res://src/ui/touch_list.gd")
const UiStyleScript = preload("res://src/ui/ui_style.gd")

const ACTIVITY_POSES := {"travelling": "walk", "returning": "walk", "fighting": "attack", "recovering": "down"}
const GEAR_SLOTS := ["weapon", "offhand", "head", "chest", "legs", "hands", "feet", "accessory"]
const HOVERING_COMPANIONS := ["Torch Sprite", "Clockwork Raven"]
# How far away an enemy stands, relative to an ordinary one.
const ENEMY_REACH := {"thornback": 1.8}

var game: Node
var sim: Node

var world: Node3D
var hero_visual: Node3D
var enemy_visual: Node3D
var companion_visual: Node3D
var camera: Camera3D
var weapon_visual: Node3D
var talent_proc_visual: MeshInstance3D
var rendered_enemy_kind: String = ""
var rendered_companion_name: String = "__unset__"
var companion_character: Node3D

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
var equipment_panel: Control
var sell_gear_button: Button
var talent_panel: VBoxContainer
var talent_button: Button
var talent_points_label: Label
var talent_list: VBoxContainer
var selected_talent_branch: String = "slayer"
var talent_proc_pulse: float = 0.0
var dev_panel: VBoxContainer
var return_panel: PanelContainer
var return_label: Label
var return_talent_button: Button
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
	# A return worth reporting: time away, or anything that went wrong with the save.
	var save_trouble: bool = pending_return_report.has("save_lost") or pending_return_report.has("recovered_from_backup") or pending_return_report.has("clock_rollback")
	if save_trouble or (bool(pending_return_report.get("loaded", false)) and int(pending_return_report.get("elapsed_actual", 0)) >= 5):
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

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.30, 0.52, 0.85)
	sky_material.sky_horizon_color = Color(0.72, 0.84, 0.93)
	sky_material.ground_horizon_color = Color(0.72, 0.84, 0.93)
	sky_material.ground_bottom_color = Color(0.36, 0.45, 0.36)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 1.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Fade the far ground into the horizon so it never ends in a hard edge.
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = sky_material.sky_horizon_color
	environment.fog_depth_begin = 30.0
	environment.fog_depth_end = 160.0
	environment.fog_sky_affect = 0.0
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	fill.light_energy = 0.3
	world.add_child(fill)

	camera = Camera3D.new()
	camera.current = true
	camera.position = sim.hero_position + Vector3(7.0, 6.0, 8.0)
	world.add_child(camera)
	camera.look_at(sim.hero_position + Vector3(0.0, 0.8, 0.0), Vector3.UP)

	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(400.0, 0.35, 400.0)
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
	_build_horizon()
	_build_briarfen()

	var trees := [
		Vector3(-6.8, 0.0, -2.5),
		Vector3(-3.2, 0.0, -4.5),
		Vector3(0.2, 0.0, 3.9),
		Vector3(3.1, 0.0, 3.6),
		Vector3(12.5, 0.0, -7.0),
		Vector3(6.9, 0.0, -5.2),
		Vector3(-1.0, 0.0, -6.1)
	]
	for index in trees.size():
		_add_prop("tree_oak" if index % 2 == 0 else "tree_pine", trees[index], index * 70.0, 0.9 + 0.1 * (index % 3))
	_add_prop("bush", Vector3(-1.6, 0.0, 3.4), 20.0)
	_add_prop("bush", Vector3(4.4, 0.0, 1.2), 140.0)
	_add_prop("rock_small", Vector3(-2.4, 0.0, -2.6), 60.0)
	_add_prop("rock_small", Vector3(12.6, 0.0, 1.6), 200.0)

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
	var town: Vector3 = sim.TOWN_POSITION
	_add_prop("cottage", town + Vector3(-2.6, 0.0, -2.2), 40.0)
	_add_prop("market_stall", town + Vector3(1.4, 0.0, -2.9), 20.0)
	_add_prop("well", town + Vector3(-2.4, 0.0, 1.8), 30.0)
	_add_prop("barrel", town + Vector3(-0.5, 0.0, -2.9), 0.0)
	_add_prop("crate", town + Vector3(0.2, 0.0, -3.2), 15.0)
	_add_prop("signpost", town + Vector3(2.4, 0.0, -1.9), 50.0)
	_add_prop("fence", town + Vector3(-4.3, 0.0, -0.2), 90.0)
	_add_prop("fence", town + Vector3(-4.3, 0.0, 1.4), 90.0)

func _build_goblin_camp() -> void:
	var camp: Vector3 = sim.GOBLIN_CAMP_POSITION
	_add_prop("goblin_tent", camp + Vector3(-1.7, 0.0, -2.1), 35.0)
	_add_prop("goblin_totem", camp + Vector3(1.3, 0.0, -1.7), 30.0)
	_add_prop("campfire", camp + Vector3(-0.1, 0.0, -1.5), 0.0)
	_add_prop("bone_pile", camp + Vector3(2.2, 0.0, -1.0), 70.0)

func _build_wolf_den() -> void:
	var den: Vector3 = sim.WOLF_DEN_POSITION
	_add_prop("wolf_den", den + Vector3(0.2, 0.0, -2.8), 30.0)
	_add_prop("rock_large", den + Vector3(2.8, 0.0, -1.2), 110.0)
	_add_prop("bone_pile", den + Vector3(-1.5, 0.0, -1.6), 200.0)
	_add_prop("rock_small", den + Vector3(-2.3, 0.0, -2.6), 20.0)

func _build_horizon() -> void:
	# Backdrop only, on the side the fixed camera looks towards.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var view := Vector2(-7.0, -8.0).normalized()
	for index in 16:
		var spot := view.rotated(rng.randf_range(-1.3, 1.3)) * rng.randf_range(55.0, 120.0)
		_add_prop("hill_round" if index % 2 == 0 else "hill_ridge", Vector3(spot.x, 0.0, spot.y), rng.randf_range(0.0, 360.0), rng.randf_range(0.7, 1.5))
	for index in 45:
		var spot := view.rotated(rng.randf_range(-1.4, 1.4)) * rng.randf_range(16.0, 50.0)
		_add_prop("tree_oak" if index % 3 == 0 else "tree_pine", Vector3(spot.x, 0.0, spot.y), rng.randf_range(0.0, 360.0), rng.randf_range(0.9, 1.6))

func _build_briarfen() -> void:
	var fen: Vector3 = sim.BRIARFEN_POSITION
	var lair: Vector3 = sim.THORNBACK_POSITION
	_add_box(fen + Vector3(0.0, 0.03, 0.0), Vector3(5.2, 0.10, 5.0), Color(0.20, 0.29, 0.25))
	_add_box(lair + Vector3(0.0, 0.04, 0.0), Vector3(4.0, 0.12, 3.6), Color(0.24, 0.25, 0.21))

	var thorns := [
		Vector3(-1.8, 0.0, -1.5),
		Vector3(-0.8, 0.0, 1.7),
		Vector3(1.5, 0.0, 1.3),
		Vector3(1.9, 0.0, -1.1)
	]
	for index in thorns.size():
		_add_prop("briar_thorn", fen + thorns[index], index * 95.0, 0.85 + 0.1 * (index % 3))
	_add_prop("dead_tree", fen + Vector3(-2.3, 0.0, -2.3), 20.0)
	_add_prop("dead_tree", fen + Vector3(2.9, 0.0, -2.6), 150.0, 0.8)
	_add_prop("bog_pool", fen + Vector3(0.9, 0.06, -1.7), 0.0)
	_add_prop("briar_bush", fen + Vector3(2.4, 0.0, 0.4), 40.0)
	_add_prop("briar_bush", fen + Vector3(-2.4, 0.0, 0.5), 200.0, 0.85)

	_add_prop("thornback_hollow", lair + Vector3(2.9, 0.0, -3.2), -15.0)
	_add_prop("briar_thorn", lair + Vector3(-1.9, 0.0, 1.3), 60.0, 1.1)
	_add_prop("bone_pile", lair + Vector3(-1.6, 0.0, 0.2), 120.0)

func _build_hero() -> Node3D:
	var hero: Node3D = CharacterVisualScript.new()
	hero.name = "Adventurer"
	hero.setup("hero")
	weapon_visual = hero.attach_point("weapon")

	# Talent proc effect: a ring that pulses on the ground under the adventurer.
	talent_proc_visual = MeshInstance3D.new()
	talent_proc_visual.name = "TalentProc"
	var proc_mesh := CylinderMesh.new()
	proc_mesh.top_radius = 0.72
	proc_mesh.bottom_radius = 0.72
	proc_mesh.height = 0.035
	talent_proc_visual.mesh = proc_mesh
	talent_proc_visual.position = Vector3(0.0, 0.025, 0.0)
	talent_proc_visual.visible = false
	hero.add_child(talent_proc_visual)
	return hero

func _sync_world(delta: float) -> void:
	var fighting: bool = sim.activity == "fighting" and not sim.enemy_kind.is_empty()
	var enemy_position: Vector3 = sim.hero_position + Vector3(1.15, 0.0, -0.45) * float(ENEMY_REACH.get(sim.enemy_kind, 1.0))

	if fighting:
		hero_visual.face(enemy_position - sim.hero_position)
	else:
		hero_visual.face(sim.hero_position - hero_visual.position)
	hero_visual.position = sim.hero_position
	hero_visual.set_state(str(ACTIVITY_POSES.get(sim.activity, "idle")))
	var pulse_scale: float = 1.06 if talent_proc_pulse > 0.0 else 1.0
	hero_visual.scale = Vector3.ONE * pulse_scale
	if talent_proc_visual != null:
		talent_proc_visual.visible = talent_proc_pulse > 0.0
		if talent_proc_visual.visible:
			var progress: float = 1.0 - clampf(talent_proc_pulse / 0.28, 0.0, 1.0)
			talent_proc_visual.scale = Vector3.ONE * (0.85 + progress * 0.45)
	_sync_equipment_visual()
	_sync_companion_visual(delta)

	if fighting:
		if rendered_enemy_kind != sim.enemy_kind:
			_rebuild_enemy(sim.enemy_kind)
		enemy_visual.visible = true
		enemy_visual.position = enemy_position
		enemy_visual.rotation.y = atan2(sim.hero_position.x - enemy_position.x, sim.hero_position.z - enemy_position.z)
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
	if companion_name in HOVERING_COMPANIONS:
		desired.y += 0.65 + sin(Time.get_ticks_msec() * 0.006) * 0.08
	companion_visual.position = companion_visual.position.lerp(desired, min(1.0, delta * 4.0))
	if companion_character != null:
		# Companions keep pace with the adventurer and never go down with them.
		companion_character.rotation.y = hero_visual.rotation.y
		var pose := str(ACTIVITY_POSES.get(sim.activity, "idle"))
		companion_character.set_state("idle" if pose == "down" else pose)

func _rebuild_companion_visual(companion_name: String) -> void:
	rendered_companion_name = companion_name
	for child in companion_visual.get_children():
		child.queue_free()

	companion_character = CharacterVisualScript.new()
	companion_character.setup(ArtCatalogScript.companion_model(companion_name))
	companion_visual.add_child(companion_character)
	companion_visual.position = hero_visual.position + Vector3(-0.95, 0.0, 0.75)

func _sync_equipment_visual() -> void:
	if hero_visual == null or sim == null:
		return
	for slot in GEAR_SLOTS:
		hero_visual.set_equipment(slot, str(sim.equipped_item(slot)))

func _rebuild_enemy(kind: String) -> void:
	rendered_enemy_kind = kind
	for child in enemy_visual.get_children():
		child.queue_free()

	var enemy: Node3D = CharacterVisualScript.new()
	enemy.setup(kind)
	enemy.set_state("attack")
	enemy_visual.add_child(enemy)

func _add_prop(model_id: String, pos: Vector3, yaw_degrees: float = 0.0, size: float = 1.0) -> void:
	var prop := ArtCatalogScript.instantiate(model_id)
	if prop == null:
		return
	prop.position = pos
	prop.rotation_degrees.y = yaw_degrees
	prop.scale = Vector3.ONE * size
	world.add_child(prop)

func _add_box(pos: Vector3, size: Vector3, colour: Color) -> void:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.position = pos
	item.material_override = _material(colour)
	world.add_child(item)

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

	# The HUD sits over a bright sky; outline it so it stays readable.
	for label in [hero_label, activity_label, quest_label, event_label]:
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.09, 0.11))
		label.add_theme_constant_override("outline_size", 6)

	var bottom := MarginContainer.new()
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 16.0
	bottom.offset_right = -16.0
	bottom.offset_top = -455.0
	bottom.offset_bottom = -16.0
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
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

	return_talent_button = Button.new()
	return_talent_button.text = "Spend talent point"
	return_talent_button.visible = false
	return_talent_button.pressed.connect(_open_talents_from_return)
	return_column.add_child(return_talent_button)

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

	talent_button = Button.new()
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

	# These open everything else, so they get a full-size touch target.
	for child in actions.get_children():
		var action := child as Button
		action.custom_minimum_size = Vector2(0.0, UiStyleScript.TOUCH)
		action.add_theme_font_size_override("font_size", 22)

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

	# The gear screen is a sheet of its own, drawn over the drawers (src/ui/gear_screen.gd).
	equipment_panel = GearScreenScript.new()
	equipment_panel.visible = false
	canvas.add_child(equipment_panel)
	equipment_panel.setup(sim, game)
	equipment_panel.gear_changed.connect(_on_gear_changed)
	sell_gear_button = equipment_panel.sell_button

func _rebuild_equipment_panel() -> void:
	if equipment_panel != null and equipment_panel.visible:
		equipment_panel.refresh()

func _select_gear_item(item_name: String) -> void:
	equipment_panel.select(item_name)

func _refresh_gear_detail() -> void:
	equipment_panel.refresh_detail()

func _on_gear_changed() -> void:
	_sync_equipment_visual()
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

	# Same touch-owned list as the gear screen, so it scrolls both ways on a phone.
	var collection_scroll: Control = TouchListScript.new()
	collection_scroll.custom_minimum_size = Vector2(0.0, 180.0)
	gacha_collection_view.add_child(collection_scroll)
	collection_list = collection_scroll.content

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
		var icon: Texture2D = ArtCatalogScript.companion_icon(item_name) if selected_banner == "companions" else ArtCatalogScript.item_icon(item_name)
		if icon != null:
			button.icon = icon
			button.expand_icon = true
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(0.0, 56.0)
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
	if not PersistenceScript.save(sim, game, now_unix) and event_label != null:
		event_label.text = "Could not save. Progress since the last save may be lost."

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
	if return_talent_button != null:
		var earned_points: int = int(report.get("talent_points", 0))
		return_talent_button.visible = earned_points > 0 and sim.talent_points_available() > 0
		return_talent_button.text = "Spend talent point" if sim.talent_points_available() == 1 else "Spend talent points"
	return_panel.visible = true
	gacha_panel.visible = false
	equipment_panel.visible = false
	talent_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _open_talents_from_return() -> void:
	if return_panel != null:
		return_panel.visible = false
	talent_panel.visible = true
	equipment_panel.visible = false
	gacha_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false
	_rebuild_talent_panel()

func _close_return_report() -> void:
	if return_panel != null:
		return_panel.visible = false

func _format_return_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	if bool(report.get("save_lost", false)):
		lines.append("Your save could not be read, so a new adventure has started.")
		lines.append(str(report.get("error", "")))
		if bool(report.get("kept_copy", false)):
			lines.append("The unreadable save was kept beside the new one.")
		return "\n".join(lines)
	if bool(report.get("recovered_from_backup", false)):
		lines.append("Your latest save could not be read, so the one before it was restored.")
	if bool(report.get("clock_rollback", false)):
		lines.append("The device clock is behind your last save, so no time away was counted.")
	if bool(report.get("save_failed", false)):
		lines.append("This return could not be saved yet.")
	lines.append("Away for %s." % _format_duration(int(report.get("elapsed_actual", 0))))

	var quests := int(report.get("quests", 0))
	var kills := int(report.get("kills", 0))
	var gold_gained := int(report.get("gold", 0))
	var levels := int(report.get("levels", 0))
	var talent_points_earned := int(report.get("talent_points", 0))
	var deaths_while_away := int(report.get("deaths", 0))

	if quests > 0:
		lines.append("%d quest%s completed." % [quests, "" if quests == 1 else "s"])
	if kills > 0:
		lines.append("%d enemies defeated." % kills)
	if gold_gained > 0:
		lines.append("+%d gold." % gold_gained)
	if levels > 0:
		lines.append("Gained %d level%s." % [levels, "" if levels == 1 else "s"])
	if talent_points_earned > 0:
		lines.append("%d talent point%s ready." % [talent_points_earned, "" if talent_points_earned == 1 else "s"])
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
	if game.dev_tools_available() and int(report.get("elapsed_simulated", 0)) > 0:
		lines.append("Dev: catch-up took %d ms." % int(report.get("catch_up_msec", 0)))

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

func _show_talent_proc(branch_id: String) -> void:
	if talent_proc_visual == null:
		return

	var colour := Color(0.62, 0.54, 0.34)
	match branch_id:
		"slayer":
			colour = Color(0.68, 0.30, 0.18)
		"warden":
			colour = Color(0.32, 0.46, 0.56)
		"trailblazer":
			colour = Color(0.58, 0.50, 0.22)

	talent_proc_visual.material_override = _material(colour)
	talent_proc_visual.visible = true
	talent_proc_visual.scale = Vector3.ONE * 0.85

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
	if talent_button != null:
		var points: int = sim.talent_points_available()
		talent_button.text = "Talents" if points <= 0 else "Talents · %d" % points

func _on_sim_event(event: Dictionary) -> void:
	event_label.text = str(event.get("message", ""))
	var event_type := str(event.get("type", ""))

	if event_type == "talent_proc":
		talent_proc_pulse = 0.28
		var talent_id: String = str(event.get("talent", ""))
		_show_talent_proc(TalentCatalogScript.branch(talent_id))

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
