class_name BrambleSeededRng
extends RefCounted

# A tiny deterministic generator is enough for this prototype. It uses only
# integer arithmetic so replay results do not depend on frame timing or UI.
const MODULUS := 2147483647
const MULTIPLIER := 1103515245
const INCREMENT := 12345

var _state: int


func _init(seed_value: int = 1) -> void:
	_state = abs(seed_value) % MODULUS
	if _state == 0:
		_state = 104729


func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		return 0
	_state = int((_state * MULTIPLIER + INCREMENT) % MODULUS)
	return _state % max_exclusive


func next_percent() -> int:
	return next_int(100)
