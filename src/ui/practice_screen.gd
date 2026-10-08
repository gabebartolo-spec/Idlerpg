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
	var column := build_sheet("Practice", 0.34)
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
	var words := Style.label(text, 24, color)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(words)

func refresh() -> void:
	var state = sim.practice
	subtitle_label.text = "Bran + Iris · NPC allies"
	mark_tabs(tabs, state.selected_role)
	status.visible = state.active or state.requested
	status.text = "Room %d/3 · %d/%d HP" % [mini(3, state.room + 1), state.hp, state.max_hp] if state.active else "Leaving after this outing"
	start_button.disabled = state.active or state.requested
	stop_button.disabled = not state.active and not state.requested
	stop_button.visible = state.active or state.requested
	start_button.text = "Practice in progress" if state.active else ("Queued" if state.requested else "Start practice")
	var key := JSON.stringify([state.selected_role, state.active, state.room, state.recap, sim.fishing.prepared])
	if key == content_key:
		return
	content_key = key
	clear_list(list)
	var benefits := {"damage": "+3 attack", "protection": "Block 3 per hit", "support": "Heal 10 every 3 turns"}
	paragraph(benefits[state.selected_role])
	paragraph("3 rooms · Stew: %d" % sim.fishing.prepared, Style.MUTED)
	if not state.first_reward_claimed:
		paragraph("First victory: +25 gold", Style.ACCENT)
	if not state.recap.is_empty():
		var result: Dictionary = state.recap
		paragraph("Victory!" if result["won"] else "Try another role or bring stew")
		paragraph("%d/3 rooms · %ds" % [result["rooms"], result["turns"]], Style.MUTED)
