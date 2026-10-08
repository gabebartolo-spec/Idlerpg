extends SceneTree

const Style = preload("res://src/ui/ui_style.gd")
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	for font in [Style.FONT, Style.FONT_STRONG]:
		check(font.get_font_name() == "Mossgate", "the game loads the original Mossgate family")
		var missing := ""
		for codepoint in range(32, 127):
			if not font.has_char(codepoint):
				missing += String.chr(codepoint)
		for character in "·×…—–→←↑↓∞✓★ÉéÅåñçøæß":
			if not font.has_char(character.unicode_at(0)):
				missing += character
		check(missing.is_empty(), "UI alphabet, numbers, punctuation and common names have drawn glyphs: " + missing)
		var digit_width: float = font.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		var steady := true
		for digit in "123456789":
			steady = steady and is_equal_approx(font.get_string_size(digit, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x, digit_width)
		check(steady, "health and countdown digits have equal advances")
		check(font.get_string_size("iii", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x < font.get_string_size("mmm", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x, "letter spacing is proportional rather than a bitmap grid")
		check(font.allow_system_fallback, "player names can use system fonts for unsupported scripts")
	var regular: Label = Style.label("Adventure complete!", 24)
	root.add_child(regular)
	var action: Button = Style.button("Explore Shattered Causeway", true)
	root.add_child(action)
	action.position.y = 100
	action.size.x = 680
	await process_frame
	check(action.get_minimum_size().x <= 680, "the longest expedition action fits a portrait phone")
	check(regular.get_theme_font("font").get_font_name() == "Mossgate", "body text uses the original family")
	check(action.get_theme_font("font").get_font_style_name() == "Semibold", "actions use the stronger optical weight")
	regular.free()
	action.free()
	print("Typography tests complete: %d failure(s)" % failures)
	quit(failures)
