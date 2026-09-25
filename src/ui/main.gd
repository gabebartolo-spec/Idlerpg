extends Control

const ContentRepository = preload("res://src/sim/content_repository.gd")
const GameStore = preload("res://src/state/game_store.gd")
const Simulator = preload("res://src/sim/expedition_simulator.gd")

const BG := Color(0.035, 0.043, 0.067, 1.0)
const SURFACE := Color(0.075, 0.090, 0.135, 1.0)
const SURFACE_ALT := Color(0.105, 0.125, 0.180, 1.0)
const BORDER := Color(0.180, 0.220, 0.310, 1.0)
const TEXT := Color(0.920, 0.940, 0.980, 1.0)
const MUTED := Color(0.620, 0.680, 0.780, 1.0)
const ACCENT := Color(0.420, 0.820, 0.690, 1.0)
const GOLD := Color(0.960, 0.770, 0.330, 1.0)
const DANGER := Color(0.980, 0.400, 0.390, 1.0)
const LOOT := Color(0.800, 0.570, 1.000, 1.0)
const COMMON := Color(0.700, 0.750, 0.820, 1.0)
const UNCOMMON := Color(0.360, 0.900, 0.610, 1.0)
const RARE := Color(0.820, 0.550, 1.000, 1.0)
const ONBOARDING_COPY := (
	"Your adventurer will travel, fight, find things, and return with a story.\n"
	+ "There is no perfect first choice. The interesting part is seeing what your preparation changes."
)
const DEBUG_COPY := (
	"Developer controls below can advance time without changing the production simulation. "
	+ "Close and reopen the app at any point; the saved departure timestamp is the source of truth."
)
const REPORT_APPLIED_COPY := (
	"The report is already applied safely to the saved state; "
	+ "reviewing it cannot duplicate rewards."
)

var content_repository
var store
var body: VBoxContainer
var header_status: Label
var developer_status: Label
var name_input: LineEdit
var refresh_timer: Timer


func _ready() -> void:
	content_repository = ContentRepository.new()
	store = GameStore.new(content_repository)
	_build_shell()
	_refresh()


func _build_shell() -> void:
	var background := ColorRect.new()
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 64)
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var title := _label("BRAMBLEWILD", 26, TEXT)
	title_box.add_child(title)
	var subtitle := _label("A little adventurer's life between check-ins", 13, MUTED)
	title_box.add_child(subtitle)

	header_status = _label("", 14, ACCENT)
	header_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_status.custom_minimum_size = Vector2(190, 0)
	header.add_child(header_status)

	var separator := HSeparator.new()
	separator.modulate = BORDER
	layout.add_child(separator)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)

	var dev_panel := _panel()
	dev_panel.custom_minimum_size = Vector2(0, 62)
	layout.add_child(dev_panel)
	var dev_box := VBoxContainer.new()
	dev_box.add_theme_constant_override("separation", 6)
	dev_panel.add_child(dev_box)
	var dev_header := HBoxContainer.new()
	dev_box.add_child(dev_header)
	var dev_title := _label("DEVELOPER CONTROLS", 11, MUTED)
	dev_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dev_header.add_child(dev_title)
	developer_status = _label("", 11, MUTED)
	developer_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dev_header.add_child(developer_status)

	var dev_buttons := HBoxContainer.new()
	dev_buttons.add_theme_constant_override("separation", 6)
	dev_box.add_child(dev_buttons)
	for button_data in [
		{"text": "+1 minute", "seconds": 60},
		{"text": "+5 minutes", "seconds": 300},
		{"text": "+15 minutes", "seconds": 900},
		{"text": "+1 day", "seconds": 86400}
	]:
		var advance_button := _button(str(button_data.text), false)
		advance_button.pressed.connect(_on_advance_time.bind(int(button_data.seconds)))
		dev_buttons.add_child(advance_button)
	var reset_button := _button("Reset prototype", true)
	reset_button.pressed.connect(_on_reset_prototype)
	dev_buttons.add_child(reset_button)

	refresh_timer = Timer.new()
	refresh_timer.wait_time = 1.0
	refresh_timer.autostart = true
	refresh_timer.timeout.connect(_on_refresh_timer)
	add_child(refresh_timer)


func _refresh() -> void:
	if body == null:
		return
	store.refresh()
	for child in body.get_children():
		child.free()

	if store.is_new_game():
		_render_onboarding()
	elif not store.get_pending_report().is_empty():
		_render_report()
	elif not store.get_active_expedition().is_empty():
		_render_away()
	else:
		_render_camp()
	_update_header()


