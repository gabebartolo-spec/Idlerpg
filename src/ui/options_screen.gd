extends "res://src/ui/sheet.gd"

signal changed
var preferences: RefCounted
var text_button: Button
var motion_button: Button
var music_button: Button
var sounds_button: Button

func setup(settings: RefCounted) -> void:
	preferences = settings
	var column := build_sheet("Options")
	subtitle_label.text = "Make yourself comfortable"
	var list := add_list(column)
	text_button = Style.button("")
	text_button.pressed.connect(func() -> void:
		preferences.larger_text = not preferences.larger_text
		refresh()
		changed.emit())
	list.content.add_child(text_button)
	motion_button = Style.button("")
	motion_button.pressed.connect(func() -> void:
		preferences.reduced_motion = not preferences.reduced_motion
		refresh()
		changed.emit())
	list.content.add_child(motion_button)
	music_button = Style.button("")
	music_button.pressed.connect(func() -> void:
		preferences.music = not preferences.music
		refresh()
		changed.emit())
	list.content.add_child(music_button)
	sounds_button = Style.button("")
	sounds_button.pressed.connect(func() -> void:
		preferences.sounds = not preferences.sounds
		refresh()
		changed.emit())
	list.content.add_child(sounds_button)
	refresh()

func refresh() -> void:
	text_button.text = "Larger text · " + ("On" if preferences.larger_text else "Off")
	motion_button.text = "Reduced motion · " + ("On" if preferences.reduced_motion else "Off")
	music_button.text = "Music · " + ("On" if preferences.music else "Off")
	sounds_button.text = "Sounds · " + ("On" if preferences.sounds else "Off")
	for entry in [[text_button, preferences.larger_text], [motion_button, preferences.reduced_motion], [music_button, preferences.music], [sounds_button, preferences.sounds]]:
		var style := Style.row_box(entry[1])
		for state in ["normal", "hover", "pressed"]:
			entry[0].add_theme_stylebox_override(state, style)
