extends RefCounted

# Shared look for management screens: warm neutral surfaces, restrained panels, modest
# corners, rarity colour only where it tells you something (docs/ART_STYLE_GUIDE.md s.11).

# Smallest comfortable touch target. The canvas is 720 px wide, so on a phone 80 px is
# about 8 mm.
const TOUCH := 80.0

const SURFACE := Color(0.17, 0.15, 0.13, 0.97)
const RAISED := Color(0.24, 0.21, 0.18)
const SELECTED := Color(0.33, 0.28, 0.21)
const LINE := Color(0.36, 0.32, 0.27)
const TEXT := Color(0.94, 0.90, 0.82)
const MUTED := Color(0.72, 0.67, 0.58)
const ACCENT := Color(0.89, 0.71, 0.24)
const BETTER := Color(0.55, 0.80, 0.45)
const WORSE := Color(0.90, 0.47, 0.40)

const RARITY := {
	"Common": Color(0.80, 0.77, 0.70),
	"Rare": Color(0.47, 0.68, 0.90),
	"Epic": Color(0.74, 0.56, 0.88),
	"Legendary": Color(0.89, 0.71, 0.24)
}

static func rarity_colour(rarity: String) -> Color:
	return RARITY.get(rarity, TEXT)

static func box(colour: Color, radius: float = 10.0, margin: float = 12.0, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_corner_radius_all(int(radius))
	style.set_content_margin_all(margin)
	if border.a > 0.0:
		style.border_color = border
		style.set_border_width_all(2)
	return style

static func label(text: String, size: int, colour: Color = TEXT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", colour)
	return result

static func button(text: String, primary: bool = false) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(0.0, TOUCH)
	result.add_theme_font_size_override("font_size", 22)
	var base := ACCENT if primary else RAISED
	var ink := Color(0.14, 0.12, 0.10) if primary else TEXT
	result.add_theme_stylebox_override("normal", box(base))
	result.add_theme_stylebox_override("hover", box(base.lightened(0.06)))
	result.add_theme_stylebox_override("pressed", box(base.darkened(0.12)))
	result.add_theme_stylebox_override("disabled", box(RAISED.darkened(0.2)))
	result.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.add_theme_color_override(state, ink)
	result.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	return result
