class_name ArtCatalog
extends RefCounted

# Lookups over the generated art manifest (src/data/art_manifest.gd).

const ArtManifestScript = preload("res://src/data/art_manifest.gd")
const Appearance = preload("res://src/data/appearance_catalog.gd")
const MATTE_NAME := "pal_matte"

static var _matte: StandardMaterial3D

static func has_model(model_id: String) -> bool:
	return ArtManifestScript.MODELS.has(model_id)

static func model_ids() -> Array:
	return ArtManifestScript.MODELS.keys()

static func model_info(model_id: String) -> Dictionary:
	return ArtManifestScript.MODELS.get(model_id, {})

static func instantiate(model_id: String) -> Node3D:
	var path := str(model_info(model_id).get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate() as Node3D
	_apply_matte(instance)
	return instance

# Models carry their palette colours per face. Everything except the glow accents is
# drawn with this one shared material, so the whole scene batches on a single material.
static func matte_material() -> StandardMaterial3D:
	if _matte == null:
		_matte = StandardMaterial3D.new()
		_matte.vertex_color_use_as_albedo = true
		_matte.roughness = 0.85
	return _matte

static func _apply_matte(node: Node) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(surface)
			if material != null and material.resource_name == MATTE_NAME:
				mesh_instance.set_surface_override_material(surface, matte_material())
	for child in node.get_children():
		_apply_matte(child)

static func item_model(item_name: String) -> String:
	return str(ArtManifestScript.ITEMS.get(item_name, {}).get("model", ""))

static func item_grip_degrees(item_name: String) -> Vector3:
	var look := Appearance.for_item(item_name)
	return Appearance.LOOKS.get(look, {}).get("grip_degrees", Vector3.ZERO)

static func companion_model(companion_name: String) -> String:
	return str(ArtManifestScript.COMPANIONS.get(companion_name, {}).get("model", ""))

static func companion_icon(companion_name: String) -> Texture2D:
	return _icon(str(ArtManifestScript.COMPANIONS.get(companion_name, {}).get("icon", "")))

static func item_icon(item_name: String) -> Texture2D:
	return _icon(str(ArtManifestScript.ITEMS.get(item_name, {}).get("icon", "")))

static func _icon(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
