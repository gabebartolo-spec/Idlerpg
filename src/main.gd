extends Node

const IdentityScreenScript = preload("res://src/ui/identity_screen.gd")
const JournalScreenScript = preload("res://src/ui/journal_screen.gd")
const FieldGuideScreenScript = preload("res://src/ui/field_guide_screen.gd")
const OptionsScreenScript = preload("res://src/ui/options_screen.gd")
const WardrobeScreenScript = preload("res://src/ui/wardrobe_screen.gd")
const MenuScreenScript = preload("res://src/ui/menu_screen.gd")
const GuildScreenScript = preload("res://src/ui/guild_screen.gd")
const PresentationControllerScript = preload("res://src/ui/presentation_controller.gd")
const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const PracticeScreenScript = preload("res://src/ui/practice_screen.gd")
const ExpeditionScreenScript = preload("res://src/ui/expedition_screen.gd")
const GameStateScript = preload("res://src/game.gd")
const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")
const PersistenceScript = preload("res://src/state/persistence.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")
const ArtCatalogScript = preload("res://src/data/art_catalog.gd")
const CharacterVisualScript = preload("res://src/view/character_visual.gd")
const TrailAudioScript = preload("res://src/view/trail_audio.gd")
const LanternHollowScript = preload("res://src/view/lantern_hollow.gd")
const RewardScreenScript = preload("res://src/ui/reward_screen.gd")
const GearScreenScript = preload("res://src/ui/gear_screen.gd")
const TalentScreenScript = preload("res://src/ui/talent_screen.gd")
const GachaScreenScript = preload("res://src/ui/gacha_screen.gd")
const RelicScreenScript = preload("res://src/ui/relic_screen.gd")
const LoadoutScreenScript = preload("res://src/ui/loadout_screen.gd")
const AdventureScreenScript = preload("res://src/ui/adventure_screen.gd")
const ReturnScreenScript = preload("res://src/ui/return_screen.gd")
const ChronicleScreenScript = preload("res://src/ui/chronicle_screen.gd")
const BossScreenScript = preload("res://src/ui/boss_screen.gd")
const UiStyleScript = preload("res://src/ui/ui_style.gd")

const ACTIVITY_POSES := {"travelling": "walk", "returning": "walk", "expedition": "walk", "fighting": "attack", "recovering": "down"}
const GEAR_SLOTS := ["weapon", "offhand", "head", "chest", "legs", "hands", "feet", "accessory"]
const HOVERING_COMPANIONS := ["Torch Sprite", "Clockwork Raven"]
# How far away an enemy stands, relative to an ordinary one.
const ENEMY_REACH := {"thornback": 1.8}

var game: Node
var sim: Node

var world: Node3D
var trail_audio: Node
var lantern_hollow: Node3D
var hero_visual: Node3D
var practice_stage: Node3D
var practice_allies: Array[Node3D] = []
var practice_foes: Array[Node3D] = []
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
var event_priority: int = 0
var event_clock: float = 0.0
var save_notice: bool = false

var gacha_panel: Control
var gacha_collection_view: Control
var gacha_history_view: Control
var selected_collection_item: String:
	get:
		return gacha_panel.selected_item
	set(value):
		gacha_panel.select_item(value)
var equipment_panel: Control
var sell_gear_button: Button
var talent_panel: Control
var boss_panel: Control
var identity_panel: Control
var journal_panel: Control
var guide_panel: Control
var options_panel: Control
var wardrobe_panel: Control
var menu_panel: Control
var guild_panel: Control
var presentation_controller: Node
var fishing_panel: Control
var practice_panel: Control
var expedition_panel: Control
var reward_panel: Control
var chronicle_panel: Control
var adventure_panel: Control
var loadout_panel: Control
var relic_panel: Control
var talent_button: Button
var talent_proc_pulse: float = 0.0
var dev_panel: VBoxContainer
var return_panel: Control
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
	# Each save gets its own run of hunt rolls, fixed from here on.
	if sim.drop_seed == 0:
		sim.drop_seed = 1 + randi() % 0x7ffffffe
	if not sim.active_relic.is_empty() and not sim.owns_relic(sim.active_relic, game):
		sim.active_relic = ""
	if not sim.active_companion.is_empty() and game.collection_count("companions", sim.active_companion) <= 0:
		sim.clear_active_companion()
	sim.event_emitted.connect(_on_sim_event)

	_build_world()
	trail_audio = TrailAudioScript.new()
	add_child(trail_audio)
	trail_audio.setup(game.presentation)
	_build_ui()
	_refresh_wallet(game.gacha_tokens)
	_refresh_sim_ui()
	# A return worth reporting: time away, or anything that went wrong with the save.
	var save_trouble: bool = pending_return_report.has("save_lost") or pending_return_report.has("recovered_from_backup") or pending_return_report.has("clock_rollback")
	if save_trouble or (bool(pending_return_report.get("loaded", false)) and int(pending_return_report.get("elapsed_actual", 0)) >= 5):
		_show_return_report(pending_return_report)

