extends RefCounted

# VESPERBELL visual language: ash-dark ground, bone text, one bronze accent.
# Rarity colors are the only additional hues the game is allowed.

const BG := Color("171412")
const PANEL := Color("221d18")
const PANEL_LIGHT := Color("2b251f")
const TEXT := Color("e8ddc8")
const DIM := Color("9a8f7d")
const FAINT := Color("6b6154")
const BRONZE := Color("d0a95c")
const BRONZE_DEEP := Color("8a6f3c")
const DANGER := Color("cf7a52")
const GRAVE := Color("c05a48")
const GOOD := Color("97ab7e")

const RARITY := [
	Color("9a938a"),  # Worn
	Color("6fa08a"),  # Tempered (verdigris)
	Color("d0a95c"),  # Bellforged (bronze)
	Color("c9b3e6")   # Requiem (ash-lilac)
]

const FONT_SMALL := 15
const FONT_BODY := 20
const FONT_LARGE := 26
const FONT_TITLE := 38


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_BODY
	var label_color := Color("e8ddc8")
	t.set_color("font_color", "Label", label_color)
	t.set_stylebox("panel", "PanelContainer", flat(PANEL, 14, 16))
	var le := flat(PANEL_LIGHT, 10, 14)
	le.border_width_bottom = 2
	le.border_color = BRONZE_DEEP
	t.set_stylebox("normal", "LineEdit", le)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", BRONZE)
	t.set_color("font_placeholder_color", "LineEdit", FAINT)
	return t


static func flat(bg: Color, radius := 12, margin := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func outlined(bg: Color, border: Color, radius := 12, margin := 14) -> StyleBoxFlat:
	var sb := flat(bg, radius, margin)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = border
	return sb
