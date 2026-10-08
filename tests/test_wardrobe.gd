extends SceneTree

const Sim = preload("res://src/sim/adventurer_sim.gd")
const Game = preload("res://src/game.gd")
const Wardrobe = preload("res://src/state/wardrobe.gd")
const Catalog = preload("res://src/data/appearance_catalog.gd")
const Art = preload("res://src/data/art_catalog.gd")
const Persistence = preload("res://src/state/persistence.gd")
const PATH := "user://wardrobe_test.json"
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
	var sim: Node = Sim.new()
	var game: Node = Game.new()
	root.add_child(sim)
	root.add_child(game)
	sim.add_gear("Wolfskin Hood")
	check(sim.wardrobe.owned.has("wolf_hood"), "first gear acquisition permanently unlocks its appearance")
	sim.wardrobe.wear("wolf_hood")
	check(sim.sell_gear("Wolfskin Hood")["ok"] and sim.gear_count("Wolfskin Hood") == 0, "source gear can be sold normally")
	check(sim.wardrobe.visible_item("head", "") == "Wolfskin Hood", "sold gear's appearance remains wearable")
	sim.add_gear("Wolfskin Hood")
	sim.salvage_gear("Wolfskin Hood")
	check(sim.wardrobe.owned["wolf_hood"]["sources"].size() == 1 and sim.wardrobe.equipped["head"] == "wolf_hood", "reacquisition/salvage neither repeats grants nor loses the chosen look")
	sim.add_gear("Leather Hood")
	sim.equip_gear("Leather Hood")
	var before: Dictionary = sim.to_save_dict()
	before.erase("wardrobe")
	var power := [sim.effective_attack(), sim.effective_max_hp(), sim.effective_attack_interval(), sim.effective_move_speed()]
	sim.wardrobe.clear("head")
	sim.wardrobe.wear("wolf_hood")
	var after: Dictionary = sim.to_save_dict()
	after.erase("wardrobe")
	check(before == after and power == [sim.effective_attack(), sim.effective_max_hp(), sim.effective_attack_interval(), sim.effective_move_speed()], "wearing/removing a look changes no combat field, clock, RNG, reward or functional gear")
	sim.loadouts.save_current(0, "Trail build", sim)
	sim.loadouts.apply(0, sim, game)
	check(sim.wardrobe.equipped.get("head", "") == "wolf_hood", "combat loadouts leave fashion choices intact")
	check(not sim.wardrobe.wear("star_helm") and not sim.wardrobe.wear("unknown"), "locked and unknown looks cannot be equipped")
	var known: Dictionary = sim.wardrobe.owned.duplicate(true)
	sim.wardrobe.merge_ownership({"star_helm": {"sources": ["restore:mock-order"]}, "wolf_hood": {"sources": ["restore:mock-order"]}})
	sim.wardrobe.merge_ownership({"star_helm": {"sources": ["restore:mock-order"]}})
	check(sim.wardrobe.owned.has("star_helm") and sim.wardrobe.owned["wolf_hood"]["sources"].has(known["wolf_hood"]["sources"][0]), "restoration fixtures merge ownership without replacing earned provenance")
	check(sim.wardrobe.owned["star_helm"]["sources"].size() == 1 and sim.wardrobe.equipped["head"] == "wolf_hood", "duplicate restoration is idempotent and preserves the selected outfit")
	var bounded: RefCounted = Wardrobe.new()
	bounded.acquire_item("Wolfskin Hood")
	for index in 40:
		bounded.grant("wolf_hood", "a:restore-%d" % index)
	check(bounded.owned["wolf_hood"]["sources"].size() == 16 and bounded.owned["wolf_hood"]["sources"].has("gear:Wolfskin Hood"), "bounded restoration history cannot evict original earned provenance")
	for entry in Catalog.LOOKS.values():
		check(Art.has_model(Art.item_model(entry["item"])) and Art.item_icon(entry["item"]) != null, "curated appearance has a preview asset: " + entry["name"])
	var loaded: RefCounted = Wardrobe.new()
	loaded.load_save_dict(JSON.parse_string(JSON.stringify(sim.wardrobe.to_save_dict())))
	check(loaded.to_save_dict() == sim.wardrobe.to_save_dict(), "appearance ownership, provenance and selection round-trip through JSON")
	loaded.load_save_dict({"owned": {"wolf_hood": {"sources": ["gear:Wolfskin Hood"]}, "unknown": {"sources": ["made-up"]}}, "equipped": {"weapon": "wolf_hood", "head": "star_helm"}})
	check(loaded.owned.size() == 1 and loaded.equipped.is_empty(), "invalid slots, locked selections and unknown assets fall back to functional gear")
	loaded.load_save_dict({"owned": 7, "equipped": "bad"})
	check(loaded.owned.is_empty() and loaded.equipped.is_empty(), "malformed ownership blocks do not crash")
	var legacy: Dictionary = sim.to_save_dict()
	legacy.erase("wardrobe")
	var migrated: Node = Sim.new()
	root.add_child(migrated)
	migrated.load_save_dict(legacy)
	check(migrated.wardrobe.owned.is_empty() and migrated.wardrobe.equipped.is_empty(), "legacy unsupported gear does not fabricate appearance ownership or selections")
	legacy["gear_inventory"]["Iron Sword"] = 1
	migrated.load_save_dict(legacy)
	check(migrated.wardrobe.owned.has("trail_blade") and migrated.wardrobe.equipped.is_empty(), "legacy held gear safely grants a look without auto-wearing it")
	for file in Persistence.files_for(PATH):
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	game.collection["gear"]["Starforged Helm"] = 1
	check(Persistence.save(sim, game, 1000, PATH), "wardrobe shares the ordinary atomic save")
	Persistence.load_and_advance(migrated, game, 1000, PATH)
	check(migrated.wardrobe.equipped["head"] == "wolf_hood" and migrated.wardrobe.owned.has("star_helm"), "close/reopen retains selected and restored appearances")
	# A pre-wardrobe save with permanent collection evidence, but no held item.
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	payload["version"] = 16
	payload["sim"].erase("wardrobe")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()
	Persistence.load_and_advance(migrated, game, 1000, PATH)
	check(migrated.wardrobe.owned.has("star_helm") and migrated.gear_count("Starforged Helm") == 0, "legacy permanent collection evidence restores a sold look without granting combat gear")
	var normal: Node = Sim.new()
	var styled: Node = Sim.new()
	root.add_child(normal)
	root.add_child(styled)
	normal.load_save_dict(sim.to_save_dict())
	styled.load_save_dict(sim.to_save_dict())
	styled.wardrobe.wear("star_helm")
	normal.simulate_elapsed(600.0)
	styled.simulate_offline(600.0)
	var normal_save: Dictionary = normal.to_save_dict()
	var styled_save: Dictionary = styled.to_save_dict()
	normal_save.erase("wardrobe")
	styled_save.erase("wardrobe")
	check(normal_save == styled_save, "different appearances preserve full watched/offline outcomes")
	for node in [sim, game, migrated, normal, styled]:
		node.free()
	for path in Persistence.files_for(PATH):
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Wardrobe tests complete: %d failure(s)" % failures)
	quit(failures)
