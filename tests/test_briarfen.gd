extends SceneTree

const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")

var failures: int = 0
var saw_briarfen: bool = false
var saw_thornback: bool = false
var saw_briarfen_complete: bool = false

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _on_event(event: Dictionary) -> void:
	if str(event.get("type", "")) == "travel_started" and str(event.get("destination", "")) == "briarfen":
		saw_briarfen = true
	if str(event.get("type", "")) == "fight_started" and str(event.get("enemy", "")) == "thornback":
		saw_thornback = true
	if str(event.get("type", "")) == "quest_completed" and str(event.get("quest", "")) == "briarfen":
		saw_briarfen_complete = true

func _run() -> void:
	var sim: Node = AdventurerSimScript.new()
	sim.event_emitted.connect(_on_event)
	root.add_child(sim)

	var elapsed := 0.0
	while sim.quest_cycles_completed < 2 and elapsed < 300.0:
		sim.advance(0.1)
		elapsed += 0.1

	_check(sim.quest_cycles_completed >= 2, "second progression quest completes autonomously")
	_check(saw_briarfen, "adventurer travels into the new Briarfen zone")
	_check(sim.briarlings_killed == 4, "Briarfen quest clears four Briarlings")
	_check(saw_thornback, "Briarfen quest reaches named boss Old Thornback")
	_check(sim.thornback_killed, "Old Thornback is defeated")
	_check(saw_briarfen_complete, "Briarfen quest completion is emitted distinctly")
	_check(int(sim.gear_inventory.get("Briarheart Charm", 0)) == 1, "Old Thornback guarantees the world-only Briarheart Charm")
	_check(int(sim.inventory.get("Thornback Tusk", 0)) >= 1, "named boss leaves a readable trophy")
	_check(sim.hero_position.distance_to(sim.TOWN_POSITION) < 0.01, "Briarfen quest finishes back at Mossgate")

	var saved: Dictionary = sim.to_save_dict()
	var restored: Node = AdventurerSimScript.new()
	root.add_child(restored)
	restored.load_save_dict(saved)
	_check(restored.quest_kind == sim.quest_kind, "expanded quest state survives save/load")
	_check(restored.gear_inventory == sim.gear_inventory, "Briarfen boss reward survives save/load")

	print("Briarfen tests complete: %d failure(s)" % failures)
	quit(failures)
