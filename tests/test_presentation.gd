extends SceneTree

const Preferences = preload("res://src/state/presentation_preferences.gd")
const Controller = preload("res://src/ui/presentation_controller.gd")
const Style = preload("res://src/ui/ui_style.gd")
const TouchList = preload("res://src/ui/touch_list.gd")
const Character = preload("res://src/view/character_visual.gd")
const Game = preload("res://src/game.gd")
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Persistence = preload("res://src/state/persistence.gd")
const PATH := "user://presentation_test.json"
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var game: Node = Game.new()
	var sim: Node = Sim.new()
	root.add_child(game)
	root.add_child(sim)
	var before: Dictionary = sim.to_save_dict()
	game.presentation.larger_text = true
	game.presentation.reduced_motion = true
	check(sim.to_save_dict() == before, "comfort preferences do not change combat, clocks, rewards or RNG")
	for file in Persistence.files_for(PATH):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	check(Persistence.save(sim, game, 1000, PATH), "comfort preferences save with the adventurer")
	var restored: Node = Game.new()
	var restored_sim: Node = Sim.new()
	root.add_child(restored)
	root.add_child(restored_sim)
	Persistence.load_and_advance(restored_sim, restored, 1000, PATH)
	check(restored.presentation.to_save_dict() == game.presentation.to_save_dict(), "both preferences survive close/reopen")
	var legacy: Dictionary = game.to_save_dict()
	legacy.erase("presentation")
	restored.load_save_dict(legacy)
	check(not restored.presentation.larger_text and not restored.presentation.reduced_motion, "legacy saves migrate to ordinary text and motion")
	var preferences: RefCounted = Preferences.new()
	preferences.load_save_dict({"larger_text": "yes", "reduced_motion": 7, "unknown": true})
	check(not preferences.larger_text and not preferences.reduced_motion, "malformed preference types cannot enable settings")
	preferences.load_save_dict("not a dictionary")
	check(preferences.to_save_dict() == {"larger_text": false, "reduced_motion": false}, "invalid preference blocks retain safe defaults")
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var body: Label = Style.label("Open counters, bigger letters", 24)
	var heading: Label = Style.label("Options", 32)
	canvas.add_child(body)
	canvas.add_child(heading)
	var list: Control = TouchList.new()
	canvas.add_child(list)
	var controller: Node = Controller.new()
	root.add_child(controller)
	controller.setup(preferences, canvas)
	preferences.larger_text = true
	preferences.reduced_motion = true
	controller.apply()
	check(body.get_theme_font_size("font_size") == 28 and heading.get_theme_font_size("font_size") == 32, "larger reading text preserves header space")
	controller.apply()
	check(body.get_theme_font_size("font_size") == 28, "refreshing preferences never compounds font growth")
	var later: Label = Style.label("Newly found trail", 24)
	canvas.add_child(later)
	var transient: Label = Style.label("A row rebuilt immediately", 24)
	canvas.add_child(transient)
	transient.free()
	await process_frame
	check(later.get_theme_font_size("font_size") == 28, "rebuilt rows inherit the saved larger text setting")
	check(list.reduced_motion, "existing scroll lists receive reduced motion")
	list.velocity = 500.0
	list.set_reduced_motion(true)
	check(list.velocity == 0.0, "enabling reduced motion stops an existing flick")
	preferences.larger_text = false
	preferences.reduced_motion = false
	controller.apply()
	check(body.get_theme_font_size("font_size") == 24 and later.get_theme_font_size("font_size") == 24 and not list.reduced_motion, "turning options off restores original sizes and scrolling")
	var character: Node3D = Character.new()
	root.add_child(character)
	character.setup("hero")
	character.set_process(false)
	character.set_state("walk")
	character._process(0.1)
	check(character.model.position.y > 0.0, "ordinary watching keeps its walk animation")
	character.reduced_motion = true
	character._process(0.1)
	var still: bool = character.model.position == Vector3.ZERO
	for part in character.parts:
		still = still and character.parts[part].rotation == character.rest[part]
	check(still, "reduced motion resets bobbing and limb swings")
	character.set_state("down")
	character._process(0.1)
	check(is_equal_approx(character.model.rotation.x, -PI / 2.0), "resolved defeat remains visible with reduced motion")
	character.reduced_motion = false
	character.set_state("walk")
	character._process(0.1)
	check(character.model.position.y > 0.0, "ordinary animation resumes when the option is disabled")
	character.free()
	canvas.free()
	controller.free()
	game.free()
	sim.free()
	restored.free()
	restored_sim.free()
	for file in Persistence.files_for(PATH):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Presentation tests complete: %d failure(s)" % failures)
	quit(failures)
