extends Node3D

# A character model from the art build, animated by swinging its parts.
# Presentation only: it shows a state the simulation already decided.

const ArtCatalogScript = preload("res://src/data/art_catalog.gd")

const PART_NAMES := [
	"torso", "body", "head", "tail",
	"arm_l", "arm_r", "leg_l", "leg_r",
	"leg_fl", "leg_fr", "leg_bl", "leg_br"
]
const SLOT_ATTACH := {
	"weapon": "attach_hand_r",
	"offhand": "attach_hand_l",
	"head": "attach_head",
	"chest": "attach_chest"
}

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

func set_state(next_state: String) -> void:
	if next_state != state:
		state = next_state
		clock = 0.0

func face(direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length() > 0.001:
		rotation.y = atan2(direction.x, direction.z)

func attach_point(slot: String) -> Node3D:
	if model == null:
		return null
	return model.find_child(str(SLOT_ATTACH.get(slot, "")), true, false) as Node3D

func set_equipment(slot: String, item_name: String) -> void:
	if str(worn_names.get(slot, "")) == item_name:
		return
	worn_names[slot] = item_name
	if worn.has(slot):
		worn[slot].queue_free()
		worn.erase(slot)

	var point := attach_point(slot)
	var item := ArtCatalogScript.instantiate(ArtCatalogScript.item_model(item_name))
	if point == null or item == null:
		return
	point.add_child(item)
	worn[slot] = item

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

func _pitch(part_name: String, angle: float) -> void:
	if parts.has(part_name):
		parts[part_name].rotation.x += angle
