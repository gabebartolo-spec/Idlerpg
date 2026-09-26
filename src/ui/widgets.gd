extends RefCounted

# Small UI factories shared by every screen. Kept boring on purpose.

const ThemeLib = preload("res://src/ui/theme.gd")
const Loot = preload("res://src/sim/loot.gd")


static func label(text: String, font_size: int = ThemeLib.FONT_BODY, color: Color = ThemeLib.TEXT, centered: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if centered:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(text: String) -> Label:
	var l := label(text, ThemeLib.FONT_TITLE, ThemeLib.BRONZE, true)
	return l


static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func hspace(width: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func style_button(btn: Button, kind: String) -> void:
	var normal: StyleBoxFlat
	var hover: StyleBoxFlat
	var pressed: StyleBoxFlat
	var disabled: StyleBoxFlat
	var font := ThemeLib.TEXT
	var font_disabled := ThemeLib.FAINT
	match kind:
		"primary":
			normal = ThemeLib.flat(ThemeLib.BRONZE, 14, 18)
			hover = ThemeLib.flat(ThemeLib.BRONZE.lightened(0.08), 14, 18)
			pressed = ThemeLib.flat(ThemeLib.BRONZE_DEEP, 14, 18)
			disabled = ThemeLib.flat(ThemeLib.PANEL_LIGHT, 14, 18)
			font = ThemeLib.BG
		"ghost":
			normal = ThemeLib.outlined(Color(0, 0, 0, 0), ThemeLib.BRONZE_DEEP, 14, 16)
			hover = ThemeLib.outlined(Color(1, 1, 1, 0.03), ThemeLib.BRONZE, 14, 16)
			pressed = ThemeLib.flat(ThemeLib.PANEL_LIGHT, 14, 16)
			disabled = ThemeLib.outlined(Color(0, 0, 0, 0), ThemeLib.FAINT, 14, 16)
		"danger":
			normal = ThemeLib.outlined(Color(0, 0, 0, 0), ThemeLib.GRAVE, 14, 16)
			hover = ThemeLib.outlined(Color(1, 0, 0, 0.05), ThemeLib.DANGER, 14, 16)
			pressed = ThemeLib.flat(ThemeLib.PANEL_LIGHT, 14, 16)
			disabled = ThemeLib.outlined(Color(0, 0, 0, 0), ThemeLib.FAINT, 14, 16)
		_:
			normal = ThemeLib.flat(Color(0, 0, 0, 0), 12, 14)
			hover = ThemeLib.flat(ThemeLib.PANEL_LIGHT, 12, 14)
			pressed = ThemeLib.flat(ThemeLib.PANEL_LIGHT, 12, 14)
			disabled = ThemeLib.flat(Color(0, 0, 0, 0), 12, 14)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", font)
	btn.add_theme_color_override("font_hover_color", font)
	btn.add_theme_color_override("font_pressed_color", font)
	btn.add_theme_color_override("font_disabled_color", font_disabled)


static func button(text: String, kind: String = "ghost", font_size: int = ThemeLib.FONT_BODY) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 64)
	style_button(b, kind)
	b.add_theme_font_size_override("font_size", font_size)
	return b


static func small_button(text: String, kind: String = "ghost") -> Button:
	var b := button(text, kind, ThemeLib.FONT_SMALL)
	b.custom_minimum_size = Vector2(0, 44)
	return b


## A tappable list row: optional colored dot, main text, right-aligned note.
static func row(main_text: String, note: String, dot_color: Color, font_size: int = ThemeLib.FONT_BODY) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 64)
	style_button(b, "flat")
	var box := HBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_right = -14
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	if dot_color != Color.TRANSPARENT:
		var dot := label("●", 16, dot_color)
		dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(dot)
		box.add_child(hspace(10))
	var name_label := label(main_text, font_size)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(name_label)
	if note != "":
		var note_label := label(note, ThemeLib.FONT_SMALL, ThemeLib.DIM)
		note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(note_label)
	return b


static func dots(filled: int, total: int, color: Color, empty_color: Color) -> Label:
	var s := ""
	for i in total:
		s += "●" if i < filled else "○"
		if i < total - 1:
			s += " "
	var l := label(s, 18, color)
	# per-char coloring is overkill; empty dots share the color at lower alpha
	if filled >= total:
		l.add_theme_color_override("font_color", color)
	return l


static func hline() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(ThemeLib.DIM, 0.25)
	c.custom_minimum_size = Vector2(0, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func clock_str(seconds: int) -> String:
	var s := maxi(0, seconds)
	return "%d:%02d" % [s / 60, s % 60]


static func stat_word_line(stats: Dictionary) -> String:
	return "MIGHT %d · WARD %d · LUCK %d" % [int(stats["might"]), int(stats["ward"]), int(stats["luck"])]


static func item_stat_line(def: Dictionary) -> String:
	var parts: Array = []
	for pair in [["might", "MIGHT"], ["ward", "WARD"], ["luck", "LUCK"]]:
		var v := int(def.get(pair[0], 0))
		if v != 0:
			parts.append("%s %+d" % [pair[1], v])
	if parts.is_empty():
		return "no stat it will admit to"
	return " · ".join(parts)


static func rarity_name(def: Dictionary) -> String:
	return Loot.RARITY_NAMES[clampi(int(def.get("rarity", 0)), 0, 3)]


static func rarity_color(def: Dictionary) -> Color:
	return ThemeLib.RARITY[clampi(int(def.get("rarity", 0)), 0, 3)]
