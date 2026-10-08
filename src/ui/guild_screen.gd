extends "res://src/ui/sheet.gd"
signal changed
const Online = preload("res://src/services/online_adventure.gd")
const Chest = preload("res://src/ui/chest_art.gd")
const Art = preload("res://src/data/art_catalog.gd")
const Looks = preload("res://src/data/appearance_catalog.gd")
var online: Node
var sim: Node
var settings: RefCounted
var page := "guild"
var selected_build := "trail"
var tabs: Dictionary
var scroll: ScrollContainer
var body: VBoxContainer
var notice_label: Label
var refresh_button: Button
var fields: Dictionary = {}
var buttons: Dictionary = {}
var show_recover := false
var show_connection := false
var details := false

func setup(sim_node: Node, preferences: RefCounted, storage_path: String = "user://idle_rpg_online.json") -> void:
	sim = sim_node
	settings = preferences
	online = Online.new()
	add_child(online)
	online.setup(sim, storage_path)
	online.updated.connect(refresh)
	online.appearance_changed.connect(func() -> void: changed.emit())
	var column := build_sheet("Guild", 0.20)
	tabs = add_tabs(column, [["guild", "Guild"], ["raid", "Raid"], ["supplies", "Supplies"]], func(id: String) -> void:
		page = id
		online.reveal.clear()
		refresh()
		scroll.scroll_vertical = 0)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	notice_label = Style.label("", 20, Style.MUTED)
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(notice_label)
	refresh_button = Style.button("Refresh")
	refresh_button.pressed.connect(online.sync)
	column.add_child(refresh_button)
	refresh()

func open() -> void:
	online.reveal.clear()
	super.open()
	online.sync()

func _text(value: String, size_: int = 24, color_: Color = Style.TEXT) -> Label:
	var label := Style.label(value, size_, color_)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(label)
	return label

func _button(id: String, title: String, callback: Callable, primary: bool = false) -> Button:
	var button := Style.button(title, primary)
	button.disabled = online.busy
	button.pressed.connect(callback)
	body.add_child(button)
	buttons[id] = button
	return button

func _field(id: String, placeholder: String, value: String = "", secret: bool = false) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.text = value
	field.secret = secret
	field.custom_minimum_size.y = Style.TOUCH
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_font_override("font", Style.FONT)
	field.add_theme_font_size_override("font_size", 24)
	field.editable = not online.busy
	body.add_child(field)
	fields[id] = field
	return field

func refresh() -> void:
	if body == null:
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	fields.clear()
	buttons.clear()
	mark_tabs(tabs, page)
	subtitle_label.text = "Connecting…" if online.busy else ("Guild playtest" if online.profile.is_empty() else "%d supply gold" % int(online.profile.get("gold", 0)))
	notice_label.text = online.notice
	notice_label.visible = not online.notice.is_empty()
	refresh_button.disabled = online.busy or online.client.token.is_empty()
	if online.session.data.has("pending"):
		_button("retry", "Retry interrupted action", online.retry, true)
	if online.client.endpoint.is_empty() or show_connection:
		_connection()
	elif not online.recovery_key.is_empty():
		_recovery_details()
	elif online.client.token.is_empty():
		_sign_in()
	elif not online.reveal.is_empty() and page == "raid":
		_reward()
	elif page == "account":
		_account()
	elif page == "supplies":
		_supplies()
	elif page == "raid":
		_raid()
	else:
		_guild()

func _connection() -> void:
	_text("Playtest connection", 28)
	_text("Use the address in your playtest invitation.", 22, Style.MUTED)
	_field("endpoint", "https://…", online.client.endpoint)
	_button("connect", "Connect", func() -> void:
		var url: String = fields["endpoint"].text
		show_connection = false
		online.connect_service(url), true)
	if not online.client.endpoint.is_empty():
		_button("cancel_connection", "Keep current connection", func() -> void: show_connection = false; refresh())

func _sign_in() -> void:
	if show_recover:
		_text("Recover your adventurer", 28)
		_field("account_id", "Account ID")
		_field("recovery", "Recovery key", "", true)
		_button("recover", "Recover account", func() -> void:
			var id: String = fields["account_id"].text
			var key: String = fields["recovery"].text
			online.recover(id, key), true)
		_button("new", "New adventurer", func() -> void: show_recover = false; refresh())
	else:
		_text("Adventure together", 28)
		_field("name", "Adventurer name", sim.identity.adventurer_name)
		_button("create", "Create online adventurer", func() -> void:
			var name_: String = fields["name"].text
			online.create_account(name_), true)
		_button("existing", "I have recovery details", func() -> void: show_recover = true; refresh())
	_text("Your solo adventure stays yours.", 22, Style.MUTED)
	_button("connection", "Connection", func() -> void: show_connection = true; refresh())

