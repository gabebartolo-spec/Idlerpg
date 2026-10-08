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
var upgrades_first: bool = false
var worn_only: bool = false
var pending_disposal: String = ""
var confirmation_seconds: float = 0.0
var sort_button: Button
var worn_button: Button
var favourite_button: Button
var inventory_caption: String = ""

var list: Control
var stats_label: Label
var caption_label: Label
var detail_name: Label
var detail_compare: Label
var equip_button: Button
var sell_button: Button
var salvage_button: Button
var lock_button: Button
var slot_buttons: Dictionary = {}
var rows: Dictionary = {}

func setup(sim_node: Node, game_node: Node) -> void:
	sim = sim_node
	game = game_node
	_build()
	visibility_changed.connect(_cancel_disposal)
	refresh()

func select(item_name: String) -> void:
	if item_name not in visible_items():
		return
	_cancel_disposal()
	selected = item_name
	_restyle_rows()
	refresh_detail()

func set_slot_filter(slot_name: String) -> void:
	if not slot_name.is_empty() and slot_name not in SLOTS:
		return
	if slot_name == slot_filter:
		return
	slot_filter = slot_name
	_cancel_disposal()
	if not selected.is_empty() and not slot_name.is_empty() and GearCatalogScript.slot(selected) != slot_name:
		selected = ""
	list.scroll_to(0.0)
	refresh()

func visible_items() -> Array[String]:
	var names: Array[String] = []
	for item_name in sim.owned_gear_names():
		if slot_filter.is_empty() or GearCatalogScript.slot(item_name) == slot_filter:
			if worn_only and sim.equipped_item(GearCatalogScript.slot(item_name)) != item_name:
				continue
			names.append(item_name)
	names.sort_custom(_before)
	return names

func _before(a: String, b: String) -> bool:
	if upgrades_first:
		var delta_a := _change(a, str(sim.equipped_item(GearCatalogScript.slot(a))))
		var delta_b := _change(b, str(sim.equipped_item(GearCatalogScript.slot(b))))
		var better_a := delta_a.x >= 0 and delta_a.y >= 0 and delta_a != Vector2i.ZERO
		var better_b := delta_b.x >= 0 and delta_b.y >= 0 and delta_b != Vector2i.ZERO
		if better_a != better_b:
			return better_a
	if game.is_favourite(a) != game.is_favourite(b):
		return game.is_favourite(a)
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
	var column := build_sheet("Gear", 0.26)
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
		chip.tooltip_text = str(SLOT_LABELS[slot_name])
		chip.pressed.connect(set_slot_filter.bind(slot_name))
		slots.add_child(chip)
		slot_buttons[slot_name] = chip

	var browse := HBoxContainer.new()
	column.add_child(browse)
	sort_button = Style.button("By slot")
	sort_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort_button.pressed.connect(_toggle_sort)
	browse.add_child(sort_button)
	worn_button = Style.button("Show worn")
	worn_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	worn_button.pressed.connect(_toggle_worn)
	browse.add_child(worn_button)
	caption_label = Style.label("", 18, Style.MUTED)
	column.add_child(caption_label)

	list = add_list(column)
	list.row_tapped.connect(_on_row_tapped)
	add_line(column)

	# Comparison and actions stay pinned under the list, always within reach.
	var selection_row := HBoxContainer.new()
	column.add_child(selection_row)
	detail_name = Style.label("", 22)
	detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_name.clip_text = true
	selection_row.add_child(detail_name)
	favourite_button = Style.button("☆")
	favourite_button.custom_minimum_size.x = Style.TOUCH
	favourite_button.tooltip_text = "Favourite this item"
	favourite_button.pressed.connect(_toggle_favourite)
	selection_row.add_child(favourite_button)
	lock_button = Style.button("Lock")
	lock_button.pressed.connect(_toggle_lock)
	selection_row.add_child(lock_button)
	detail_compare = Style.label("", 19, Style.MUTED)
	detail_compare.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_compare.custom_minimum_size = Vector2(0.0, 56.0)
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
	if not selected.is_empty() and selected not in visible_items():
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
	inventory_caption = "%s · %d item%s" % [
		"All gear" if slot_filter.is_empty() else str(SLOT_LABELS[slot_filter]),
		names.size(),
		"" if names.size() == 1 else "s"
	]
	_refresh_balances()
	sort_button.text = "Upgrades first" if upgrades_first else "By slot"
	worn_button.text = "Show all" if worn_only else "Show worn"

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
	if game.is_locked(item_name):
		about.text = "Locked · " + about.text
	if game.is_favourite(item_name):
		about.text = "★ " + about.text
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
	favourite_button.disabled = not has_item
	favourite_button.text = "★" if has_item and game.is_favourite(selected) else "☆"
	lock_button.disabled = not has_item
	lock_button.text = "Unlock" if has_item and game.is_locked(selected) else "Lock"
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
	detail_name.text = "%s ×%d · %s" % [selected, sim.gear_count(selected), _stats(selected)]
	detail_name.tooltip_text = GearCatalogScript.source_text(selected)
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
	elif not sim.can_dispose_gear(selected):
		detail_compare.text += " · Take off before disposing of your last copy"
	var effect_text: String = GearCatalogScript.effect_text(selected)
	if not effect_text.is_empty():
		detail_compare.text += "\n" + effect_text
	var source_text := GearCatalogScript.source_text(selected)
	if not source_text.is_empty():
		detail_compare.text += "\nSource: " + source_text

	equip_button.text = "Take off" if is_worn else "Equip"
	sell_button.text = "Sell +%dg" % GearCatalogScript.sell_value(selected)
	salvage_button.text = "Salvage +%d" % GearCatalogScript.salvage_tokens(selected)
	var can_dispose: bool = sim.can_dispose_gear(selected) and not locked
	sell_button.disabled = not can_dispose
	salvage_button.disabled = not can_dispose or GearCatalogScript.salvage_tokens(selected) <= 0
	if GearCatalogScript.salvage_tokens(selected) <= 0:
		salvage_button.text = "No tokens"
		salvage_button.tooltip_text = "World loot gives no salvage tokens. Sell it for gold instead."
	else:
		salvage_button.tooltip_text = ""
	if pending_disposal == "sell":
		sell_button.text = "Confirm sell"
	elif pending_disposal == "salvage":
		salvage_button.text = "Confirm salvage"

