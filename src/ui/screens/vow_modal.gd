extends Control

# THE VOW — the milestone build choice. Two promises; the adventurer keeps one.

const Ui = preload("res://src/ui/widgets.gd")
const HeroLib = preload("res://src/sim/hero.gd")

var game
var main


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 30
	panel.offset_right = -30
	panel.offset_top = 200
	panel.offset_bottom = -120
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var pending: Array = game.pending_vows()
	var level := int(pending[0]) if not pending.is_empty() else 0
	box.add_child(Ui.label("THE BELL ASKS A VOW", 24, Ui.ThemeLib.BRONZE, true))
	box.add_child(Ui.label("They reached level %d. It wants a promise — kept on every road after this." % level, 15, Ui.ThemeLib.DIM, true))
	box.add_child(Ui.spacer(6))

	var choices: Array = HeroLib.VOW_CHOICES.get(level, [])
	for vow_id in choices:
		var vow: Dictionary = HeroLib.VOWS[str(vow_id)]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 110)
		Ui.style_button(b, "ghost")
		var inner := VBoxContainer.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 18
		inner.offset_right = -18
		inner.offset_top = 12
		inner.offset_bottom = -12
		inner.add_theme_constant_override("separation", 3)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inner)
		inner.add_child(Ui.label(str(vow["name"]).to_upper(), 19, Ui.ThemeLib.TEXT))
		inner.add_child(Ui.label(str(vow["text"]), 14, Ui.ThemeLib.DIM))
		b.pressed.connect(_choose.bind(str(vow_id)))
		box.add_child(b)


func _choose(vow_id: String) -> void:
	if game.choose_vow(vow_id):
		main.play_sfx("toll")
		main.close_overlay()
		main.after_report()