func _process(delta: float) -> void:
	sim.advance(delta)
	game.collect_income(sim)
	event_clock = maxf(0.0, event_clock - delta)
	if event_clock == 0.0 and not save_notice:
		event_label.visible = false
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
	lantern_hollow = LanternHollowScript.new()
	world.add_child(lantern_hollow)
	lantern_hollow.build()
	var pond := MeshInstance3D.new()
	var water := CylinderMesh.new()
	water.top_radius = 1.4
	water.bottom_radius = 1.4
	water.height = 0.04
	pond.mesh = water
	pond.position = preload("res://src/data/fishing_catalog.gd").POSITION + Vector3(-1.5, 0.03, 0.0)
	pond.material_override = _material(Color(0.15, 0.48, 0.67))
	add_child(pond)

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
	_build_practice_stage()

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

func _build_practice_stage() -> void:
	practice_stage = Node3D.new()
	practice_stage.position = preload("res://src/data/practice_catalog.gd").POSITION
	practice_stage.visible = false
	world.add_child(practice_stage)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(5.0, 0.05, 4.5)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = 0.025
	floor_mesh.material_override = _material(Color(0.35, 0.38, 0.34))
	practice_stage.add_child(floor_mesh)
	for index in 2:
		var ally: Node3D = CharacterVisualScript.new()
		ally.setup("hero")
		ally.show_identity("slate" if index == 0 else "moss", false)
		ally.position = Vector3(-1.4 if index == 0 else 1.4, 0.0, 0.5)
		ally.face(Vector3(0, 0, -1))
		practice_stage.add_child(ally)
		practice_allies.append(ally)
		var label := Label3D.new()
		label.font = UiStyleScript.FONT_STRONG
		label.text = "Bran\nNPC protection" if index == 0 else "Iris\nNPC support"
		label.font_size = 32
		label.outline_size = 4
		label.pixel_size = 0.006
		label.position.y = 2.0
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		ally.add_child(label)
	for model_id in ["goblin", "briarling", "thornback"]:
		var foe: Node3D = CharacterVisualScript.new()
		foe.setup(model_id)
		foe.position = Vector3(0, 0, -1.7)
		foe.set_state("attack")
		foe.visible = false
		practice_stage.add_child(foe)
		practice_foes.append(foe)

