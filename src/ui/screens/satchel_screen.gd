extends Control

# SATCHEL — the build screen. Equipped on top, findings below.
# Comparisons are words and deltas, never a stat table.

const Ui = preload("res://src/ui/widgets.gd")
const HeroLib = preload("res://src/sim/hero.gd")

const SLOT_NAMES := {"weapon": "WEAPON", "armor": "ARMOR", "charm": "CHARM"}

var game
var main

var _list_box: VBoxContainer


func _init(game_ref, main_ref) -> void:
	game = game_ref
	main = main_ref


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_right = -24
	box.offset_top = 20
	box.offset_bottom = -16
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var top := HBoxContainer.new()
	box.add_child(top)
	var back := Ui.small_button("‹  THE BELL", "flat")
	back.custom_minimum_size = Vector2(120, 44)
	back.pressed.connect(func(): main.switch_tab("bell"))
	top.add_child(back)
	var stats_label := Ui.label("", 16, Ui.ThemeLib.DIM)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(stats_label)
	var stats := game.stats()
	stats_label.text = "%s · GRIT %d" % [Ui.stat_word_line(stats), HeroLib.grit_max(int(stats["ward"]))]

	var vows: Array = game.vows()
	if vows.is_empty():
		box.add_child(Ui.label("No vows yet. The bell will ask.", 14, Ui.ThemeLib.FAINT))
	else:
		var names: Array = []
		for v in vows:
			names.append(str(HeroLib.VOWS.get(str(v), {}).get("name", str(v))))
		box.add_child(Ui.label("Vows: " + ", ".join(names), 14, Ui.ThemeLib.FAINT))

	box.add_child(Ui.label("WORN", 14, Ui.ThemeLib.FAINT))
	var worn := HBoxContainer.new()
	worn.add_theme_constant_override("separation", 10)
	box.add_child(worn)
	for slot in ["weapon", "armor", "charm"]:
		worn.add_child(_slot_card(slot))

	box.add_child(Ui.label("CARRIED", 14, Ui.ThemeLib.FAINT))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_list_box)
	_rebuild_list()


func _slot_card(slot: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 86)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Ui.style_button(b, "flat")
	var inst: Dictionary = game.equipped().get(slot, {})
	var def := game.content.get_item(str(inst.get("id", ""))) if not inst.is_empty() else {}
	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 12
	inner.offset_right = -12
	inner.offset_top = 8
	inner.offset_bottom = -8
	inner.add_theme_constant_override("separation", 1)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)
	inner.add_child(Ui.label(SLOT_NAMES.get(slot, slot), 12, Ui.ThemeLib.FAINT))
	if def.is_empty():
		inner.add_child(Ui.label("—", 17, Ui.ThemeLib.FAINT))
	else:
		var temper_note := ""
		if int(inst.get("temper", 0)) > 0:
			temper_note = "  +%d" % int(inst["temper"])
		inner.add_child(Ui.label(str(def.get("name", "")), 16, Ui.rarity_color(def)))
		inner.add_child(Ui.label(Ui.item_stat_line(def) + temper_note, 12, Ui.ThemeLib.DIM))
	b.pressed.connect(_open_item.bind(inst, slot, true))
	return b


func _rebuild_list() -> void:
	for child in _list_box.get_children():
		_list_box.remove_child(child)
		child.queue_free()
	var inv: Array = game.inventory()
	if inv.is_empty():
		_list_box.add_child(Ui.label("Nothing but lint and road-dust.", 15, Ui.ThemeLib.FAINT, true))
		return
	for inst in inv:
		var def := game.content.get_item(str(inst["id"]))
		var temper_note := ""
		if int(inst.get("temper", 0)) > 0:
			temper_note = "  ·  tempered +%d" % int(inst["temper"])
		var row := Ui.row(
			str(def.get("name", "?")),
			"%s  ·  %s%s" % [Ui.rarity_name(def), str(def.get("slot", "")), temper_note],
			Ui.rarity_color(def)
		)
		row.pressed.connect(_open_item.bind(inst, str(def.get("slot", "")), false))
		_list_box.add_child(row)


func _open_item(inst: Dictionary, slot: String, is_equipped: bool) -> void:
	if inst.is_empty():
		return
	var sheet := ItemSheet.new(game, main, inst, slot, is_equipped)
	main.open_overlay(sheet, func(): _rebuild_list())


# ------------------------------------------------------------------ item sheet