func _update_header() -> void:
	if store.is_new_game():
		header_status.text = "Create an adventurer"
		developer_status.text = "Time controls are active for rapid testing"
		return
	var adventurer: Dictionary = store.get_adventurer()
	if not store.get_pending_report().is_empty():
		header_status.text = "RETURN REPORT READY"
	elif not store.get_active_expedition().is_empty():
		header_status.text = (
			"AWAY · %s"
			% store.get_route(str(store.get_active_expedition().get("route_id", ""))).get(
				"name", "route"
			)
		)
	else:
		header_status.text = "AT CAMP · LEVEL %d" % int(adventurer.get("level", 1))
	developer_status.text = (
		"Debug clock: +%s" % Simulator.format_duration(store.debug_offset_seconds)
	)


func _render_onboarding() -> void:
	body.add_child(
		_section_title("Give the adventurer a name", "Then choose a road and leave them to it.")
	)
	var card := _panel()
	card.custom_minimum_size = Vector2(0, 230)
	body.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	box.add_child(_label(ONBOARDING_COPY, 16, TEXT))
	name_input = LineEdit.new()
	name_input.placeholder_text = "Adventurer name (for example, Sable)"
	name_input.custom_minimum_size = Vector2(0, 48)
	name_input.add_theme_font_size_override("font_size", 16)
	name_input.text_submitted.connect(_on_name_submitted)
	box.add_child(name_input)
	var create_button := _button("Begin at Bramblewild", false)
	create_button.custom_minimum_size = Vector2(0, 48)
	create_button.pressed.connect(_on_create_pressed)
	box.add_child(create_button)
	name_input.grab_focus.call_deferred()


func _render_camp() -> void:
	var adventurer: Dictionary = store.get_adventurer()
	var stats: Dictionary = store.get_current_stats()
	body.add_child(
		_section_title("Camp", "Decide what kind of story the next departure might become.")
	)

	var character_card := _panel()
	body.add_child(character_card)
	var character_box := VBoxContainer.new()
	character_box.add_theme_constant_override("separation", 8)
	character_card.add_child(character_box)
	var character_header := HBoxContainer.new()
	character_box.add_child(character_header)
	var character_name := _label(str(adventurer.get("name", "Adventurer")), 23, TEXT)
	character_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_header.add_child(character_name)
	character_header.add_child(_label("Level %d" % int(adventurer.get("level", 1)), 18, ACCENT))
	character_box.add_child(
		_label(
			(
				"XP %d · %s to next level · %d gold"
				% [
					int(adventurer.get("xp", 0)),
					_format_xp_to_next(adventurer),
					int(adventurer.get("gold", 0))
				]
			),
			13,
			MUTED
		)
	)
	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 8)
	character_box.add_child(stat_row)
	stat_row.add_child(
		_stat_card("STRIKE", int(stats.get("strike", 0)), "finish fights sooner", ACCENT)
	)
	stat_row.add_child(
		_stat_card(
			"GUARD", int(stats.get("guard", 0)), "survive danger", Color(0.450, 0.700, 0.950, 1)
		)
	)
	stat_row.add_child(
		_stat_card("FORTUNE", int(stats.get("fortune", 0)), "notice better finds", GOLD)
	)

	body.add_child(
		_section_title("Equipped for the next story", "No single score decides what is best.")
	)
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 8)
	body.add_child(equipment_row)
	for slot in ["weapon", "armor", "trinket"]:
		var item_id := str(adventurer.get("equipment", {}).get(slot, ""))
		equipment_row.add_child(_item_card(item_id, "%s · equipped" % slot.capitalize(), false, ""))

	if not adventurer.get("inventory", []).is_empty():
		body.add_child(_section_title("Pack", "New items are choices, not automatic upgrades."))
		for item_id in adventurer.inventory:
			body.add_child(_inventory_row(str(item_id)))

	body.add_child(
		_section_title(
			"Choose the next objective", "The route tells you what kind of risk you are accepting."
		)
	)
	for route in store.get_routes():
		body.add_child(_route_card(route))

	body.add_child(
		_section_title(
			"Recent expedition history", "The adventurer's story persists between departures."
		)
	)
	var history: Array = store.get_history()
	if history.is_empty():
		body.add_child(
			_panel_with_text(
				"No chapters yet. The first one starts when you choose a route.", MUTED
			)
		)
	else:
		for index in range(history.size() - 1, -1, -1):
			var entry: Dictionary = history[index]
			body.add_child(_history_row(entry))