func _recovery_details() -> void:
	_text("Keep your recovery details", 28)
	_text("Save these privately. They restore your online adventurer on another device.", 22, Style.MUTED)
	_field("id_copy", "Account ID", online.client.account_id).editable = false
	_field("key_copy", "Recovery key", online.recovery_key, true).editable = false
	_button("copy_recovery", "Copy recovery details", func() -> void:
		DisplayServer.clipboard_set(online.client.account_id + "\n" + online.recovery_key)
		online.notice = "Copied · save privately"
		notice_label.text = online.notice
		notice_label.visible = true)
	_button("saved_recovery", "I saved them · continue", func() -> void:
		online.recovery_key = ""
		page = "guild"
		refresh(), true)

func _guild() -> void:
	if online.guild.is_empty():
		_text("Find your party", 28)
		_field("guild_name", "Guild name")
		_button("create_guild", "Create guild", func() -> void:
			var name_: String = fields["guild_name"].text
			online.action("/v1/guilds", {"name": name_}), true)
		_field("invite", "Guild invite")
		_button("join_guild", "Join guild", func() -> void:
			var invite: String = fields["invite"].text
			online.action("/v1/guild/join", {"invite": invite}))
		_button("account", "Account", func() -> void: page = "account"; refresh())
		return
	_text(str(online.guild["name"]), 28)
	for member in online.guild["members"]:
		_text(str(member["name"]) + (" · Leader" if member["id"] == online.guild["leader"] else ""), 24)
	_button("go_raid", "Prepare for the Warden", func() -> void: page = "raid"; refresh(), true)
	_button("copy_invite", "Copy guild invite", func() -> void:
		DisplayServer.clipboard_set(str(online.guild["invite"]))
		online.notice = "Guild invite copied"
		notice_label.text = online.notice
		notice_label.visible = true)
	_button("account", "Account", func() -> void: page = "account"; refresh())

func _account() -> void:
	_text(str(online.profile.get("name", "Adventurer")), 28)
	_field("account_id", "Account ID", online.client.account_id).editable = false
	if not online.guild.is_empty():
		_button("leave", "Leave guild", online.action.bind("/v1/guild/leave"))
	_button("signout", "Sign out", online.sign_out)
	_button("connection", "Connection", func() -> void: show_connection = true; refresh())
	_button("back_guild", "Back to guild", func() -> void: page = "guild"; refresh())

func _supplies() -> void:
	_text("Guild supplies", 28)
	var outing: Variant = online.profile.get("outing")
	if outing is Dictionary:
		var ready := int(outing["ready"]) <= int(online.profile.get("server_time", 0))
		_text("Supply chest ready" if ready else "Supply outing · five minutes", 24)
		if ready:
			_button("supply_open", "Open supply chest", func() -> void:
				page = "raid"
				online.action("/v1/outings/" + str(outing["id"]) + "/open"), true)
	else:
		_button("supply_start", "Send on supply outing", func() -> void: online.action("/v1/outings"), true)
	for build in ["thornward", "keeper"]:
		if build not in online.profile.get("builds", []):
			var cost := int(online.build_costs.get(build, -1))
			if cost >= 0:
				_button("buy_" + build, "%s build · %d gold" % [str(build).capitalize(), cost], online.action.bind("/v1/builds", {"build": build})).disabled = online.busy or int(online.profile.get("gold", 0)) < cost
	_button("build_details", "Build details", func() -> void: details = not details; refresh())
	if details:
		_text("Raid builds supply their own stats. Solo gear stays on your adventure.", 22, Style.MUTED)
		for build in online.build_catalog:
			var stats: Dictionary = online.build_catalog[build]
			_text("%s · %d HP\n%d damage · %d protection · %d healing" % [str(build).capitalize(), stats["hp"], stats["attack"], stats["shield"], stats["heal"]], 22)

