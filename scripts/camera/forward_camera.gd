class_name ForwardCamera
extends Camera2D
## Side-scrolling camera that only moves forward, like the arcade run-and-guns.
## Keeps Grit about a third of the way across the screen, follows him up and down when he
## lands somewhere new (or rides an elevator), and can lock in place for arena fights.

@export var target_path: NodePath
## How far ahead of Grit the camera centers, in pixels.
@export var lookahead := 40.0
## Right edge of the level; the camera never shows past it.
@export var level_end_x := 2000.0
## How far above Grit's feet the camera centers vertically.
@export var vertical_offset := 60.0
## Vertical limits for the camera center.
@export var min_y := -1000.0
@export var max_y := 90.0
## How quickly the camera catches up vertically.
@export var vertical_speed := 5.0

var locked := false

var _lock_x := 0.0
var _target_y := 90.0
var _shake_strength := 0.0
var _shake_time := 0.0


func _ready() -> void:
	Game.shake_requested.connect(_on_shake_requested)
	_target_y = position.y


## Freezes scrolling with the screen centered on `center_x` (slides there if needed).
func lock_at(center_x: float) -> void:
	locked = true
	_lock_x = center_x


func unlock() -> void:
	locked = false


## Jumps straight to Grit, e.g. after restarting from a checkpoint.
func snap_to_target() -> void:
	var target := get_node_or_null(target_path) as Player
	if target == null:
		return
	position.x = minf(target.global_position.x + lookahead, level_end_x - get_viewport_rect().size.x / 2.0)
	_target_y = clampf(target.global_position.y - vertical_offset, min_y, max_y)
	position.y = _target_y


## Holds the camera at a fixed height until Grit next lands, e.g. during the parachute drop.
func hold_height(y: float) -> void:
	_target_y = clampf(y, min_y, max_y)
	position.y = _target_y


func _physics_process(delta: float) -> void:
	var half_width := get_viewport_rect().size.x / 2.0
	var target := get_node_or_null(target_path) as Player
	if target:
		if locked:
			position.x = move_toward(position.x, _lock_x, 120.0 * delta)
		elif not target.dead:
			var desired := minf(target.global_position.x + lookahead, level_end_x - half_width)
			position.x = maxf(position.x, desired)
		# Follow vertically only once Grit lands, so jumps don't bob the screen.
		if not target.dead and (target.is_on_floor() or target.global_position.y - position.y > 70.0):
			_target_y = clampf(target.global_position.y - vertical_offset, min_y, max_y)
		position.y = lerpf(position.y, _target_y, clampf(vertical_speed * delta, 0.0, 1.0))
		target.camera_left_limit = position.x - half_width + 8.0
		target.camera_right_limit = position.x + half_width - 8.0 if locked else INF

	if _shake_time > 0.0:
		_shake_time -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).round() * _shake_strength
	else:
		offset = Vector2.ZERO


func _on_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = maxf(strength, _shake_strength if _shake_time > 0.0 else 0.0)
	_shake_time = maxf(duration, _shake_time)
