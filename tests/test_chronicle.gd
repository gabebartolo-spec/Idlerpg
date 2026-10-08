extends SceneTree

const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Persistence = preload("res://src/state/persistence.gd")
const Chronicle = preload("res://src/state/chronicle.gd")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func pair() -> Array:
	var sim := Sim.new()
	var game := Game.new()
	root.add_child(sim)
	root.add_child(game)
	return [sim, game]

func _run() -> void:
	var original := pair()
	var sim: Node = original[0]
	sim.drop_seed = 123
	sim.set_active_companion("Stable Hound")
	var initial: Dictionary = sim.to_save_dict()
	sim.simulate_elapsed(7200.0)
	check(sim.chronicle.seen.has("first_kill"), "a real first kill is remembered")
	check(sim.chronicle.events.size() > 1, "adventure produces meaningful milestones")
	check(sim.chronicle.seen.has("bond:Stable Hound:2"), "companion bond growth records a real milestone")
	var offline: Node = pair()[0]
	offline.load_save_dict(initial)
	offline.simulate_offline(7200.0)
	check(offline.to_save_dict() == sim.to_save_dict(), "watched and offline milestones and progression match")
	var saved: Dictionary = sim.to_save_dict()
	var restored: Node = pair()[0]
	restored.load_save_dict(saved)
	check(restored.chronicle.to_save_dict() == sim.chronicle.to_save_dict(), "history and stable IDs survive reload")
	var mark: int = restored.chronicle.sequence
	restored.add_gear("Crownblade")
	check(restored.chronicle.sequence == mark + 1, "useful gear creates a milestone")
	restored.add_gear("Crownblade")
	check(restored.chronicle.sequence == mark + 1, "duplicate gear cannot replay a milestone")
	restored.equip_gear("Crownblade")
	restored.add_gear("Iron Sword")
	check(restored.chronicle.sequence == mark + 1, "inferior gear is not described as a useful upgrade")
	restored.enemy_kind = "thornback"
	restored.enemy_max_hp = 100
	restored.enemy_hp = 10
	restored._die()
	check(restored.chronicle.seen.has("close:thornback"), "a real close defeat records remaining enemy health")
	var boss: Node = pair()[0]
	boss.hero_level = 10
	boss._start_fight("thornback")
	boss.enemy_hp = 1
	boss._defeat_enemy()
	check(boss.chronicle.seen.has("first_boss"), "a boss victory records its first-win milestone")
	boss._start_fight("thornback")
	boss.enemy_hp = boss.enemy_max_hp
	boss._die()
	check(not boss.chronicle.seen.has("close:thornback"), "a decisive loss cannot fabricate a close defeat")
	var old: Dictionary = saved.duplicate(true)
	old.erase("chronicle")
	var migrated: Node = pair()[0]
	migrated.load_save_dict(old)
	check(migrated.chronicle.events.is_empty() and migrated.chronicle.seen.has("first_kill"), "legacy progress seeds deduplication without fabricated history")
	var memory := Chronicle.new()
	for i in 100:
		memory.remember(str(i), "Milestone", "chronicle", "", i, 1, 0)
	check(memory.events.size() == Chronicle.LIMIT, "long histories are bounded")
	memory.remember("0", "Again", "chronicle", "", 1000, 1, 0)
	check(memory.sequence == 100, "evicted events cannot replay")
	var highlights: Array = memory.highlights_since(0)
	check(highlights.size() == 3 and highlights[0]["id"] == "99", "return selects three highest priority actual events")
	check(memory.highlights_since(memory.sequence).is_empty(), "a no-event return has no invented highlights")
	var path := "user://test_chronicle_return.json"
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var fresh := pair()
	fresh[0].drop_seed = 123
	check(Persistence.save(fresh[0], fresh[1], 1000, path), "chronicle start checkpoints")
	var returned := pair()
	var report: Dictionary = Persistence.load_and_advance(returned[0], returned[1], 605800, path)
	check(report["highlights"].size() > 0 and report["highlights"].size() <= 3, "seven-day return selects highlights")
	check(report["kills"] == returned[0].total_kills, "highlight selection preserves aggregate totals")
	var returned_again := pair()
	var again: Dictionary = Persistence.load_and_advance(returned_again[0], returned_again[1], 605800, path)
	check(again["highlights"].is_empty() and again["kills"] == 0 and again["gear"].is_empty(), "reopening cannot repeat highlights or rewards")
	check(returned_again[0].chronicle.to_save_dict() == returned[0].chronicle.to_save_dict(), "offline highlights remain browsable after reload")
	for file in Persistence.files_for(path):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	print("Chronicle tests complete: %d failure(s)" % failures)
	quit(failures)
