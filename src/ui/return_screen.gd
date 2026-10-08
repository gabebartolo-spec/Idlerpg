extends "res://src/ui/sheet.gd"

signal destination_requested(route: String, target: String)
signal talents_requested

var list: Control
var summary: Label
var talent_button: Button

func setup() -> void:
	var column := build_sheet("Welcome back", 0.34)
	subtitle_label.text = "Your adventure continued"
	list = add_list(column)
	talent_button = Style.button("Spend talent points")
	talent_button.pressed.connect(func() -> void: talents_requested.emit())
	column.add_child(talent_button)
	var history := Style.button("Details")
	history.pressed.connect(func() -> void: destination_requested.emit("guide", "away"))
	column.add_child(history)

func show_report(report: Dictionary, totals: String) -> void:
	clear_list(list)
	subtitle_label.text = "Save needs attention" if report.get("save_lost", false) else "Your adventure continued"
	for event in report.get("highlights", []).slice(0, 2):
		var button := Style.button(_highlight_title(event))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 110.0
		button.pressed.connect(func() -> void: destination_requested.emit(str(event["route"]), str(event.get("target", ""))))
		list.content.add_child(button)
	summary = Style.label(totals, 24)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.content.add_child(summary)
	list.scroll_to(0.0)
	visible = true

func _highlight_title(event: Dictionary) -> String:
	var target := str(event.get("target", ""))
	match str(event.get("route", "")):
		"gear", "relics":
			return "+ " + target if not target.is_empty() else "New find"
		"boss":
			return "Boss milestone"
		"expedition":
			return "Expedition returned"
		"practice":
			return "Practice victory"
		"fishing":
			return "First catch"
		"journal":
			return "New discovery"
		"companions", "companion":
			return target if not target.is_empty() else "Companion milestone"
		"talents":
			return "New talent milestone"
	return "Adventure milestone"
