class_name ShieldTrooper
extends Enemy
## Advances slowly behind a riveted steel shield that stops bullets from the front.
## Beat him with grenades, rockets, the knife, or shots from above.

const WALK_SPEED := 15.0
const FIRE_RANGE := 170.0
const BULLET_SPEED := 110.0
const FRAMES := ["idle", "walk0", "walk1", "walk2", "walk3", "ping0", "ping1", "ping2", "ping3", "ping4",
	"dead0", "dead1"]

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
		_draw_frame(2, _death_frame(FRAMES))
		return
	# The ping frames are the same poses with the shield lit up by a deflected bullet.
	var pose := 0
	if absf(velocity.x) > 1.0:
		pose = 1 + int(_anim_time * 5.0) % 4
	_draw_frame(2, pose + (5 if _ping > 0.0 else 0))