func _render_away() -> void:
	var active: Dictionary = store.get_active_expedition()
	var route: Dictionary = store.get_route(str(active.get("route_id", "")))
	var elapsed := store.active_elapsed_seconds()
	var remaining := store.active_remaining_seconds()
	body.add_child(
		_section_title(
			"While you were away",
			"The simulation resolves at meaningful event boundaries, not every second."
		)
	)
	var card := _panel()
	body.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	box.add_child(
		_label(
			(
				"%s is out on %s"
				% [
					str(store.get_adventurer().get("name", "The adventurer")),
					str(route.get("name", "the road"))
				]
			),
			22,
			TEXT
		)
	)
	box.add_child(_label(str(route.get("tagline", "The expedition is underway.")), 14, MUTED))
	box.add_child(
		_label(
			(
				"Elapsed: %s / %s"
				% [
					Simulator.format_duration(elapsed),
					Simulator.format_duration(int(route.get("duration_seconds", 0)))
				]
			),
			15,
			ACCENT
		)
	)
	if remaining > 0:
		box.add_child(
			_label(
				(
					"The next report will be ready in approximately %s."
					% Simulator.format_duration(remaining)
				),
				14,
				MUTED
			)
		)
	else:
		box.add_child(_label("The route is complete. Check the return report.", 14, LOOT))
	var check_button := _button("Check expedition", false)
	check_button.pressed.connect(_refresh)
	box.add_child(check_button)

	body.add_child(_panel_with_text(DEBUG_COPY, MUTED))


func _render_report() -> void:
	var report: Dictionary = store.get_pending_report()
	var outcome_color := ACCENT if str(report.get("outcome", "")) == "complete" else DANGER
	body.add_child(
		_section_title(
			"Welcome back",
			"The important part is not only what was earned, but what actually happened."
		)
	)

	var headline_card := _panel()
	body.add_child(headline_card)
	var headline_box := VBoxContainer.new()
	headline_box.add_theme_constant_override("separation", 8)
	headline_card.add_child(headline_box)
	headline_box.add_child(
		_label(str(report.get("headline", "The expedition is over.")), 24, outcome_color)
	)
	headline_box.add_child(_label(str(report.get("summary", "")), 15, TEXT))
	headline_box.add_child(
		_label(
			(
				"%s · %s · %s"
				% [
					str(report.get("zone", "Bramblewild")),
					str(report.get("route_name", "route")),
					Simulator.format_duration(int(report.get("elapsed_seconds", 0)))
				]
			),
			13,
			MUTED
		)
	)

	body.add_child(
		_section_title(
			"What happened",
			"Every line below is generated from the resolved route stages and rolls."
		)
	)
	for event in report.get("events", []):
		body.add_child(_event_row(event))

	body.add_child(_section_title("What changed", REPORT_APPLIED_COPY))
	var reward_card := _panel()
	body.add_child(reward_card)
	var reward_box := VBoxContainer.new()
	reward_box.add_theme_constant_override("separation", 6)
	reward_card.add_child(reward_box)
	reward_box.add_child(
		_label(
			(
				"+%d XP     +%d gold     %d encounter%s won"
				% [
					int(report.get("xp_gained", 0)),
					int(report.get("gold_gained", 0)),
					int(report.get("encounters_won", 0)),
					"" if int(report.get("encounters_won", 0)) == 1 else "s"
				]
			),
			16,
			GOLD
		)
	)
	if not report.get("level_ups", []).is_empty():
		reward_box.add_child(
			_label("Level up: now Level %d" % int(report.get("new_level", 1)), 16, ACCENT)
		)
	else:
		reward_box.add_child(
			_label(
				(
					"Level %d · %d danger moment%s"
					% [
						int(report.get("new_level", 1)),
						int(report.get("danger_moments", 0)),
						"" if int(report.get("danger_moments", 0)) == 1 else "s"
					]
				),
				13,
				MUTED
			)
		)

	body.add_child(
		_section_title(
			"Discoveries",
			"Compare the context of a find before deciding whether it belongs in the next story."
		)
	)
	var items: Array = report.get("items", [])
	if items.is_empty():
		body.add_child(
			_panel_with_text(
				"No equipment came home this time. The experience and story still count.", MUTED
			)
		)
	else:
		for item_entry in items:
			body.add_child(_report_item_row(item_entry))

	var continue_button := _button("Continue to camp", false)
	continue_button.custom_minimum_size = Vector2(0, 48)
	continue_button.pressed.connect(_on_claim_report)
	body.add_child(continue_button)


