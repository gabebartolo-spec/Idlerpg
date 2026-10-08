extends "res://src/ui/sheet.gd"
signal changed
const Catalog = preload("res://src/data/practice_catalog.gd")
var sim: Node
var tabs: Dictionary
var status: Label
var list: Control
var start_button: Button
var stop_button: Button
var content_key: String = ""

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Practice dungeon", 0.22)
	status = Style.label("", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	tabs = add_tabs(column, [["damage", "Damage"], ["protection", "Protect"], ["support", "Support"]], func(id: String) -> void:
		sim.practice.selected_role = id
		refresh()
		changed.emit())
	list = add_list(column)
	start_button = Style.button("Practice after this outing", true)
	start_button.pressed.connect(func() -> void:
		if sim.request_practice(sim.practice.selected_role):
			refresh()
			changed.emit())
	column.add_child(start_button)
	stop_button = Style.button("Cancel / leave practice")
	stop_button.pressed.connect(func() -> void:
		sim.stop_practice()
		refresh()
		changed.emit())
	column.add_child(stop_button)
	refresh()

func _process(_delta: float) -> void:
	if visible and sim != null:
		refresh()

func paragraph(text: String, color: Color = Style.TEXT) -> void:
	var words := Style.label(text, 21, color)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(words)

func refresh() -> void:
	var state = sim.practice
	subtitle_label.text = "Two NPC allies · local practice"
	mark_tabs(tabs, state.selected_role)
	status.text = "Room %d/3 · %s · party %d/%d HP" % [mini(3, state.room + 1), Catalog.ROLES[state.role]["name"], state.hp, state.max_hp] if state.active else ("Queued after this outing" if state.requested else "Prepare for the Moss Sentinel")
	start_button.disabled = state.active or state.requested
	stop_button.disabled = not state.active and not state.requested
	start_button.text = "Enter from the pond" if sim.activity == "fishing" else "Practice after this outing"
	var key := JSON.stringify([state.selected_role, state.active, state.room, state.recap, sim.fishing.prepared])
	if key == content_key:
		return
	content_key = key
	clear_list(list)
	paragraph("Your next role: " + str(Catalog.ROLES[state.selected_role]["description"]))
	paragraph("Bran · NPC protection: 36 health, 3 damage and block 2 each enemy turn.\nIris · NPC support: 24 health, 2 damage and heal 3 every third turn.", Style.MUTED)
	paragraph("Three rooms: Training Gate → Root Corridor → Moss Sentinel. The Sentinel bursts every fourth party turn. Your role and current build are fixed at entry.", Style.MUTED)
	paragraph("Prepared Pond Stew: %d. At most one is used per run, restoring 12 health when the full heal fits. Unused stew is kept. First victory: +25 gold once." % sim.fishing.prepared, Style.MUTED)
	if not state.recap.is_empty():
		var result: Dictionary = state.recap
		paragraph("Last run %d · %s\n%s" % [result["run"], "Victory" if result["won"] else "Stopped / defeated", result["reason"]])
		var c: Dictionary = result["contributions"]
		paragraph("%s: %d damage · %d blocked · %d healed\nBran (NPC): %d damage · %d blocked\nIris (NPC): %d damage · %d healed\nPreparation: %d healed" % [sim.identity.adventurer_name, c["hero_damage"], c["hero_block"], c["hero_heal"], c["bran_damage"], c["bran_block"], c["iris_damage"], c["iris_heal"], c["stew_heal"]])
		for line in result["log"]:
			paragraph(str(line), Style.MUTED)
