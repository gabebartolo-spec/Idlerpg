extends SceneTree
const Sim = preload("res://src/sim/adventurer_sim.gd")
const Chest = preload("res://src/state/reward_chests.gd")
var failures := 0
func _init() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		failures += 1
		push_error(message)
func _run() -> void:
	var sim := Sim.new()
	root.add_child(sim)
	sim.reward_chests.issue(1, "hollow", 80, "lantern_crook")
	check(not sim.reward_chests.issue(1, "hollow", 80, "lantern_crook"), "completion replay cannot issue another chest")
	sim.reward_chests.issue(2, "hollow", 25, "lantern_crook")
	check(sim.reward_chests.pending[1]["look"] == "", "an unopened earned look is not promised twice")
	var restored := Sim.new()
	root.add_child(restored)
	restored.load_save_dict(JSON.parse_string(JSON.stringify(sim.to_save_dict())))
	check(restored.reward_chests.to_save_dict() == sim.reward_chests.to_save_dict(), "fixed unopened contents survive reload without rerolling")
	var claims: Array[Dictionary] = []
	restored.event_emitted.connect(func(event: Dictionary) -> void:
		if event["type"] == "chest_opened": claims.append(restored.to_save_dict()))
	var receipt: Dictionary = restored.claim_reward_chest("trail:1")
	check(receipt["gold"] == 80 and restored.gold == 80 and restored.wardrobe.owned.has("lantern_crook"), "open pays gold and permanent appearance together")
	check(restored.claim_reward_chest("trail:1").is_empty() and restored.gold == 80, "repeated open cannot duplicate gold or ownership")
	check(claims.size() == 1 and claims[0]["gold"] == 80 and claims[0]["reward_chests"]["pending"].size() == 1, "event-time checkpoint sees claim removed and rewards already delivered")
	var loaded := Chest.new()
	loaded.load_save_dict(JSON.parse_string(JSON.stringify(restored.reward_chests.to_save_dict())))
	check(loaded.take("trail:1").is_empty() and loaded.take("trail:2")["gold"] == 25, "claimed and unopened receipts retain distinct state after reload")
	loaded.load_save_dict(["invalid"])
	check(loaded.pending.is_empty(), "malformed optional inbox defaults safely")
	loaded.load_save_dict({"pending": "invalid", "last_opened": {}})
	check(loaded.pending.is_empty(), "malformed receipt list cannot crash save loading")
	var legacy: Dictionary = sim.to_save_dict()
	legacy.erase("reward_chests")
	legacy["gold"] = 123
	restored.load_save_dict(legacy)
	check(restored.gold == 123 and restored.reward_chests.pending.is_empty(), "old saves keep banked progress and do not fabricate retroactive chests")
	var screen := preload("res://src/ui/reward_screen.gd").new()
	root.add_child(screen)
	var prefs := preload("res://src/state/presentation_preferences.gd").new()
	prefs.reduced_motion = true
	prefs.larger_text = OS.get_cmdline_user_args().has("--large-text")
	var presentation := preload("res://src/ui/presentation_controller.gd").new()
	root.add_child(presentation)
	presentation.setup(prefs, root)
	screen.setup(sim, prefs)
	screen.open()
	await process_frame
	await process_frame
	check(screen.action_button.get_global_rect().end.y <= root.get_visible_rect().size.y, "chest action stays inside the portrait screen")
	check(screen.action_button.text == "Open chest" and not screen.wear_button.visible, "unopened reward offers one clear action")
	screen.action_button.pressed.emit()
	await process_frame
	check(screen.chest.opened and screen.chest.progress == 1 and screen.wear_button.visible, "opening reveals usable contents with instant reduced-motion presentation")
	check(screen.chest.reward_texture != null, "settled appearance is shown emerging from the opened chest")
	await process_frame
	check(screen.wear_button.get_global_rect().end.y <= root.get_visible_rect().size.y, "wear action remains reachable after the reveal")
	screen.wear_button.pressed.emit()
	check(sim.wardrobe.equipped.get("weapon", "") == "lantern_crook", "earned look can be worn directly from the reveal")
	screen.action_button.pressed.emit()
	check(screen.viewing.is_empty() and screen.action_button.text == "Open chest", "next chest requires a separate deliberate opening")
	check(screen.chest.reward_texture == null, "next unopened chest cannot retain the previous reward illustration")
	var returned := preload("res://src/ui/return_screen.gd").new()
	root.add_child(returned)
	returned.setup()
	returned.show_report({"chests_ready": 1}, "Away · 15 min")
	check(returned.list.content.get_child(0).text == "Open 1 earned chest", "return report routes directly to secured rewards")
	returned.free()
	screen.free()
	sim.free()
	restored.free()
	await process_frame
	print("Reward chest tests complete: %d failure(s)" % failures)
	quit(failures)
