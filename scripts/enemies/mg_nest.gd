class_name MGNest
extends StaticBody2D
## A concrete machine-gun bunker built into a wall. Sweeps bursts across the ground in front of it.
## Destroy it with sustained fire or explosives. The origin is the bottom center of the bunker.

signal defeated

const BURST_SIZE := 6
const BURST_INTERVAL := 0.09
const BULLET_SPEED := 130.0
const BulletScene := preload("res://scenes/projectiles/bullet.tscn")
const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

@export var max_health := 15
@export var score_value := 500
@export_range(-1, 1, 2) var facing := -1
## Sweep range for each burst, in radians below the horizontal.
@export var sweep_from := -0.05
@export var sweep_to := 0.35

var health := 15
var dead := false

var _timer := 1.2
var _shots_left := 0
var _hit_flash := 0.0
var _active := false


func _ready() -> void:
	add_to_group("enemies")
	health = max_health


func _physics_process(delta: float) -> void:
	if dead:
		return
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	if not _active:
		var screen_pos := get_global_transform_with_canvas().origin
		_active = Rect2(Vector2.ZERO, get_viewport_rect().size).has_point(screen_pos + Vector2(-facing * 20, -10))
		return
	_timer -= delta
	if _timer <= 0.0:
		if _shots_left == 0:
			_shots_left = BURST_SIZE
		var t := 1.0 - float(_shots_left - 1) / float(BURST_SIZE - 1)
		var angle := lerpf(sweep_from, sweep_to, t)
		var direction := Vector2(facing * cos(angle), sin(angle))
		var bullet := BulletScene.instantiate() as Bullet
		bullet.setup(Bullet.Team.ENEMY, global_position + Vector2(facing * 16, -12), direction * BULLET_SPEED, 1)
		get_parent().add_child(bullet)
		_shots_left -= 1
		_timer = BURST_INTERVAL if _shots_left > 0 else 2.2
	queue_redraw()


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	_hit_flash = 0.06
	queue_redraw()
	if health <= 0:
		dead = true
		remove_from_group("enemies")
		set_deferred("collision_layer", 0)
		Game.add_score(score_value)
		var explosion := ExplosionScene.instantiate() as Explosion
		explosion.position = global_position + Vector2(0, -12)
		explosion.radius = 20.0
		explosion.hurts_enemies = false
		get_parent().add_child.call_deferred(explosion)
		defeated.emit()


func _draw() -> void:
	if dead:
		draw_rect(Rect2(-16, -10, 32, 10), Color("3a3c3e"))
		draw_rect(Rect2(-10, -14, 8, 4), Color("2a2c2e"))
		return
	var concrete := Color.WHITE if _hit_flash > 0.0 else Color("8a8e90")
	draw_rect(Rect2(-16, -26, 32, 26), concrete)
	draw_rect(Rect2(-16, -26, 32, 3), Color("a8acae"))
	draw_rect(Rect2(-12, -16, 24, 6), Color("1a1c1e"))
	draw_line(Vector2(facing * 4, -13), Vector2(facing * 20, -12), Color("2b2b2b"), 2.0)
	if _shots_left > 0 and int(_timer * 60.0) % 2 == 0:
		draw_circle(Vector2(facing * 21, -12), 3.0, Color("fff2a8"))
	# Health bar so the player can see progress on a tough target.
	draw_rect(Rect2(-12, -30, 24, 2), Color("3a0d0d"))
	draw_rect(Rect2(-12, -30, 24.0 * health / max_health, 2), Color("ff4632"))