func _stats(item_name: String) -> String:
	var parts: Array[String] = []
	if GearCatalogScript.attack_bonus(item_name) > 0:
		parts.append("+%d attack" % GearCatalogScript.attack_bonus(item_name))
	if GearCatalogScript.hp_bonus(item_name) > 0:
		parts.append("+%d health" % GearCatalogScript.hp_bonus(item_name))
	var effect_id: String = GearCatalogScript.effect(item_name)
	if not effect_id.is_empty():
		parts.append(str(GearCatalogScript.EFFECTS[effect_id]["name"]))
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
	if selected.is_empty() or game.is_locked(selected) or not sim.can_dispose_gear(selected):
		return
	if not _confirm_disposal("sell"):
		return
	if bool(sim.sell_gear(selected).get("ok", false)):
		refresh()
		gear_changed.emit()

func _salvage_selected() -> void:
	if selected.is_empty() or game.is_locked(selected) or not sim.can_dispose_gear(selected) or GearCatalogScript.salvage_tokens(selected) <= 0:
		return
	if not _confirm_disposal("salvage"):
		return
	var result: Dictionary = sim.salvage_gear(selected)
	if bool(result.get("ok", false)):
		game.grant_tokens(int(result.get("tokens", 0)))
		refresh()
		gear_changed.emit()

func _toggle_lock() -> void:
	if selected.is_empty() or sim.gear_count(selected) <= 0:
		return
	game.set_locked(selected, not game.is_locked(selected))
	_cancel_disposal()
	refresh()
	gear_changed.emit()

func _toggle_favourite() -> void:
	if selected.is_empty() or sim.gear_count(selected) <= 0:
		return
	game.set_favourite(selected, not game.is_favourite(selected))
	refresh()
	gear_changed.emit()

func _toggle_sort() -> void:
	upgrades_first = not upgrades_first
	_cancel_disposal()
	list.scroll_to(0.0)
	refresh()

func _toggle_worn() -> void:
	worn_only = not worn_only
	_cancel_disposal()
	list.scroll_to(0.0)
	refresh()

func _confirm_disposal(action: String) -> bool:
	if GearCatalogScript.rarity(selected) not in ["Epic", "Legendary"]:
		return true
	if pending_disposal == action and confirmation_seconds > 0.0:
		pending_disposal = ""
		confirmation_seconds = 0.0
		return true
	pending_disposal = action
	confirmation_seconds = 5.0
	refresh_detail()
	return false

func _cancel_disposal() -> void:
	pending_disposal = ""
	confirmation_seconds = 0.0
	if detail_name != null:
		refresh_detail()

func _refresh_balances() -> void:
	caption_label.text = inventory_caption + " · Gold %d · Tokens %s" % [sim.gold, "∞" if game.dev_infinite_tokens else str(game.gacha_tokens)]

func _process(delta: float) -> void:
	if not is_visible_in_tree() or sim == null:
		return
	_refresh_balances()
	if confirmation_seconds > 0.0:
		confirmation_seconds -= delta
		if confirmation_seconds <= 0.0:
			_cancel_disposal()
