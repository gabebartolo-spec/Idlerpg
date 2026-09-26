extends Control

# HOME — "The Bell". One job: what is happening, and the next decision.
# The countdown is the heart of this screen; the bell swings when it matters.

const Ui = preload("res://src/ui/widgets.gd")
const BellCanvas = preload("res://src/ui/bell_canvas.gd")
const ExpeditionLib = preload("res://src/sim/expedition.gd")
const HeroLib = preload("res://src/sim/hero.gd")

var game
var main

var _canvas: Control
var _status_box: VBoxContainer
var _state_key := ""
var _countdown_label: Label
var _toll_label: Label
var _dots_label: Label
var _action_button: Button
var _note_label: Label
var _xp_bar: ProgressBar
var _header_label: Label
var _purse_label: Label


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_right = -28
	box.offset_top = 18
	box.offset_bottom = -16
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	# -- header: who they are, what they carry
	var header := HBoxContainer.new()
	box.add_child(header)
	_header_label = Ui.label("", 19, Ui.ThemeLib.TEXT)
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_header_label)
	_purse_label = Ui.label("", 15, Ui.ThemeLib.DIM)
	_purse_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_purse_label)

	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 5)
	_xp_bar.show_percentage = false
	var bg_sb := Ui.ThemeLib.flat(Color(0, 0, 0, 0.35), 3, 0)
	var fill_sb := Ui.ThemeLib.flat(ThemeLib.BRONZE_DEEP, 3, 0)
	_xp_bar.add_theme_stylebox_override("background", bg_sb)
	_xp_bar.add_theme_stylebox_override("fill", fill_sb)
	box.add_child(_xp_bar)

	box.add_child(Ui.spacer(6))

	# -- the bell
	_canvas = BellCanvas.new()
	_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_canvas)

	# -- status block (rebuilt per state)
	_status_box = VBoxContainer.new()
	_status_box.add_theme_constant_override("separation", 6)
	box.add_child(_status_box)

	var bottom_flex := Ui.spacer(4)
	bottom_flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(bottom_flex)

	_note_label = Ui.label("", 14, Ui.ThemeLib.FAINT, true)
	box.add_child(_note_label)


func _progress_level_info() -> Array:
	var level := int(game.hero()["level"])
	var xp := int(game.hero()["xp"])
	var floor_xp := HeroLib.xp_for_level(level)
	var ceil_xp := HeroLib.xp_for_level(level + 1) if level < HeroLib.MAX_LEVEL else floor_xp
	var frac := 1.0 if level >= HeroLib.MAX_LEVEL else clampf(float(xp - floor_xp) / float(maxi(1, ceil_xp - floor_xp)), 0.0, 1.0)
	return [frac, xp, HeroLib.xp_to_next(xp, level)]


func _refresh_header() -> void:
	var hero := game.hero()
	_header_label.text = "%s · LEVEL %d" % [str(hero["name"]).to_upper(), int(hero["level"])]
	_purse_label.text = "gold %d   ·   shards %d" % [int(hero["gold"]), int(hero["shards"])]
	var info := _progress_level_info()
	_xp_bar.value = float(info[0]) * 100.0


func tick(_now: int) -> void:
	game.update()
	_refresh_header()
	var key := _current_state_key()
	if key != _state_key:
		var was_out := _state_key == "out"
		_state_key = key
		_rebuild_status()
		if key == "ready" and not was_out:
			pass  # first paint after load; don't slam the bell at launch
		elif was_out and key == "ready":
			_canvas.ring(1.0)
			main.play_sfx("toll")
	if key == "out" and _countdown_label != null:
		var info: Dictionary = game.expedition_info()
		_countdown_label.text = Ui.clock_str(int(info["planned"]) - int(info["elapsed"]))
		var toll := int(info["toll_index"]) + 1
		if _toll_label != null:
			_toll_label.text = "the %s of %d tolls — %s" % [_ordinal_word(toll), int(info["depth"]), str(info["zone_name"])]
		if _dots_label != null:
			_dots_label.text = _dots_text(toll, int(info["depth"]))


func ring_bell(strength: float = 1.0) -> void:
	if _canvas != null:
		_canvas.ring(strength)


func _current_state_key() -> String:
	if game.has_report():
		return "ready"
	if game.has_expedition():
		return "out"
	return "idle"


func _rebuild_status() -> void:
	for child in _status_box.get_children():
		_status_box.remove_child(child)
		child.queue_free()
	_countdown_label = null
	_toll_label = null
	_dots_label = null
	if _action_button != null:
		_action_button.queue_free()
		_action_button = null

	match _state_key:
		"out":
			var info: Dictionary = game.expedition_info()
			_toll_label = Ui.label("", 16, Ui.ThemeLib.DIM, true)
			_status_box.add_child(_toll_label)
			_countdown_label = Ui.label("", 52, Ui.ThemeLib.TEXT, true)
			_status_box.add_child(_countdown_label)
			_dots_label = Ui.label("", 16, Ui.ThemeLib.BRONZE, true)
			_status_box.add_child(_dots_label)
			_status_box.add_child(Ui.spacer(10))
			_action_button = Ui.button("RING THEM HOME", "ghost")
			if bool(info.get("no_retreat", false)):
				_action_button.disabled = true
				_action_button.text = "THE LOW ROAD HEARS NO RECALL"
			else:
				_action_button.pressed.connect(_on_recall)
			_status_box.add_child(_action_button)
		"ready":
			var chained := int(game.pending_report().get("chained", 1))
			var line := "They are back. Something came back with them."
			if chained > 1:
				line = "%d expeditions came home while you were away." % chained
			_status_box.add_child(Ui.label(line, 17, Ui.ThemeLib.GOOD, true))
			_status_box.add_child(Ui.spacer(10))
			_action_button = Ui.button("SEE WHAT THEY FOUND", "primary", 26)
			_action_button.pressed.connect(func(): main.push_screen("report"))
			_status_box.add_child(_action_button)
		_:
			_status_box.add_child(Ui.label("THE BELL IS QUIET", 17, Ui.ThemeLib.FAINT, true))
			_status_box.add_child(Ui.spacer(10))
			_action_button = Ui.button("SEND THEM OUT", "primary", 26)
			_action_button.pressed.connect(func(): main.push_screen("zone"))
			_status_box.add_child(_action_button)
	_refresh_note()


func _refresh_note() -> void:
	match _state_key:
		"out":
			if game.standing().get("enabled", false):
				_note_label.text = "Standing orders: they set out again the moment they return."
			else:
				_note_label.text = "The bell keeps the time. Close the game; the road goes on."
		"ready":
			_note_label.text = ""
		_:
			if int(game.lifetime().get("runs", 0)) == 0:
				_note_label.text = "Choose a road below. The bell will keep the time."
			elif game.standing().get("enabled", false):
				_note_label.text = "Standing orders: they set out again the moment they return."
			else:
				_note_label.text = ""


func _on_recall() -> void:
	var err: String = game.recall()
	if err == "":
		_canvas.ring(0.6)
		main.play_sfx("toll")
		_state_key = ""
		tick(game.now())


func _ordinal_word(n: int) -> String:
	var words := ["first", "second", "third", "fourth", "fifth", "sixth"]
	if n >= 1 and n <= words.size():
		return words[n - 1]
	return "%dth" % n


func _dots_text(filled: int, total: int) -> String:
	var s := ""
	for i in total:
		s += "◆ " if i < filled else "◇ "
	return s.strip_edges()
