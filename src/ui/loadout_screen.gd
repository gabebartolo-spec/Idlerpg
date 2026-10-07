extends "res://src/ui/sheet.gd"
signal changed
var sim: Node
var game: Node
var index: int = 0
var tabs := {}
var name_input: LineEdit
var detail: Label
var apply_button: Button
var available_button: Button

func setup(sim_node: Node, game_node: Node) -> void:
	sim = sim_node
	game = game_node
	var column := build_sheet("Build loadouts")
	tabs = add_tabs(column, [[0, "Build 1"], [1, "Build 2"], [2, "Build 3"]], func(next: int) -> void:
		index = next
		refresh())
	name_input = LineEdit.new()
	name_input.max_length = 32
	name_input.custom_minimum_size.y = Style.TOUCH
	name_input.add_theme_font_size_override("font_size", 24)
	column.add_child(name_input)
	var list := add_list(column)
	detail = Style.label("", 22, Style.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(detail)
	var save_button := Style.button("Save current build in this slot")
	save_button.pressed.connect(func() -> void:
		if sim.loadouts.save_current(index, name_input.text, sim):
			refresh()
			changed.emit())
	column.add_child(save_button)
	apply_button = Style.button("Apply complete loadout", true)
	apply_button.pressed.connect(func() -> void: apply(false))
	column.add_child(apply_button)
	available_button = Style.button("Apply available pieces")
	available_button.pressed.connect(func() -> void: apply(true))
	column.add_child(available_button)
	refresh()

func apply(available: bool) -> void:
	var result: Dictionary = sim.loadouts.apply(index, sim, game, available)
	if bool(result["ok"]):
		changed.emit()
	refresh()

func refresh() -> void:
	mark_tabs(tabs, index)
	subtitle_label.text = "Three free slots"
	var saved: Dictionary = sim.loadouts.presets.get(str(index), {})
	name_input.text = str(saved.get("name", "Build %d" % (index + 1)))
	var plan: Dictionary = sim.loadouts.preview(index, sim, game)
	detail.text = str(plan["error"])
	if not saved.is_empty():
		var pieces: Array[String] = []
		for item in saved.get("equipment", {}).values():
			if not str(item).is_empty():
				pieces.append(str(item))
		detail.text += "\n\nGear: %s\n%d talents\nCompanion: %s" % [", ".join(pieces) if not pieces.is_empty() else "None", saved.get("talents", {}).size(), str(saved.get("companion", "")) if not str(saved.get("companion", "")).is_empty() else "None"]
		detail.text += "\nRelic: " + str(saved.get("relic", "None"))
	apply_button.disabled = not bool(plan["ok"])
	var fallback: Dictionary = sim.loadouts.preview(index, sim, game, true)
	available_button.visible = not plan["missing"].is_empty()
	available_button.disabled = not bool(fallback["ok"])
	if available_button.visible:
		detail.text += "\n\nAvailable pieces keeps your current owned item/companion where a saved piece is missing. It never creates replacements."
