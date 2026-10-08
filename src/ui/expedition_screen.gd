extends "res://src/ui/sheet.gd"
signal changed
signal route_requested(route: String)
const Catalog = preload("res://src/data/expedition_catalog.gd")
var sim: Node
var tabs: Dictionary
var status: Label
var list: Control
var start_button: Button
var stop_button: Button
var reward_button: Button
var content_key: String = ""
var mode: String = "route"
var mode_tabs: Dictionary

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Expeditions", 0.22)
	status = Style.label("", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	mode_tabs = add_tabs(column, [["route", "Choose"], ["story", "Results"]], func(id: String) -> void:
		mode = id
		refresh())
	tabs = add_tabs(column, [["greenway", "Greenway"], ["causeway", "Causeway"]], func(id: String) -> void:
		sim.expedition.selected_route = id
		refresh()
		changed.emit())
	var woodland_tabs := add_tabs(column, [["hollow", "Lantern Hollow"], ["rise", "Keeper's Rise"]], func(id: String) -> void:
		sim.expedition.selected_route = id
		refresh()
		changed.emit())
	tabs.merge(woodland_tabs)
	list = add_list(column)
	reward_button = Style.button("Open earned chest", true)
	reward_button.pressed.connect(func() -> void: route_requested.emit("rewards"))
	column.add_child(reward_button)
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
	var words := Style.label(text, 24, color)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(words)

func refresh() -> void:
	var state = sim.expedition
	reward_button.visible = mode == "story" and not sim.reward_chests.pending.is_empty()
	subtitle_label.text = "Trails of Mossgate"
	mark_tabs(tabs, state.selected_route)
	mark_tabs(mode_tabs, mode)
	tabs["greenway"].get_parent().visible = mode == "route"
	tabs["hollow"].get_parent().visible = mode == "route"
	status.visible = state.active or state.requested
	status.text = "Stage %d/5 · %d/%d HP\nNext in %ds" % [mini(5, state.node + 1), state.hp, state.max_hp, int(ceil(float(Catalog.node_usec(state.route) - state.remainder_usec) / 1000000.0))] if state.active else "Leaving after this outing"
	var locked := Catalog.locked_reason(state.selected_route, state.claimed_routes)
	start_button.disabled = state.active or state.requested or not locked.is_empty()
	start_button.text = "Expedition in progress" if state.active else ("Queued after this outing" if state.requested else "Explore " + str(Catalog.ROUTES[state.selected_route]["name"]))
	stop_button.disabled = not state.active and not state.requested
	stop_button.visible = state.active or state.requested
	var key := JSON.stringify([mode, state.selected_route, state.active, state.node, state.discoveries, state.recap, state.claimed_routes, sim.fishing.prepared, sim.has_gear_effect("thornward")])
	if key == content_key:
		return
	content_key = key
	clear_list(list)
	if mode == "story":
		if state.recap.is_empty():
			paragraph("Your next adventure starts here.", Style.MUTED)
		else:
			paragraph("Adventure complete!" if state.recap["won"] else "Returned early")
			paragraph("+%d gold" % state.recap["gold"], Style.ACCENT)
			paragraph("%s · %d/5 stages" % [Catalog.ROUTES[state.recap["route"]]["name"], state.recap["nodes"]], Style.MUTED)
			if state.recap["stew_used"]:
				paragraph("Stew used", Style.MUTED)
			var look: String = Catalog.ROUTES[state.recap["route"]].get("look", "")
			if bool(state.recap["won"]) and not look.is_empty():
				paragraph("Look earned · " + str(preload("res://src/data/appearance_catalog.gd").LOOKS[look]["name"]), Style.ACCENT)
		return
	var selected: Dictionary = Catalog.ROUTES[state.selected_route]
	paragraph(str(selected.get("risk", "Easy trail" if state.selected_route == "greenway" else "Risky trail")))
	paragraph("%d min · %d gold" % [Catalog.node_usec(state.selected_route) * 5 / 60000000, Catalog.total_gold(state.selected_route, not state.claimed_routes.has(state.selected_route))], Style.ACCENT)
	if not locked.is_empty():
		paragraph(locked, Style.MUTED)
	elif selected.has("hint"):
		paragraph(selected["hint"], Style.MUTED)
	if state.selected_route == "causeway":
		paragraph("Bring stew or thorn protection", Style.MUTED)
	if selected.has("look"):
		paragraph("Earn " + str(preload("res://src/data/appearance_catalog.gd").LOOKS[selected["look"]]["name"]), Style.ACCENT)
	paragraph("Stew: %d · Thornward: %s" % [sim.fishing.prepared, "ready" if sim.has_gear_effect("thornward") else "—"], Style.MUTED)
