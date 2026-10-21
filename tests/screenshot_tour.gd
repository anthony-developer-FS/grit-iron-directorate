extends "res://tests/smoke_test.gd"
## Runs the smoke-test bot with rendering on and saves screenshots along the way.
## Run (needs a display): godot --fixed-fps 60 res://tests/screenshot_tour.tscn -- <output dir>

const SHOT_TIMES := [0.6, 2.2, 5.5, 7.0, 9.5, 13.0, 17.0, 21.0]

var _out_dir := "user://screenshots"
var _next_shot := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(_out_dir)
	super._ready()


func _process(_delta: float) -> void:
	if _next_shot < SHOT_TIMES.size() and _time >= SHOT_TIMES[_next_shot]:
		var image := get_viewport().get_texture().get_image()
		image.resize(image.get_width() * 4, image.get_height() * 4, Image.INTERPOLATE_NEAREST)
		image.save_png("%s/shot_%02d.png" % [_out_dir, _next_shot])
		_next_shot += 1
