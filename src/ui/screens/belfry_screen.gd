extends Control

const Ui = preload("res://src/ui/widgets.gd")
const BelfryArt = preload("res://src/ui/belfry_art.gd")

var game
var main
var _page := "workshop"
var _signature := ""
var _last_tick := -1
var _wallet: Label
var _bonus: Label
var _notice: Label
var _art: Control
var _scroll: ScrollContainer
var _body: VBoxContainer
var _tabs := {}
var _upgrade_buttons := {}
var _claim_buttons := {}


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	box.add_child(Ui.label("THE BELLKEEPER'S WORK", 13, Ui.ThemeLib.DIM))
	var heading := HBoxContainer.new()
	box.add_child(heading)
	var title := Ui.label("THE BELFRY", 34, Ui.ThemeLib.BRONZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_wallet = Ui.label("", 16, Ui.ThemeLib.TEXT)
	_wallet.autowrap_mode = TextServer.AUTOWRAP_OFF
	_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_wallet)
	_art = BelfryArt.new()
	box.add_child(_art)
	_bonus = Ui.label("", 16, Ui.ThemeLib.BRONZE, true)
	box.add_child(_bonus)
	box.add_child(Ui.label("What returns from the road becomes a reason to return.", 15, Ui.ThemeLib.DIM, true))
	box.add_child(Ui.spacer(4))

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	for id in ["workshop", "milestones", "ledger"]:
		var button := Ui.button(id.to_upper(), "ghost", 16)
		button.custom_minimum_size.y = 50
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_page.bind(id))
		tabs.add_child(button)
		_tabs[id] = button

	_notice = Ui.label("", 15, Ui.ThemeLib.GOOD, true)
	_notice.visible = false
	box.add_child(_notice)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	_scroll.add_child(_body)
	_refresh()


func _select_page(id: String) -> void:
	_page = id
	_notice.visible = false
	_scroll.scroll_vertical = 0
	_refresh()


func tick(now: int) -> void:
	if now == _last_tick:
		return
	_last_tick = now
	if _state_signature() != _signature:
		_refresh()


func _state_signature() -> String:
	return JSON.stringify([game.hero()["gold"], game.hero()["shards"], game.state["belfry"], game.lifetime(), game.has_expedition()])


func _refresh() -> void:
	_signature = _state_signature()
	_wallet.text = "%d gold\n%d shards" % [int(game.hero()["gold"]), int(game.hero()["shards"])]
	var bonuses: Dictionary = game.belfry_bonuses()
	_bonus.text = "PERMANENT   ·   +%d MIGHT   ·   +%d WARD   ·   +%d LUCK" % [bonuses["might"], bonuses["ward"], bonuses["luck"]]
	_art.ranks = bonuses
	_art.queue_redraw()
	for id in _tabs:
		Ui.style_button(_tabs[id], "primary" if id == _page else "ghost")
	var ready: int = game.milestones_ready()
	_tabs["milestones"].text = "MILESTONES (%d)" % ready if ready > 0 else "MILESTONES"
	var scroll_position := _scroll.scroll_vertical
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_upgrade_buttons.clear()
	_claim_buttons.clear()
	match _page:
		"workshop":
			_build_workshop()
		"milestones":
			_build_milestones()
		"ledger":
			_build_ledger()
	_scroll.set_deferred("scroll_vertical", scroll_position)


func _card() -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Ui.ThemeLib.flat(Ui.ThemeLib.PANEL, 14, 18))
	_body.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 9)
	panel.add_child(inner)
	return inner


