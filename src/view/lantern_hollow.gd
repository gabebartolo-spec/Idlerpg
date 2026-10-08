extends Node3D

# Authored dressing and encounter poses only. The saved expedition owns all outcomes.
const Art = preload("res://src/data/art_catalog.gd")
const Trails = preload("res://src/data/expedition_catalog.gd")
const Character = preload("res://src/view/character_visual.gd")
var creatures: Dictionary = {}
var encounter_visible: bool = false
var encounter_position := Vector3.ZERO

func build() -> void:
	name = "Lanternwood"
	var trail := StandardMaterial3D.new()
	trail.albedo_color = Color(0.26, 0.20, 0.12)
	trail.roughness = 1.0
	var ground := StandardMaterial3D.new()
	ground.albedo_color = Color(0.09, 0.16, 0.10)
	ground.roughness = 1.0
	var seen := {}
	for route in ["hollow", "rise"]:
		var points: Array = Trails.WAYPOINTS[route]
		var previous: Vector3 = Trails.POSITION
		for point: Vector3 in points:
			_path(previous, point, trail)
			previous = point
			if seen.has(point):
				continue
			seen[point] = true
			_clearing(point, ground)
			_prop("lantern_post", point + Vector3(-1.6, 0, 0.8), 25)
			_prop("mooncap_cluster", point + Vector3(1.7, 0, 0.8), 0, 1.1)
			_prop("bush", point + Vector3(2.5, 0, 1.5), 20, .85)
	# The camera looks from the south-east. Leave that side of every fight clear.
	for spot in [Vector3(10, 0, 6), Vector3(14, 0, 6), Vector3(18, 0, 6), Vector3(23, 0, 7), Vector3(27, 0, 7), Vector3(8, 0, 11), Vector3(9, 0, 15)]:
		_prop("tree_oak", spot, spot.x * 13, 1.25)
	_prop("lantern_arch", Vector3(12, 0, 8.8), 15)
	_prop("bog_pool", Vector3(13.2, .04, 14), 0)
	_prop("keeper_shrine", Vector3(20, 0, 8.7), 0, 1.15)
	_prop("keeper_shrine", Vector3(26, 0, 10.2), 20, 1.4)
	_prop("lantern_arch", Vector3(18, 0, 19), 55)
	_prop("briar_bush", Vector3(20.8, 0, 17), 45, 1.25)
	_prop("dead_tree", Vector3(24.4, 0, 12), 130, 1.15)
	_prop("crate", Vector3(18, 0, 12.6), 15)
	_prop("crate", Vector3(24, 0, 14.7), -15)
	for id in ["lantern_moth", "root_keeper"]:
		var creature := Character.new()
		creature.setup(id)
		creature.visible = false
		creature.set_process(false)
		add_child(creature)
		creatures[id] = creature

func sync(sim: Node, reduced_motion: bool) -> void:
	encounter_visible = false
	var state = sim.expedition
	var model := ""
	if sim.activity == "expedition" and state.active:
		var id: String = Trails.ROUTES[state.route]["nodes"][state.node]
		model = str(Trails.ENCOUNTERS[id].get("model", ""))
		var waypoint: Vector3 = Trails.WAYPOINTS[state.route][state.node]
		encounter_position = waypoint + Vector3(1.0, 0, -0.4)
		encounter_visible = not model.is_empty() and sim.hero_position.distance_to(waypoint) < 2.6
	for id in creatures:
		var creature: Node3D = creatures[id]
		creature.visible = encounter_visible and id == model
		creature.set_process(creature.visible)
		if creature.visible:
			creature.reduced_motion = reduced_motion
			creature.position = encounter_position
			creature.scale = Vector3.ONE * (1.2 if state.route == "rise" and state.node == 4 else 1.0)
			# A moth's fan is its readable motif; present it toward the fixed camera.
			creature.face(Vector3(5, 0, 8) if id == "lantern_moth" else sim.hero_position - creature.position)
			creature.set_state("attack")

func _prop(id: String, position_: Vector3, yaw: float, size_: float = 1.0) -> void:
	var prop := Art.instantiate(id)
	if prop != null:
		prop.position = position_
		prop.rotation_degrees.y = yaw
		prop.scale = Vector3.ONE * size_
		add_child(prop)

func _clearing(center: Vector3, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 3.0
	mesh.bottom_radius = 3.0
	mesh.height = .025
	mesh.radial_segments = 12
	var patch := MeshInstance3D.new()
	patch.mesh = mesh
	patch.position = center + Vector3(0, .025, 0)
	patch.scale.z = .8
	patch.material_override = material
	add_child(patch)

func _path(from: Vector3, to: Vector3, material: Material) -> void:
	# One strip and rounded caps in one draw, rather than a row of separate discs.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := (to - from).normalized().cross(Vector3.UP) * .72
	var lift := Vector3(0, .05, 0)
	var corners := [from - side + lift, from + side + lift, to + side + lift, to - side + lift]
	for index in [0, 2, 1, 0, 3, 2]:
		surface.set_normal(Vector3.UP)
		surface.add_vertex(corners[index])
	for center in [from + lift, to + lift]:
		for index in 8:
			for vertex in [center, center + Vector3(cos(index * TAU / 8), 0, sin(index * TAU / 8)) * .72, center + Vector3(cos((index + 1) * TAU / 8), 0, sin((index + 1) * TAU / 8)) * .72]:
				surface.set_normal(Vector3.UP)
				surface.add_vertex(vertex)
	var patch := MeshInstance3D.new()
	patch.mesh = surface.commit()
	patch.material_override = material
	add_child(patch)
