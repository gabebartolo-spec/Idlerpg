extends Control

# THE RETURN MOMENT. The whole game earns its keep here.
# A few lines that tell the story, one emphasized find, the totals, one button.

const Ui = preload("res://src/ui/widgets.gd")
const Loot = preload("res://src/sim/loot.gd")

const TONE_COLORS := {
	"neutral": Color("9a8f7d"),
	"good": Color("97ab7e"),
	"danger": Color("cf7a52"),
	"grave": Color("c05a48")
}

var game
var main


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var payload: Dictionary = game.pending_report()
	if payload.is_empty():
		payload = {"runs": [], "events": [], "loot": [], "standout": {}, "totals": {"xp": 0, "gold": 0, "shards": 0}, "levels_gained": [], "any_death": false, "chained": 1}

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 26
	box.offset_right = -26
	box.offset_top = 40
	box.offset_bottom = -24
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var mourns: bool = bool(payload.get("any_death", false))
	box.add_child(Ui.label("THE BELL MOURNS" if mourns else "THE BELL SPEAKS", 26, Ui.ThemeLib.GRAVE if mourns else Ui.ThemeLib.BRONZE, true))

	var chained := int(payload.get("chained", 1))
	if chained > 1:
		box.add_child(Ui.label("%d expeditions came home while you were away." % chained, 15, Ui.ThemeLib.DIM, true))
	else:
		var runs: Array = payload.get("runs", [])
		if not runs.is_empty():
			box.add_child(Ui.label(str(runs[0].get("zone_name", "")), 15, Ui.ThemeLib.DIM, true))

	box.add_child(Ui.hline())

	# -- the story
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var story := VBoxContainer.new()
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.add_theme_constant_override("separation", 7)
	scroll.add_child(story)

	for event in payload.get("events", []):
		story.add_child(_event_row(event))

	# -- levels
	var levels: Array = payload.get("levels_gained", [])
	if not levels.is_empty():
		story.add_child(Ui.spacer(4))
		story.add_child(Ui.label("THEY RETURN STRONGER — LEVEL %d" % int(levels[-1]), 18, Ui.ThemeLib.BRONZE, true))

	# -- the find
	var standout: Dictionary = payload.get("standout", {})
	var loot: Array = payload.get("loot", [])
	if not standout.is_empty():
		story.add_child(Ui.spacer(8))
		story.add_child(_standout_card(standout))
		var others := 0
		for inst in loot:
			var def: Dictionary = game.content.get_item(str(inst["id"]))
			if str(def.get("id", "")) == str(standout.get("id", "")):
				continue
			others += 1
			if others <= 4:
				story.add_child(_loot_row(def))
		if loot.size() > 5:
			story.add_child(Ui.label("…and %d more things besides." % (loot.size() - 5), 14, Ui.ThemeLib.FAINT, true))

	story.add_child(Ui.spacer(8))
	var totals: Dictionary = payload.get("totals", {})
	var parts: Array = []
	if int(totals.get("xp", 0)) != 0:
		parts.append("+%d XP" % int(totals["xp"]))
	if int(totals.get("gold", 0)) != 0:
		parts.append("+%d gold" % int(totals["gold"]))
	if int(totals.get("shards", 0)) != 0:
		parts.append("+%d shards" % int(totals["shards"]))
	if not parts.is_empty():
		box.add_child(Ui.label("  ·  ".join(parts), 18, Ui.ThemeLib.TEXT, true))

	box.add_child(Ui.spacer(4))
	if not loot.is_empty():
		var open_satchel := Ui.button("MAKE SENSE OF IT", "ghost")
		open_satchel.pressed.connect(func():
			game.clear_report()
			main.pop_screen()
			main.switch_tab("satchel")
		)
		box.add_child(open_satchel)
	var done := Ui.button("CONTINUE", "primary", 24)
	done.pressed.connect(_on_continue)
	box.add_child(done)

	# sound: toll on arrival, brighter chime for the good stuff
	main.play_sfx("toll")
	if int(standout.get("rarity", 0)) >= 2:
		main.play_sfx("chime_high")
	elif not loot.is_empty():
		main.play_sfx("chime")


func _event_row(event: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var tone: String = str(event.get("tone", "neutral"))
	var tick := ColorRect.new()
	tick.color = TONE_COLORS.get(tone, Ui.ThemeLib.DIM)
	tick.custom_minimum_size = Vector2(4, 8)
	tick.size_flags_vertical = Control.SIZE_FILL
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tick)
	var text := Ui.label(str(event.get("text", "")), 17, Ui.ThemeLib.TEXT if tone != "grave" else Ui.ThemeLib.GRAVE)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row


func _standout_card(def: Dictionary) -> Control:
	var rarity := int(def.get("rarity", 0))
	var color: Color = Ui.ThemeLib.RARITY[clampi(rarity, 0, 3)]
	var card := PanelContainer.new()
	var sb := Ui.ThemeLib.outlined(ThemeLib.PANEL_LIGHT, color, 14, 16)
	card.add_theme_stylebox_override("panel", sb)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	card.add_child(inner)
	inner.add_child(Ui.label("THE FIND OF THE ROAD", 13, Ui.ThemeLib.DIM, true))
	inner.add_child(Ui.label(str(def.get("name", "")), 26, color, true))
	inner.add_child(Ui.label("%s · %s" % [Ui.rarity_name(def), str(def.get("slot", ""))], 14, Ui.ThemeLib.DIM, true))
	var effect: String = str(def.get("special_text", ""))
	if effect == "":
		effect = Ui.item_stat_line(def)
	inner.add_child(Ui.label(effect, 17, Ui.ThemeLib.TEXT, true))
	inner.add_child(Ui.label(str(def.get("flavor", "")), 13, Ui.ThemeLib.FAINT, true))
	return card


func _loot_row(def: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var dot := Ui.label("●", 13, Ui.rarity_color(def))
	row.add_child(dot)
	var text := Ui.label(str(def.get("name", "")), 15, Ui.ThemeLib.DIM)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row


func _on_continue() -> void:
	game.clear_report()
	main.pop_screen()
	main.after_report()
