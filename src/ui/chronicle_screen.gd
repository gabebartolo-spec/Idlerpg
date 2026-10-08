extends "res://src/ui/sheet.gd"

signal route_requested(route: String)
var sim: Node
var list: Control
var selected: String = ""
var routes: Dictionary = {}
var targets: Dictionary = {}
var rows: Dictionary = {}
var act_button: Button

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Adventurer chronicle")
	list = add_list(column)
	list.row_tapped.connect(func(row: Control) -> void:
		selected = str(row.get_meta("key"))
		restyle_rows(rows, selected)
		act_button.disabled = str(routes.get(selected, "")).is_empty())
	act_button = Style.button("Review this milestone", true)
	act_button.disabled = true
	act_button.pressed.connect(func() -> void: route_requested.emit(str(routes.get(selected, ""))))
	column.add_child(act_button)
	refresh()

func refresh() -> void:
	if list == null:
		return
	clear_list(list)
	routes.clear()
	targets.clear()
	rows.clear()
	selected = ""
	act_button.disabled = true
	var entries: Array = sim.chronicle.entries.duplicate(true)
	subtitle_label.text = "%d remembered milestones" % entries.size()
	if entries.is_empty():
		var empty := Style.label("Your next first victory, useful find or bond will be remembered here.", 22, Style.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.content.add_child(empty)
	entries.reverse()
	for entry in entries:
		var key := str(entry["id"])
		routes[key] = str(entry["route"])
		targets[key] = str(entry.get("target", ""))
		var row := make_row(key, 112.0)
		rows[key] = row
		var words := Style.label(str(entry["message"]), 22)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(words)
		list.content.add_child(row)
