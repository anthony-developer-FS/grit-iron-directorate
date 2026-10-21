extends Node
## Global game state and shared signals. Autoloaded as `Game`.

signal score_changed(score: int)
signal lives_changed(lives: int)
signal grenades_changed(grenades: int)
signal weapon_changed(label: String, ammo: int)
signal pows_changed(count: int)
signal shake_requested(strength: float, duration: float)
signal message_requested(text: String, duration: float)
signal game_over
signal continued

const START_LIVES := 3
const START_GRENADES := 10

var score := 0
var lives := START_LIVES
var grenades := START_GRENADES
var pows_rescued := 0
var is_game_over := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func use_grenade() -> bool:
	if grenades <= 0:
		return false
	grenades -= 1
	grenades_changed.emit(grenades)
	return true


func add_grenades(amount: int) -> void:
	grenades += amount
	grenades_changed.emit(grenades)


func reset_grenades() -> void:
	grenades = START_GRENADES
	grenades_changed.emit(grenades)


func set_weapon(label: String, ammo: int) -> void:
	weapon_changed.emit(label, ammo)


func rescue_pow() -> void:
	pows_rescued += 1
	pows_changed.emit(pows_rescued)
	add_score(500)


## Takes a life away. Returns true if the player can respawn, false on game over.
func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	if lives > 0:
		return true
	is_game_over = true
	get_tree().paused = true
	game_over.emit()
	return false


## Called from the game over screen. Resets the score (arcade rules) and resumes play.
func continue_game() -> void:
	is_game_over = false
	score = 0
	lives = START_LIVES
	score_changed.emit(score)
	lives_changed.emit(lives)
	reset_grenades()
	get_tree().paused = false
	continued.emit()


func shake(strength: float, duration: float) -> void:
	shake_requested.emit(strength, duration)


func show_message(text: String, duration := 2.0) -> void:
	message_requested.emit(text, duration)


func _setup_input() -> void:
	_bind("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_bind("aim_up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_bind("crouch", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_bind("jump", [KEY_Z, KEY_SPACE], [JOY_BUTTON_A])
	_bind("shoot", [KEY_X, KEY_J], [JOY_BUTTON_X])
	_bind("grenade", [KEY_C, KEY_K], [JOY_BUTTON_B])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_bind("toggle_fullscreen", [KEY_F11])


## Adds default bindings for an action unless the project already defines it,
## so bindings set in Project Settings (or a future remap menu) take priority.
func _bind(action: StringName, keys: Array, buttons: Array = [], axis := -1, axis_value := 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.4)
	for key in keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key
		InputMap.action_add_event(action, key_event)
	for button in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = button
		InputMap.action_add_event(action, button_event)
	if axis >= 0:
		var motion_event := InputEventJoypadMotion.new()
		motion_event.axis = axis
		motion_event.axis_value = axis_value
		InputMap.action_add_event(action, motion_event)
