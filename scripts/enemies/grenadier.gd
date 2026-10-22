class_name Grenadier
extends Enemy
## Holds position on ledges and in trenches and lobs stick grenades that land where Grit stands.

const THROW_RANGE := 200.0
const WIND_UP := 0.5
const FLIGHT_TIME := 1.0
const GrenadeScene := preload("res://scenes/projectiles/grenade.tscn")

var _timer := 1.0
var _winding_up := false


func _think(delta: float, player: Player) -> void:
	velocity.x = 0.0
	_timer -= delta
	if player == null:
		_winding_up = false
		return
	_face(player)
	if absf(player.global_position.x - global_position.x) > THROW_RANGE:
		return
	if not _winding_up and _timer <= 0.0:
		_winding_up = true
		_timer = WIND_UP
	elif _winding_up and _timer <= 0.0:
		_winding_up = false
		_timer = randf_range(2.2, 3.0)
		_throw(player)


func _throw(player: Player) -> void:
	var grenade := GrenadeScene.instantiate() as Grenade
	grenade.target_group = &"player"
	var start := global_position + Vector2(facing * 4, -26)
	grenade.position = start
	# Solve the arc so it lands at Grit's feet after FLIGHT_TIME seconds.
	var offset := player.global_position + Vector2(0, -4) - start
	grenade.velocity = Vector2(offset.x / FLIGHT_TIME, offset.y / FLIGHT_TIME - 0.5 * Grenade.GRAVITY * FLIGHT_TIME)
	get_parent().add_child(grenade)


func _draw() -> void:
	if dead:
		_draw_corpse(Color("6d7a80"))
		return
	_draw_soldier(Color("6d7a80"))
	# Arm raised while winding up a throw.
	if _winding_up:
		draw_line(Vector2(-facing * 3, -18), Vector2(-facing * 7, -28), Color("6d7a80"), 2.0)
		draw_rect(Rect2(-facing * 7 - 2, -32, 4, 4), Color("4a4e54"))
	else:
		draw_rect(Rect2(-facing * 6 - 1, -12, 3, 3), Color("4a4e54"))
