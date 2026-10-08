extends "res://src/ui/sheet.gd"
signal changed
const Identity = preload("res://src/state/adventurer_identity.gd")
var sim: Node
var name_input: LineEdit
var preview: Label
var swatch: ColorRect
var title_list: Control
var palette_tabs: Dictionary
var save_button: Button
func setup(sim_node: Node) -> void:
	sim = sim_node
	var column := build_sheet("Your adventurer", 0.26)
	preview = Style.label("", 25)
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(preview)
	swatch = ColorRect.new()
	swatch.custom_minimum_size = Vector2(0, 32)
	column.add_child(swatch)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Adventurer name · up to 24 characters"
	name_input.max_length = 24
	name_input.custom_minimum_size.y = Style.TOUCH
	name_input.add_theme_font_size_override("font_size", 24)
	column.add_child(name_input)
	save_button = Style.button("Save name", true)
	save_button.pressed.connect(func() -> void:
		sim.identity.rename(name_input.text)
		name_input.release_focus()
		refresh()
		changed.emit())
	column.add_child(save_button)
	column.add_child(Style.label("Free outfit accents · previewed on your adventurer", 20, Style.MUTED))
	palette_tabs = add_tabs(column, [["amber", "Amber"], ["moss", "Moss"], ["slate", "Slate"]], func(id: String) -> void:
		sim.identity.set_palette(id)
		refresh()
		changed.emit())
	title_list = add_list(column)
	refresh()
func refresh() -> void:
	preview.text = sim.identity.display_name()
	name_input.text = sim.identity.adventurer_name
	swatch.color = Identity.PALETTES[sim.identity.palette]
	mark_tabs(palette_tabs, sim.identity.palette)
	subtitle_label.text = "First-boss keepsake earned" if sim.thornback_rank > 0 else "First-boss keepsake · defeat Old Thornback"
	clear_list(title_list)
	var none := Style.button("Show no title")
	none.pressed.connect(_title.bind(""))
	title_list.content.add_child(none)
	for id in Identity.TITLES:
		var earned: bool = id in sim.identity.earned_titles(sim)
		var button := Style.button(("Earned: " if earned else "Locked: ") + str(Identity.TITLES[id]))
		button.disabled = not earned
		button.pressed.connect(_title.bind(id))
		title_list.content.add_child(button)
	var clue := Style.label("Scout: complete the opening errand. Thornbreaker and the keepsake: win your first boss fight. Titles and accents grant no stats.", 20, Style.MUTED)
	clue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_list.content.add_child(clue)
func _title(id: String) -> void:
	if sim.identity.choose_title(id, sim):
		refresh()
		changed.emit()
