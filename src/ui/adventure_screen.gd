extends "res://src/ui/sheet.gd"

signal route_requested(route: String)
signal changed
const Policy = preload("res://src/data/adventure_policy.gd")
var mode: String = "goals"
var tabs := {}
var sim: Node
var list: Control
var selected: String = "prepare"
var rows := {}
var cards := {}
var detail: Label
var track_button: Button
var review_button: Button

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Adventure goals")
	tabs = add_tabs(column, [["goals", "Goals"], ["policies", "Adventure policy"]], func(id: String) -> void:
		mode = id
		selected = "prepare" if id == "goals" else sim.adventure_policy
		list.scroll_to(0.0)
		refresh())
	list = add_list(column)
	list.row_tapped.connect(func(row: Control) -> void:
		selected = str(row.get_meta("key"))
		refresh_detail())
	detail = Style.label("", 20, Style.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(detail)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	track_button = Style.button("Track goal", true)
	track_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_button.pressed.connect(func() -> void:
		var success: bool = sim.set_tracked_goal(selected) if mode == "goals" else sim.set_adventure_policy(selected)
		if success:
			refresh()
			changed.emit())
	actions.add_child(track_button)
	review_button = Style.button("Review preparation")
	review_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	review_button.pressed.connect(func() -> void: route_requested.emit("boss" if mode == "policies" else str(cards[selected]["route"])))
	actions.add_child(review_button)
	refresh()

func refresh() -> void:
	clear_list(list)
	rows.clear()
	cards.clear()
	mark_tabs(tabs, mode)
	track_button.text = "Track goal" if mode == "goals" else "Use next outing"
	if mode == "policies":
		subtitle_label.text = "Next outing policy"
		for id in Policy.POLICIES:
			cards[id] = Policy.POLICIES[id]
			var row := make_row(id, 128.0)
			rows[id] = row
			var words := Style.label(("Selected · " if sim.adventure_policy == id else "") + str(Policy.POLICIES[id]["name"]), 22)
			words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(words)
			list.content.add_child(row)
		refresh_detail()
		return
	subtitle_label.text = "Three permanent pursuits"
	for card in sim.goals.cards(sim):
		var id := str(card["id"])
		cards[id] = card
		var done: bool = sim.goals.completed.has(id)
		var row := make_row(id, 128.0)
		rows[id] = row
		var progress := "Complete · reward delivered" if done else "%d/%d · +25 gold once" % [card["progress"], card["required"]]
		var words := Style.label("%s%s\n%s" % ["Tracked · " if sim.goals.tracked == id else "", card["title"], progress], 22)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(words)
		list.content.add_child(row)
	refresh_detail()

func refresh_detail() -> void:
	if not cards.has(selected):
		selected = sim.goals.tracked
	restyle_rows(rows, selected)
	if mode == "policies":
		detail.text = str(cards[selected]["description"]) + " Change takes effect next outing."
		track_button.disabled = sim.adventure_policy == selected
	else:
		detail.text = str(cards[selected]["clue"])
		track_button.disabled = sim.goals.tracked == selected
