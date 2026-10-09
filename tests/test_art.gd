extends SceneTree

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const ArtCatalogScript = preload("res://src/data/art_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")
const CharacterVisualScript = preload("res://src/view/character_visual.gd")

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	_check(not ArtCatalogScript.imported_pilot_enabled, "legendary import pilot is off in normal sessions")
	var procedural: Dictionary = preload("res://src/data/art_manifest.gd").MODELS
	for model_id in ["crownblade", "starforged_helm", "titanheart_plate"]:
		_check(ArtCatalogScript.model_info(model_id) == procedural[model_id], "%s retains its procedural default" % model_id)
	ArtCatalogScript.imported_pilot_enabled = true
	for item_name in ["Crownblade", "Starforged Helm", "Titanheart Plate"]:
		var model_id := ArtCatalogScript.item_model(item_name)
		var instance := ArtCatalogScript.instantiate(model_id)
		_check(instance != null and ArtCatalogScript.item_icon(item_name) != null, "%s pilot or fallback loads with matching icon" % item_name)
		var imported: Dictionary = preload("res://src/data/imported_art_manifest.gd").MODELS
		if imported.has(model_id):
			_check(ArtCatalogScript.model_info(model_id)["path"] == imported[model_id]["path"], "%s selects the actual imported GLB during review" % item_name)
			var textured: bool = false
			if instance != null:
				for mesh in instance.find_children("*", "MeshInstance3D", true, false):
					var material = mesh.get_active_material(0)
					if material is StandardMaterial3D and material.albedo_texture != null:
						textured = true
			_check(textured, "%s preserves its imported colour texture" % item_name)
		if instance != null: instance.free()
	ArtCatalogScript.imported_pilot_enabled = false
	var missing_models: Array[String] = []
	for model_id in ArtCatalogScript.model_ids():
		var instance := ArtCatalogScript.instantiate(model_id)
		if instance == null:
			missing_models.append(model_id)
			continue
		for node_name in ArtCatalogScript.model_info(model_id).get("nodes", []):
			if instance.find_child(node_name, true, false) == null:
				missing_models.append("%s/%s" % [model_id, node_name])
		instance.free()
	_check(missing_models.is_empty(), "every manifest model loads with its parts %s" % str(missing_models))

	var missing_gear: Array[String] = []
	for item_name in GearCatalogScript.ITEMS:
		if not ArtCatalogScript.has_model(ArtCatalogScript.item_model(item_name)) or ArtCatalogScript.item_icon(item_name) == null:
			missing_gear.append(item_name)
	_check(missing_gear.is_empty(), "every gear item has a model and an icon %s" % str(missing_gear))

	var missing_companions: Array[String] = []
	for companion_name in CompanionCatalogScript.COMPANIONS:
		var companion: Node3D = CharacterVisualScript.new()
		if not companion.setup(ArtCatalogScript.companion_model(companion_name)) or ArtCatalogScript.companion_icon(companion_name) == null:
			missing_companions.append(companion_name)
		companion.free()
	_check(missing_companions.is_empty(), "every companion has an animatable model and an icon %s" % str(missing_companions))

	for model_id in ["hero", "goblin", "wolf", "briarling", "thornback", "lantern_moth", "root_keeper"]:
		var character: Node3D = CharacterVisualScript.new()
		root.add_child(character)
		_check(character.setup(model_id), "%s character builds from its model" % model_id)
		_check(character.parts.has("head"), "%s has animatable parts" % model_id)
		if model_id == "hero":
			for slot in ["weapon", "offhand", "head", "chest", "legs", "hands", "feet", "accessory"]:
				_check(character.attach_point(slot) != null, "hero has a %s attach point" % slot)
			character.set_equipment("weapon", "Iron Sword")
			_check(character.worn.has("weapon"), "equipping a weapon shows its model in the hand")
			character.set_equipment("feet", "Trail Boots")
			_check(character.worn.get("feet", []).size() == 2, "paired gear shows on both sides")
			character.set_equipment("weapon", "")
			_check(not character.worn.has("weapon"), "unequipping removes the model")
		character.free()

	print("Art tests complete: %d failure(s)" % failures)
	quit(failures)
