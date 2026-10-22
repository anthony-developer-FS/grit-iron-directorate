extends Node
## Headless smoke test: a bot plays the test range and checks the core systems work.
## Run: godot --headless --fixed-fps 60 res://tests/smoke_test.tscn
## Exits with code 0 on success, 1 on failure.

const LevelScene := preload("res://scenes/levels/test_range.tscn")
const TIME_LIMIT := 60.0
## Left edges of the sandbags, the pit, the bunker and the second sandbags in test_range.tscn.
const JUMP_POINTS := [260.0, 700.0, 900.0, 1460.0]

var _level: Node
var _player: Player
var _camera: ForwardCamera
var _time := 0.0
var _start_x := 0.0
var _got_hmg := false
var _threw_grenade := false
var _crouched := false
var _failures: PackedStringArray = []


func _ready() -> void:
	_level = LevelScene.instantiate()
	add_child(_level)
	_player = _level.get_node("Player")
	_camera = _level.get_node("Camera")
	_start_x = _player.global_position.x
	# Keep the bot alive so the run reaches the end; deaths are tested separately below.
	Game.lives = 99


func _physics_process(delta: float) -> void:
	_time += delta
	if Game.is_game_over:
		_fail("game over during the run")
		_finish()
		return

	Input.action_press("move_right")
	# Tap shoot (the pistol needs taps) and jump just before each obstacle or pit.
	_tap("shoot", int(_time * 60.0) % 6 == 0)
	var x := _player.global_position.x
	var near_obstacle := false
	for obstacle_x in JUMP_POINTS:
		if x > obstacle_x - 24.0 and x < obstacle_x - 12.0:
			near_obstacle = true
	_tap("jump", near_obstacle and _player.is_on_floor())
	if _time > 1.0 and not _threw_grenade:
		Input.action_press("grenade")
		_threw_grenade = true
	elif _threw_grenade:
		Input.action_release("grenade")
	if _player.crouching:
		_crouched = true
	if _player.weapon == "hmg":
		_got_hmg = true

	if _player.global_position.x > 1870.0 or _time > TIME_LIMIT:
		_finish()


func _tap(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	set_physics_process(false)
	for action in ["move_right", "shoot", "jump", "grenade"]:
		Input.action_release(action)

	if _player.global_position.x < 1870.0:
		_fail("bot did not reach the goal (x = %.0f after %.1fs)" % [_player.global_position.x, _time])
	if _camera.position.x <= 160.0:
		_fail("camera never scrolled")
	if Game.score <= 0:
		_fail("no points scored")
	if Game.grenades >= Game.START_GRENADES and not _threw_grenade:
		_fail("grenade was never thrown")
	if Game.pows_rescued < 1:
		_fail("no POW rescued")
	if not _got_hmg:
		_fail("never picked up the heavy machine gun")
	if _player.global_position.x < _camera.position.x - 160.0:
		_fail("player left the screen behind the camera")

	await _test_death_and_respawn()

	if _failures.is_empty():
		print("SMOKE TEST PASSED in %.1fs simulated: score %d, POWs %d, enemies left %d" % [
			_time, Game.score, Game.pows_rescued, get_tree().get_nodes_in_group("enemies").size()])
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("SMOKE TEST FAILED: " + failure)
		get_tree().quit(1)


func _test_death_and_respawn() -> void:
	# Wait out any invulnerability, then take a hit.
	var waited := 0
	while (_player.is_invulnerable() or _player.dead) and waited < 600:
		await get_tree().physics_frame
		waited += 1
	var lives_before := Game.lives
	_player.take_damage(1)
	if not _player.dead:
		_fail("player did not die when hit")
	await get_tree().create_timer(Player.RESPAWN_DELAY + 0.2).timeout
	if _player.dead:
		_fail("player did not respawn")
	if Game.lives != lives_before - 1:
		_fail("life was not lost on death")
	if not _player.is_invulnerable():
		_fail("no invulnerability after respawn")
	_player.take_damage(1)
	if _player.dead:
		_fail("invulnerable player died")
