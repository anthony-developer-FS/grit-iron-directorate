class_name ForwardCamera
extends Camera2D
## Side-scrolling camera that only moves forward, like the arcade run-and-guns.
## Keeps Grit about a third of the way across the screen and stops at the level's end.

@export var target_path: NodePath
## How far ahead of Grit the camera centers, in pixels.
@export var lookahead := 40.0
## Right edge of the level; the camera never shows past it.
@export var level_end_x := 2000.0
## Set true to freeze scrolling, e.g. for a mini-boss or boss arena.
@export var locked := false

var _shake_strength := 0.0
var _shake_time := 0.0


func _ready() -> void:
	Game.shake_requested.connect(_on_shake_requested)


func _physics_process(delta: float) -> void:
	var half_width := get_viewport_rect().size.x / 2.0
	var target := get_node_or_null(target_path) as Player
	if target:
		if not locked and not target.dead:
			var desired := minf(target.global_position.x + lookahead, level_end_x - half_width)
			position.x = maxf(position.x, desired)
		target.camera_left_limit = position.x - half_width + 8.0

	if _shake_time > 0.0:
		_shake_time -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * _shake_strength
	else:
		offset = Vector2.ZERO


func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = maxf(strength, _shake_strength if _shake_time > 0.0 else 0.0)
	_shake_time = maxf(duration, _shake_time)
