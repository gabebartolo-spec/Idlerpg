extends RefCounted

# Tiny procedural sound kit — no audio files, all PCM synthesized at startup.
# A bell is a couple of inharmonic partials with a long decay; that is the
# whole vocabulary: toll, knell, chime, thock.

const RATE := 22050

var _players: Array = []
var _sounds := {}
var enabled := true


func _init(parent: Node) -> void:
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		parent.add_child(p)
		_players.append(p)
	_sounds["toll"] = _bell_tone(196.0, 1.8, 0.42)
	_sounds["knell"] = _bell_tone(98.0, 2.4, 0.5)
	_sounds["chime"] = _chime([523.25, 659.25, 783.99], 0.9)
	_sounds["chime_high"] = _chime([659.25, 783.99, 1046.5, 1318.5], 1.1)
	_sounds["thock"] = _thock()


func play(sound_name: String) -> void:
	if not enabled or not _sounds.has(sound_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sounds[sound_name]
			p.play()
			return
	_players[0].stream = _sounds[sound_name]
	_players[0].play()


func _render(seconds: float, sample: Callable) -> AudioStreamWAV:
	var count := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(RATE)
		var v: float = clampf(sample.call(t), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


func _bell_tone(freq: float, seconds: float, vol: float) -> AudioStreamWAV:
	return _render(seconds, func(t: float) -> float:
		var env := exp(-2.2 * t) * (1.0 - exp(-160.0 * t))
		var v := 0.0
		v += sin(TAU * freq * t) * 0.55
		v += sin(TAU * freq * 2.76 * t) * 0.22 * exp(-3.5 * t)
		v += sin(TAU * freq * 5.40 * t) * 0.10 * exp(-5.0 * t)
		return v * env * vol
	)


func _chime(freqs: Array, seconds: float) -> AudioStreamWAV:
	return _render(seconds, func(t: float) -> float:
		var v := 0.0
		for i in freqs.size():
			var start := float(i) * 0.11
			if t >= start:
				var lt := t - start
				var env := exp(-4.5 * lt) * (1.0 - exp(-300.0 * lt))
				v += sin(TAU * float(freqs[i]) * lt) * env * 0.30
		return v * 0.9
	)


func _thock() -> AudioStreamWAV:
	return _render(0.18, func(t: float) -> float:
		var env := exp(-26.0 * t)
		var knock := sin(TAU * 82.0 * t) * 0.8
		var click := (1.0 - t * 90.0) * 0.25 if t < 0.011 else 0.0
		return (knock + click) * env
	)
