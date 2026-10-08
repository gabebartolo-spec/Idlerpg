extends "res://src/ui/sheet.gd"

# The gacha screen: summon from a banner, browse what has been collected, read history.
# One banner choice applies to summoning and the collection; history covers every banner.
#
# Presentation only. Pulls, favourites, locks and the active companion go through the game
# state and simulation; the signals tell the scene what to refresh and save.

signal summoned
signal companion_changed
signal collection_changed

const ArtCatalogScript = preload("res://src/data/art_catalog.gd")
const CompanionCatalogScript = preload("res://src/data/companion_catalog.gd")
const GearCatalogScript = preload("res://src/data/gear_catalog.gd")

const BANNERS := [["gear", "Gear"], ["companions", "Companions"], ["relics", "Relics"]]
const MODES := [["summon", "Summon"], ["collection", "Collection"], ["history", "History"]]
const RESULT_ROW := 64.0
# A big pull lists its notable results, not every common.
const MAX_HIGHLIGHTS := 30

var sim: Node
var game: Node
var banner: String = "gear"
var mode: String = "summon"
var selected_item: String = ""
var banner_results: Dictionary = {}
var collection_offsets: Dictionary = {}

var mode_tabs: Dictionary = {}
var banner_tabs: Dictionary = {}
var rows: Dictionary = {}
var summon_view: VBoxContainer
var collection_view: VBoxContainer
var history_view: VBoxContainer
var banner_label: Label
var results_list: Control
var summon_one: Button
var summon_ten: Button
var collection_list: Control
var history_list: Control
var detail_name: Label
var detail_text: Label
var use_button: Button
var favourite_button: Button
var lock_button: Button

func setup(sim_node: Node, game_node: Node) -> void:
	sim = sim_node
	game = game_node
	_build()
	_show_results("Pick a banner and summon.", [])
	refresh()

func show_mode(next_mode: String) -> void:
	mode = next_mode
	refresh()

func select_banner(banner_id: String) -> void:
	if banner_id == banner or not game.BANNERS.has(banner_id):
		return
	collection_offsets[banner] = collection_list.offset
	if banner_id != banner:
		selected_item = ""
		collection_list.scroll_to(0.0)
	banner = banner_id
	var result: Dictionary = banner_results.get(banner, {})
	_show_results(str(result.get("summary", "Pick a banner and summon.")), result.get("items", []))
	refresh()
	_restore_collection_position(banner_id)

func _restore_collection_position(banner_id: String) -> void:
	await get_tree().process_frame
	if banner == banner_id:
		collection_list.scroll_to(float(collection_offsets.get(banner_id, 0.0)))

func select_item(item_name: String) -> void:
	if game.collection_count(banner, item_name) <= 0:
		return
	selected_item = item_name
	restyle_rows(rows, selected_item)
	refresh_detail()

func refresh_wallet() -> void:
	if subtitle_label != null:
		subtitle_label.text = "Tokens: ∞ (dev)" if game.dev_infinite_tokens else "Tokens: %d" % game.gacha_tokens
	if summon_one != null:
		summon_one.disabled = not game.dev_infinite_tokens and game.gacha_tokens < game.SUMMON_COST
		summon_ten.disabled = not game.dev_infinite_tokens and game.gacha_tokens < game.SUMMON_COST * 10

func summon(count: int) -> void:
	var response: Dictionary = game.pull(banner, count)
	if not bool(response.get("ok", false)):
		_show_results(str(response.get("error", "Summon failed")), [])
		return

	var results: Array = response.get("results", [])
	var rarity_counts := {"Common": 0, "Rare": 0, "Epic": 0, "Legendary": 0}
	var highlights: Array = []
	var new_count := 0
	for result in results:
		var rarity: String = str(result.get("rarity", "Common"))
		var item_name: String = str(result.get("name", ""))
		var is_new: bool = bool(result.get("is_new", false))
		rarity_counts[rarity] = int(rarity_counts.get(rarity, 0)) + 1
		if is_new:
			new_count += 1
		if banner == "gear":
			sim.add_gear(item_name)
		if count <= 10 or is_new or rarity == "Epic" or rarity == "Legendary":
			highlights.append(result)

	var summary := "Pulled %d · %d new · %d common · %d rare · %d epic · %d legendary" % [
		results.size(), new_count, rarity_counts["Common"], rarity_counts["Rare"],
		rarity_counts["Epic"], rarity_counts["Legendary"]
	]
	banner_results[banner] = {"summary": summary, "items": highlights.duplicate(true)}
	_show_results(summary, highlights)
	refresh()
	summoned.emit()

func use_item() -> void:
	if banner != "companions" or selected_item.is_empty() or game.collection_count("companions", selected_item) <= 0:
		return
	if sim.active_companion == selected_item:
		sim.clear_active_companion()
	else:
		sim.set_active_companion(selected_item)
	refresh()
	companion_changed.emit()

func toggle_favourite() -> void:
	if selected_item.is_empty() or game.collection_count(banner, selected_item) <= 0:
		return
	game.set_favourite(selected_item, not game.is_favourite(selected_item))
	refresh()
	collection_changed.emit()

