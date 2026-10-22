class_name ShieldTrooper
extends Enemy
## Advances slowly behind a riveted steel shield that stops bullets from the front.
## Beat him with grenades, rockets, the knife, or shots from above.

const WALK_SPEED := 15.0
const FIRE_RANGE := 170.0
const BULLET_SPEED := 110.0

var _timer := 1.5
var _ping := 0.0


func _think(delta: float, player: Player) -> void:
	_timer -= delta
	_ping = maxf(_ping - delta, 0.0)
	velocity.x = 0.0
	if player == null:
		return
	_face(player)
	var distance := absf(player.global_position.x - global_position.x)
	if distance > 40.0:
		velocity.x = facing * WALK_SPEED
	if distance < FIRE_RANGE and _timer <= 0.0:
		_timer = 2.0
		var muzzle := global_position + Vector2(facing * 10, -16)
		_fire_bullet(muzzle, Vector2(facing, 0), BULLET_SPEED)


## Bullets arriving from the shield side, below the top of the shield, are deflected.
func blocks_hit(hit_position: Vector2) -> bool:
	if dead:
		return false
	var from_front := (hit_position.x - global_position.x) * facing > 0.0
	var below_top := hit_position.y > global_position.y - 27.0
	if from_front and below_top:
		_ping = 0.06
		queue_redraw()
		return true
	return false


func _draw() -> void:
	if dead:
		_draw_corpse(Color("5d6166"))
		return
	_draw_soldier(Color("5d6166"))
	var shield_color := Color("dcdcdc") if _ping > 0.0 else Color("7a7f86")
	draw_rect(Rect2(facing * 7 - 3, -28, 6, 27), shield_color)
	draw_rect(Rect2(facing * 7 - 3, -28, 6, 27), Color("2e3033"), false, 1.0)
	draw_rect(Rect2(facing * 7 - 1, -22, 2, 3), Color("1c1c1c"))
	for y in [-25, -10, -4]:
		draw_rect(Rect2(facing * 7 - 2, y, 1, 1), Color("b0b4ba"))
