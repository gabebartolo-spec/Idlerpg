extends Node

var preferences: RefCounted
var scope: Node

func setup(settings: RefCounted, canvas: Node) -> void:
	preferences = settings
	scope = canvas
	get_tree().node_added.connect(_new_node)
	apply()

func _new_node(node: Node) -> void:
	if is_instance_valid(scope) and scope.is_ancestor_of(node):
		call_deferred("_apply_added", node.get_instance_id())

func _apply_added(instance_id: int) -> void:
	# A screen may rebuild/free a row in the same frame it creates it. Resolve
	# its ID after deferral rather than passing a possibly freed typed Node.
	var node := instance_from_id(instance_id)
	if is_instance_valid(node):
		_apply_node(node)

func apply() -> void:
	if is_instance_valid(scope):
		_walk(scope)

func _walk(node: Node) -> void:
	_apply_node(node)
	for child in node.get_children():
		_walk(child)

func _apply_node(node: Node) -> void:
	if not is_instance_valid(node) or preferences == null:
		return
	if node.has_method("set_reduced_motion"):
		node.set_reduced_motion(preferences.reduced_motion)
	if node is Label or node is Button or node is LineEdit:
		# Header subtitles intentionally clip to one line. Their title/action stay
		# full size; growing body copy must not hide the Back control.
		if node is Label and node.clip_text:
			return
		if not node.has_meta("reading_base_size"):
			node.set_meta("reading_base_size", node.get_theme_font_size("font_size"))
		var base: int = node.get_meta("reading_base_size")
		node.add_theme_font_size_override("font_size", base + (4 if preferences.larger_text and base <= 26 else 0))
