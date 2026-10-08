extends "res://src/ui/sheet.gd"

signal route_requested(route: String)
var list: Control
var routes: Dictionary
var options_button: Button

func setup(show_dev: bool) -> void:
	var column := build_sheet("More")
	subtitle_label.text = "Your adventure"
	list = add_list(column)
	var entries := [["adventure", "Adventure"], ["expedition", "Expeditions"], ["fishing", "Fishing"],
		["practice", "Practice"], ["boss", "Boss"], ["builds", "Builds"], ["relics", "Relics"],
		["wardrobe", "Wardrobe"], ["identity", "Adventurer"], ["journal", "Field journal"], ["chronicle", "Chronicle"]]
	if show_dev:
		entries.append(["dev", "Developer tools"])
	for entry in entries:
		var button := Style.button(entry[1])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void: route_requested.emit(entry[0]))
		list.content.add_child(button)
		routes[entry[0]] = button
	options_button = Style.button("Options")
	options_button.pressed.connect(func() -> void: route_requested.emit("options"))
	column.add_child(options_button)
