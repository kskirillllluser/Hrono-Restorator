extends Node

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music2: AudioStreamPlayer
var _cache := {}
var _current := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music2 = AudioStreamPlayer.new()
	add_child(_music)
	add_child(_music2)
	for m in [_music, _music2]:
		m.finished.connect(func(): if m.volume_db > -40.0: m.play())
	set_volume(G.volume)

func _stream(snd: String) -> AudioStream:
	if not _cache.has(snd):
		_cache[snd] = load("res://audio/%s.wav" % snd)
	return _cache[snd]

func play(snd: String, vol_db := 0.0, pitch := 1.0) -> void:
	for p in _pool:
		if not p.playing:
			p.stream = _stream(snd)
			p.volume_db = vol_db
			p.pitch_scale = pitch
			p.play()
			return

func music(track: String, fade := 1.5) -> void:
	if track == _current:
		return
	_current = track
	var old := _music
	_music = _music2
	_music2 = old
	if track != "":
		_music.stream = _stream(track)
		_music.volume_db = -40
		_music.play()
		create_tween().tween_property(_music, "volume_db", -6.0, fade)
	var tw := create_tween()
	tw.tween_property(_music2, "volume_db", -60.0, fade)
	tw.tween_callback(_music2.stop)

func set_volume(v: float) -> void:
	G.volume = v
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.001)))
