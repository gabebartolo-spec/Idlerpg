extends "res://src/ui/sheet.gd"
signal changed
const Relics = preload("res://src/data/relic_catalog.gd")
var sim: Node
var game: Node
var selected: String = ""
var list: Control
var rows := {}
var detail: Label
var equip_button: Button
var clear_button: Button
func setup(sim_node: Node, game_node: Node) -> void:
	sim = sim_node
	game = game_node
	var column := build_sheet("Relic slot")
	list = add_list(column)
	list.row_tapped.connect(func(row: Control) -> void:
		selected = str(row.get_meta("key"))
		refresh_detail())
	detail = Style.label("", 22, Style.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	equip_button = Style.button("Equip selected relic", true)
	equip_button.pressed.connect(func() -> void:
		if sim.equip_relic(selected, game):
			refresh()
			changed.emit())
	column.add_child(equip_button)
	clear_button = Style.button("Unequip relic")
	clear_button.pressed.connect(func() -> void:
		sim.equip_relic("", game)
		refresh()
		changed.emit())
	column.add_child(clear_button)
	refresh()
func refresh() -> void:
	clear_list(list)
	rows.clear()
	subtitle_label.text = "Equipped · " + (sim.active_relic if not sim.active_relic.is_empty() else "None")
	for name in Relics.ITEMS:
		var owned: bool = sim.owns_relic(name, game)
		var row := make_row(name, 112.0)
		rows[name] = row
		var label := Style.label("%s%s\n%s" % ["Equipped · " if sim.active_relic == name else "", name, Relics.description(name)], 22, Style.TEXT if owned else Style.MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		list.content.add_child(row)
	refresh_detail()
func refresh_detail() -> void:
	restyle_rows(rows, selected)
	var owned: bool = sim.owns_relic(selected, game)
	detail.text = Relics.description(selected)
	if Relics.FREE_SOURCES.has(selected):
		detail.text += "\n" + str(Relics.FREE_SOURCES[selected]) + (" · owned" if owned else " · not yet earned")
	elif Relics.valid(selected):
		detail.text += "\nRelic Vault collection" + (" · owned" if owned else " · not collected")
	else:
		detail.text = "Choose a relic. Free travel and health relics come from ordinary adventuring."
	equip_button.disabled = not owned or sim.active_relic == selected
	clear_button.disabled = sim.active_relic.is_empty()
