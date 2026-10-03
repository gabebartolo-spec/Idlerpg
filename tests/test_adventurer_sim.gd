extends SceneTree

const AdventurerSimScript = preload("res://src/sim/adventurer_sim.gd")

var failures: int = 0
var seen_events: Dictionary = {}
var seen_enemies: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _on_event(event: Dictionary) -> void:
	var type: String = str(event.get("type", ""))
	seen_events[type] = int(seen_events.get(type, 0)) + 1
	if type == "fight_started":
		var enemy: String = str(event.get("enemy", ""))
		seen_enemies[enemy] = int(seen_enemies.get(enemy, 0)) + 1

func _run() -> void:
	var sim: Node = AdventurerSimScript.new()
	sim.event_emitted.connect(_on_event)
	root.add_child(sim)

	_check(sim.activity == "travelling", "adventurer starts by travelling to the quest")
	_check(sim.current_quest_text().contains("Goblins"), "first quest objective is readable")

	var elapsed: float = 0.0
	while sim.quest_cycles_completed < 1 and elapsed < 180.0:
		sim.advance(0.1)
		elapsed += 0.1

	_check(sim.quest_cycles_completed == 1, "adventurer completes the quest chain autonomously")
	_check(sim.goblins_killed == 3, "quest defeats three goblins")
	_check(sim.wolves_killed == 2, "quest defeats two wolves")
	_check(int(seen_enemies.get("goblin", 0)) == 3, "three goblin encounters were authoritative")
	_check(int(seen_enemies.get("wolf", 0)) == 2, "two wolf encounters were authoritative")
	_check(seen_events.has("travel_started"), "simulation emits travel events")
	_check(seen_events.has("enemy_defeated"), "simulation emits combat-result events")
	_check(seen_events.has("quest_completed"), "simulation emits quest completion")
	_check(sim.gold >= 20, "quest grants gold")
	_check(sim.hero_level >= 2, "combat and quest XP can level the adventurer")
	_check(int(sim.inventory.get("Goblin Trinket", 0)) == 3, "goblin loot is recorded")
	_check(int(sim.inventory.get("Wolf Pelt", 0)) == 2, "wolf loot is recorded")
	_check(sim.hero_position.distance_to(sim.TOWN_POSITION) < 0.01, "quest finishes back in town")

	var death_sim: Node = AdventurerSimScript.new()
	root.add_child(death_sim)
	death_sim.take_damage(999)
	_check(death_sim.activity == "recovering", "lethal damage enters recovery instead of deleting the character")
	_check(death_sim.deaths == 1, "death is recorded")

	var recovery_elapsed: float = 0.0
	while death_sim.activity == "recovering" and recovery_elapsed < 10.0:
		death_sim.advance(0.1)
		recovery_elapsed += 0.1

	_check(death_sim.activity != "recovering", "adventurer resumes the quest after recovery")
	_check(death_sim.hero_hp == death_sim.hero_max_hp, "recovery restores health")

	print("Adventurer simulation tests complete: %d failure(s)" % failures)
	quit(failures)