func toggle_lock() -> void:
	if selected_item.is_empty() or game.collection_count(banner, selected_item) <= 0:
		return
	game.set_locked(selected_item, not game.is_locked(selected_item))
	refresh()
	collection_changed.emit()

func _build() -> void:
	var column := build_sheet("Gacha", 0.30)
	mode_tabs = add_tabs(column, MODES, show_mode)
	banner_tabs = add_tabs(column, BANNERS, select_banner)
	banner_label = Style.label("", 19, Style.MUTED)
	banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(banner_label)

	summon_view = _view(column)
	results_list = add_list(summon_view)
	results_list.row_tapped.connect(_on_result_row)
	add_line(summon_view)
	var summon_row := HBoxContainer.new()
	summon_row.add_theme_constant_override("separation", 10)
	summon_view.add_child(summon_row)
	summon_one = Style.button("Summon ×1 · %d tokens" % game.SUMMON_COST)
	summon_one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summon_one.pressed.connect(summon.bind(1))
	summon_row.add_child(summon_one)
	summon_ten = Style.button("Summon ×10 · %d tokens" % (game.SUMMON_COST * 10), true)
	summon_ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summon_ten.pressed.connect(summon.bind(10))
	summon_row.add_child(summon_ten)

	collection_view = _view(column)
	collection_list = add_list(collection_view)
	collection_list.row_tapped.connect(_on_collection_row)
	add_line(collection_view)
	detail_name = Style.label("", 22)
	detail_name.clip_text = true
	collection_view.add_child(detail_name)
	detail_text = Style.label("", 19, Style.MUTED)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.custom_minimum_size = Vector2(0.0, 56.0)
	collection_view.add_child(detail_text)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	collection_view.add_child(actions)
	use_button = Style.button("Travel together", true)
	use_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	use_button.size_flags_stretch_ratio = 1.5
	use_button.pressed.connect(use_item)
	actions.add_child(use_button)
	favourite_button = Style.button("Favourite")
	favourite_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	favourite_button.pressed.connect(toggle_favourite)
	actions.add_child(favourite_button)
	lock_button = Style.button("Lock")
	lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_button.pressed.connect(toggle_lock)
	actions.add_child(lock_button)

	history_view = _view(column)
	history_list = add_list(history_view)

func _on_collection_row(row: Control) -> void:
	# Only things you own can be selected.
	var item_name := str(row.get_meta("key"))
	if game.collection_count(banner, item_name) > 0:
		select_item(item_name)

func _view(parent: Control) -> VBoxContainer:
	var view := VBoxContainer.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.add_theme_constant_override("separation", 12)
	parent.add_child(view)
	return view

func refresh() -> void:
	if summon_view == null:
		return
	refresh_wallet()
	mark_tabs(mode_tabs, mode)
	mark_tabs(banner_tabs, banner)
	summon_view.visible = mode == "summon"
	collection_view.visible = mode == "collection"
	history_view.visible = mode == "history"
	# History covers every banner, so the banner choice is hidden there.
	(banner_tabs[banner] as Control).get_parent().visible = mode != "history"
	banner_label.visible = mode != "history"

	var pity: int = game.pity_remaining(banner)
	banner_label.text = "%s · %d of %d collected · Legendary guaranteed within %d pull%s" % [
		game.banner_label(banner), game.collected_unique(banner), game.banner_item_count(banner),
		pity, "" if pity == 1 else "s"
	]
	var chances: Dictionary = game.RARITY_CHANCES
	banner_label.text += "\nBase odds: %d%% common · %d%% rare · %d%% epic · %d%% legendary" % [chances["Common"], chances["Rare"], chances["Epic"], chances["Legendary"]]
	if mode == "collection":
		_rebuild_collection()
	elif mode == "history":
		_rebuild_history()

func _show_results(summary: String, highlights: Array) -> void:
	clear_list(results_list)
	results_list.scroll_to(0.0)
	var headline := Style.label(summary, 20)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.custom_minimum_size = Vector2(0.0, RESULT_ROW)
	results_list.content.add_child(headline)
	for result in highlights.slice(0, MAX_HIGHLIGHTS):
		var rarity: String = str(result.get("rarity", "Common"))
		var item_name: String = str(result.get("name", ""))
		var row := make_row(item_name, RESULT_ROW)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		var title := Style.label(item_name, 21, Style.rarity_colour(rarity))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.clip_text = true
		line.add_child(title)
		line.add_child(Style.label("New · %s" % rarity if bool(result.get("is_new", false)) else "%s · copy %d" % [rarity, int(result.get("copy", 1))], 18, Style.MUTED))
		results_list.content.add_child(row)
	if highlights.size() > MAX_HIGHLIGHTS:
		results_list.content.add_child(Style.label("and %d more" % (highlights.size() - MAX_HIGHLIGHTS), 18, Style.MUTED))

func _icon(item_name: String) -> Texture2D:
	return ArtCatalogScript.companion_icon(item_name) if banner == "companions" else ArtCatalogScript.item_icon(item_name)

