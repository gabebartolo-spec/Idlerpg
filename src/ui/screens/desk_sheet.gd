extends Control

# The Bellkeeper's Desk — a debug tool, hidden in normal builds.
# Time is moved forward here so nobody waits eight hours to test the return.

const Ui = preload("res://src/ui/widgets.gd")

var game
var main


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_right = -40
	panel.offset_top = 320
	panel.offset_bottom = -220
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(Ui.label("THE BELLKEEPER'S DESK", 18, Ui.ThemeLib.BRONZE, true))
	box.add_child(Ui.label("Move the hour hand forward. Testing only — the bell will know.", 13, Ui.ThemeLib.FAINT, true))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for jump in [[1, "+1 MIN"], [10, "+10 MIN"], [60, "+1 HOUR"]]:
		var b := Ui.button(str(jump[1]), "ghost")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var seconds: int = int(jump[0]) * 60
		b.pressed.connect(func(): game.debug_advance(seconds))
		row.add_child(b)

	var close_btn := Ui.button("CLOSE", "flat")
	close_btn.pressed.connect(func(): main.close_overlay())
	box.add_child(close_btn)
