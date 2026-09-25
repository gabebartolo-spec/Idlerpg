class_name BrambleGameClock
extends RefCounted


func now() -> int:
	return int(Time.get_unix_time_from_system())
