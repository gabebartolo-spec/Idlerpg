extends Control

# ZONE CHOICE — the risk/reward decision. Three roads, one depth, no advice.
# The game shows what is true; it does not tell the player what to do.

const Ui = preload("res://src/ui/widgets.gd")
const ExpeditionLib = preload("res://src/sim/expedition.gd")

var game
var main

var _rows := {}
var _selected_zone := ""
var _selected_depth := 3
var _depth_buttons := {}
var _send_button: Button
var _seal_note: Label


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_right = -24
	box.offset_top = 20
	box.offset_bottom = -20
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var back := Ui.small_button("‹  THE BELL", "flat")
	back.custom_minimum_size = Vector2(120, 44)
	back.pressed.connect(func(): main.pop_screen())
	var back_wrap := HBoxContainer.new()
	back_wrap.add_child(back)
	box.add_child(back_wrap)

	box.add_child(Ui.label("WHERE DOES THE ROAD GO?", 24, Ui.ThemeLib.BRONZE))
	box.add_child(Ui.spacer(4))

	for zone in game.content.all_zones():
		box.add_child(_build_zone_row(zone))
		box.add_child(Ui.spacer(2))

	box.add_child(Ui.spacer(8))
	box.add_child(Ui.label("HOW DEEP BEFORE THEY TURN BACK?", 16, Ui.ThemeLib.DIM))
	var depth_row := HBoxContainer.new()
	depth_row.add_theme_constant_override("separation", 10)
	box.add_child(depth_row)
	for depth in range(game.DEPTH_MIN, game.DEPTH_MAX + 1):
		var b := Ui.button(str(depth), "ghost", 22)
		b.custom_minimum_size = Vector2(64, 60)
		b.pressed.connect(_on_depth.bind(depth))
		depth_row.add_child(b)
		_depth_buttons[depth] = b
	var est := Ui.label("", 15, Ui.ThemeLib.DIM)
	est.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	est.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	est.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	depth_row.add_child(est)
	_est_label = est

	var standing := game.standing()
	var standing_btn := Ui.button("", "ghost")
	standing_btn.toggle_mode = true
	standing_btn.button_pressed = bool(standing.get("enabled", false))
	standing_btn.toggled.connect(_on_standing)
	standing_btn.custom_minimum_size = Vector2(0, 52)
	_standing_button = standing_btn
	_sync_standing_text()
	box.add_child(standing_btn)

	var flex := Ui.spacer(4)
	flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(flex)

	_seal_note = Ui.label("", 15, Ui.ThemeLib.DANGER, true)
	box.add_child(_seal_note)

	_send_button = Ui.button("SEND THEM OUT", "primary", 24)
	_send_button.pressed.connect(_on_send)
	box.add_child(_send_button)

	# restore last choice as the default
	_selected_zone = str(standing.get("zone_id", "marrowfields"))
	_selected_depth = int(standing.get("depth", 3))
	_sync_selection()


var _est_label: Label
var _standing_button: Button


func _build_zone_row(zone: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 96)
	Ui.style_button(b, "flat")
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 16
	inner.offset_right = -16
	inner.offset_top = 10
	inner.offset_bottom = -10
	inner.add_theme_constant_override("separation", 2)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)

	var top := HBoxContainer.new()
	inner.add_child(top)
	var name_label := Ui.label(str(zone["name"]).to_upper(), 20, Ui.ThemeLib.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var danger := int(zone["danger_base"])
	var danger_label := Ui.label("danger  ", 14, Ui.ThemeLib.DIM)
	danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(danger_label)
	top.add_child(Ui.label(_danger_pips(danger), 15, Ui.ThemeLib.DANGER))

	inner.add_child(Ui.label(str(zone["tagline"]), 15, Ui.ThemeLib.DIM))
	var meta := Ui.label(
		"level %d+  ·  %s" % [int(zone["min_level"]), str(zone["loot_hint"])],
		13, Ui.ThemeLib.FAINT
	)
	inner.add_child(meta)

	b.pressed.connect(_on_zone.bind(str(zone["id"])))
	_rows[str(zone["id"])] = {"button": b, "zone": zone}
	return b


func _danger_pips(danger: int) -> String:
	return "◆".repeat(clampi(danger, 1, 4)) + "◇".repeat(maxi(0, 4 - clampi(danger, 1, 4)))


func _on_zone(zone_id: String) -> void:
	_selected_zone = zone_id
	_sync_selection()


func _on_depth(depth: int) -> void:
	_selected_depth = depth
	_sync_selection()


func _on_standing(pressed: bool) -> void:
	game.set_standing(pressed)
	_sync_standing_text()


func _sync_standing_text() -> void:
	if _standing_button.button_pressed:
		_standing_button.text = "STANDING ORDERS: WALK AGAIN ON RETURN"
	else:
		_standing_button.text = "STANDING ORDERS: OFF"


func _sync_selection() -> void:
	for zone_id in _rows:
		var entry: Dictionary = _rows[zone_id]
		var b: Button = entry["button"]
		var zone: Dictionary = entry["zone"]
		var locked: bool = game.zone_locked(zone)
		var selected: bool = zone_id == _selected_zone
		if selected:
			b.add_theme_stylebox_override("normal", Ui.ThemeLib.outlined(ThemeLib.PANEL_LIGHT, Ui.ThemeLib.BRONZE, 14, 14))
		else:
			b.add_theme_stylebox_override("normal", Ui.ThemeLib.flat(ThemeLib.PANEL, 14, 14))
		b.add_theme_stylebox_override("hover", b.get_theme_stylebox("normal"))
		b.modulate = Color(1, 1, 1, 0.55 if locked else 1.0)
	for depth in _depth_buttons:
		var b: Button = _depth_buttons[depth]
		if depth == _selected_depth:
			b.add_theme_stylebox_override("normal", Ui.ThemeLib.flat(Ui.ThemeLib.BRONZE, 12, 14))
			b.add_theme_color_override("font_color", Ui.ThemeLib.BG)
		else:
			b.add_theme_stylebox_override("normal", Ui.ThemeLib.outlined(Color(0, 0, 0, 0), Ui.ThemeLib.BRONZE_DEEP, 12, 14))
			b.add_theme_color_override("font_color", Ui.ThemeLib.BRONZE)
	# time estimate with current gear
	var zone := game.content.get_zone(_selected_zone)
	if not zone.is_empty():
		var toll_len := ExpeditionLib.toll_seconds(zone, game.snapshot_now())
		var minutes := int(round(toll_len * float(_selected_depth) / 60.0))
		_est_label.text = "≈ %d min" % minutes
	# seal + send state
	var err: String = game.zone_ok(_selected_zone, _selected_depth)
	_seal_note.text = err if err != "" else ""
	_send_button.disabled = err != ""


func _on_send() -> void:
	var err: String = game.send_out(_selected_zone, _selected_depth)
	if err == "":
		main.pop_screen()
		main.on_sent_out()
	else:
		_seal_note.text = err
