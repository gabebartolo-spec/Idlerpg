extends RefCounted

# One token per twelve simulated minutes, independent of quests and check-ins.
const INTERVAL_USEC := 720000000
const TOKENS_PER_DAY := 120
var remainder_usec: int = 0
var total: int = 0

func advance(seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	var elapsed: int = int(round(seconds * 1000000.0)) + remainder_usec
	total += elapsed / INTERVAL_USEC
	remainder_usec = elapsed % INTERVAL_USEC

func to_save_dict() -> Dictionary:
	return {"remainder_usec": remainder_usec, "total": total}

func load_save_dict(data: Dictionary) -> void:
	remainder_usec = clampi(int(data.get("remainder_usec", 0)), 0, INTERVAL_USEC - 1)
	total = maxi(0, int(data.get("total", 0)))