func _sync_world(delta: float) -> void:
	var reduced: bool = game.presentation.reduced_motion
	lantern_hollow.sync(sim, reduced)
	hero_visual.reduced_motion = reduced
	practice_stage.visible = sim.activity == "practice"
	if practice_stage.visible:
		for ally in practice_allies:
			ally.reduced_motion = reduced
			ally.set_state("attack")
		for index in practice_foes.size():
			practice_foes[index].reduced_motion = reduced
			practice_foes[index].visible = index == sim.practice.room
		hero_visual.face(Vector3(0, 0, -1))
	var fighting: bool = sim.activity == "fighting" and not sim.enemy_kind.is_empty()
	var enemy_position: Vector3 = sim.hero_position + Vector3(1.15, 0.0, -0.45) * float(ENEMY_REACH.get(sim.enemy_kind, 1.0))

	if lantern_hollow.encounter_visible:
		hero_visual.face(lantern_hollow.encounter_position - sim.hero_position)
	elif sim.activity == "fishing":
		hero_visual.face(Vector3.LEFT)
	elif sim.activity == "practice":
		hero_visual.face(Vector3(0, 0, -1))
	elif fighting:
		hero_visual.face(enemy_position - sim.hero_position)
	else:
		hero_visual.face(sim.hero_position - hero_visual.position)
	hero_visual.show_identity(sim.identity.palette, sim.thornback_rank > 0)
	hero_visual.position = sim.hero_position
	hero_visual.set_state("attack" if sim.activity == "practice" or lantern_hollow.encounter_visible else str(ACTIVITY_POSES.get(sim.activity, "idle")))
	var pulse_scale: float = 1.06 if talent_proc_pulse > 0.0 and not reduced else 1.0
	hero_visual.scale = Vector3.ONE * pulse_scale
	if talent_proc_visual != null:
		talent_proc_visual.visible = talent_proc_pulse > 0.0 and not reduced
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
		# The telegraph: the boss swells and shudders while it winds up.
		var swell: float = 1.14 + (0.0 if reduced else sin(Time.get_ticks_msec() * 0.03) * 0.04) if sim.enemy_winding_up() else 1.0
		enemy_visual.scale = Vector3.ONE * swell if reduced else enemy_visual.scale.lerp(Vector3.ONE * swell, min(1.0, delta * 12.0))
		for character in enemy_visual.get_children():
			if character is CharacterVisualScript:
				character.reduced_motion = reduced
	else:
		enemy_visual.visible = false
		rendered_enemy_kind = ""

	var woodland: bool = sim.activity == "expedition" and sim.expedition.route in ["hollow", "rise"]
	var desired_camera: Vector3 = hero_visual.position + (Vector3(5.6, 4.8, 6.4) if woodland else Vector3(7.0, 6.0, 8.0))
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
		desired.y += 0.65 + (0.0 if game.presentation.reduced_motion else sin(Time.get_ticks_msec() * 0.006) * 0.08)
	companion_visual.position = companion_visual.position.lerp(desired, min(1.0, delta * 4.0))
	if companion_character != null:
		companion_character.reduced_motion = game.presentation.reduced_motion
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
		hero_visual.set_equipment(slot, sim.wardrobe.visible_item(slot, sim.equipped_item(slot)))

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
	var layer := CanvasLayer.new()
	add_child(layer)
	var canvas := preload("res://src/ui/safe_area.gd").new()
	canvas.name = "SafeArea"
	layer.add_child(canvas)

	var top := MarginContainer.new()
	top.anchor_right = 1.0
	top.offset_left = 16.0
	top.offset_right = -16.0
	top.offset_top = 18.0
	top.offset_bottom = 165.0
	canvas.add_child(top)

	var hud_card := PanelContainer.new()
	hud_card.add_theme_stylebox_override("panel", UiStyleScript.box(Color(0.15, 0.17, 0.13, 0.93), 16.0, 14.0))
	top.add_child(hud_card)
	var top_column := VBoxContainer.new()
	top_column.add_theme_constant_override("separation", 4)
	hud_card.add_child(top_column)

	hero_label = Label.new()
	hero_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_label.add_theme_font_override("font", UiStyleScript.FONT_STRONG)
	hero_label.add_theme_font_size_override("font_size", 26)
	top_column.add_child(hero_label)

	activity_label = Label.new()
	activity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	activity_label.add_theme_font_size_override("font_size", 24)
	top_column.add_child(activity_label)

	quest_label = Label.new()
	quest_label.visible = false
	top_column.add_child(quest_label)

	event_label = Label.new()
	event_label.text = ""
	event_label.visible = false
	event_label.add_theme_font_size_override("font_size", 22)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top_column.add_child(event_label)

	# A quiet solid surface keeps the custom letters readable over any sky.
	for label in [hero_label, activity_label, quest_label, event_label]:
		label.add_theme_color_override("font_color", UiStyleScript.TEXT)

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

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	bottom_column.add_child(actions)

	var equipment_button := UiStyleScript.button("Gear")
	equipment_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_button.pressed.connect(_toggle_equipment)
	actions.add_child(equipment_button)

	talent_button = UiStyleScript.button("Talents")
	talent_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talent_button.pressed.connect(_toggle_talents)
	actions.add_child(talent_button)

	var gacha_button := UiStyleScript.button("Summon")
	gacha_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gacha_button.pressed.connect(_toggle_gacha)
	actions.add_child(gacha_button)
	var more_button := UiStyleScript.button("More")
	more_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	more_button.pressed.connect(func() -> void: _toggle_sheet(menu_panel))
	actions.add_child(more_button)

	# These open everything else, so they get a full-size touch target.
	for child in actions.get_children():
		var action := child as Button
		action.custom_minimum_size = Vector2(0.0, UiStyleScript.TOUCH)
		action.add_theme_font_size_override("font_size", 22)

	if game.dev_tools_available():
		dev_panel = VBoxContainer.new()
		dev_panel.visible = false
		dev_panel.add_theme_constant_override("separation", 6)
		bottom_column.add_child(dev_panel)
		_build_dev_tools(dev_panel)

	# Management screens are sheets of their own, drawn over the world (src/ui/).
	equipment_panel = GearScreenScript.new()
	equipment_panel.visible = false
	canvas.add_child(equipment_panel)
	equipment_panel.setup(sim, game)
	equipment_panel.gear_changed.connect(_on_gear_changed)
	sell_gear_button = equipment_panel.sell_button

	talent_panel = TalentScreenScript.new()
	talent_panel.visible = false
	canvas.add_child(talent_panel)
	talent_panel.setup(sim)
	talent_panel.talents_changed.connect(_on_build_changed)

	boss_panel = BossScreenScript.new()
	boss_panel.visible = false
	canvas.add_child(boss_panel)
	boss_panel.setup(sim)
	boss_panel.build_changed.connect(_on_gear_changed)
	boss_panel.talents_requested.connect(_open_talents_from_return)

	gacha_panel = GachaScreenScript.new()
	gacha_panel.visible = false
	canvas.add_child(gacha_panel)
	gacha_panel.setup(sim, game)
	gacha_panel.summoned.connect(_on_build_changed)
	gacha_panel.collection_changed.connect(_on_build_changed)
	gacha_panel.companion_changed.connect(_on_companion_changed)
	gacha_collection_view = gacha_panel.collection_view
	gacha_history_view = gacha_panel.history_view

	relic_panel = RelicScreenScript.new()
	relic_panel.visible = false
	canvas.add_child(relic_panel)
	relic_panel.setup(sim, game)
	relic_panel.changed.connect(_on_gear_changed)

	loadout_panel = LoadoutScreenScript.new()
	loadout_panel.visible = false
	canvas.add_child(loadout_panel)
	loadout_panel.setup(sim, game)
	loadout_panel.changed.connect(_on_gear_changed)

	adventure_panel = AdventureScreenScript.new()
	adventure_panel.visible = false
	canvas.add_child(adventure_panel)
	adventure_panel.setup(sim)
	adventure_panel.route_requested.connect(_open_chronicle_route)
	adventure_panel.changed.connect(_save_now)

	identity_panel = IdentityScreenScript.new()
	identity_panel.visible = false
	canvas.add_child(identity_panel)
	identity_panel.setup(sim)
	identity_panel.changed.connect(_save_now)
	journal_panel = JournalScreenScript.new()
	journal_panel.visible = false
	canvas.add_child(journal_panel)
	journal_panel.setup(sim)
	journal_panel.guide_requested.connect(func() -> void: _open_chronicle_destination("guide", ""))
	guide_panel = FieldGuideScreenScript.new()
	guide_panel.visible = false
	canvas.add_child(guide_panel)
	guide_panel.setup(sim)
	fishing_panel = FishingScreenScript.new()
	fishing_panel.visible = false
	canvas.add_child(fishing_panel)
	fishing_panel.setup(sim)
	fishing_panel.changed.connect(_save_now)
	practice_panel = PracticeScreenScript.new()
	practice_panel.visible = false
	canvas.add_child(practice_panel)
	practice_panel.setup(sim)
	practice_panel.changed.connect(_save_now)
	expedition_panel = ExpeditionScreenScript.new()
	expedition_panel.visible = false
	canvas.add_child(expedition_panel)
	expedition_panel.setup(sim)
	expedition_panel.changed.connect(_save_now)
	expedition_panel.route_requested.connect(_open_chronicle_route)
	reward_panel = RewardScreenScript.new()
	reward_panel.visible = false
	canvas.add_child(reward_panel)
	reward_panel.setup(sim, game.presentation)
	reward_panel.changed.connect(_on_gear_changed)
	guild_panel = GuildScreenScript.new()
	guild_panel.visible = false
	canvas.add_child(guild_panel)
	guild_panel.setup(sim, game.presentation)
	guild_panel.changed.connect(_on_gear_changed)
	chronicle_panel = ChronicleScreenScript.new()
	chronicle_panel.visible = false
	canvas.add_child(chronicle_panel)
	chronicle_panel.setup(sim)
	chronicle_panel.route_requested.connect(func(route: String) -> void: _open_chronicle_destination(route, str(chronicle_panel.targets.get(chronicle_panel.selected, ""))))

	return_panel = ReturnScreenScript.new()
	return_panel.visible = false
	canvas.add_child(return_panel)
	return_panel.setup()
	return_panel.destination_requested.connect(_open_chronicle_destination)
	return_panel.talents_requested.connect(_open_talents_from_return)
	return_talent_button = return_panel.talent_button
	menu_panel = MenuScreenScript.new()
	menu_panel.visible = false
	canvas.add_child(menu_panel)
	menu_panel.setup(game.dev_tools_available())
	menu_panel.route_requested.connect(_open_chronicle_route)
	options_panel = OptionsScreenScript.new()
	options_panel.visible = false
	canvas.add_child(options_panel)
	options_panel.setup(game.presentation)
	options_panel.changed.connect(_on_options_changed)
	wardrobe_panel = WardrobeScreenScript.new()
	wardrobe_panel.visible = false
	canvas.add_child(wardrobe_panel)
	wardrobe_panel.setup(sim, game)
	wardrobe_panel.changed.connect(_on_gear_changed)
	presentation_controller = PresentationControllerScript.new()
	add_child(presentation_controller)
	presentation_controller.setup(game.presentation, canvas)

