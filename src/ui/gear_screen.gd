extends "res://src/ui/sheet.gd"

# The gear screen: a sheet over the lower part of the screen, so the adventurer stays in
# view above it. Browse by slot, compare against what is worn, equip, sell or salvage.
# Design and touch rules: docs/UI_GEAR_SCREEN.md.
#
# Presentation only. Every change goes through the simulation and game state, then
# `gear_changed` tells the scene to update the adventurer and save.

signal gear_changed

const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const ArtCatalogScript = preload("res://src/data/art_catalog.gd")

const SLOTS := ["weapon", "offhand", "head", "chest", "legs", "hands", "feet", "accessory"]
const SLOT_LABELS := {
	"": "All", "weapon": "Weapon", "offhand": "Shield", "head": "Head", "chest": "Chest",
	"legs": "Legs", "hands": "Hands", "feet": "Feet", "accessory": "Charm"
}
const RARITY_ORDER := ["Legendary", "Epic", "Rare", "Common"]

var sim: Node
var game: Node
var selected: String = ""
var slot_filter: String = ""

var list: Control
var stats_label: Label
var caption_label: Label
var detail_name: Label
var detail_compare: Label
var equip_button: Button
var sell_button: Button
var salvage_button: Button
var slot_buttons: Dictionary = {}
var rows: Dictionary = {}

func setup(sim_node: Node, game_node: Node) -> void:
	sim = sim_node
	game = game_node
	_build()
	refresh()

func select(item_name: String) -> void:
	selected = item_name
	_restyle_rows()
	refresh_detail()

func set_slot_filter(slot_name: String) -> void:
	slot_filter = slot_name
	list.scroll_to(0.0)
	refresh()

func visible_items() -> Array[String]:
	var names: Array[String] = []
	for item_name in sim.owned_gear_names():
		if slot_filter.is_empty() or GearCatalogScript.slot(item_name) == slot_filter:
			names.append(item_name)
	names.sort_custom(_before)
	return names

func _before(a: String, b: String) -> bool:
	var slot_a := SLOTS.find(GearCatalogScript.slot(a))
	var slot_b := SLOTS.find(GearCatalogScript.slot(b))
	if slot_a != slot_b:
		return slot_a < slot_b
	var rarity_a := RARITY_ORDER.find(GearCatalogScript.rarity(a))
	var rarity_b := RARITY_ORDER.find(GearCatalogScript.rarity(b))
	if rarity_a != rarity_b:
		return rarity_a < rarity_b
	return a < b

func _build() -> void:
	var column := build_sheet("Gear")
	stats_label = subtitle_label

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	column.add_child(slots)
	for slot_name in [""] + SLOTS:
		var chip := Button.new()
		chip.custom_minimum_size = Vector2(0.0, Style.TOUCH)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.focus_mode = Control.FOCUS_NONE
		chip.expand_icon = true
		chip.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_theme_font_size_override("font_size", 15)
		chip.add_theme_color_override("font_color", Style.TEXT)
		chip.pressed.connect(set_slot_filter.bind(slot_name))
		slots.add_child(chip)
		slot_buttons[slot_name] = chip

	caption_label = Style.label("", 18, Style.MUTED)
	column.add_child(caption_label)

	list = add_list(column)
	list.row_tapped.connect(_on_row_tapped)
	add_line(column)

	# Comparison and actions stay pinned under the list, always within reach.
	detail_name = Style.label("", 22)
	detail_name.clip_text = true
	column.add_child(detail_name)
	detail_compare = Style.label("", 19, Style.MUTED)
	detail_compare.clip_text = true
	column.add_child(detail_compare)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	equip_button = Style.button("Equip", true)
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.size_flags_stretch_ratio = 1.4
	equip_button.pressed.connect(_equip_selected)
	actions.add_child(equip_button)
	sell_button = Style.button("Sell")
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.pressed.connect(_sell_selected)
	actions.add_child(sell_button)
	salvage_button = Style.button("Salvage")
	salvage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	salvage_button.pressed.connect(_salvage_selected)
	actions.add_child(salvage_button)

func refresh() -> void:
	if list == null:
		return
	if not selected.is_empty() and sim.gear_count(selected) <= 0:
		selected = ""

	stats_label.text = "Attack %d · Health %d" % [sim.effective_attack(), sim.effective_max_hp()]
	for slot_name in slot_buttons:
		var chip: Button = slot_buttons[slot_name]
		var worn := "" if slot_name.is_empty() else str(sim.equipped_item(slot_name))
		chip.icon = ArtCatalogScript.item_icon(worn) if not worn.is_empty() else null
		chip.text = "" if chip.icon != null else str(SLOT_LABELS[slot_name])
		var chosen: bool = slot_name == slot_filter
		var style := Style.box(Style.SELECTED if chosen else Style.RAISED, 10.0, 4.0, Style.ACCENT if chosen else Color.TRANSPARENT)
		for state in ["normal", "hover", "pressed"]:
			chip.add_theme_stylebox_override(state, style)

	var names := visible_items()
	caption_label.text = "%s · %d item%s" % [
		"All gear" if slot_filter.is_empty() else str(SLOT_LABELS[slot_filter]),
		names.size(),
		"" if names.size() == 1 else "s"
	]

	clear_list(list)
	rows.clear()
	if names.is_empty():
		var empty := Style.label(
			"Nothing here yet. Keep questing, or try the Gear banner." if slot_filter.is_empty()
			else "No %s gear yet." % str(SLOT_LABELS[slot_filter]).to_lower(), 20, Style.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
		list.content.add_child(empty)
	for item_name in names:
		var row := _make_row(item_name)
		rows[item_name] = row
		list.content.add_child(row)
	_restyle_rows()
	refresh_detail()

func _make_row(item_name: String) -> Control:
	var slot_name: String = GearCatalogScript.slot(item_name)
	var worn: String = str(sim.equipped_item(slot_name))
	var is_worn: bool = worn == item_name

	var row := make_row(item_name)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)

	add_icon(line, ArtCatalogScript.item_icon(item_name))

	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 2)
	line.add_child(words)
	var count: int = sim.gear_count(item_name)
	var title := Style.label(item_name if count <= 1 else "%s ×%d" % [item_name, count], 22, Style.rarity_colour(GearCatalogScript.rarity(item_name)))
	title.clip_text = true
	words.add_child(title)
	var about := Style.label("%s %s · %s" % [
		GearCatalogScript.rarity(item_name), str(SLOT_LABELS[slot_name]).to_lower(), _stats(item_name)
	], 17, Style.MUTED)
	about.clip_text = true
	words.add_child(about)

	var verdict := Style.label("", 19)
	verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	verdict.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_worn:
		verdict.text = "Worn"
		verdict.add_theme_color_override("font_color", Style.ACCENT)
	else:
		var change := _change(item_name, worn)
		verdict.text = _change_text(change)
		verdict.add_theme_color_override("font_color", _change_colour(change))
	line.add_child(verdict)
	return row

