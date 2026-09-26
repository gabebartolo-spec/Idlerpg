extends Control

# VESPERBELL app shell: owns the game, the two tabs, the pushed screens,
# overlays, the Android Back button, and the falling ash.

const VbContent = preload("res://src/data/content.gd")
const VbGame = preload("res://src/state/game.gd")
const ThemeLib = preload("res://src/ui/theme.gd")
const SfxLib = preload("res://src/ui/sfx.gd")
const CreateScreen = preload("res://src/ui/screens/create_screen.gd")
const BellScreen = preload("res://src/ui/screens/bell_screen.gd")
const ZoneScreen = preload("res://src/ui/screens/zone_screen.gd")
const ReportScreen = preload("res://src/ui/screens/report_screen.gd")
const SatchelScreen = preload("res://src/ui/screens/satchel_screen.gd")
const VowModal = preload("res://src/ui/screens/vow_modal.gd")
const DeskSheet = preload("res://src/ui/screens/desk_sheet.gd")

var game
var sfx

var _stack: Array = []
var _holder: Control
var _nav: Control
var _overlay: Control = null
var _overlay_close_cb := Callable()


func _ready() -> void:
	theme = ThemeLib.build()
	game = VbGame.new(VbContent.new())
	sfx = SfxLib.new(self)
	game.update()
	_build_shell()
	if game.is_new_game():
		push_screen("create")
	else:
		push_screen("bell")
		after_report()


func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = ThemeLib.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var ash := CPUParticles2D.new()
	ash.position = Vector2(360, -24)
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(420, 10)
	ash.amount = 46
	ash.lifetime = 18.0
	ash.preprocess = 18.0
	ash.direction = Vector2(0.12, 1)
	ash.spread = 10.0
	ash.gravity = Vector2(0, 3)
	ash.initial_velocity_min = 5.0
	ash.initial_velocity_max = 16.0
	ash.scale_amount_min = 0.6
	ash.scale_amount_max = 2.0
	ash.color = Color(0.62, 0.58, 0.5, 0.15)
	add_child(ash)

	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.offset_bottom = -78
	_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_holder)

	_nav = PanelContainer.new()
	_nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_nav.offset_top = -78
	var nav_style := ThemeLib.flat(ThemeLib.PANEL, 0, 8)
	nav_style.content_margin_top = 10
	nav_style.content_margin_bottom = 22
	_nav.add_theme_stylebox_override("panel", nav_style)
	add_child(_nav)

	var nav_box := HBoxContainer.new()
	nav_box.add_theme_constant_override("separation", 10)
	_nav.add_child(nav_box)

	var bell_tab := Ui.button("THE BELL", "ghost", 17)
	bell_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bell_tab.pressed.connect(func(): switch_tab("bell"))
	nav_box.add_child(bell_tab)
	var satchel_tab := Ui.button("SATCHEL", "ghost", 17)
	satchel_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	satchel_tab.pressed.connect(func(): switch_tab("satchel"))
	nav_box.add_child(satchel_tab)
	_bell_tab = bell_tab
	_satchel_tab = satchel_tab

	if OS.is_debug_build():
		var desk := Ui.small_button("desk", "flat")
		desk.custom_minimum_size = Vector2(70, 44)
		desk.pressed.connect(func(): open_overlay(DeskSheet.new(game, self)))
		nav_box.add_child(desk)


const Ui = preload("res://src/ui/widgets.gd")


# ------------------------------------------------------------------ screens

func _make(id: String) -> Control:
	match id:
		"create":
			return CreateScreen.new(game, self)
		"bell":
			return BellScreen.new(game, self)
		"zone":
			return ZoneScreen.new(game, self)
		"report":
			return ReportScreen.new(game, self)
		"satchel":
			return SatchelScreen.new(game, self)
	return Control.new()


func push_screen(id: String) -> void:
	var node := _make(id)
	_holder.add_child(node)
	_stack.append({"id": id, "node": node})
	_sync_nav()


func pop_screen() -> void:
	if _stack.size() <= 1:
		return
	var entry: Dictionary = _stack.pop_back()
	entry["node"].queue_free()
	_sync_nav()


func switch_tab(id: String) -> void:
	while _stack.size() > 1:
		var entry: Dictionary = _stack.pop_back()
		entry["node"].queue_free()
	if not _stack.is_empty():
		if str(_stack[0]["id"]) == id:
			_sync_nav()
			return
		_stack[0]["node"].queue_free()
		var node := _make(id)
		_holder.add_child(node)
		_stack[0] = {"id": id, "node": node}
	_sync_nav()


func current_id() -> String:
	if _stack.is_empty():
		return ""
	return str(_stack[-1]["id"])


func _sync_nav() -> void:
	var top := current_id()
	_nav.visible = top != "create"
	if _overlay != null:
		_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bell_tab.modulate = Color(1, 1, 1, 1.0) if top == "bell" else Color(1, 1, 1, 0.45)
	_satchel_tab.modulate = Color(1, 1, 1, 1.0) if top == "satchel" else Color(1, 1, 1, 0.45)


# ------------------------------------------------------------------ overlays

func open_overlay(node: Control, on_close: Callable = Callable()) -> void:
	if _overlay != null:
		return
	_overlay = node
	_overlay_close_cb = on_close
	add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func close_overlay() -> void:
	if _overlay == null:
		return
	var node := _overlay
	_overlay = null
	var cb := _overlay_close_cb
	_overlay_close_cb = Callable()
	node.queue_free()
	if cb.is_valid():
		cb.call()


func has_overlay() -> bool:
	return _overlay != null


# ------------------------------------------------------------------ flow

func enter_game() -> void:
	switch_tab("bell")


func on_sent_out() -> void:
	play_sfx("toll")
	if not _stack.is_empty() and str(_stack[0]["id"]) == "bell" and _stack[0]["node"].has_method("ring_bell"):
		_stack[0]["node"].ring_bell(0.7)


func after_report() -> void:
	if current_id() == "bell" and not game.pending_vows().is_empty() and _overlay == null:
		open_overlay(VowModal.new(game, self))


func play_sfx(sound_name: String) -> void:
	sfx.play(sound_name)


# ------------------------------------------------------------------ frame

func _process(_delta: float) -> void:
	game.update()
	if not _stack.is_empty():
		var top: Control = _stack[-1]["node"]
		if is_instance_valid(top) and top.has_method("tick"):
			top.tick(game.now())


# ------------------------------------------------------------------ back

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()


func _go_back() -> void:
	if _overlay != null:
		close_overlay()
		return
	if _stack.size() > 1:
		pop_screen()
		return
	get_tree().quit()