func _on_options_changed() -> void:
	presentation_controller.apply()
	trail_audio.apply_preferences()
	_sync_world(0.0)
	_save_now()

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

# Talents, summons and locks can all change what the gear screen shows.
func _on_build_changed() -> void:
	_rebuild_equipment_panel()
	_save_now()

func _on_companion_changed() -> void:
	_sync_companion_visual(1.0)
	_save_now()

func _unlock_talent(talent_id: String) -> void:
	talent_panel.unlock(talent_id)

func _select_banner(banner_id: String) -> void:
	gacha_panel.select_banner(banner_id)

func _show_gacha_mode(mode: String) -> void:
	gacha_panel.show_mode(mode)

func _summon(count: int) -> void:
	gacha_panel.summon(count)

func _use_collection_item() -> void:
	gacha_panel.use_item()

func _refresh_wallet(_tokens: int) -> void:
	if gacha_panel != null:
		gacha_panel.refresh_wallet()

# Only one sheet, drawer or report is open at a time.
func _close_drawers() -> void:
	for sheet in [equipment_panel, talent_panel, boss_panel, gacha_panel, wardrobe_panel, adventure_panel, loadout_panel, relic_panel, chronicle_panel, journal_panel, guide_panel, options_panel, menu_panel, guild_panel, identity_panel, fishing_panel, practice_panel, expedition_panel, reward_panel, dev_panel, return_panel]:
		if sheet != null:
			sheet.visible = false

