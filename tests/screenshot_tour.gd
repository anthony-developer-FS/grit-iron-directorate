extends "res://tests/mission_test.gd"
## Runs the mission bot with rendering on and saves a screenshot at each beat of the level.
## Run (needs a display): godot --fixed-fps 60 res://tests/screenshot_tour.tscn -- <output dir>

var _out_dir := "user://screenshots"
var _taken := {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(_out_dir)
	await super._ready()


func _process(_delta: float) -> void:
	if _player == null:
		return
	var x := _player.global_position.x
	var y := _player.global_position.y
	_shot_once("01_parachute_drop", _time > 1.0)
	_shot_once("02_beach", x > 600.0)
	_shot_once("03_trenches", x > 1150.0)
	_shot_once("04_mg_nest", x > 1400.0)
	_shot_once("05_artillery", x > 1880.0)
	_shot_once("06_mortar_bluff", x > 2090.0)
	_shot_once("07_half_track", _camera.locked and x < 3000.0 and _time - _taken.get("06_mortar_bluff", 0.0) > 4.0)
	_shot_once("08_bunker", x > 2700.0)
	_shot_once("09_elevator", y < 40.0 and x > 2890.0 and x < 2960.0)
	_shot_once("10_cliff_top", x > 3120.0)
	_shot_once("11_boss_turrets", _boss.phase == SeewallBattery.Phase.TURRETS and _boss_time > 2.0)
	_shot_once("12_boss_cannon", _boss.phase == SeewallBattery.Phase.CANNON and _boss._charging)
	_shot_once("13_boss_core", _boss.phase == SeewallBattery.Phase.CORE and _boss._timer > 1.5)
	var helping := get_tree().get_nodes_in_group("pows").any(func(pow: Node) -> bool: return pow is Pow and pow.is_fighting())
	_shot_once("03b_pow_helping", helping and x > 760.0)
	_shot_once("14_results", (_level.get_node("HUD/Results") as Control).visible)


func _shot_once(shot_name: String, condition: bool) -> void:
	if not condition or _taken.has(shot_name):
		return
	_taken[shot_name] = _time
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, shot_name])
