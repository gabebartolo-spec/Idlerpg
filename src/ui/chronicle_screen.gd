extends "res://src/ui/sheet.gd"

signal destination_requested(route: String, target: String)

var sim: Node
var list: Control

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Adventurer chronicle", 0.26)
	list = add_list(column)
	refresh()

func refresh() -> void:
	clear_list(list)
	subtitle_label.text = "Milestones remembered · newest first"
	if sim.chronicle.events.is_empty():
		var empty := Style.label("Your story starts here. Milestones from this adventure will appear as they happen.", 24)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.content.add_child(empty)
	for event in sim.chronicle.events:
		var button := Style.button("Level %d · Quest %d\n%s" % [event["level"], int(event["quest"]) + 1, event["message"]])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 120.0
		button.pressed.connect(func() -> void: destination_requested.emit(str(event["route"]), str(event["target"])))
		list.content.add_child(button)
