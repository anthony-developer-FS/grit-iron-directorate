extends Node
## Plays sound effects from assets/sound (made by tools/sound/build.py). Autoloaded as `Sfx`.
## Call Sfx.play("name") from anywhere; a small pool of players lets sounds overlap.

const SOUNDS := ["pistol", "hmg", "shotgun", "flame", "rocket", "enemy_shot", "mg_shot", "flak",
	"cannon", "cannon_charge", "explosion", "explosion_big", "grenade_throw", "knife", "hit", "ping",
	"enemy_die", "player_hurt", "player_die", "jump", "pickup_weapon", "pickup_item", "pow_freed",
	"checkpoint", "supply_drop", "weapon_empty", "shell_whistle", "flare", "menu_move", "menu_select",
	"pause", "mission_complete", "game_over", "elevator", "alarm"]
## Per-sound mix, in dB. Anything not listed plays at 0 dB.
const VOLUME := {"hmg": -4.0, "mg_shot": -5.0, "enemy_shot": -3.0, "flame": -4.0, "hit": -6.0,
	"jump": -6.0, "shell_whistle": -4.0, "elevator": -6.0, "flak": -3.0}
const POOL_SIZE := 16
## The same sound won't restart more often than this, so rapid fire doesn't pile up.
const MIN_GAP := 0.03

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
## Headless runs (the tests, CI) have no audio output, and their dummy driver never finishes
## playbacks, so sounds are skipped there.
var _muted := DisplayServer.get_name() == "headless"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound in SOUNDS:
		_streams[sound] = load("res://assets/sound/%s.wav" % sound)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)
	Game.checkpoint_reached.connect(play.bind("checkpoint"))
	Game.mission_completed.connect(play.bind("mission_complete"))
	Game.game_over.connect(play.bind("game_over"))


## Plays `sound` with a little random pitch so repeats don't sound mechanical.
func play(sound: String, pitch_jitter := 0.05) -> void:
	if _muted:
		return
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		push_warning("Unknown sound: %s" % sound)
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < MIN_GAP:
		return
	_last_played[sound] = now
	var player := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = VOLUME.get(sound, 0.0)
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()

