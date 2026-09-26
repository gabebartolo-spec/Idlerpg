class_name VbRng
extends RefCounted

# Lehmer minimal-standard generator (48271 / 2^31 - 1).
# Integer-only, 64-bit safe in GDScript, fully deterministic across platforms.
# Consumed strictly in beat order, so a run replays identically from its seed.

const MODULUS := 2147483647
const MULTIPLIER := 48271

var _state: int


func _init(seed_value: int = 1) -> void:
	var s := absi(int(seed_value)) % MODULUS
	_state = s if s != 0 else 104729


func next_unit() -> float:
	_state = int((_state * MULTIPLIER) % MODULUS)
	return float(_state) / float(MODULUS)


func next_percent() -> int:
	return int(next_unit() * 100.0)


func next_int(max_exclusive: int) -> int:
	if max_exclusive <= 0:
		return 0
	return int(next_unit() * float(max_exclusive))


func pick(items: Array):
	if items.is_empty():
		return null
	return items[next_int(items.size())]


func roll(percent: int) -> bool:
	return next_percent() < percent