func _toggle_sheet(sheet: Control) -> void:
	var opening: bool = not sheet.visible
	_close_drawers()
	if opening:
		sheet.open()

func _toggle_equipment() -> void:
	_toggle_sheet(equipment_panel)

func _toggle_talents() -> void:
	_toggle_sheet(talent_panel)

func _toggle_boss() -> void:
	_toggle_sheet(boss_panel)

func _toggle_gacha() -> void:
	gacha_panel.show_mode("summon")
	_toggle_sheet(gacha_panel)

func _toggle_dev_tools() -> void:
	if dev_panel == null:
		return
	var opening: bool = not dev_panel.visible
	_close_drawers()
	dev_panel.visible = opening

func _dev_stress_pull() -> void:
	_close_drawers()
	gacha_panel.show_mode("summon")
	gacha_panel.open()
	_summon(100)

func _show_return_report(report: Dictionary) -> void:
	if return_panel == null:
		return
	_close_drawers()
	guide_panel.away_notes = _format_return_report(report)
	var presentation_report := report.duplicate(true)
	presentation_report["chests_ready"] = sim.reward_chests.pending.size()
	return_panel.show_report(presentation_report, _compact_return_report(report))
	return_label = return_panel.summary
	if return_talent_button != null:
		var earned_points: int = int(report.get("talent_points", 0))
		return_talent_button.visible = earned_points > 0 and sim.talent_points_available() > 0
		return_talent_button.text = "Spend talent point" if sim.talent_points_available() == 1 else "Spend talent points"
	return_panel.visible = true

