extends "res://src/ui/sheet.gd"
signal changed
const Art = preload("res://src/data/art_catalog.gd")
const Looks = preload("res://src/data/appearance_catalog.gd")
const Trails = preload("res://src/data/expedition_catalog.gd")
var sim: Node
var settings: RefCounted
var chest: Control
var list: Control
var action_button: Button
var wear_button: Button
var viewing: Dictionary = {}

func setup(sim_node: Node, preferences: RefCounted) -> void:
	sim = sim_node
	settings = preferences
	var column := build_sheet("Trail rewards", .20)
	chest = preload("res://src/ui/chest_art.gd").new()
	column.add_child(chest)
	list = add_list(column)
	action_button = Style.button("Open chest", true)
	action_button.pressed.connect(_action)
	column.add_child(action_button)
	wear_button = Style.button("Wear your new look")
	wear_button.pressed.connect(func() -> void:
		var gear := str(viewing.get("gear", ""))
		var applied: bool = sim.equip_gear(gear) if not gear.is_empty() else sim.wardrobe.wear(str(viewing.get("look", "")))
		if applied:
			refresh()
			changed.emit())
	column.add_child(wear_button)
	refresh()

func open() -> void:
	viewing.clear()
	super.open()

func _action() -> void:
	if not viewing.is_empty():
		viewing.clear()
		if sim.reward_chests.pending.is_empty():
			close()
		else:
			refresh()
		return
	if not sim.reward_chests.pending.is_empty():
		viewing = sim.claim_reward_chest(sim.reward_chests.pending[0]["id"])
		refresh()
		changed.emit()

func refresh() -> void:
	clear_list(list)
	chest.reduced_motion = settings.reduced_motion
	chest.opened = not viewing.is_empty()
	subtitle_label.text = "%d chest%s ready" % [sim.reward_chests.pending.size(), "" if sim.reward_chests.pending.size() == 1 else "s"]
	var gear := str(viewing.get("gear", ""))
	var look := str(viewing.get("look", ""))
	wear_button.visible = not gear.is_empty() or not look.is_empty()
	wear_button.disabled = sim.equipped_item(GearCatalog.slot(gear)) == gear if not gear.is_empty() else (not look.is_empty() and sim.wardrobe.equipped.get(Looks.LOOKS[look]["slot"], "") == look)
	wear_button.text = ("Equipped" if wear_button.disabled else "Equip new gear") if not gear.is_empty() else ("Wearing" if wear_button.disabled else "Wear your new look")
	if not viewing.is_empty():
		list.content.add_child(Style.label("+%d gold" % viewing["gold"], 32, Style.ACCENT))
		if not gear.is_empty():
			var line := HBoxContainer.new()
			add_icon(line, Art.item_icon(gear))
			var words := Style.label(gear, 28)
			words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(words)
			list.content.add_child(line)
			var stats: Array[String] = []
			if GearCatalog.attack_bonus(gear) > 0: stats.append("+%d ATK" % GearCatalog.attack_bonus(gear))
			if GearCatalog.hp_bonus(gear) > 0: stats.append("+%d HP" % GearCatalog.hp_bonus(gear))
			stats.append(str(GearCatalog.EFFECTS.get(GearCatalog.effect(gear), {}).get("name", "")))
			list.content.add_child(Style.label(" · ".join(stats), 24, Style.ACCENT))
		if not str(viewing["look"]).is_empty():
			var item: Dictionary = Looks.LOOKS[viewing["look"]]
			var line := HBoxContainer.new()
			add_icon(line, Art.item_icon(item["item"]))
			var label := Style.label(item["name"], 28)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_child(label)
			list.content.add_child(line)
			list.content.add_child(Style.label("Yours to keep · appearance only", 24, Style.MUTED))
		action_button.text = "Next chest" if not sim.reward_chests.pending.is_empty() else "Back to adventure"
		action_button.disabled = false
	elif not sim.reward_chests.pending.is_empty():
		var receipt: Dictionary = sim.reward_chests.pending[0]
		list.content.add_child(Style.label(Trails.ROUTES[receipt["route"]]["name"], 28))
		list.content.add_child(Style.label("Earned on your adventure", 24, Style.MUTED))
		action_button.text = "Open chest"
		action_button.disabled = false
	else:
		list.content.add_child(Style.label("Your next trail holds a reward.", 24, Style.MUTED))
		action_button.text = "No chests waiting"
		action_button.disabled = true
