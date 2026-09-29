extends Control

# A read-only window onto deterministic elapsed-time resolution. Opening this
# screen cannot award rewards, reroll a fight, or reveal the next beat.
const Ui = preload("res://src/ui/widgets.gd")
const ZoneArt = preload("res://src/ui/zone_art.gd")
const TONES := {"neutral": Color("9a8f7d"), "good": Color("97ab7e"), "danger": Color("cf7a52"), "grave": Color("c05a48")}

var game
var main
var _last_second := -1
var _run_key := ""
var _event_count := 0
var _title: Label
var _art: TextureRect
var _status: Label
var _clock: Label
var _grit: Label
var _echo: Label
var _findings: Label
var _progress: ProgressBar
var _scroll: ScrollContainer
var _story: VBoxContainer
var _note: Label
var _recall: Button
var _report: Button


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var back := Ui.small_button("‹  THE BELL", "flat")
	back.pressed.connect(func(): main.pop_screen())
	box.add_child(back)
	box.add_child(Ui.label("LISTENING TO THE ROAD", 13, Ui.ThemeLib.DIM))
	_title = Ui.label("THE JOURNEY", 28, Ui.ThemeLib.BRONZE)
	box.add_child(_title)
	_art = ZoneArt.new("", 190)
	box.add_child(_art)

	var timer := HBoxContainer.new()
	box.add_child(timer)
	_status = Ui.label("", 16, Ui.ThemeLib.DIM)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer.add_child(_status)
	_clock = Ui.label("", 28, Ui.ThemeLib.TEXT)
	_clock.autowrap_mode = TextServer.AUTOWRAP_OFF
	timer.add_child(_clock)
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 6
	_progress.add_theme_stylebox_override("background", Ui.ThemeLib.flat(Ui.ThemeLib.PANEL_LIGHT, 3, 0))
	_progress.add_theme_stylebox_override("fill", Ui.ThemeLib.flat(Ui.ThemeLib.BRONZE, 3, 0))
	box.add_child(_progress)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	box.add_child(stats)
	_grit = Ui.label("", 16, Ui.ThemeLib.TEXT)
	_echo = Ui.label("", 16, Ui.ThemeLib.BRONZE)
	_findings = Ui.label("", 16, Ui.ThemeLib.GOOD)
	for label in [_grit, _echo, _findings]:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(label)
	box.add_child(Ui.label("Findings are not safe until they come home. The bell reveals no future.", 14, Ui.ThemeLib.FAINT))
	box.add_child(Ui.hline())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_story = VBoxContainer.new()
	_story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story.add_theme_constant_override("separation", 12)
	_scroll.add_child(_story)
	_note = Ui.label("", 15, Ui.ThemeLib.DANGER, true)
	box.add_child(_note)
	_recall = Ui.button("RING THEM HOME", "ghost", 18)
	_recall.pressed.connect(_on_recall)
	box.add_child(_recall)
	_report = Ui.button("READ THE RETURN", "primary", 20)
	_report.pressed.connect(_on_report)
	box.add_child(_report)
	tick(game.now())


func tick(now: int) -> void:
	if now == _last_second:
		return
	_last_second = now
	_report.visible = game.has_report()
	if not game.has_expedition():
		_status.text = "The road is quiet. A report waits at the bell." if game.has_report() else "Nobody is on the road."
		_clock.text = "—"
		_progress.value = 100
		_recall.visible = false
		_grit.text = "JOURNEY ENDED"
		_echo.text = ""
		_findings.text = ""
		_note.text = ""
		return
	var exp: Dictionary = game.state["expedition"]
	var key := "%s:%s:%s" % [exp["zone_id"], exp["seed"], exp["started_at"]]
	var view: Dictionary = game.expedition_view()
	var zone: Dictionary = game.content.get_zone(str(exp["zone_id"]))
	if key != _run_key:
		_run_key = key
		_event_count = 0
		for child in _story.get_children():
			_story.remove_child(child)
			child.queue_free()
		_title.text = str(zone["name"]).to_upper()
		_art.texture = ZoneArt.get_art(str(zone.get("art", "")))
	var info: Dictionary = game.expedition_info()
	var planned := int(view["planned_seconds"])
	_clock.text = Ui.clock_str(planned - int(view["elapsed_seconds"]))
	_status.text = "TOLL %d / %d  ·  %d FIGHT(S) PER TOLL" % [int(info["toll_index"]) + 1, int(exp["depth"]), int(zone.get("combats_per_toll", 1))]
	_progress.value = minf(100.0, float(view["elapsed_seconds"]) * 100.0 / float(maxi(1, planned)))
	_grit.text = "GRIT  %d / %d" % [view["grit"], exp["snapshot"]["grit_max"]]
	_echo.text = "ECHO  %d / 5" % int(view["echo"])
	_findings.text = "FINDINGS  %d" % view["loot"].size()
	_recall.visible = true
	_recall.disabled = not game.can_recall()
	_note.text = "The Low Road hears no recall." if bool(info.get("no_retreat", false)) else ""
	var events: Array = view["events"]
	if events.size() > _event_count:
		var was_at_bottom := _scroll.scroll_vertical + _scroll.size.y >= _story.size.y - 16
		for event in events.slice(_event_count):
			_append_event(event)
		_event_count = events.size()
		if was_at_bottom:
			_scroll.set_deferred("scroll_vertical", 100000)


func _append_event(event: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var color: Color = TONES.get(str(event.get("tone", "neutral")), Ui.ThemeLib.DIM)
	var time := Ui.label(Ui.clock_str(int(event.get("at_seconds", 0))), 14, color)
	time.custom_minimum_size.x = 56
	time.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(time)
	var text := Ui.label(str(event.get("text", "")), 17, color)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_story.add_child(row)


func _on_recall() -> void:
	var error: String = game.recall()
	if error == "":
		main.play_sfx("toll")
	_last_second = -1
	tick(game.now())
	if error != "" and game.has_expedition():
		_note.text = error


func _on_report() -> void:
	if not game.has_report():
		return
	main.pop_screen()
	main.push_screen("report")
