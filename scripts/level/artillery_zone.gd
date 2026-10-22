class_name ArtilleryZone
extends Area2D
## While Grit is inside, off-screen guns pound the ground around him. Each shell is marked by a
## flare before it lands, so the answer is to keep moving.

const StrikeScene := preload("res://scenes/fx/artillery_strike.tscn")

@export var interval := 0.8
@export var warning_time := 1.6

var _player: Player
var _timer := 0.5


func _ready() -> void:
	body_entered.connect(func(body: Node) -> void:
		if body is Player:
			_player = body
			Game.show_message("INCOMING ARTILLERY!", 1.5))
	body_exited.connect(func(body: Node) -> void:
		if body == _player:
			_player = null)


func _physics_process(delta: float) -> void:
	if _player == null or _player.dead:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	var strike := StrikeScene.instantiate() as ArtilleryStrike
	# Land shells around and ahead of Grit.
	var target_x := _player.global_position.x + randf_range(-30.0, 90.0)
	strike.position = ArtilleryStrike.find_ground(get_world_2d().direct_space_state, Vector2(target_x, _player.global_position.y - 4.0))
	strike.warning_time = warning_time
	get_parent().add_child(strike)
