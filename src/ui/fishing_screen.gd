extends "res://src/ui/sheet.gd"
signal changed
const Catalog = preload("res://src/data/fishing_catalog.gd")
var sim: Node
var status: Label
var progress: ProgressBar
var stock_label: Label
var reel_button: Button
var choose_button: Button
var prepare_button: Button
var result_label: Label

func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Mossgate Pond", 0.22)
	status = Style.label("", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	var rules := Style.label("One passive catch every 15 seconds: perch, carp, then herb. All ingredients come from passive fishing. Adventures pause at the pond; earned tokens keep accruing.", 20, Style.MUTED)
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(rules)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 32
	progress.show_percentage = false
	column.add_child(progress)
	reel_button = Style.button("Optional reel · green at 7–9 seconds", true)
	reel_button.pressed.connect(func() -> void:
		result_label.text = sim.reel_fishing()["message"]
		refresh()
		changed.emit())
	column.add_child(reel_button)
	result_label = Style.label("Ten timely reels add one bonus perch. Missing does not lose your passive catch.", 20, Style.MUTED)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(result_label)
	var list := add_list(column)
	stock_label = Style.label("", 23)
	list.content.add_child(stock_label)
	var recipe := Style.label("Pond Stew: 2 perch + 1 carp + 1 herb. Prepare for the practice dungeon; heals 12 party health once.", 20, Style.MUTED)
	recipe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(recipe)
	prepare_button = Style.button("Prepare Pond Stew")
	prepare_button.pressed.connect(func() -> void:
		if sim.prepare_stew():
			refresh()
			changed.emit())
	column.add_child(prepare_button)
	choose_button = Style.button("Fish after this outing", true)
	choose_button.pressed.connect(func() -> void:
		sim.set_fishing(not sim.fishing.requested)
		refresh()
		changed.emit())
	column.add_child(choose_button)
	refresh()

func _process(_delta: float) -> void:
	if visible and sim != null:
		refresh()

func refresh() -> void:
	var state = sim.fishing
	subtitle_label.text = "Passive profession · no energy cost"
	status.text = "Fishing · cast %.1f / 15 seconds" % (float(state.progress_usec) / 1000000.0) if sim.activity == "fishing" else ("Queued after this outing" if state.requested else "Choose a peaceful pause at the pond")
	progress.value = float(state.progress_usec) / float(Catalog.INTERVAL_USEC) * 100.0
	var green: bool = state.progress_usec >= 7000000 and state.progress_usec <= 9000000
	progress.modulate = Color(0.4, 0.9, 0.5) if green else Color.WHITE
	reel_button.disabled = sim.activity != "fishing" or state.last_attempt == state.catches
	choose_button.text = "Resume adventures" if sim.activity == "fishing" else ("Cancel fishing request" if state.requested else "Fish after this outing")
	prepare_button.disabled = not state.can_prepare()
	stock_label.text = "Perch: %d\nCarp: %d\nHerbs: %d\nPrepared stew: %d\nTimely reels: %d / 10\nBonus perch: %d" % [state.stock.get("Pond Perch", 0), state.stock.get("Silver Carp", 0), state.stock.get("Reed Herb", 0), state.prepared, state.successful_reels % 10, state.bonus_catches]
