class_name MortarCrew
extends Enemy
## Sits behind cover and calls mortar shells onto Grit's position. Each shell is marked by a flare
## before it lands, so staying on the move is the answer.

const RANGE := 280.0
const StrikeScene := preload("res://scenes/fx/artillery_strike.tscn")
const FRAMES := ["idle", "fire", "dead0", "dead1"]

var _timer := 1.5
var _recoil := 0.0


func _think(delta: float, player: Player) -> void:
	velocity.x = 0.0
	_timer -= delta
	_recoil = maxf(_recoil - delta, 0.0)
	if player == null:
		return
	_face(player)
	if _timer <= 0.0 and absf(player.global_position.x - global_position.x) < RANGE:
		_timer = randf_range(3.0, 3.8)
		_recoil = 0.25
		var strike := StrikeScene.instantiate() as ArtilleryStrike
		strike.position = ArtilleryStrike.find_ground(get_world_2d().direct_space_state, player.global_position + Vector2(player.velocity.x * 0.6, -4))
		strike.warning_time = 1.3
		get_parent().add_child(strike)


func _draw() -> void:
	if dead:
		_draw_frame(3, _death_frame(FRAMES))
	else:
		_draw_frame(3, FRAMES.find("fire" if _recoil > 0.1 else "idle"))