func _open_chronicle_route(route: String) -> void:
	_open_chronicle_destination(route, "")

func _open_chronicle_destination(route: String, target: String) -> void:
	_close_drawers()
	match route:
		"guild":
			guild_panel.open()
		"rewards":
			reward_panel.open()
		"wardrobe":
			wardrobe_panel.open()
		"options":
			options_panel.open()
		"identity":
			identity_panel.open()
		"adventure":
			adventure_panel.open()
		"builds":
			loadout_panel.open()
		"dev":
			if dev_panel != null:
				dev_panel.visible = true
		"summon":
			gacha_panel.show_mode("summon")
			gacha_panel.open()
		"guide":
			if guide_panel.tabs.has(target):
				guide_panel.chapter = target
			guide_panel.open()
		"expedition":
			expedition_panel.open()
			expedition_panel.mode = "story" if not sim.expedition.recap.is_empty() else "route"
			if not target.is_empty() and sim.expedition.Catalog.ROUTES.has(target):
				sim.expedition.selected_route = target
			expedition_panel.refresh()
		"practice":
			practice_panel.open()
		"fishing":
			fishing_panel.open()
		"journal":
			journal_panel.open()
			journal_panel.select(target)
		"gear":
			equipment_panel.worn_only = false
			equipment_panel.selected = ""
			equipment_panel.set_slot_filter("")
			equipment_panel.open()
			equipment_panel.select(target)
		"relics":
			relic_panel.open()
		"boss":
			boss_panel.open()
		"talents":
			talent_panel.open()
		"companion", "companions":
			gacha_panel.select_banner("companions")
			gacha_panel.show_mode("collection")
			gacha_panel.open()
			gacha_panel.select_item(target if not target.is_empty() else sim.active_companion)
		_:
			chronicle_panel.open()

func _open_talents_from_return() -> void:
	_close_drawers()
	talent_panel.open()

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

func _set_infinite_tokens(enabled: bool) -> void:
	game.set_dev_infinite_tokens(enabled)
	_refresh_wallet(game.gacha_tokens)

func _reset_pity() -> void:
	game.dev_reset_pity()
	event_label.text = "Dev: pity counters reset."

func _save_now(now_unix: int = -1) -> void:
	if sim == null or game == null:
		return
	var saved: bool = PersistenceScript.save(sim, game, now_unix)
	if not saved and event_label != null:
		save_notice = true
		event_label.text = "Could not save. Progress since the last save may be lost."
		event_label.visible = true
	elif saved and save_notice:
		save_notice = false
		event_label.visible = false

func _dev_simulate_away() -> void:
	var now_unix := int(Time.get_unix_time_from_system())
	PersistenceScript.save(sim, game, now_unix - 600)
	var report: Dictionary = PersistenceScript.load_and_advance(sim, game, now_unix)
	_show_return_report(report)
	if dev_panel != null:
		dev_panel.visible = false

func _close_return_report() -> void:
	if return_panel != null:
		return_panel.visible = false

