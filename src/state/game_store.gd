class_name BrambleGameStore
extends RefCounted

const Simulator = preload("res://src/sim/expedition_simulator.gd")
const SaveRepository = preload("res://src/persistence/save_repository.gd")
const GameClock = preload("res://src/state/game_clock.gd")

const SCHEMA_VERSION := 1
const HISTORY_LIMIT := 10

var content
var simulator
var save_repository
var clock
var state: Dictionary
var debug_offset_seconds := 0


func _init(content_repository, repository = null, injected_clock = null) -> void:
	content = content_repository
	simulator = Simulator.new()
	save_repository = repository if repository != null else SaveRepository.new()
	clock = injected_clock if injected_clock != null else GameClock.new()
	state = _default_state()
	_load_state()


func _default_state() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"adventurer": simulator.create_new_adventurer(""),
		"history": [],
		"active_expedition": null,
		"pending_report": null,
		"next_seed": 1,
		"last_saved_at": 0
	}


func _load_state() -> void:
	var loaded: Dictionary = save_repository.load_state()
	if loaded.is_empty() or int(loaded.get("schema_version", 0)) != SCHEMA_VERSION:
		state = _default_state()
		return
	if not loaded.get("adventurer", {}) is Dictionary:
		state = _default_state()
		return
	state = loaded
	_normalize_state()


func _normalize_state() -> void:
	if not state.has("history") or not state.history is Array:
		state.history = []
	if not state.has("active_expedition"):
		state.active_expedition = null
	if not state.has("pending_report"):
		state.pending_report = null
	if not state.has("next_seed"):
		state.next_seed = 1
	var adventurer: Dictionary = state.adventurer
	if not adventurer.has("equipment") or not adventurer.equipment is Dictionary:
		adventurer.equipment = simulator.create_new_adventurer(adventurer.get("name", "")).equipment
	if not adventurer.has("inventory") or not adventurer.inventory is Array:
		adventurer.inventory = []
	if not adventurer.has("gold"):
		adventurer.gold = 0
	if not adventurer.has("xp"):
		adventurer.xp = 0
	if not adventurer.has("level"):
		adventurer.level = simulator.level_for_xp(int(adventurer.xp))


func is_new_game() -> bool:
	return str(state.adventurer.get("name", "")).strip_edges().is_empty()


func get_adventurer() -> Dictionary:
	return state.adventurer


func get_active_expedition() -> Dictionary:
	return state.active_expedition if state.active_expedition is Dictionary else {}


func get_pending_report() -> Dictionary:
	return state.pending_report if state.pending_report is Dictionary else {}


func get_history() -> Array:
	return state.history


func get_current_stats() -> Dictionary:
	return simulator.calculate_stats(state.adventurer, content)


func get_item(item_id: String) -> Dictionary:
	return content.get_item(item_id)


func get_route(route_id: String) -> Dictionary:
	return content.get_route(route_id)


func get_routes() -> Array:
	return content.all_routes()


func create_adventurer(adventurer_name: String) -> bool:
	var clean_name := adventurer_name.strip_edges()
	if clean_name.is_empty():
		return false
	state = _default_state()
	state.adventurer = simulator.create_new_adventurer(clean_name)
	debug_offset_seconds = 0
	_save()
	return true


func start_expedition(route_id: String) -> bool:
	if is_new_game() or state.active_expedition != null or state.pending_report != null:
		return false
	if content.get_route(route_id).is_empty():
		return false
	# Debug time belongs to the previous expedition; a new departure starts from
	# the real clock so repeated test loops do not accumulate an invisible offset.
	debug_offset_seconds = 0
	var seed := int(state.get("next_seed", 1))
	state.next_seed = seed + 1
	state.active_expedition = simulator.create_expedition(
		state.adventurer, route_id, current_time(), seed, content
	)
	_save()
	return true


func refresh() -> bool:
	if state.active_expedition == null or state.pending_report != null:
		return false
	var result: Dictionary = simulator.resolve_expedition(
		state.active_expedition, current_time(), content
	)
	if not bool(result.get("ready", false)):
		return false
	var report: Dictionary = result.get("report", {})
	_apply_report(report)
	state.pending_report = report
	state.active_expedition = null
	_save()
	return true


func claim_report() -> void:
	if state.pending_report == null:
		return
	state.pending_report = null
	_save()


func equip_item(item_id: String) -> bool:
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty():
		return false
	var inventory: Array = state.adventurer.inventory
	var inventory_index := inventory.find(item_id)
	if inventory_index < 0:
		return false
	var slot := str(item.get("slot", ""))
	if slot.is_empty():
		return false
	var old_item_id := str(state.adventurer.equipment.get(slot, ""))
	inventory.remove_at(inventory_index)
	state.adventurer.equipment[slot] = item_id
	if not old_item_id.is_empty() and old_item_id != item_id:
		inventory.append(old_item_id)
	_save()
	return true


func sell_item(item_id: String) -> bool:
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty():
		return false
	var inventory: Array = state.adventurer.inventory
	var inventory_index := inventory.find(item_id)
	if inventory_index < 0:
		return false
	inventory.remove_at(inventory_index)
	state.adventurer.gold = int(state.adventurer.gold) + int(item.get("sell_value", 0))
	_save()
	return true


func inventory_count(item_id: String) -> int:
	var count := 0
	for candidate in state.adventurer.inventory:
		if str(candidate) == item_id:
			count += 1
	return count


func is_equipped(item_id: String) -> bool:
	for equipped_id in state.adventurer.equipment.values():
		if str(equipped_id) == item_id:
			return true
	return false


func preview_route(route_id: String) -> Dictionary:
	return simulator.preview_route(state.adventurer, route_id, content)


func current_time() -> int:
	return int(clock.now()) + debug_offset_seconds


func advance_debug_time(seconds: int) -> void:
	debug_offset_seconds += max(0, seconds)
	refresh()


func active_elapsed_seconds() -> int:
	if state.active_expedition == null:
		return 0
	return max(0, current_time() - int(state.active_expedition.get("started_at", current_time())))


func active_remaining_seconds() -> int:
	if state.active_expedition == null:
		return 0
	return max(
		0, int(state.active_expedition.get("planned_duration", 0)) - active_elapsed_seconds()
	)


func reset_prototype() -> void:
	state = _default_state()
	debug_offset_seconds = 0
	_save()


func _apply_report(report: Dictionary) -> void:
	var adventurer: Dictionary = state.adventurer
	adventurer.xp = int(adventurer.xp) + int(report.get("xp_gained", 0))
	adventurer.gold = int(adventurer.gold) + int(report.get("gold_gained", 0))
	adventurer.level = int(report.get("new_level", adventurer.level))
	for item_entry in report.get("items", []):
		var item_id := str(item_entry.get("item_id", ""))
		if not item_id.is_empty():
			adventurer.inventory.append(item_id)
	for event in report.get("events", []):
		if str(event.get("importance", "minor")) == "major":
			state.history.append(
				{
					"kind": str(event.get("kind", "event")),
					"tone": str(event.get("tone", "neutral")),
					"text": str(event.get("text", "Something happened.")),
					"timestamp": current_time()
				}
			)
	while state.history.size() > HISTORY_LIMIT:
		state.history.pop_front()


func _save() -> void:
	state.last_saved_at = current_time()
	if not save_repository.save_state(state):
		push_error("The current game state could not be saved.")