func _route_card(route: Dictionary) -> Control:
	var route_id := str(route.get("id", ""))
	var card := _panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	card.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := _label(str(route.get("name", "Route")), 20, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(
		_label(
			str(route.get("danger", "Unknown danger")),
			14,
			_danger_color(str(route.get("danger", "")))
		)
	)
	box.add_child(_label(str(route.get("tagline", "")), 14, MUTED))
	box.add_child(
		_label(
			(
				"%s · Focus: %s"
				% [
					Simulator.format_duration(int(route.get("duration_seconds", 0))),
					str(route.get("reward_focus", "rewards"))
				]
			),
			13,
			GOLD
		)
	)
	box.add_child(_label(str(route.get("risk_hint", "")), 13, TEXT))
	var preview: Dictionary = store.preview_route(route_id)
	box.add_child(_label("Why this might fit: %s" % str(preview.get("fit", "")), 12, MUTED))
	var send_button := _button("Send %s" % str(route.get("name", "the adventurer")), false)
	send_button.pressed.connect(_on_route_selected.bind(route_id))
	box.add_child(send_button)
	return card


func _inventory_row(item_id: String) -> Control:
	var item: Dictionary = store.get_item(item_id)
	var panel := _panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(
		_label(
			"%s · %s" % [str(item.get("name", item_id)), str(item.get("rarity", "Common"))],
			16,
			_rarity_color(str(item.get("rarity", "Common")))
		)
	)
	info.add_child(
		_label("%s · %s" % [_item_stats_text(item), str(item.get("description", ""))], 12, MUTED)
	)
	var equip_button := _button("Equip", false)
	equip_button.pressed.connect(_on_equip_item.bind(item_id))
	row.add_child(equip_button)
	var sell_button := _button("Sell +%dg" % int(item.get("sell_value", 0)), true)
	sell_button.pressed.connect(_on_sell_item.bind(item_id))
	row.add_child(sell_button)
	return panel


func _report_item_row(item_entry: Dictionary) -> Control:
	var item_id := str(item_entry.get("item_id", ""))
	var item: Dictionary = store.get_item(item_id)
	var panel := _panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var rarity := str(item.get("rarity", "Common"))
	var title := _label(
		"%s · %s" % [str(item.get("name", item_id)), rarity], 18, _rarity_color(rarity)
	)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(
		_label("Found in %s" % str(item_entry.get("source", "the expedition")), 12, MUTED)
	)
	box.add_child(_label(str(item.get("description", "")), 13, TEXT))
	box.add_child(_label("Why it matters: %s" % str(item.get("identity", "")), 12, MUTED))
	box.add_child(_label(_item_stats_text(item), 14, GOLD))
	box.add_child(_label(_comparison_text(item_id), 13, ACCENT))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	if store.inventory_count(item_id) > 0:
		var equip_button := _button("Equip this item", false)
		equip_button.pressed.connect(_on_equip_item.bind(item_id))
		actions.add_child(equip_button)
		var sell_button := _button("Sell for %dg" % int(item.get("sell_value", 0)), true)
		sell_button.pressed.connect(_on_sell_item.bind(item_id))
		actions.add_child(sell_button)
	else:
		actions.add_child(_label("This item is equipped or has already been sold.", 13, MUTED))
	return panel


func _event_row(event: Dictionary) -> Control:
	var tone := str(event.get("tone", "neutral"))
	var accent := ACCENT
	if tone == "danger":
		accent = DANGER
	elif tone == "loot":
		accent = LOOT
	elif tone == "neutral":
		accent = Color(0.450, 0.650, 0.850, 1)
	var panel := _panel()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(_label(str(event.get("kind", "event")).to_upper(), 11, accent))
	box.add_child(_label(str(event.get("text", "Something happened.")), 15, TEXT))
	box.add_child(
		_label(
			"CAUSE · %s" % str(event.get("evidence", "The simulation moved to the next stage.")),
			12,
			MUTED
		)
	)
	return panel


func _history_row(entry: Dictionary) -> Control:
	var panel := _panel()
	panel.add_theme_stylebox_override("panel", _style(SURFACE, Color(0.130, 0.170, 0.235, 1)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	row.add_child(
		_label(
			str(entry.get("kind", "event")).to_upper(),
			10,
			_tone_color(str(entry.get("tone", "neutral")))
		)
	)
	var text := _label(str(entry.get("text", "")), 13, TEXT)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return panel


func _item_card(item_id: String, caption: String, actions: bool, source: String) -> Control:
	var item: Dictionary = store.get_item(item_id)
	var panel := _panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(_label(caption.to_upper(), 10, MUTED))
	box.add_child(
		_label(str(item.get("name", item_id)), 16, _rarity_color(str(item.get("rarity", "Common"))))
	)
	box.add_child(_label(_item_stats_text(item), 13, GOLD))
	box.add_child(_label(str(item.get("identity", "")), 12, MUTED))
	if not source.is_empty():
		box.add_child(_label(source, 11, MUTED))
	if actions:
		var equip_button := _button("Equip", false)
		equip_button.pressed.connect(_on_equip_item.bind(item_id))
		box.add_child(equip_button)
	return panel


func _stat_card(stat_name: String, value: int, explanation: String, accent: Color) -> Control:
	var panel := _panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(SURFACE_ALT, accent.darkened(0.65)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	box.add_child(_label(stat_name, 11, accent))
	box.add_child(_label(str(value), 22, TEXT))
	box.add_child(_label(explanation, 11, MUTED))
	return panel


func _section_title(title_text: String, subtitle_text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_label(title_text, 19, TEXT))
	box.add_child(_label(subtitle_text, 12, MUTED))
	return box


func _panel_with_text(text: String, color: Color) -> Control:
	var panel := _panel()
	panel.add_child(_label(text, 14, color))
	return panel


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(SURFACE, BORDER))
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text: String, subdued: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	var normal_color := SURFACE_ALT if subdued else Color(0.150, 0.300, 0.285, 1)
	var hover_color := (
		Color(0.190, 0.370, 0.340, 1) if not subdued else Color(0.150, 0.180, 0.240, 1)
	)
	button.add_theme_stylebox_override("normal", _style(normal_color, BORDER, 8))
	button.add_theme_stylebox_override("hover", _style(hover_color, ACCENT, 8))
	button.add_theme_stylebox_override("pressed", _style(hover_color.darkened(0.15), ACCENT, 8))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	return button


func _style(background_color: Color, border_color: Color, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _item_stats_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	var stats: Dictionary = item.get("stats", {})
	for stat_name in ["strike", "guard", "fortune"]:
		var value := int(stats.get(stat_name, 0))
		if value != 0:
			parts.append("%s %s%d" % [stat_name.capitalize(), "+" if value > 0 else "", value])
	if parts.is_empty():
		return "No visible stat bonus"
	return " · ".join(parts)


func _comparison_text(item_id: String) -> String:
	var item: Dictionary = store.get_item(item_id)
	var slot := str(item.get("slot", ""))
	var equipped_id := str(store.get_adventurer().get("equipment", {}).get(slot, ""))
	var equipped: Dictionary = store.get_item(equipped_id)
	var deltas: Array[String] = []
	for stat_name in ["strike", "guard", "fortune"]:
		var delta := (
			int(item.get("stats", {}).get(stat_name, 0))
			- int(equipped.get("stats", {}).get(stat_name, 0))
		)
		if delta != 0:
			deltas.append("%s %s%d" % [stat_name.capitalize(), "+" if delta > 0 else "", delta])
	if deltas.is_empty():
		return "Compared with the equipped %s: the visible stats are the same." % slot
	return (
		"Compared with the equipped %s: %s. Choose the consequence, not a single score."
		% [slot, " · ".join(deltas)]
	)


func _format_xp_to_next(adventurer: Dictionary) -> String:
	var level := int(adventurer.get("level", 1))
	var xp := int(adventurer.get("xp", 0))
	var remaining := store.simulator.xp_to_next_level(xp, level)
	return "max level" if remaining == 0 else "%d XP" % remaining


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Rare":
			return RARE
		"Uncommon":
			return UNCOMMON
	return COMMON


func _danger_color(danger: String) -> Color:
	match danger:
		"High":
			return DANGER
		"Medium":
			return GOLD
	return ACCENT


func _tone_color(tone: String) -> Color:
	match tone:
		"danger":
			return DANGER
		"loot":
			return LOOT
		"good":
			return ACCENT
	return MUTED


func _on_name_submitted(_text: String) -> void:
	_on_create_pressed()


func _on_create_pressed() -> void:
	if name_input != null and store.create_adventurer(name_input.text):
		_refresh()


func _on_route_selected(route_id: String) -> void:
	if store.start_expedition(route_id):
		_refresh()


func _on_claim_report() -> void:
	store.claim_report()
	_refresh()


func _on_equip_item(item_id: String) -> void:
	store.equip_item(item_id)
	_refresh()


func _on_sell_item(item_id: String) -> void:
	store.sell_item(item_id)
	_refresh()


func _on_advance_time(seconds: int) -> void:
	store.advance_debug_time(seconds)
	_refresh()


func _on_reset_prototype() -> void:
	store.reset_prototype()
	_refresh()


func _on_refresh_timer() -> void:
	if not store.get_active_expedition().is_empty():
		_refresh()
