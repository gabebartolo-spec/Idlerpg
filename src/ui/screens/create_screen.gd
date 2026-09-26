extends Control

# First launch: one name, one button. The game teaches everything else later.

const Ui = preload("res://src/ui/widgets.gd")
const BellCanvas = preload("res://src/ui/bell_canvas.gd")

var game
var main

var _name_edit: LineEdit


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 36
	box.offset_right = -36
	box.offset_top = 60
	box.offset_bottom = -70
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var canvas := BellCanvas.new()
	canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(canvas)

	box.add_child(Ui.title("VESPERBELL"))
	var tagline := Ui.label("Send them into the ash.\nListen for the bell.", 17, Ui.ThemeLib.DIM, true)
	box.add_child(tagline)
	box.add_child(Ui.spacer(26))

	var prompt := Ui.label("Who walks for you?", 22, Ui.ThemeLib.TEXT, true)
	box.add_child(prompt)
	box.add_child(Ui.spacer(8))

	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(0, 64)
	_name_edit.max_length = 24
	_name_edit.placeholder_text = "a name for the road"
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_size_override("font_size", 22)
	box.add_child(_name_edit)

	var choose := Ui.small_button("LET THE BELL CHOOSE", "ghost")
	choose.pressed.connect(_on_choose)
	box.add_child(choose)
	box.add_child(Ui.spacer(16))

	var begin := Ui.button("THEY WALK AT DUSK", "primary", 24)
	begin.pressed.connect(_on_begin)
	box.add_child(begin)


func _on_choose() -> void:
	_name_edit.text = game.random_name()


func _on_begin() -> void:
	var adventurer_name := _name_edit.text.strip_edges()
	if adventurer_name.is_empty():
		adventurer_name = game.random_name()
	if game.create_adventurer(adventurer_name):
		main.enter_game()
