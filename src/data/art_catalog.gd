class_name ArtCatalog
extends RefCounted

# Lookups over the generated art manifest (src/data/art_manifest.gd).

const ArtManifestScript = preload("res://src/data/art_manifest.gd")

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
	return packed.instantiate() as Node3D

static func item_model(item_name: String) -> String:
	return str(ArtManifestScript.ITEMS.get(item_name, {}).get("model", ""))

static func item_icon(item_name: String) -> Texture2D:
	var path := str(ArtManifestScript.ITEMS.get(item_name, {}).get("icon", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
