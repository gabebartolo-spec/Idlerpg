extends TextureRect

# Prefer Godot's imported textures (including exported remaps). The raw-file
# fallback allows headless tests and a first run before the editor import pass.
static var _textures: Dictionary = {}


func _init(path: String = "", height: float = 136.0) -> void:
	custom_minimum_size.y = height
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if path != "":
		texture = get_art(path)


static func get_art(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var result: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		result = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			result = ImageTexture.create_from_image(image)
	if result != null:
		_textures[path] = result
	return result
