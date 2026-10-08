extends Node

const MUSIC = preload("res://assets/audio/quiet_trail.wav")
const REWARD = preload("res://assets/audio/reward.wav")
const PICKUP = preload("res://assets/audio/pickup.wav")
var preferences: RefCounted
var music_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer
var suspended: bool = false

func setup(settings: RefCounted) -> void:
	preferences = settings
	music_player = AudioStreamPlayer.new()
	var loop: AudioStreamWAV = MUSIC.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(round(loop.get_length() * loop.mix_rate))
	music_player.stream = loop
	music_player.volume_db = -12.0
	add_child(music_player)
	effect_player = AudioStreamPlayer.new()
	effect_player.volume_db = -10.0
	add_child(effect_player)
	apply_preferences()

func apply_preferences() -> void:
	if not is_instance_valid(music_player) or not is_instance_valid(effect_player):
		return
	if suspended:
		music_player.stop()
		effect_player.stop()
		return
	if preferences.music:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()
	if not preferences.sounds:
		effect_player.stop()

func play_event(type: String, successful: bool = true) -> bool:
	if preferences == null or suspended or not preferences.sounds or effect_player.playing:
		return false
	if type in ["practice_completed", "expedition_completed"] and not successful:
		return false
	match type:
		"level_up", "boss_defeated", "practice_completed", "expedition_completed", "chest_opened":
			effect_player.stream = REWARD
		"gear_obtained", "relic_obtained", "stew_prepared":
			effect_player.stream = PICKUP
		_:
			return false
	effect_player.play()
	return true

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		suspended = true
		apply_preferences()
	elif what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		suspended = false
		apply_preferences()

func _exit_tree() -> void:
	# Release active playback and duplicated loop data when the scene closes.
	for player in [music_player, effect_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
