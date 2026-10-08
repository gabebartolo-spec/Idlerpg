extends "res://src/ui/sheet.gd"
signal changed
signal route_requested(route: String)
const Catalog = preload("res://src/data/expedition_catalog.gd")
const Builds = preload("res://src/data/lantern_build_catalog.gd")
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
	mode_tabs = add_tabs(column, [["route", "Choose"], ["story", "Results"], ["builds", "Builds"]], func(id: String) -> void:
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
	var long_tabs := add_tabs(column, [["mothwatch", "Mothwatch"], ["moonwell", "Moonwell"], ["lamplighter", "Circuit"]], func(id: String) -> void:
		sim.expedition.selected_route = id
		refresh()
		changed.emit())
	tabs.merge(long_tabs)
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
	tabs["mothwatch"].get_parent().visible = mode == "route" and state.claimed_routes.has("hollow")
	status.visible = state.active or state.requested
	var remaining: int = int(ceil(float(Catalog.node_usec(state.route) - state.remainder_usec) / 1000000.0))
	var wait := "%dh %dm" % [remaining / 3600, (remaining % 3600) / 60] if remaining >= 3600 else ("%dm" % int(ceil(remaining / 60.0)) if remaining >= 60 else "%ds" % remaining)
	status.text = "Stage %d/5 · %d/%d HP\nNext in %s" % [mini(5, state.node + 1), state.hp, state.max_hp, wait] if state.active else "Leaving after this outing"
	var locked := Catalog.locked_reason(state.selected_route, state.claimed_routes)
	start_button.disabled = state.active or state.requested or not locked.is_empty()
	start_button.visible = mode == "route"
	start_button.text = "Expedition in progress" if state.active else ("Queued after this outing" if state.requested else "Explore " + str(Catalog.ROUTES[state.selected_route]["name"]))
	stop_button.disabled = not state.active and not state.requested
	stop_button.visible = state.active or state.requested
	var key := JSON.stringify([mode, state.selected_route, state.active, state.node, state.discoveries, state.recap, state.claimed_routes, sim.fishing.prepared, sim.has_gear_effect("thornward"), sim.gear_inventory, sim.equipped, sim.unlocked_talents, sim.hero_level])
	if key == content_key:
		return
	content_key = key
	clear_list(list)
	if mode == "builds":
		for id in Builds.BUILDS:
			var spec: Dictionary = Builds.BUILDS[id]
			paragraph(spec["name"], Style.ACCENT)
			paragraph(spec["hint"], Style.MUTED)
			var needed := Builds.missing(id, sim)
			for item in spec["equipment"].values():
				if str(item).is_empty(): continue
				var line := HBoxContainer.new()
				add_icon(line, preload("res://src/data/art_catalog.gd").item_icon(item))
				var words := Style.label(str(item) + (" · need" if sim.gear_count(item) == 0 else ""), 24)
				words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				line.add_child(words)
				list.content.add_child(line)
			if not str(spec["talent"]).is_empty() and not sim.has_talent(spec["talent"]): paragraph("Thick hide · costs 1 talent point", Style.MUTED)
			var action := Style.button("Equip " + str(spec["name"]))
			action.disabled = not needed.is_empty()
			action.pressed.connect(func() -> void:
				if Builds.apply(id, sim):
					refresh()
					changed.emit())
			list.content.add_child(action)
		return
	if mode == "story":
		if state.recap.is_empty():
			paragraph("Your next adventure starts here.", Style.MUTED)
		else:
			paragraph("Adventure complete!" if state.recap["won"] else "Returned early")
			var receipt: Dictionary = {}
			for pending in sim.reward_chests.pending:
				if pending["id"] == "trail:%d" % int(state.recap.get("run", 0)): receipt = pending
			paragraph("%d gold kept · %d in chest" % [int(state.recap["gold"]) - int(receipt["gold"]), int(receipt["gold"])] if not receipt.is_empty() else "+%d gold collected" % int(state.recap["gold"]), Style.ACCENT)
			paragraph("%s · %d/5 stages" % [Catalog.ROUTES[state.recap["route"]]["name"], state.recap["nodes"]], Style.MUTED)
			if state.recap["stew_used"]:
				paragraph("Stew used", Style.MUTED)
			var look: String = receipt.get("look", "")
			if not look.is_empty():
				paragraph("In chest · " + str(preload("res://src/data/appearance_catalog.gd").LOOKS[look]["name"]), Style.ACCENT)
			if not str(receipt.get("gear", "")).is_empty(): paragraph("In chest · " + str(receipt["gear"]), Style.ACCENT)
		return
	var selected: Dictionary = Catalog.ROUTES[state.selected_route]
	paragraph(str(selected.get("risk", "Easy trail" if state.selected_route == "greenway" else "Risky trail")))
	var minutes: int = Catalog.node_usec(state.selected_route) * 5 / 60000000
	var duration := "%dh" % (minutes / 60) if minutes >= 60 else "%d min" % minutes
	paragraph("%s · %d gold" % [duration, Catalog.total_gold(state.selected_route, not state.claimed_routes.has(state.selected_route))], Style.ACCENT)
	if not locked.is_empty():
		paragraph(locked, Style.MUTED)
	elif selected.has("hint"):
		paragraph(selected["hint"], Style.MUTED)
	if state.selected_route == "causeway":
		paragraph("Bring stew or thorn protection", Style.MUTED)
	if selected.has("look"):
		var item: Dictionary = preload("res://src/data/appearance_catalog.gd").LOOKS[selected["look"]]
		var line := HBoxContainer.new()
		add_icon(line, preload("res://src/data/art_catalog.gd").item_icon(item["item"]))
		line.get_child(0).custom_minimum_size = Vector2(128, 128)
		var pending_look := false
		for receipt in sim.reward_chests.pending: pending_look = pending_look or receipt.get("look", "") == selected["look"]
		var ownership := " · owned" if sim.wardrobe.owned.has(selected["look"]) else (" · in chest" if pending_look else " · earn")
		var words := Style.label(str(item["name"]) + ownership, 26, Style.ACCENT)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		list.content.add_child(line)
	if selected.has("gear"):
		var reward: String = selected["gear"]
		var line := HBoxContainer.new()
		add_icon(line, preload("res://src/data/art_catalog.gd").item_icon(reward))
		line.get_child(0).custom_minimum_size = Vector2(128, 128)
		var effect: String = GearCatalog.EFFECTS.get(GearCatalog.effect(reward), {}).get("name", "")
		var words := Style.label(reward + "\n" + effect, 26, Style.ACCENT)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		list.content.add_child(line)
		var secured: bool = sim.gear_count(reward) > 0
		for receipt in sim.reward_chests.pending:
			secured = secured or receipt.get("gear", "") == reward
		paragraph("Already secured · repeat gold" if secured else "Guaranteed gear chest", Style.MUTED)
		paragraph("%d/3 clears · mastery" % mini(3, int(state.route_clears.get(state.selected_route, 0))), Style.MUTED)
	paragraph("Stew: %d · Thornward: %s" % [sim.fishing.prepared, "ready" if sim.has_gear_effect("thornward") else "—"], Style.MUTED)