func _raid() -> void:
	if not online.profile.get("raid_chests", []).is_empty():
		var receipt: Dictionary = online.profile["raid_chests"][0]
		var chest := Chest.new()
		chest.reduced_motion = settings.reduced_motion
		body.add_child(chest)
		_text("Your raid chest is ready", 28)
		_button("raid_open", "Open your chest", online.action.bind("/v1/raids/" + str(receipt["raid"]) + "/open"), true)
		return
	if online.raids.is_empty():
		_text("The Hollow Warden", 28)
		_text("Three adventurers. Prepare, then come back tomorrow.", 24, Style.MUTED)
		if not online.guild.is_empty() and online.guild["leader"] == online.client.account_id:
			_button("start_raid", "Start preparation", online.action.bind("/v1/raids"), true)
		else:
			_text("Your guild leader can start the raid.", 24, Style.MUTED)
		return
	var raid: Dictionary = online.raids[0]
	var path_ := "/v1/raids/" + str(raid["id"])
	_text("The Hollow Warden", 28)
	if raid.get("result") is Dictionary:
		_text("Victory" if raid["result"]["won"] else "Another try awaits", 28, Style.ACCENT)
		var mine: Dictionary = raid["result"]["contributions"].get(online.client.account_id, {})
		if not mine.is_empty():
			_text("%d damage · %d protected\n%d healed · %d seals" % [mine["damage"], mine["prevented"], mine["healed"], mine["seals"]], 22)
		if not online.guild.is_empty() and online.guild["leader"] == online.client.account_id:
			_button("start_raid", "Prepare another raid", online.action.bind("/v1/raids"), true)
		return
	var remaining := maxi(0, int(raid["ready"]) - int(raid["server_time"]))
	_text("Leaves in %dh %dm" % [remaining / 3600, (remaining % 3600) / 60], 24, Style.ACCENT)
	for member in raid["roster"]:
		_text("%s · %s" % [member["name"], str(member["role"]).capitalize()], 24)
	if remaining == 0:
		_button("result", "Check result", online.sync, true)
		return
	var choices := OptionButton.new()
	choices.custom_minimum_size.y = Style.TOUCH
	choices.add_theme_font_override("font", Style.FONT)
	choices.add_theme_font_size_override("font_size", 24)
	choices.add_theme_stylebox_override("normal", Style.box(Style.RAISED))
	var builds: Array = online.profile.get("builds", ["trail"])
	for build in builds:
		choices.add_item(str(build).capitalize() + " build")
	choices.select(maxi(0, builds.find(selected_build)))
	selected_build = str(builds[choices.selected])
	choices.item_selected.connect(func(index: int) -> void: selected_build = str(builds[index]))
	body.add_child(choices)
	for role in ["damage", "protection", "preparation"]:
		var occupant := ""
		for member in raid["roster"]:
			if member["role"] == role:
				occupant = str(member["account"])
		var mine: bool = occupant == online.client.account_id
		if not occupant.is_empty() and not mine:
			continue
		var title: String = ("Update " + str(role) + " build") if mine else ("Prepare " + str(role))
		_button("role_" + role, title, func() -> void: online.action(path_ + "/enroll", {"role": role, "build": selected_build}), mine)
	for member in raid["roster"]:
		if member["account"] == online.client.account_id:
			_button("withdraw", "Withdraw preparation", online.action.bind(path_ + "/withdraw"))
	_button("details", "Role details", func() -> void: details = not details; refresh())
	if details:
		_text("Damage defeats the Warden. Protection stops heavy blows. Preparation breaks seals and heals. Starter builds can win together.", 22, Style.MUTED)
		var stats: Dictionary = online.build_catalog.get(selected_build, {})
		if not stats.is_empty():
			_text("%d HP · %d damage\n%d protection · %d healing" % [stats["hp"], stats["attack"], stats["shield"], stats["heal"]], 22)
		_text("Raid builds supply their own stats. Solo gear stays on your adventure.", 22, Style.MUTED)

func _reward() -> void:
	var chest := Chest.new()
	chest.opened = true
	chest.reduced_motion = settings.reduced_motion
	body.add_child(chest)
	_text("+%d supply gold" % int(online.reveal.get("gold", 0)), 32, Style.ACCENT)
	var look := str(online.reveal.get("look", ""))
	if Looks.LOOKS.has(look):
		var line := HBoxContainer.new()
		add_icon(line, Art.item_icon(str(Looks.LOOKS[look]["item"])))
		var label := Style.label(str(Looks.LOOKS[look]["name"]), 28)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(label)
		body.add_child(line)
		_button("wear", "Wear your new look", func() -> void:
			if sim.wardrobe.wear(look):
				changed.emit()
				online.notice = "Wearing your Warden lantern"
				refresh(), true)
	_button("done", "Back to raid", func() -> void: online.reveal.clear(); refresh())
