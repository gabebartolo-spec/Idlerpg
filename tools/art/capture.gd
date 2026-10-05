extends SceneTree

# In-engine art review: runs the real main scene and saves screenshots of the
# adventurer walking and fighting each enemy in a different gear set, each with a
# close-up of the worn gear.
# Needs a window, so run it without --headless:
#   godot --path . -s res://tools/art/capture.gd
# Writes art/review/ingame_*.png. Uses a throwaway save, never the player's.

const SAVE_PATH := "user://idle_rpg_save.json"
const BACKUP_PATH := "user://idle_rpg_save.capture_backup.json"
const LOADOUTS := [
	["Iron Sword", "Rough Trousers", "Hide Gloves", "Trail Boots", "Copper Ring"],
	["Crownblade", "Titanheart Plate", "Starforged Helm", "Oak Buckler", "Steel Greaves", "Knight Gauntlets", "Worldwalker Boots", "Phoenix Sigil"],
	["Ember Staff", "Wyrmhide Coat", "Leather Hood", "Dragon Legguards", "Rune Grips", "Shadow Treads", "Sapphire Charm"]
]

var main: Node
var shot: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var user_dir := DirAccess.open("user://")
	var had_save := FileAccess.file_exists(SAVE_PATH)
	if had_save:
		user_dir.rename(SAVE_PATH, BACKUP_PATH)

	main = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame

	var sim: Node = main.get("sim")
	_equip(sim, LOADOUTS[0])
	await _snap("walk")
	await _closeup("walk_gear")
	await _until(sim, "goblin")
	_equip(sim, LOADOUTS[1])
	await _snap("goblin_fight")
	await _closeup("goblin_fight_gear")
	await _until(sim, "wolf")
	_equip(sim, LOADOUTS[2])
	await _snap("wolf_fight")
	await _closeup("wolf_fight_gear")

	main.free()
	if FileAccess.file_exists(SAVE_PATH):
		user_dir.remove(SAVE_PATH)
	if had_save:
		user_dir.rename(BACKUP_PATH, SAVE_PATH)
	quit()

func _equip(sim: Node, items: Array) -> void:
	for item_name in items:
		sim.add_gear(item_name)
		sim.equip_gear(item_name)

func _until(sim: Node, enemy_kind: String) -> void:
	# Fast-forward the simulation, then let the camera and poses settle.
	var guard := 0
	while not (sim.activity == "fighting" and sim.enemy_kind == enemy_kind) and guard < 20000:
		sim.advance(0.1)
		guard += 1

func _closeup(label: String) -> void:
	# Hold the scene still and bring the camera in on the adventurer.
	var camera: Camera3D = main.get("camera")
	var hero: Node3D = main.get("hero_visual")
	var home := camera.global_transform
	main.set_process(false)
	hero.set_state("idle")
	# Come in along the game camera's own line of sight, which the zones keep clear.
	hero.rotation.y = atan2(7.0, 8.0) - 0.5
	camera.position = hero.position + Vector3(2.1, 1.5, 2.4)
	camera.look_at(hero.position + Vector3(0.0, 0.85, 0.0), Vector3.UP)
	await _snap(label)
	camera.global_transform = home
	main.set_process(true)

func _snap(label: String) -> void:
	for frame in 45:
		await process_frame
	shot += 1
	var path := "res://art/review/ingame_%d_%s.png" % [shot, label]
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("Saved ", path)
