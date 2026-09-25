extends RefCounted

var value: int


func _init(start_time: int = 0) -> void:
	value = start_time


func now() -> int:
	return value
