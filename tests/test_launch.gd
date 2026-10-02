extends SceneTree

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
	var packed: PackedScene = load("res://main.tscn")
	_check(packed != null, "main scene loads")
	if packed == null:
		quit(failures)
		return

	var instance: Node = packed.instantiate()
	_check(instance != null, "main scene instantiates")
	if instance == null:
		quit(failures)
		return

	root.add_child(instance)
	await process_frame
	await process_frame

	_check(instance.get("sim") != null, "main scene creates the adventurer simulation")
	_check(instance.get("hero_visual") != null, "main scene creates the watched 3D adventurer")
	_check(instance.get("activity_label") != null, "main scene creates current-activity UI")

	var sim: Node = instance.get("sim")
	if sim != null:
		_check(sim.activity in ["travelling", "fighting", "looting", "returning", "resting", "recovering"], "simulation is actively doing something")

	instance.queue_free()
	await process_frame

	print("Launch smoke tests complete: %d failure(s)" % failures)
	quit(failures)
