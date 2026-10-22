class_name Grenadier
extends Enemy
## Holds position on ledges and in trenches and lobs stick grenades that land where Grit stands.

const THROW_RANGE := 200.0
const WIND_UP := 0.5
const FLIGHT_TIME := 1.0
const GrenadeScene := preload("res://scenes/projectiles/grenade.tscn")
const FRAMES := ["idle", "run0", "run1", "run2", "run3", "run4", "run5", "windup", "throw",
	"dead0", "dead1"]

var _timer := 1.0
var _winding_up := false
var _throw_pose := 0.0


func _think(delta: float, player: Player) -> void:
	velocity.x = 0.0
	_timer -= delta
	_throw_pose = maxf(_throw_pose - delta, 0.0)
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
		_throw_pose = 0.2
		_timer = randf_range(2.2, 3.0)
		_throw(player)


func _throw(player: Player) -> void:
	Sfx.play("grenade_throw")
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
		_draw_frame(1, _death_frame(FRAMES))
	elif _winding_up:
		_draw_frame(1, FRAMES.find("windup"))
	elif _throw_pose > 0.0:
		_draw_frame(1, FRAMES.find("throw"))
	elif absf(velocity.x) > 1.0:
		_draw_frame(1, _cycle(FRAMES, "run", 6, 8.0))
	else:
		_draw_frame(1, FRAMES.find("idle"))
