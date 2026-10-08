extends SceneTree

const Audio = preload("res://src/view/trail_audio.gd")
const Preferences = preload("res://src/state/presentation_preferences.gd")
const Sim = preload("res://src/sim/adventurer_sim.gd")
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func _run() -> void:
	var preferences: RefCounted = Preferences.new()
	var audio: Node = Audio.new()
	root.add_child(audio)
	audio.setup(preferences)
	check(not audio.music_player.playing and not audio.effect_player.playing, "a new adventure starts quietly")
	check(not audio.play_event("level_up"), "disabled sounds never start playback")
	preferences.music = true
	audio.apply_preferences()
	await process_frame
	check(audio.music_player.playing and not audio.effect_player.playing, "music can play independently of reward sounds")
	var stream: AudioStreamWAV = audio.music_player.stream
	check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end == 529200 and is_equal_approx(stream.get_length(), 24.0), "the original trail sketch loops over its exact sample range")
	check(stream.data.size() <= 1100000 and not stream.stereo, "the background loop stays within the small mono asset budget")
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not audio.music_player.playing and not audio.play_event("level_up") and preferences.music, "backgrounding stops playback without changing saved choices")
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(audio.music_player.playing, "returning to the game restores opted-in music")
	preferences.music = false
	preferences.sounds = true
	audio.apply_preferences()
	check(not audio.music_player.playing and audio.play_event("gear_obtained"), "reward sounds can play independently of music")
	check(audio.effect_player.stream == Audio.PICKUP and not audio.play_event("gear_obtained"), "a reward burst makes one sound without restarting it for every item")
	audio.effect_player.stop()
	check(not audio.play_event("practice_completed", false) and not audio.play_event("expedition_completed", false), "failed runs do not play victory sounds")
	check(not audio.play_event("hero_attack") and audio.play_event("level_up"), "ordinary combat stays quiet while milestones have a short cue")
	check(audio.effect_player.stream == Audio.REWARD, "milestones use the original reward chime")
	preferences.sounds = false
	audio.apply_preferences()
	check(not audio.effect_player.playing, "turning sounds off stops a currently playing cue")
	preferences.music = true
	preferences.sounds = true
	var restored: RefCounted = Preferences.new()
	restored.load_save_dict(JSON.parse_string(JSON.stringify(preferences.to_save_dict())))
	check(restored.music and restored.sounds, "both audio choices survive save JSON")
	restored.load_save_dict({"larger_text": true, "reduced_motion": true})
	check(restored.larger_text and restored.reduced_motion and not restored.music and not restored.sounds, "older comfort records keep their choices and default audio off")
	var sim: Node = Sim.new()
	root.add_child(sim)
	var before: Dictionary = sim.to_save_dict()
	preferences.sounds = true
	audio.apply_preferences()
	audio.play_event("expedition_completed")
	check(sim.to_save_dict() == before, "audio playback changes no adventurer state or outcome")
	sim.free()
	audio.free()
	stream = null
	# Let the audio mixer retire stopped playback before the test process exits.
	await create_timer(0.3).timeout
	print("Audio tests complete: %d failure(s)" % failures)
	quit(failures)
