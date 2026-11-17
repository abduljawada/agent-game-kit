extends Node
## Sound effects and music. Creates "Music" and "SFX" buses if the project has none, so
## Settings.master_volume and per-bus volumes work without editor setup.
##   Audio.play(preload("res://.../jump1.ogg"))          # one-shot SFX, slight pitch variation
##   Audio.play_music(preload("res://.../theme.ogg"))     # loops; crossfades from the old track
##   Audio.set_bus_volume(&"SFX", 0.5)                    # linear 0..1

const SFX_BUS := &"SFX"
const MUSIC_BUS := &"Music"
const VOICES := 12

var _voices: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer
var _fading: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_voices.append(p)
	_music = _make_music_player()
	_fading = _make_music_player()


## Plays a one-shot sound. pitch_jitter randomises pitch by ± that fraction so repeated
## sounds (footsteps, coins) don't sound identical. Returns the player used.
func play(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> AudioStreamPlayer:
	if stream == null:
		return null
	var p := _voices[_next]
	_next = (_next + 1) % _voices.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
	return p


func play_music(stream: AudioStream, fade_seconds: float = 0.8, volume_db: float = -6.0) -> void:
	if _music.stream == stream and _music.playing:
		return
	var old := _music
	_music = _fading
	_fading = old
	_music.stream = stream
	_music.volume_db = -40.0 if fade_seconds > 0.0 else volume_db
	if stream:
		_music.play()
	var tw := create_tween().set_parallel()
	tw.tween_property(_music, "volume_db", volume_db, fade_seconds)
	tw.tween_property(_fading, "volume_db", -40.0, fade_seconds)
	tw.chain().tween_callback(_fading.stop)


func stop_music(fade_seconds: float = 0.8) -> void:
	play_music(null, fade_seconds)


func set_bus_volume(bus: StringName, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, &"Master")


func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = MUSIC_BUS
	add_child(p)
	p.finished.connect(func() -> void:
		if p == _music and p.stream:
			p.play())
	return p
