extends "res://src/ui/sheet.gd"
const Catalog = preload("res://src/data/journal_catalog.gd")
var sim: Node
var list: Control
var rows: Dictionary = {}
var selected: String = ""
var known_count: int = 0
func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Greenway field journal", 0.26)
	list = add_list(column)
	refresh()
func refresh() -> void:
	clear_list(list)
	rows.clear()
	known_count = sim.journal.found.size()
	subtitle_label.text = "%d / %d permanent entries" % [sim.journal.found.size(), Catalog.ENTRIES.size()]
	for id in Catalog.ENTRIES:
		var entry: Dictionary = Catalog.ENTRIES[id]
		var known: bool = sim.journal.found.has(id)
		var row := make_row(id, 130.0)
		var words := Style.label("%s · %s\n%s" % [entry["kind"], entry["title"], entry["text"] if known else "Not discovered · " + entry["clue"]], 21, Style.TEXT if known else Style.MUTED)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(words)
		list.content.add_child(row)
		rows[id] = row
	restyle_rows(rows, selected)

func select(id: String) -> void:
	if not rows.has(id):
		return
	selected = id
	restyle_rows(rows, selected)
	await get_tree().process_frame
	if is_instance_valid(list) and rows.has(selected):
		list.scroll_to(rows[selected].position.y)
