extends Node
## Headless end-to-end test: a bot plays Mission 1 from the parachute drop to the boss and checks
## that every beat works. Grit is in god mode so the run is deterministic about reaching the end;
## damage and difficulty are checked separately at the start.
## Run: godot --headless --fixed-fps 60 res://tests/mission_test.tscn
## Exits with code 0 on success, 1 on failure.

const MissionScene := preload("res://scenes/levels/mission1.tscn")
const TIME_LIMIT := 400.0
## After this long in the boss arena the test finishes the boss off directly, phase by phase,
## since the bot can't climb the planks to reach the high targets.
const BOSS_BOT_TIME := 15.0
const SHAFT := Rect2(2895, -120, 70, 300)

var _level: Node
var _player: Player
var _camera: ForwardCamera
var _boss: SeewallBattery
var _half_track: HalfTrack
var _time := 0.0
var _boss_time := 0.0
var _failures: PackedStringArray = []
var _seen := {}
var _done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Fixed seed so enemy timings, and so the bot's run, are the same every time.
	seed(1944)
	Game.difficulty = Game.Difficulty.EASY
	Game.start_mission()
	_level = MissionScene.instantiate()
	# The level is a sibling of this node, so pausing the game pauses the level but not the test.
	get_tree().root.add_child.call_deferred(_level)
	await get_tree().process_frame
	_player = _level.get_node("Player")
	_camera = _level.get_node("Camera")
	_boss = _level.get_node("Enemies/SeewallBattery")
	_half_track = _level.get_node("Enemies/HalfTrack")
	_half_track.defeated.connect(func() -> void: _seen["half_track_defeated"] = true)
	Game.mission_completed.connect(func() -> void: _seen["mission_completed"] = true)
	Game.checkpoint_reached.connect(func() -> void: _seen["checkpoint"] = true)
	_check_difficulty()
	_check_volley_spacing()
	Game.difficulty = Game.Difficulty.HARD
	_player.god_mode = true
	Game.lives = 99


func _check_difficulty() -> void:
	if not _player.parachuting:
		_fail("Grit should start the mission under a parachute")
	if _player.health != 3:
		_fail("Easy mode should give 3 hits per life, got %d" % _player.health)
	_player.take_damage(1)
	if _player.dead or _player.health != 2:
		_fail("Easy mode: one hit should leave Grit alive with 2 HP")
	if not _player.is_invulnerable():
		_fail("Easy mode: no mercy invulnerability after a hit")


## Turret volleys must string out so each shot can be jumped on its own: fastest first,
## and more time between arrivals than a jump takes when Grit is 150 px away.
func _check_volley_spacing() -> void:
	var speeds := SeewallBattery.TURRET_VOLLEY_SPEEDS
	for i in range(1, speeds.size()):
		var gap: float = 150.0 / speeds[i] - 150.0 / speeds[i - 1]
		if gap < 1.0:
			_fail("turret volley shots %d and %d arrive only %.2fs apart" % [i, i + 1, gap])


func _physics_process(delta: float) -> void:
	if _player == null or _done:
		return
	_time += delta
	if Game.is_game_over:
		_fail("game over during the run")
		_finish()
		return

	var x := _player.global_position.x
	if _player.global_position.y < -80.0 and x > 2890.0:
		_seen["rode_elevator"] = true
	if _player.weapon != "pistol":
		_seen["weapon_" + _player.weapon] = true
	for pow in get_tree().get_nodes_in_group("pows"):
		if pow is Pow and pow.is_fighting():
			_seen["pow_fighting"] = true
	if _camera.locked:
		_seen["camera_locked"] = true
	if _boss.phase != SeewallBattery.Phase.DORMANT:
		_seen["boss_phase_%d" % _boss.phase] = true
	if get_tree().get_nodes_in_group("enemies").any(func(enemy: Node) -> bool: return enemy is MortarCrew):
		_seen["mortars_present"] = true

	_drive_bot(x)

	if x > 3340.0:
		_boss_time += delta
		if _boss_time > BOSS_BOT_TIME:
			_finish_boss()
	if _seen.has("mission_completed") and not _done:
		_done = true
		await get_tree().create_timer(3.5).timeout
		_finish()
	elif _time > TIME_LIMIT:
		_finish()


func _drive_bot(x: float) -> void:
	var frame := int(_time * 60.0)
	var in_shaft := SHAFT.has_point(_player.global_position)
	Input.action_press("move_right")
	_set_action("shoot", frame % 6 < 3)
	# Jump whenever something blocks the way, except while waiting on the elevator.
	var blocked := _player.is_on_floor() and (_player.is_on_wall() or absf(_player.velocity.x) < 1.0)
	_set_action("jump", blocked and not in_shaft and frame % 20 == 0)
	# A grenade every few seconds handles shield troopers.
	_set_action("grenade", frame % 240 == 0)


func _finish_boss() -> void:
	# One heavy hit every half second, so each phase gets to run its attacks.
	if int(_boss_time * 2.0) == int((_boss_time - get_physics_process_delta_time()) * 2.0):
		return
	for part_name in ["TurretLow", "TurretHigh", "Breech", "Core"]:
		var part := _boss.get_node(part_name) as BossPart
		if part.vulnerable and not part.is_destroyed():
			part.take_damage(10)
			return


func _set_action(action: StringName, pressed: bool) -> void:
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

	var expectations := {
		"checkpoint": "never reached the cliff-top checkpoint",
		"rode_elevator": "never rode the elevator to the cliff top",
		"camera_locked": "camera never locked for an arena",
		"half_track_defeated": "half-track mini-boss was not defeated",
		"weapon_hmg": "never picked up the heavy machine gun",
		"weapon_rocket": "never got the rocket launcher from the half-track",
		"mortars_present": "mortar crews never appeared",
		"boss_phase_1": "boss never started (turret phase)",
		"boss_phase_2": "boss never reached the cannon phase",
		"boss_phase_3": "boss never reached the core phase",
		"boss_phase_4": "boss was never destroyed",
		"mission_completed": "mission never completed",
		"pow_fighting": "no rescued POW fought alongside Grit",
	}
	for key in expectations:
		if not _seen.has(key):
			_fail(expectations[key])
	var ammo_left := 0
	for i in range(1, 5):
		if _level.get_node_or_null("Pickups/AmmoBox%d" % i):
			ammo_left += 1
	if ammo_left > 2:
		_fail("only %d of 4 ammo boxes collected" % (4 - ammo_left))
	if Game.pows_rescued < 2:
		_fail("only %d POWs rescued" % Game.pows_rescued)
	var results := _level.get_node("HUD/Results") as Control
	if _seen.has("mission_completed") and not results.visible:
		_fail("results screen did not appear")

	if _failures.is_empty():
		print("MISSION TEST PASSED in %.1fs simulated: score %d, POWs %d, accuracy %d%%" % [
			_time, Game.score, Game.pows_rescued, roundi(Game.accuracy() * 100.0)])
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("MISSION TEST FAILED: " + failure)
		printerr("Grit ended at %s after %.1fs; seen: %s" % [_player.global_position, _time, _seen.keys()])
		get_tree().quit(1)