class ItemSheet:
	extends Control

	const Ui = preload("res://src/ui/widgets.gd")

	var game
	var main
	var inst: Dictionary
	var slot: String
	var is_equipped: bool
	var _on_close: Callable
	var _note: Label


	func _init(game_ref, main_ref, inst_ref, slot_ref, equipped_flag) -> void:
		game = game_ref
		main = main_ref
		inst = inst_ref
		slot = slot_ref
		is_equipped = equipped_flag


	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.6)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)

		var panel := PanelContainer.new()
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.offset_left = 30
		panel.offset_right = -30
		panel.offset_top = 120
		panel.offset_bottom = -40
		add_child(panel)

		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 9)
		panel.add_child(box)

		var def := game.content.get_item(str(inst.get("id", "")))
		var color: Color = Ui.rarity_color(def)
		box.add_child(Ui.label(str(def.get("name", "?")), 26, color))
		var sell_gold := int(def.get("value", 0)) + int(inst.get("temper", 0)) * game.TEMPER_SELL_BONUS
		var salvage_shards: int = game.content_salvage(def, int(inst.get("temper", 0)))
		box.add_child(Ui.label("%s · %s · sells %d gold · yields %d shards" % [
			Ui.rarity_name(def), str(def.get("slot", "")), sell_gold, salvage_shards
		], 13, Ui.ThemeLib.DIM))
		box.add_child(Ui.label(Ui.item_stat_line(def), 19, Ui.ThemeLib.TEXT))

		var special: String = str(def.get("special_text", ""))
		if special != "":
			box.add_child(Ui.label(special, 16, Ui.ThemeLib.BRONZE))
		var flavor: String = str(def.get("flavor", ""))
		if flavor != "":
			box.add_child(Ui.label(flavor, 14, Ui.ThemeLib.FAINT))

		# the comparison, in words and deltas only
		if not is_equipped:
			var current: Dictionary = game.equipped().get(str(def.get("slot", "")), {})
			if not current.is_empty():
				var current_def := game.content.get_item(str(current.get("id", "")))
				box.add_child(Ui.hline())
				box.add_child(Ui.label("INSTEAD OF %s:" % str(current_def.get("name", "")).to_upper(), 13, Ui.ThemeLib.FAINT))
				box.add_child(Ui.label(_delta_line(def, current_def), 16, Ui.ThemeLib.TEXT))

		_note = Ui.label("", 14, Ui.ThemeLib.DANGER)
		box.add_child(_note)

		box.add_child(Ui.spacer(4))
		if not is_equipped:
			var equip_btn := Ui.button("WEAR IT", "primary", 22)
			equip_btn.pressed.connect(_on_equip)
			box.add_child(equip_btn)
			var trade := HBoxContainer.new()
			trade.add_theme_constant_override("separation", 10)
			box.add_child(trade)
			var sell_btn := Ui.button("SELL  +%d g" % sell_gold, "ghost")
			sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sell_btn.pressed.connect(_on_sell)
			trade.add_child(sell_btn)
			var salvage_btn := Ui.button("SALVAGE  +%d shards" % salvage_shards, "ghost")
			salvage_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			salvage_btn.pressed.connect(_on_salvage)
			trade.add_child(salvage_btn)
		else:
			var cost := game.temper_cost(slot)
			var temper_btn: Button
			if cost > 0:
				temper_btn = Ui.button("TEMPER +1  ·  %d SHARDS" % cost, "ghost")
				temper_btn.pressed.connect(_on_temper)
			else:
				temper_btn = Ui.button("TEMPERED TO ITS LIMIT", "ghost")
				temper_btn.disabled = true
			box.add_child(temper_btn)

		var close_btn := Ui.button("CLOSE", "flat")
		close_btn.pressed.connect(_close)
		box.add_child(close_btn)


	func _delta_line(candidate: Dictionary, current: Dictionary) -> String:
		var parts: Array = []
		var labels := {"might": "MIGHT", "ward": "WARD", "luck": "LUCK"}
		for key in ["might", "ward", "luck"]:
			var d := int(candidate.get(key, 0)) - int(current.get(key, 0))
			if d != 0:
				parts.append("%s %+d" % [labels[key], d])
		if parts.is_empty():
			return "no difference the numbers can see"
		return "  ".join(parts)


	func _on_equip() -> void:
		game.equip(int(inst["uid"]))
		main.play_sfx("thock")
		_close()


	func _on_sell() -> void:
		var gold := game.sell(int(inst["uid"]))
		if gold > 0:
			main.play_sfx("thock")
			_close()


	func _on_salvage() -> void:
		var shards := game.salvage(int(inst["uid"]))
		if shards > 0:
			main.play_sfx("thock")
			_close()


	func _on_temper() -> void:
		var err: String = game.temper(slot)
		if err == "":
			main.play_sfx("chime")
			_close()
		else:
			_note.text = err


	func _close() -> void:
		main.close_overlay()
