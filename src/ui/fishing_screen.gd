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
	var column := build_sheet("Fishing", 0.34)
	status = Style.label("", 22)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 32
	progress.show_percentage = false
	column.add_child(progress)
	reel_button = Style.button("Reel in · optional", true)
	reel_button.pressed.connect(func() -> void:
		var result: Dictionary = sim.reel_fishing()
		result_label.text = ("Bonus perch!" if sim.fishing.successful_reels % 10 == 0 else "Nice reel! %d/10" % (sim.fishing.successful_reels % 10)) if result.get("ok", false) else "Missed · passive catch is safe"
		refresh()
		changed.emit())
	column.add_child(reel_button)
	result_label = Style.label("Tap when green for a bonus", 22, Style.MUTED)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(result_label)
	var list := add_list(column)
	stock_label = Style.label("", 24)
	list.content.add_child(stock_label)
	var recipe := Style.label("Stew: 2 perch + 1 carp + 1 herb\nRestores 12 health", 22, Style.MUTED)
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
	subtitle_label.text = "Mossgate Pond · 15s per catch"
	status.text = "Next catch: %ds" % int(ceil(float(Catalog.INTERVAL_USEC - state.progress_usec) / 1000000.0)) if sim.activity == "fishing" else ("Leaving after this outing" if state.requested else "Take a break by the pond")
	progress.value = float(state.progress_usec) / float(Catalog.INTERVAL_USEC) * 100.0
	var green: bool = state.progress_usec >= 7000000 and state.progress_usec <= 9000000
	progress.modulate = Color(0.4, 0.9, 0.5) if green else Color.WHITE
	reel_button.disabled = sim.activity != "fishing" or state.last_attempt == state.catches
	choose_button.text = "Resume adventures" if sim.activity == "fishing" else ("Cancel fishing request" if state.requested else "Fish after this outing")
	prepare_button.disabled = not state.can_prepare()
	stock_label.text = "Perch: %d  ·  Carp: %d  ·  Herbs: %d\nStew ready: %d" % [state.stock.get("Pond Perch", 0), state.stock.get("Silver Carp", 0), state.stock.get("Reed Herb", 0), state.prepared]
	stock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stock_label.custom_minimum_size.y = Style.TOUCH
