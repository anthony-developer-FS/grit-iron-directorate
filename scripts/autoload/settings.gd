extends Node
## Player settings: music and effects volume and fullscreen, saved to user://settings.cfg.
## Autoloaded as `Settings`. Also makes the pixel font the default for all text.

const PATH := "user://settings.cfg"
const PixelFont := preload("res://assets/fonts/pixel.fnt")
## Volume steps shown on the options screen. DEFAULT_LEVEL plays the buses at the levels in
## default_bus_layout.tres; the top steps go a little louder.
const MAX_LEVEL := 10
const DEFAULT_LEVEL := 8

var music_level := DEFAULT_LEVEL
var sfx_level := DEFAULT_LEVEL
var fullscreen := false

var _base_db := {}
var _windowed := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ThemeDB.fallback_font = PixelFont
	_windowed = DisplayServer.get_name() != "headless"
	for bus in ["Music", "SFX"]:
		_base_db[bus] = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		music_level = clampi(config.get_value("audio", "music", DEFAULT_LEVEL), 0, MAX_LEVEL)
		sfx_level = clampi(config.get_value("audio", "sfx", DEFAULT_LEVEL), 0, MAX_LEVEL)
		fullscreen = config.get_value("display", "fullscreen", false)
	_apply_volume("Music", music_level)
	_apply_volume("SFX", sfx_level)
	_apply_fullscreen()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(not fullscreen)


func set_music_level(level: int) -> void:
	music_level = clampi(level, 0, MAX_LEVEL)
	_apply_volume("Music", music_level)
	_save()


func set_sfx_level(level: int) -> void:
	sfx_level = clampi(level, 0, MAX_LEVEL)
	_apply_volume("SFX", sfx_level)
	_save()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	_save()


func _apply_volume(bus: String, level: int) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, level == 0)
	AudioServer.set_bus_volume_db(index, _base_db[bus] + linear_to_db(float(level) / DEFAULT_LEVEL))


func _apply_fullscreen() -> void:
	if not _windowed:
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_level)
	config.set_value("audio", "sfx", sfx_level)
	config.set_value("display", "fullscreen", fullscreen)
	config.save(PATH)