func _build_workshop() -> void:
	_body.add_child(Ui.label("RESTORE THE BELL-YARD", 15, Ui.ThemeLib.DIM))
	_body.add_child(Ui.label("Bonuses belong to the adventurer, not their gear. They survive every fall.", 15, Ui.ThemeLib.FAINT))
	if game.has_expedition():
		_body.add_child(Ui.label("Already on the road? This journey and its standing-order chain keep the old build. Send out again to use new upgrades.", 15, Ui.ThemeLib.DANGER))
	for row in game.upgrade_rows():
		var card := _card()
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 12)
		card.add_child(top)
		var name_label := Ui.label(str(row["name"]), 23, Ui.ThemeLib.TEXT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		var rank := int(row["rank"])
		var cap: int = row["costs"].size()
		var pips := Ui.label("◆".repeat(rank) + "◇".repeat(cap - rank), 19, Ui.ThemeLib.BRONZE)
		pips.autowrap_mode = TextServer.AUTOWRAP_OFF
		top.add_child(pips)
		card.add_child(Ui.label(str(row["text"]), 16, Ui.ThemeLib.DIM))
		card.add_child(Ui.label("RANK %d / %d  ·  +%d %s" % [rank, cap, rank, str(row["stat"]).to_upper()], 13, Ui.ThemeLib.BRONZE))
		var button := Ui.button("FULLY RESTORED", "ghost", 17)
		if not row["maxed"]:
			var cost: Dictionary = row["cost"]
			button.text = "RESTORE  ·  " + _price(cost)
			Ui.style_button(button, "primary" if row["affordable"] else "ghost")
			button.pressed.connect(_on_upgrade.bind(str(row["id"])))
		button.disabled = not row["affordable"]
		card.add_child(button)
		_upgrade_buttons[row["id"]] = button
		if not row["maxed"] and not row["affordable"]:
			card.add_child(Ui.label("Earn gold on the road; claim milestones or salvage loot for shards.", 13, Ui.ThemeLib.FAINT))


func _build_milestones() -> void:
	_body.add_child(Ui.label("PROMISES TO THE ROAD", 15, Ui.ThemeLib.DIM))
	_body.add_child(Ui.label("Always active. No timer, no expiry. Each reward can be claimed once.", 15, Ui.ThemeLib.FAINT))
	var rows: Array = game.milestone_rows()
	# Claimable first; unfinished next; completed promises remain in the ledger.
	rows.sort_custom(func(a, b):
		var a_order := 0 if a["ready"] else (2 if a["claimed"] else 1)
		var b_order := 0 if b["ready"] else (2 if b["claimed"] else 1)
		return a_order < b_order
	)
	for row in rows:
		var card := _card()
		card.add_child(Ui.label(str(row["name"]), 23, Ui.ThemeLib.GOOD if row["claimed"] else Ui.ThemeLib.TEXT))
		card.add_child(Ui.label(str(row["text"]), 16, Ui.ThemeLib.DIM))
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 6
		bar.show_percentage = false
		bar.max_value = int(row["target"])
		bar.value = int(row["progress"])
		bar.add_theme_stylebox_override("background", Ui.ThemeLib.flat(Ui.ThemeLib.BG, 3, 0))
		bar.add_theme_stylebox_override("fill", Ui.ThemeLib.flat(Ui.ThemeLib.BRONZE, 3, 0))
		card.add_child(bar)
		card.add_child(Ui.label("%d / %d   ·   %s" % [row["progress"], row["target"], _price(row)], 14, Ui.ThemeLib.BRONZE))
		var button := Ui.button("REWARD COLLECTED" if row["claimed"] else ("CLAIM REWARD" if row["ready"] else "IN PROGRESS"), "primary" if row["ready"] else "flat", 17)
		button.disabled = not row["ready"]
		button.pressed.connect(_on_claim.bind(str(row["id"])))
		card.add_child(button)
		_claim_buttons[row["id"]] = button


func _build_ledger() -> void:
	var rows: Array = game.collection_rows()
	var found: int = game.state["belfry"]["discoveries"].size()
	_body.add_child(Ui.label("THE FINDINGS LEDGER  ·  %d / %d" % [found, rows.size()], 17, Ui.ThemeLib.BRONZE))
	_body.add_child(Ui.label("Only things brought home are recorded. Sell, salvage, or wear them — their story stays here.", 15, Ui.ThemeLib.DIM))
	for row in rows:
		var card := _card()
		if row["discovered"]:
			card.add_child(Ui.label(str(row["name"]), 21, Ui.rarity_color(row)))
			card.add_child(Ui.label("%s · %s · %s" % [Ui.rarity_name(row), str(row["slot"]), Ui.item_stat_line(row)], 14, Ui.ThemeLib.DIM))
			if str(row.get("special_text", "")) != "":
				card.add_child(Ui.label(str(row["special_text"]), 15, Ui.ThemeLib.BRONZE))
			card.add_child(Ui.label(str(row.get("flavor", "")), 15, Ui.ThemeLib.FAINT))
		else:
			card.add_child(Ui.label("UNDISCOVERED " + str(row["slot"]).to_upper(), 17, Ui.ThemeLib.FAINT))
			var places: Array = []
			for zone_id in row.get("zones", []):
				places.append(str(game.content.get_zone(str(zone_id)).get("name", "the ash")))
			card.add_child(Ui.label("Seek it in " + ", ".join(places) if not places.is_empty() else "The Gravecho guards this story.", 14, Ui.ThemeLib.FAINT))


func _price(cost: Dictionary) -> String:
	var text := "%d GOLD" % int(cost.get("gold", 0))
	if int(cost.get("shards", 0)) > 0:
		text += " + %d SHARDS" % int(cost["shards"])
	return text


func _on_upgrade(id: String) -> void:
	var err: String = game.buy_upgrade(id)
	_feedback(err, "Restored. The next road begins a little stronger.")


func _on_claim(id: String) -> void:
	var err: String = game.claim_milestone(id)
	_feedback(err, "The bell remembers. Gold and shards added to your purse.")


func _feedback(err: String, success: String) -> void:
	_notice.text = success if err == "" else err
	_notice.add_theme_color_override("font_color", Ui.ThemeLib.GOOD if err == "" else Ui.ThemeLib.DANGER)
	_notice.visible = true
	if err == "":
		main.play_sfx("chime")
	_refresh()