func _restyle_rows() -> void:
	restyle_rows(rows, selected)

func refresh_detail() -> void:
	if detail_name == null:
		return
	var has_item: bool = not selected.is_empty() and sim.gear_count(selected) > 0
	equip_button.disabled = not has_item
	if not has_item:
		detail_name.text = "Tap an item to compare it"
		detail_name.add_theme_color_override("font_color", Style.MUTED)
		detail_compare.text = "Its change against what you are wearing shows here."
		detail_compare.add_theme_color_override("font_color", Style.MUTED)
		equip_button.text = "Equip"
		sell_button.text = "Sell"
		salvage_button.text = "Salvage"
		sell_button.disabled = true
		salvage_button.disabled = true
		return

	var slot_name: String = GearCatalogScript.slot(selected)
	var worn: String = str(sim.equipped_item(slot_name))
	var is_worn: bool = worn == selected
	detail_name.text = "%s · %s" % [selected, _stats(selected)]
	detail_name.add_theme_color_override("font_color", Style.rarity_colour(GearCatalogScript.rarity(selected)))

	var locked: bool = game.is_locked(selected)
	if is_worn:
		detail_compare.text = "You are wearing this."
		detail_compare.add_theme_color_override("font_color", Style.ACCENT)
	else:
		var change := _change(selected, worn)
		detail_compare.text = "Replaces %s: %s" % [worn if not worn.is_empty() else "an empty slot", _change_text(change)]
		detail_compare.add_theme_color_override("font_color", _change_colour(change))
	if locked:
		detail_compare.text += " · Locked"

	equip_button.text = "Take off" if is_worn else "Equip"
	sell_button.text = "Sell +%dg" % GearCatalogScript.sell_value(selected)
	salvage_button.text = "Salvage +%d" % GearCatalogScript.salvage_tokens(selected)
	var can_dispose: bool = sim.can_dispose_gear(selected) and not locked
	sell_button.disabled = not can_dispose
	salvage_button.disabled = not can_dispose

func _stats(item_name: String) -> String:
	var parts: Array[String] = []
	if GearCatalogScript.attack_bonus(item_name) > 0:
		parts.append("+%d attack" % GearCatalogScript.attack_bonus(item_name))
	if GearCatalogScript.hp_bonus(item_name) > 0:
		parts.append("+%d health" % GearCatalogScript.hp_bonus(item_name))
	return " · ".join(parts) if not parts.is_empty() else "no stats"

# Attack and health change from swapping `worn` for `item_name`.
func _change(item_name: String, worn: String) -> Vector2i:
	return Vector2i(
		GearCatalogScript.attack_bonus(item_name) - GearCatalogScript.attack_bonus(worn),
		GearCatalogScript.hp_bonus(item_name) - GearCatalogScript.hp_bonus(worn))

func _change_text(change: Vector2i) -> String:
	var parts: Array[String] = []
	if change.x != 0:
		parts.append("%+d attack" % change.x)
	if change.y != 0:
		parts.append("%+d health" % change.y)
	return " · ".join(parts) if not parts.is_empty() else "same stats"

func _change_colour(change: Vector2i) -> Color:
	if change.x >= 0 and change.y >= 0 and change != Vector2i.ZERO:
		return Style.BETTER
	if change.x <= 0 and change.y <= 0 and change != Vector2i.ZERO:
		return Style.WORSE
	return Style.MUTED

func _on_row_tapped(row: Control) -> void:
	if row.has_meta("key"):
		select(str(row.get_meta("key")))

func _equip_selected() -> void:
	if selected.is_empty():
		return
	var slot_name: String = GearCatalogScript.slot(selected)
	var changed: bool = sim.unequip_gear(selected) if sim.equipped_item(slot_name) == selected else sim.equip_gear(selected)
	if changed:
		refresh()
		gear_changed.emit()

func _sell_selected() -> void:
	if selected.is_empty() or game.is_locked(selected):
		return
	if bool(sim.sell_gear(selected).get("ok", false)):
		refresh()
		gear_changed.emit()

func _salvage_selected() -> void:
	if selected.is_empty() or game.is_locked(selected):
		return
	var result: Dictionary = sim.salvage_gear(selected)
	if bool(result.get("ok", false)):
		game.grant_tokens(int(result.get("tokens", 0)))
		refresh()
		gear_changed.emit()