func _compact_return_report(report: Dictionary) -> String:
	if report.get("newer_version", false) or report.get("save_lost", false):
		return _format_return_report(report)
	var lines: Array[String] = ["Away · " + _format_duration(int(report.get("elapsed_actual", 0)))]
	var gains: Array[String] = []
	for reward in [["gold", "gold"], ["tokens", "tokens"]]:
		var count := int(report.get(reward[0], 0))
		if count > 0:
			gains.append("+%d %s" % [count, reward[1]])
	if not gains.is_empty():
		lines.append(" · ".join(gains))
	var levels := int(report.get("levels", 0))
	if levels > 0:
		lines.append("+%d level%s" % [levels, "" if levels == 1 else "s"])
	var gear: Dictionary = report.get("gear", {})
	if not gear.is_empty():
		var count := 0
		for amount in gear.values():
			count += int(amount)
		lines.append("%d gear found" % count)
	var catches := int(report.get("fish_catches", 0))
	if catches > 0:
		lines.append("%d catches" % catches)
	if report.get("deaths", 0) > 0:
		lines.append("Defeated · recovered in Mossgate")
	if report.get("recovered_from_backup", false):
		lines.append("Previous save restored")
	if report.get("clock_rollback", false):
		lines.append("Clock changed · no time away counted")
	if report.get("save_failed", false):
		lines.append("Could not save this return")
	if report.get("capped", false):
		lines.append("7-day catch-up limit reached")
	return "\n".join(lines)

func _format_return_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	if bool(report.get("newer_version", false)):
		return "Your save belongs to a newer game version. Update the game to continue. Your existing save was left untouched; this build cannot replace it."
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
	lines.append("%s · Away for %s." % [sim.identity.adventurer_name, _format_duration(int(report.get("elapsed_actual", 0)))])

	var quests := int(report.get("quests", 0))
	var kills := int(report.get("kills", 0))
	var gold_gained := int(report.get("gold", 0))
	var levels := int(report.get("levels", 0))
	var talent_points_earned := int(report.get("talent_points", 0))
	var deaths_while_away := int(report.get("deaths", 0))

	if int(report.get("tokens", 0)) > 0:
		lines.append("+%d earned summon tokens." % int(report["tokens"]))
	if int(report.get("fish_catches", 0)) > 0:
		lines.append("%d passive catches at Mossgate Pond." % int(report["fish_catches"]))
	if int(report.get("practice_clears", 0)) > 0:
		lines.append("%d practice dungeon clear(s) with NPC allies." % int(report["practice_clears"]))
	if int(report.get("expeditions", 0)) > 0:
		lines.append("%d trail expedition(s) completed." % int(report["expeditions"]))
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
		lines.append("Defeated %d time%s. Recovery takes place in Mossgate." % [deaths_while_away, "" if deaths_while_away == 1 else "s"])
	var boss_ranks := int(report.get("boss_ranks", 0))
	if boss_ranks > 0:
		lines.append("Beat Old Thornback %d time%s. It is now rank %d." % [boss_ranks, "" if boss_ranks == 1 else "s", sim.thornback_rank])

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
		lines.append("Gear found: %s." % ", ".join(gear_parts.slice(0, 4)))

	if bool(report.get("capped", false)):
		lines.append("Prototype catch-up is currently capped at 7 days per return.")
	if game.dev_tools_available() and int(report.get("elapsed_simulated", 0)) > 0:
		lines.append("Dev: catch-up took %d ms." % int(report.get("catch_up_msec", 0)))

	if lines.size() == 1:
		lines.append("No new milestones during this return.")

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
	if gacha_panel != null and gacha_panel.visible:
		gacha_panel.refresh_wallet()
	hero_label.text = "%s · Lv %d\n%d/%d HP · %d gold" % [
		sim.identity.adventurer_name,
		sim.hero_level,
		sim.hero_hp,
		sim.effective_max_hp(),
		sim.gold
	]
	activity_label.text = _compact_activity()
	if menu_panel != null:
		menu_panel.routes["rewards"].text = "Rewards · %d ready" % sim.reward_chests.pending.size() if not sim.reward_chests.pending.is_empty() else "Rewards"
	quest_label.text = sim.current_quest_text()
	if talent_button != null:
		var points: int = sim.talent_points_available()
		talent_button.text = "Talents" if points <= 0 else "Talents · %d" % points

