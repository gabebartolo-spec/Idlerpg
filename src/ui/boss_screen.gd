extends "res://src/ui/sheet.gd"

# The boss and hunts screen: what happened in the last fight with Old Thornback, what to
# change, and which world item the adventurer is hunting.
# Tapping a row only selects it; the pinned button acts on it.
#
# Presentation only. The explanation comes from src/sim/boss_advice.gd and every action
# goes through the simulation, then `build_changed` tells the scene to refresh and save.

signal build_changed
signal talents_requested

const BossAdviceScript = preload("res://src/sim/boss_advice.gd")
const BossCatalogScript = preload("res://src/data/boss_catalog.gd")
const HuntCatalogScript = preload("res://src/data/hunt_catalog.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")
const ArtCatalogScript = preload("res://src/data/art_catalog.gd")

const ADVICE_ROW := 112.0

var sim: Node
var selected: String = ""

var rows: Dictionary = {}
# What each row does when acted on: {"action", "target"}.
var row_actions: Dictionary = {}
var list: Control
var detail_text: Label
var act_button: Button
var refresh_clock: float = 0.0

func setup(sim_node: Node) -> void:
	sim = sim_node
	_build()
	refresh()

func select(key: String) -> void:
	if not row_actions.has(key):
		return
	selected = key
	restyle_rows(rows, selected)
	refresh_detail()

# Carries out the selected row. Returns false when there was nothing to do.
func act() -> bool:
	var entry: Dictionary = row_actions.get(selected, {})
	match str(entry.get("action", "")):
		"equip":
			if not sim.equip_gear(str(entry["target"])):
				return false
		"hunt":
			if not sim.set_hunt_target(str(entry["target"])):
				return false
		"talents":
			talents_requested.emit()
			return true
		_:
			return false
	selected = ""
	refresh()
	build_changed.emit()
	return true

func _build() -> void:
	var column := build_sheet("Boss and hunts")

	list = add_list(column)
	list.row_tapped.connect(func(row: Control) -> void: select(str(row.get_meta("key"))))
	add_line(column)

	detail_text = Style.label("", 19, Style.MUTED)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.custom_minimum_size = Vector2(0.0, 56.0)
	column.add_child(detail_text)

	act_button = Style.button("Choose", true)
	act_button.pressed.connect(act)
	column.add_child(act_button)

func refresh() -> void:
	if list == null:
		return
	var previous_action: Dictionary = row_actions.get(selected, {}).duplicate()
	subtitle_label.text = "%s · rank %d" % [BossCatalogScript.NAME, sim.thornback_rank]

	clear_list(list)
	rows.clear()
	row_actions.clear()

	var advice: Dictionary = BossAdviceScript.advise(sim)
	var fight_lines: Array[String] = [str(advice["headline"])]
	fight_lines.append_array(advice["facts"])
	var fight := Style.label("\n".join(fight_lines), 19)
	fight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(fight)

	var suggestions: Array = advice["suggestions"]
	if not suggestions.is_empty():
		list.content.add_child(Style.label("What would help", 20, Style.ACCENT))
	for index in suggestions.size():
		var suggestion: Dictionary = suggestions[index]
		var key := "advice:%d" % index
		var row := make_row(key, ADVICE_ROW)
		var words := Style.label(str(suggestion["text"]), 18)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(words)
		rows[key] = row
		row_actions[key] = {"action": suggestion["action"], "target": suggestion["target"]}
		list.content.add_child(row)

	list.content.add_child(Style.label("Hunts · one at a time", 20, Style.ACCENT))
	for hunt_id in HuntCatalogScript.hunt_ids():
		var key := "hunt:%s" % hunt_id
		var row := _hunt_row(key, hunt_id)
		rows[key] = row
		list.content.add_child(row)

	if not rows.has(selected):
		selected = ""
	elif not previous_action.is_empty() and row_actions.get(selected, {}) != previous_action:
		selected = ""
	restyle_rows(rows, selected)
	refresh_detail()

func _hunt_row(key: String, hunt_id: String) -> Control:
	var hunt: Dictionary = HuntCatalogScript.HUNTS[hunt_id]
	var item_name := str(hunt["item"])
	var owned: bool = sim.gear_count(item_name) > 0
	var hunting: bool = sim.hunt_target == hunt_id

	var row := make_row(key, ADVICE_ROW)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	row.add_child(line)
	add_icon(line, ArtCatalogScript.item_icon(item_name))

	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 2)
	line.add_child(words)
	var title := Style.label(item_name, 22, Style.rarity_colour(GearCatalogScript.rarity(item_name)))
	title.clip_text = true
	words.add_child(title)
	var about := Style.label("%s · %d%% a kill, certain by kill %d" % [
		hunt["enemy_label"], int(round(float(hunt["chance"]) * 100.0)), int(hunt["pity"])], 17, Style.MUTED)
	about.clip_text = true
	words.add_child(about)

	var state := Style.label("", 19, Style.MUTED)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if owned:
		state.text = "Owned"
		state.add_theme_color_override("font_color", Style.ACCENT)
	elif hunting:
		state.text = "Hunting\n%d / %d" % [sim.hunt_kills(hunt_id), int(hunt["pity"])]
		state.add_theme_color_override("font_color", Style.BETTER)
	else:
		state.text = "%d / %d" % [sim.hunt_kills(hunt_id), int(hunt["pity"])]
	line.add_child(state)

	if owned and sim.equipped_item(GearCatalogScript.slot(item_name)) != item_name:
		row_actions[key] = {"action": "equip", "target": item_name, "hunt": hunt_id}
	else:
		row_actions[key] = {"action": "" if owned or hunting else "hunt", "target": hunt_id, "hunt": hunt_id}
	return row

func refresh_detail() -> void:
	if detail_text == null:
		return
	act_button.disabled = true
	act_button.text = "Choose"
	if selected.is_empty():
		detail_text.text = "Tap a suggestion or a hunt. Hunts are earned by play and are never on a banner."
		return

	var entry: Dictionary = row_actions.get(selected, {})
	var action := str(entry.get("action", ""))
	if selected.begins_with("hunt:"):
		var hunt: Dictionary = HuntCatalogScript.HUNTS[str(entry.get("hunt", entry["target"]))]
		var item_name := str(hunt["item"])
		detail_text.text = "%s %s" % [GearCatalogScript.summary(item_name), GearCatalogScript.effect_text(item_name)]
		if sim.gear_count(item_name) > 0:
			act_button.text = "Owned"
		elif action.is_empty():
			act_button.text = "Hunting"
	else:
		detail_text.text = "Nothing to tap for this one." if action.is_empty() else "Tap the button to do this now."

	match action:
		"equip":
			act_button.text = "Equip %s" % str(entry["target"])
			act_button.disabled = false
		"hunt":
			act_button.text = "Hunt %s" % str(HuntCatalogScript.HUNTS[str(entry["target"])]["item"])
			act_button.disabled = false
		"talents":
			act_button.text = "Open talents"
			act_button.disabled = false

func _process(delta: float) -> void:
	if not is_visible_in_tree() or sim == null:
		return
	refresh_clock += delta
	if refresh_clock >= 1.0 and not list.is_interacting():
		refresh_clock = 0.0
		refresh()