func _rebuild_collection() -> void:
	if not selected_item.is_empty() and game.collection_count(banner, selected_item) <= 0:
		selected_item = ""
	clear_list(collection_list)
	rows.clear()
	# What you own comes first; what is still to find follows, dimmed.
	var names: Array[String] = []
	for owned in [true, false]:
		for favourite in [true, false]:
			for item_name in game.collection_items(banner):
				if (game.collection_count(banner, item_name) > 0) == owned and game.is_favourite(item_name) == favourite:
					names.append(item_name)
	for item_name in names:
		var rarity: String = game.item_rarity(banner, item_name)
		var count: int = game.collection_count(banner, item_name)
		var row := make_row(item_name)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		add_icon(line, _icon(item_name))

		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", 2)
		line.add_child(words)
		var title := Style.label(item_name, 22, Style.rarity_colour(rarity) if count > 0 else Style.MUTED.darkened(0.25))
		title.clip_text = true
		words.add_child(title)
		var marks: Array[String] = [rarity]
		if game.is_favourite(item_name):
			marks.append("Favourite")
		if game.is_locked(item_name):
			marks.append("Locked")
		var about := Style.label(" · ".join(marks), 17, Style.MUTED if count > 0 else Style.MUTED.darkened(0.25))
		about.clip_text = true
		words.add_child(about)

		var state := Style.label("", 19, Style.MUTED)
		state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if count <= 0:
			state.text = "Not found yet"
			row.modulate = Color(1.0, 1.0, 1.0, 0.55)
		elif banner == "companions" and sim.active_companion == item_name:
			state.text = "With you"
			state.add_theme_color_override("font_color", Style.ACCENT)
		else:
			state.text = "×%d" % count
		line.add_child(state)

		rows[item_name] = row
		collection_list.content.add_child(row)
	restyle_rows(rows, selected_item)
	refresh_detail()

func refresh_detail() -> void:
	if detail_name == null:
		return
	var is_companion: bool = banner == "companions" and CompanionCatalogScript.has_companion(selected_item)
	use_button.visible = is_companion
	var owned: bool = not selected_item.is_empty() and game.collection_count(banner, selected_item) > 0
	favourite_button.disabled = not owned
	lock_button.disabled = not owned
	if not owned:
		detail_name.text = "Tap something you have collected"
		detail_name.add_theme_color_override("font_color", Style.MUTED)
		detail_text.text = "Favourites are marked in the list. Locked gear cannot be sold or salvaged."
		favourite_button.text = "Favourite"
		lock_button.text = "Lock"
		use_button.visible = false
		return

	detail_name.text = "%s · owned ×%d" % [selected_item, game.collection_count(banner, selected_item)]
	detail_name.add_theme_color_override("font_color", Style.rarity_colour(game.item_rarity(banner, selected_item)))
	if is_companion:
		detail_text.text = "%s · Bond %d. %s" % [
			CompanionCatalogScript.role(selected_item), sim.companion_bond_level(selected_item),
			CompanionCatalogScript.description(selected_item)
		]
		use_button.text = "Rest companion" if sim.active_companion == selected_item else "Travel together"
	else:
		detail_text.text = "%s from the %s." % [game.item_rarity(banner, selected_item), game.banner_label(banner)]
		if banner == "relics":
			detail_text.text += " Collection only: relics have no gameplay effect yet."
		if banner == "gear":
			detail_text.text = "+%d attack · +%d health" % [GearCatalogScript.attack_bonus(selected_item), GearCatalogScript.hp_bonus(selected_item)]
			var effect_text := GearCatalogScript.effect_text(selected_item)
			if not effect_text.is_empty():
				detail_text.text += "\n" + effect_text
	favourite_button.text = "Unfavourite" if game.is_favourite(selected_item) else "Favourite"
	lock_button.text = "Unlock" if game.is_locked(selected_item) else "Lock"

# Collection rows as shown, top to bottom.
func content_order() -> Array[String]:
	var order: Array[String] = []
	for row in collection_list.content.get_children():
		if row.has_meta("key"):
			order.append(str(row.get_meta("key")))
	return order

func _rebuild_history() -> void:
	clear_list(history_list)
	var history: Array[Dictionary] = game.recent_summons(40)
	if history.is_empty():
		history_list.content.add_child(Style.label("No summons yet.", 20, Style.MUTED))
	for entry in history:
		var rarity: String = str(entry.get("rarity", "Common"))
		var row := make_row(str(entry.get("name", "?")), RESULT_ROW)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		var title := Style.label(str(entry.get("name", "?")), 21, Style.rarity_colour(rarity))
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.clip_text = true
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_child(title)
		words.add_child(Style.label(game.banner_label(str(entry.get("banner", ""))), 17, Style.MUTED))
		line.add_child(words)
		var copy: int = int(entry.get("copy", 1))
		line.add_child(Style.label("New · %s" % rarity if bool(entry.get("is_new", false)) else "%s · copy %d" % [rarity, copy], 18, Style.MUTED))
		row.tooltip_text = game.banner_label(str(entry.get("banner", "")))
		history_list.content.add_child(row)

func _on_result_row(row: Control) -> void:
	if not row.has_meta("key"):
		return
	show_mode("collection")
	select_item(str(row.get_meta("key")))
