extends Node
## Background music. Autoloaded as `Music`. Tracks come from tools/sound/music.py and loop.
## Switching tracks fades the old one out and the new one in.

const TRACKS := ["mission", "boss"]
const FADE_TIME := 0.8
const SILENT_DB := -40.0

var current := ""

var _streams := {}
var _player: AudioStreamPlayer
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	add_child(_player)
	for track in TRACKS:
		var stream := load("res://assets/sound/music_%s.ogg" % track) as AudioStreamOggVorbis
		stream.loop = true
		_streams[track] = stream
	Game.mission_completed.connect(stop)
	Game.game_over.connect(stop)
	Game.continued.connect(func() -> void: play("boss" if current == "boss" else "mission"))


func play(track: String) -> void:
	# No audio output when headless (tests, CI); see Sfx.
	if DisplayServer.get_name() == "headless":
		current = track
		return
	if track == current and _player.playing:
		return
	current = track
	_fade_to(func() -> void:
		_player.stream = _streams[track]
		_player.play())


func stop() -> void:
	_fade_to(_player.stop)


func _fade_to(then: Callable) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if _player.playing:
		_tween.tween_property(_player, "volume_db", SILENT_DB, FADE_TIME * 0.5)
	_tween.tween_callback(then)
	_tween.tween_property(_player, "volume_db", 0.0, FADE_TIME * 0.5)
