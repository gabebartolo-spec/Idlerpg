extends Node3D

# A character model from the art build, animated by swinging its parts.
# Presentation only: it shows a state the simulation already decided.

const ArtCatalogScript = preload("res://src/data/art_catalog.gd")

const PART_NAMES := [
	"torso", "body", "head", "tail",
	"arm_l", "arm_r", "leg_l", "leg_r",
	"leg_fl", "leg_fr", "leg_bl", "leg_br",
	"wing_l", "wing_r"
]
# Paired slots show the same model on both sides.
const SLOT_ATTACH := {
	"weapon": ["attach_hand_r"],
	"offhand": ["attach_hand_l"],
	"head": ["attach_head"],
	"chest": ["attach_chest"],
	"legs": ["attach_leg_l", "attach_leg_r"],
	"hands": ["attach_glove_l", "attach_glove_r"],
	"feet": ["attach_foot_l", "attach_foot_r"],
	"accessory": ["attach_accessory"]
}

var outfit_accent: MeshInstance3D
var keepsake_pin: MeshInstance3D
var identity_palette: String = ""
var model: Node3D
var state: String = "idle"
var clock: float = 0.0
var parts: Dictionary = {}
var rest: Dictionary = {}
var worn: Dictionary = {}
var worn_names: Dictionary = {}

func setup(model_id: String) -> bool:
	model = ArtCatalogScript.instantiate(model_id)
	if model == null:
		return false
	add_child(model)
	for part_name in PART_NAMES:
		var part := model.find_child(part_name, true, false) as Node3D
		if part != null:
			parts[part_name] = part
			rest[part_name] = part.rotation
	return true

func show_identity(palette: String, keepsake: bool) -> void:
	if outfit_accent == null:
		outfit_accent = MeshInstance3D.new()
		outfit_accent.name = "OutfitAccent"
		var sash := BoxMesh.new()
		sash.size = Vector3(0.62, 0.12, 0.12)
		outfit_accent.mesh = sash
		outfit_accent.position = Vector3(0, 0.85, 0.18)
		model.add_child(outfit_accent)
		keepsake_pin = MeshInstance3D.new()
		var pin := SphereMesh.new()
		pin.radius = 0.07
		pin.height = 0.14
		keepsake_pin.mesh = pin
		keepsake_pin.position = Vector3(0.16, 1.10, 0.20)
		var metal := StandardMaterial3D.new()
		metal.albedo_color = Color(0.94, 0.76, 0.22)
		keepsake_pin.material_override = metal
		model.add_child(keepsake_pin)
	if palette != identity_palette:
		identity_palette = palette
		var cloth := StandardMaterial3D.new()
		cloth.albedo_color = preload("res://src/state/adventurer_identity.gd").PALETTES.get(palette, Color(0.82, 0.49, 0.16))
		outfit_accent.material_override = cloth
	keepsake_pin.visible = keepsake

func set_state(next_state: String) -> void:
	if next_state != state:
		state = next_state
		clock = 0.0

func face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length() > 0.001:
		rotation.y = atan2(direction.x, direction.z)

func attach_points(slot: String) -> Array[Node3D]:
	var points: Array[Node3D] = []
	if model == null:
		return points
	for point_name in SLOT_ATTACH.get(slot, []):
		var point := model.find_child(point_name, true, false) as Node3D
		if point != null:
			points.append(point)
	return points

func attach_point(slot: String) -> Node3D:
	var points := attach_points(slot)
	return points[0] if not points.is_empty() else null

func set_equipment(slot: String, item_name: String) -> void:
	if str(worn_names.get(slot, "")) == item_name:
		return
	worn_names[slot] = item_name
	for piece in worn.get(slot, []):
		piece.queue_free()
	worn.erase(slot)

	var pieces: Array[Node3D] = []
	for point in attach_points(slot):
		var piece := ArtCatalogScript.instantiate(ArtCatalogScript.item_model(item_name))
		if piece != null:
			point.add_child(piece)
			pieces.append(piece)
	if not pieces.is_empty():
		worn[slot] = pieces

func _process(delta: float) -> void:
	if model == null:
		return
	clock += delta
	for part_name in parts:
		parts[part_name].rotation = rest[part_name]
	model.position = Vector3.ZERO
	model.rotation = Vector3.ZERO

	match state:
		"walk":
			var swing := sin(clock * 9.0) * 0.6
			_pitch("leg_l", swing)
			_pitch("leg_r", -swing)
			_pitch("arm_l", -swing * 0.7)
			_pitch("arm_r", swing * 0.4)
			_pitch("leg_fl", swing)
			_pitch("leg_br", swing)
			_pitch("leg_fr", -swing)
			_pitch("leg_bl", -swing)
			_pitch("tail", swing * 0.3)
			model.position.y = abs(sin(clock * 9.0)) * 0.04
		"attack":
			# Wind up for most of the beat, then strike fast.
			var beat := fmod(clock * 1.3, 1.0)
			var windup := smoothstep(0.0, 0.6, beat) - smoothstep(0.6, 0.72, beat)
			var strike := smoothstep(0.6, 0.72, beat) - smoothstep(0.72, 1.0, beat)
			_pitch("arm_r", lerp(0.15, -1.75, windup))
			_pitch("arm_l", -0.3)
			_pitch("torso", strike * 0.2)
			_pitch("head", windup * -0.25)
			_pitch("tail", sin(clock * 12.0) * 0.3)
			model.position.z = strike * 0.2 - windup * 0.06
		"down":
			model.rotation.x = -PI / 2.0
			model.position.y = 0.16
		_:
			_pitch("head", sin(clock * 2.0) * 0.05)
			_pitch("arm_l", sin(clock * 2.0) * 0.04)
			_pitch("tail", sin(clock * 3.0) * 0.25)

	# Winged characters flap in every state.
	var flap := sin(clock * 12.0) * 0.5
	if parts.has("wing_l"):
		parts["wing_l"].rotation.z += flap
	if parts.has("wing_r"):
		parts["wing_r"].rotation.z -= flap

func _pitch(part_name: String, angle: float) -> void:
	if parts.has(part_name):
		parts[part_name].rotation.x += angle