func _compact_activity() -> String:
	match sim.activity:
		"expedition":
			return "%s · %d/5" % [sim.expedition.Catalog.ROUTES[sim.expedition.route]["name"], mini(5, sim.expedition.node + 1)]
		"practice":
			return "Practice · room %d/3 · %d HP" % [mini(3, sim.practice.room + 1), sim.practice.hp]
		"fishing":
			return "Fishing · next catch in %ds" % int(ceil(float(sim.fishing.Catalog.INTERVAL_USEC - sim.fishing.progress_usec) / 1000000.0))
		"fighting":
			return sim.current_activity_text()
		"looting":
			return "Gathering loot"
		_:
			return sim.current_activity_text()

func _compact_event(event: Dictionary) -> String:
	match str(event.get("type", "")):
		"level_up":
			return "Level %d!" % int(event.get("level", sim.hero_level))
		"gear_obtained":
			return "+ " + str(event.get("gear", "New gear"))
		"relic_obtained":
			return "+ " + str(event.get("relic", "New relic"))
		"expedition_completed":
			return "Chest ready · Expedition complete" if event.get("won", false) else "Returned early · gold kept"
		"chest_opened":
			var gear := str(event.get("gear", ""))
			return "+ " + gear if not gear.is_empty() else "+%d gold · Chest opened" % int(event.get("gold", 0))
		"goal_completed":
			var title: String = preload("res://src/state/adventurer_identity.gd").TITLES.get(str(event.get("goal", "")), "")
			return "Title earned · " + title if not title.is_empty() else "Achievement · " + str(event.get("title", "Complete"))
		"practice_completed":
			return "Practice won!" if event.get("won", false) else "Practice ended · try another role"
	return ""

func _on_sim_event(event: Dictionary) -> void:
	var event_type := str(event.get("type", ""))
	if trail_audio != null:
		trail_audio.play_event(event_type, bool(event.get("won", true)))
	# Full stories remain in the journal/guide. The normal HUD is a glance.
	# Important save warnings stay visible until a successful save.
	if not save_notice and event_type in ["level_up", "gear_obtained", "relic_obtained", "expedition_completed", "practice_completed", "chest_opened", "goal_completed"]:
		var priority := 100 if event_type == "goal_completed" else (80 if event_type == "chest_opened" else 50)
		if event_clock <= 0.0 or priority >= event_priority:
			event_label.text = _compact_event(event)
			event_label.visible = true
			event_clock = 5.0
			event_priority = priority

	if adventure_panel != null and adventure_panel.visible:
		adventure_panel.refresh()
	if event_type in ["relic_obtained", "relic_equipped", "loadout_applied"]:
		if relic_panel != null and relic_panel.visible:
			relic_panel.refresh()
		if gacha_panel != null and gacha_panel.visible:
			gacha_panel.refresh()

	if event_type == "talent_proc":
		talent_proc_pulse = 0.28
		var talent_id: String = str(event.get("talent", ""))
		_show_talent_proc(TalentCatalogScript.branch(talent_id))
	if event_type in ["companion_moment", "companion_proc"]:
		talent_proc_pulse = 0.28
		_show_talent_proc("warden")

	if event_type in ["gear_obtained", "gear_equipped", "gear_unequipped", "gear_sold", "gear_salvaged", "talent_unlocked", "talents_reset"]:
		if wardrobe_panel != null and wardrobe_panel.visible:
			wardrobe_panel.refresh()
		if equipment_panel != null and equipment_panel.visible:
			_rebuild_equipment_panel()

	if event_type in ["talent_unlocked", "talents_reset", "level_up", "loadout_applied"]:
		if talent_panel != null and talent_panel.visible:
			talent_panel.refresh()

	if event_type in ["boss_defeated", "boss_lost", "gear_obtained", "gear_equipped", "gear_unequipped", "hunt_changed", "level_up", "loadout_applied", "relic_equipped"]:
		if boss_panel != null and boss_panel.visible:
			boss_panel.refresh()

	if event_type in ["companion_changed", "companion_bond_up"]:
		if gacha_panel != null and gacha_panel.visible:
			gacha_panel.refresh()
	if journal_panel != null and journal_panel.visible and journal_panel.known_count != sim.journal.found.size():
		journal_panel.refresh()
