extends "res://src/ui/sheet.gd"

# The talent screen: pick a branch, read a talent, learn it with the pinned button.
# Tapping a row only selects it, so a stray tap never spends a point.
#
# Presentation only. Learning and resetting go through the simulation, then
# `talents_changed` tells the scene to refresh and save.

signal talents_changed

const TalentCatalogScript = preload("res://src/data/talent_catalog.gd")

const TALENT_ROW := 108.0

var sim: Node
var branch: String = ""
var selected: String = ""

var tabs: Dictionary = {}
var rows: Dictionary = {}
var list: Control
var detail_name: Label
var detail_text: Label
var learn_button: Button
var reset_button: Button

func setup(sim_node: Node) -> void:
	sim = sim_node
	branch = TalentCatalogScript.branch_ids()[0]
	_build()
	refresh()

func show_branch(branch_id: String) -> void:
	if branch_id == branch:
		return
	branch = branch_id
	selected = ""
	list.scroll_to(0.0)
	refresh()

func select(talent_id: String) -> void:
	selected = talent_id
	restyle_rows(rows, selected)
	refresh_detail()

func unlock(talent_id: String) -> bool:
	if not sim.unlock_talent(talent_id):
		return false
	refresh()
	talents_changed.emit()
	return true

func _build() -> void:
	var column := build_sheet("Talents")

	var entries: Array = []
	for branch_id in TalentCatalogScript.branch_ids():
		entries.append([branch_id, TalentCatalogScript.branch_label(branch_id)])
	tabs = add_tabs(column, entries, show_branch)

	list = add_list(column)
	list.row_tapped.connect(func(row: Control) -> void: select(str(row.get_meta("key"))))
	add_line(column)

	detail_name = Style.label("", 22)
	detail_name.clip_text = true
	column.add_child(detail_name)
	detail_text = Style.label("", 19, Style.MUTED)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.custom_minimum_size = Vector2(0.0, 56.0)
	column.add_child(detail_text)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	learn_button = Style.button("Learn", true)
	learn_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	learn_button.size_flags_stretch_ratio = 1.6
	learn_button.pressed.connect(func() -> void: unlock(selected))
	actions.add_child(learn_button)
	reset_button = Style.button("Reset talents")
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.pressed.connect(_reset)
	actions.add_child(reset_button)

func refresh() -> void:
	if list == null:
		return
	var points: int = sim.talent_points_available()
	reset_button.disabled = sim.talent_points_spent() == 0
	subtitle_label.text = "%d point%s to spend · %s" % [points, "" if points == 1 else "s", sim.build_summary()]
	mark_tabs(tabs, branch)
	for branch_id in tabs:
		var learned := 0
		for talent_id in TalentCatalogScript.nodes_for_branch(branch_id):
			if sim.has_talent(talent_id):
				learned += 1
		(tabs[branch_id] as Button).text = "%s %d/%d" % [TalentCatalogScript.branch_label(branch_id), learned, TalentCatalogScript.nodes_for_branch(branch_id).size()]

	clear_list(list)
	rows.clear()
	for talent_id in TalentCatalogScript.nodes_for_branch(branch):
		var row := make_row(talent_id, TALENT_ROW)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)

		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", 2)
		line.add_child(words)
		words.add_child(Style.label(TalentCatalogScript.talent_name(talent_id), 22,
			Style.ACCENT if sim.has_talent(talent_id) else Style.TEXT))
		var about := Style.label(TalentCatalogScript.description(talent_id), 17, Style.MUTED)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.add_child(about)

		var state := Style.label(_state_text(talent_id), 19, _state_colour(talent_id))
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_child(state)

		rows[talent_id] = row
		list.content.add_child(row)
	restyle_rows(rows, selected)
	refresh_detail()

func refresh_detail() -> void:
	if detail_name == null:
		return
	if selected.is_empty():
		detail_name.text = "Tap a talent to read it"
		detail_name.add_theme_color_override("font_color", Style.MUTED)
		detail_text.text = "Learning one spends a point. Reset gives every point back."
		learn_button.text = "Learn"
		learn_button.disabled = true
		return
	detail_name.text = TalentCatalogScript.talent_name(selected)
	detail_name.add_theme_color_override("font_color", Style.ACCENT if sim.has_talent(selected) else Style.TEXT)
	detail_text.text = "%s %s." % [TalentCatalogScript.description(selected), _state_text(selected)]
	learn_button.text = "Learned" if sim.has_talent(selected) else "Learn · 1 point"
	learn_button.disabled = not sim.can_unlock_talent(selected)

func _state_text(talent_id: String) -> String:
	if sim.has_talent(talent_id):
		return "Learned"
	if sim.can_unlock_talent(talent_id):
		return "Can learn"
	var requirement: String = TalentCatalogScript.requirement(talent_id)
	if not requirement.is_empty() and not sim.has_talent(requirement):
		return "Needs %s" % TalentCatalogScript.talent_name(requirement)
	return "No points"

func _state_colour(talent_id: String) -> Color:
	if sim.has_talent(talent_id):
		return Style.ACCENT
	return Style.BETTER if sim.can_unlock_talent(talent_id) else Style.MUTED

func _reset() -> void:
	if sim.talent_points_spent() == 0:
		return
	sim.reset_talents()
	refresh()
	talents_changed.emit()
