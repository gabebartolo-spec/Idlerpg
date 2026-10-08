extends RefCounted

# Player comfort belongs outside combat and economy state.
var larger_text: bool = false
var reduced_motion: bool = false

func to_save_dict() -> Dictionary:
	return {"larger_text": larger_text, "reduced_motion": reduced_motion}

func load_save_dict(raw: Variant) -> void:
	larger_text = false
	reduced_motion = false
	if not raw is Dictionary:
		return
	if raw.get("larger_text") is bool:
		larger_text = raw["larger_text"]
	if raw.get("reduced_motion") is bool:
		reduced_motion = raw["reduced_motion"]
