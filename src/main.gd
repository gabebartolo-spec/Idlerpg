extends Node

const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const ArtCatalogScript = preload("res://src/data/art_catalog.gd")
const CharacterVisualScript = preload("res://src/view/character_visual.gd")

const ACTIVITY_POSES := {"travelling": "walk", "returning": "walk", "fighting": "attack", "recovering": "down"}
const GEAR_SLOTS := ["weapon", "offhand", "head", "chest"]

var game: Node
var sim: Node

var world: Node3D
var hero_visual: Node3D
var enemy_visual: Node3D
var camera: Camera3D
var weapon_visual: Node3D
var rendered_enemy_kind: String = ""

var hero_label: Label
var activity_label: Label
var quest_label: Label
var event_label: Label

var selected_banner: String = "gear"
var token_label: Label
var banner_label: Label
var results_label: RichTextLabel
var gacha_panel: VBoxContainer
var equipment_panel: VBoxContainer
var equipment_slots_label: Label
var gear_list: VBoxContainer
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
	sim.event_emitted.connect(_on_sim_event)

	_build_world()
	_build_ui()
	_refresh_wallet(game.gacha_tokens)
	_refresh_sim_ui()
	if bool(pending_return_report.get("loaded", false)) and int(pending_return_report.get("elapsed_actual", 0)) >= 5:
		_show_return_report(pending_return_report)

func _process(delta: float) -> void:
	sim.advance(delta)
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

	var trees := [
		Vector3(-6.8, 0.0, -2.5),
		Vector3(-3.2, 0.0, -4.5),
		Vector3(0.2, 0.0, 3.9),
		Vector3(3.1, 0.0, 3.6),
		Vector3(6.7, 0.0, 2.1),
		Vector3(6.9, 0.0, -5.2),
		Vector3(-1.0, 0.0, -6.1)
	]
	for index in trees.size():
		_add_prop("tree_oak" if index % 2 == 0 else "tree_pine", trees[index], index * 70.0, 0.9 + 0.1 * (index % 3))
	_add_prop("bush", Vector3(-1.6, 0.0, 3.4), 20.0)
	_add_prop("bush", Vector3(4.4, 0.0, 1.2), 140.0)
	_add_prop("rock_small", Vector3(-2.4, 0.0, -2.6), 60.0)
	_add_prop("rock_small", Vector3(8.2, 0.0, -1.4), 200.0)

	hero_visual = _build_hero()
	world.add_child(hero_visual)

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

func _build_hero() -> Node3D:
	var hero: Node3D = CharacterVisualScript.new()
	hero.name = "Adventurer"
	hero.setup("hero")
	weapon_visual = hero.attach_point("weapon")
	return hero

func _sync_world(delta: float) -> void:
	var fighting: bool = sim.activity == "fighting" and not sim.enemy_kind.is_empty()
	var enemy_position: Vector3 = sim.hero_position + Vector3(1.15, 0.0, -0.45)

	if fighting:
		hero_visual.face(enemy_position - sim.hero_position)
	else:
		hero_visual.face(sim.hero_position - hero_visual.position)
	hero_visual.position = sim.hero_position
	hero_visual.set_state(str(ACTIVITY_POSES.get(sim.activity, "idle")))
	_sync_equipment_visual()

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
	bottom.offset_top = -370.0
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

	var gacha_button := Button.new()
	gacha_button.text = "Gacha"
	gacha_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_button.pressed.connect(_toggle_gacha)
	actions.add_child(gacha_button)

	if game.dev_tools_available():
		var dev_button := Button.new()
		dev_button.text = "Dev tools"
		dev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dev_button.pressed.connect(_toggle_dev_tools)
		actions.add_child(dev_button)

	equipment_panel = VBoxContainer.new()
	equipment_panel.visible = false
	equipment_panel.add_theme_constant_override("separation", 6)
	bottom_column.add_child(equipment_panel)
	_build_equipment_panel(equipment_panel)

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

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 145.0)
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
	var head: String = str(sim.equipped_item("head"))
	var chest: String = str(sim.equipped_item("chest"))
	var offhand: String = str(sim.equipped_item("offhand"))
	equipment_slots_label.text = "ATK %d · HP %d\nWeapon: %s · Head: %s\nChest: %s · Off-hand: %s" % [
		sim.effective_attack(),
		sim.effective_max_hp(),
		weapon if not weapon.is_empty() else "—",
		head if not head.is_empty() else "—",
		chest if not chest.is_empty() else "—",
		offhand if not offhand.is_empty() else "—"
	]

	for child in gear_list.get_children():
		child.queue_free()

	var names: Array[String] = sim.owned_gear_names()
	if names.is_empty():
		var empty := Label.new()
		empty.text = "No gear yet. Keep questing or try the Gear banner."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		gear_list.add_child(empty)
		return

	for item_name in names:
		var button := Button.new()
		button.text = GearCatalogScript.summary(item_name)
		button.icon = ArtCatalogScript.item_icon(item_name)
		button.expand_icon = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0.0, 56.0)
		var slot_name: String = GearCatalogScript.slot(item_name)
		if sim.equipped_item(slot_name) == item_name:
			button.text += " · Equipped"
		button.pressed.connect(_equip_item.bind(item_name))
		gear_list.add_child(button)

func _equip_item(item_name: String) -> void:
	if sim.equip_gear(item_name):
		_rebuild_equipment_panel()
		_sync_equipment_visual()
		_save_now()

func _build_gacha_panel(parent: VBoxContainer) -> void:
	token_label = Label.new()
	token_label.add_theme_font_size_override("font_size", 18)
	parent.add_child(token_label)

	banner_label = Label.new()
	parent.add_child(banner_label)

	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 6)
	parent.add_child(banner_row)
	_add_banner_button(banner_row, "gear", "Gear")
	_add_banner_button(banner_row, "companions", "Companions")
	_add_banner_button(banner_row, "relics", "Relics")

	var summon_row := HBoxContainer.new()
	summon_row.add_theme_constant_override("separation", 6)
	parent.add_child(summon_row)

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
	parent.add_child(results_label)

	_select_banner(selected_banner)

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
	gacha_panel.visible = false
	return_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _toggle_gacha() -> void:
	gacha_panel.visible = not gacha_panel.visible
	equipment_panel.visible = false
	return_panel.visible = false
	if dev_panel != null:
		dev_panel.visible = false

func _toggle_dev_tools() -> void:
	if dev_panel == null:
		return
	dev_panel.visible = not dev_panel.visible
	gacha_panel.visible = false
	equipment_panel.visible = false
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
	hero_label.text = "Adventurer · Lv %d · HP %d/%d · %d gold" % [
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
	if event_type == "gear_obtained" or event_type == "gear_equipped":
		if equipment_panel != null and equipment_panel.visible:
			_rebuild_equipment_panel()

func _select_banner(banner_id: String) -> void:
	selected_banner = banner_id
	if banner_label != null:
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
		if selected_banner == "gear":
			sim.add_gear(str(result.get("name", "")))
		if rarity == "Epic" or rarity == "Legendary":
			highlights.append("%s — %s" % [rarity, result.get("name", "?")])

	var summary := "Pulled %d · C %d · R %d · E %d · L %d" % [
		results.size(),
		rarity_counts["Common"],
		rarity_counts["Rare"],
		rarity_counts["Epic"],
		rarity_counts["Legendary"]
	]
	if not highlights.is_empty():
		summary += "\n" + "\n".join(highlights.slice(0, 4))
	results_label.text = summary
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
