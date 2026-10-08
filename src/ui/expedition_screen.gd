extends "res://src/ui/sheet.gd"
signal changed
const Catalog = preload("res://src/data/expedition_catalog.gd")
var sim: Node
var tabs: Dictionary
var status: Label
var list: Control
var start_button: Button
var stop_button: Button
var content_key: String = ""
var mode: String = "route"
var mode_tabs: Dictionary

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Trail expeditions", 0.22)
	status = Style.label("", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	mode_tabs = add_tabs(column, [["route", "Choose route"], ["story", "Last journey"]], func(id: String) -> void:
		mode = id
		refresh())
	tabs = add_tabs(column, [["greenway", "Greenway"], ["causeway", "Causeway"]], func(id: String) -> void:
		sim.expedition.selected_route = id
		refresh()
		changed.emit())
	list = add_list(column)
	start_button = Style.button("Explore after this outing", true)
	start_button.pressed.connect(func() -> void:
		if sim.request_expedition(sim.expedition.selected_route):
			refresh()
			changed.emit())
	column.add_child(start_button)
	stop_button = Style.button("Cancel / leave expedition")
	stop_button.pressed.connect(func() -> void:
		sim.stop_expedition()
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
	var state = sim.expedition
	subtitle_label.text = "Five nodes · no live choices required"
	mark_tabs(tabs, state.selected_route)
	mark_tabs(mode_tabs, mode)
	tabs["greenway"].get_parent().visible = mode == "route"
	status.text = "%s · node %d/5 · %d/%d HP\nNext encounter in %ds" % [Catalog.ROUTES[state.route]["name"], mini(5, state.node + 1), state.hp, state.max_hp, int(ceil(float(Catalog.NODE_USEC - state.remainder_usec) / 1000000.0))] if state.active else ("Queued after this outing" if state.requested else "Choose your route before leaving")
	start_button.disabled = state.active or state.requested
	start_button.text = "Expedition in progress" if state.active else ("Queued after this outing" if state.requested else "Explore " + str(Catalog.ROUTES[state.selected_route]["name"]))
	stop_button.disabled = not state.active and not state.requested
	var key := JSON.stringify([mode, state.selected_route, state.active, state.node, state.discoveries, state.recap, sim.fishing.prepared, sim.has_gear_effect("thornward")])
	if key == content_key:
		return
	content_key = key
	clear_list(list)
	if mode == "story":
		if state.recap.is_empty():
			paragraph("No completed journey yet. Choose a route; its encounters resolve while you are away.", Style.MUTED)
		else:
			paragraph("%s · %s\n%d of 5 nodes · %d gold kept" % [Catalog.ROUTES[state.recap["route"]]["name"], "Completed" if state.recap["won"] else "Returned early", state.recap["nodes"], state.recap["gold"]])
			for line in state.recap["log"]:
				paragraph(str(line), Style.MUTED)
		return
	var selected: Dictionary = Catalog.ROUTES[state.selected_route]
	paragraph(str(selected["clue"]))
	paragraph("First completion: +%d gold. Later completions: +%d. Cache adds eight gold. Leaving/failing keeps found cache gold and unused preparation; final rewards require the whole route." % [selected["first_gold"], selected["repeat_gold"]], Style.MUTED)
	paragraph("Prepared stew: %d · Thornward equipped: %s. The entry build is fixed for this expedition. Passive fishing supplies stew; the earned Briarheart Charm supplies Thornward." % [sim.fishing.prepared, "yes" if sim.has_gear_effect("thornward") else "no"], Style.MUTED)
	for index in 5:
		var id: String = selected["nodes"][index]
		paragraph("%d. %s · %s" % [index + 1, Catalog.ENCOUNTERS[id]["name"], "discovered" if state.discoveries.has(id) else "unseen"], Style.MUTED)
	if not state.recap.is_empty():
		paragraph("Last expedition · %s · %s\n%s" % [Catalog.ROUTES[state.recap["route"]]["name"], "Completed" if state.recap["won"] else "Returned early", state.recap["reason"]])
		for line in state.recap["log"]:
			paragraph(str(line), Style.MUTED)
