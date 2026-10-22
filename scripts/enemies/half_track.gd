class_name HalfTrack
extends Enemy
## Mid-level mini-boss. Rolls in from the right once the arena locks, rakes the ground with its
## mounted MG and drops riflemen off the back. Starts dormant until an ArenaTrigger wakes it.

const DRIVE_SPEED := 40.0
const RiflemanScene := preload("res://scenes/enemies/rifleman.tscn")
const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

## How far left of its spawn point it patrols, in pixels.
@export var patrol_left := 150.0
@export var patrol_right := 40.0

var awake := false

var _home_x := 0.0
var _target_x := 0.0
var _burst_timer := 2.0
var _shots_left := 0
var _drop_timer := 5.0


func _ready() -> void:
	super._ready()
	_home_x = global_position.x
	_target_x = _home_x - patrol_left * 0.6


func wake() -> void:
	awake = true
	_active = true


func _physics_process(delta: float) -> void:
	if not awake and not dead:
		velocity = Vector2.ZERO
		return
	super._physics_process(delta)


func _think(delta: float, player: Player) -> void:
	# Drive between patrol points.
	if absf(global_position.x - _target_x) < 4.0:
		_target_x = randf_range(_home_x - patrol_left, _home_x + patrol_right)
	velocity.x = signf(_target_x - global_position.x) * DRIVE_SPEED
	facing = -1

	_burst_timer -= delta
	if _burst_timer <= 0.0 and player:
		if _shots_left == 0:
			_shots_left = 8
		var muzzle := global_position + Vector2(-26, -30)
		var direction := (player.global_position + Vector2(0, -16) - muzzle)
		# Keep shots near flat so they can be crouched under or jumped over.
		direction = Vector2(-1, clampf(direction.y / maxf(absf(direction.x), 1.0), -0.15, 0.15))
		_fire_bullet(muzzle, direction, 140.0)
		_shots_left -= 1
		_burst_timer = 0.1 if _shots_left > 0 else 2.0

	_drop_timer -= delta
	if _drop_timer <= 0.0:
		_drop_timer = 6.0
		if get_tree().get_nodes_in_group("enemies").size() < 4:
			var rifleman := RiflemanScene.instantiate() as Rifleman
			rifleman.position = global_position + Vector2(30, -6)
			get_parent().add_child(rifleman)


func die() -> void:
	super.die()
	velocity = Vector2.ZERO
	_death_timer = 1.5
	for i in 4:
		var explosion := ExplosionScene.instantiate() as Explosion
		explosion.position = global_position + Vector2(randf_range(-24, 24), randf_range(-30, -4))
		explosion.radius = 18.0 + i * 4.0
		explosion.hurts_enemies = false
		get_parent().add_child.call_deferred(explosion)


func _process_death(delta: float) -> void:
	_death_timer -= delta
	velocity.x = 0.0
	move_and_slide()
	modulate = Color(0.4, 0.4, 0.4, clampf(_death_timer, 0.0, 1.0))
	if _death_timer <= 0.0:
		queue_free()


func _draw() -> void:
	var hull := Color.WHITE if _hit_flash > 0.0 else Color("5d6166")
	# Tracks at the back, wheels at the front.
	draw_rect(Rect2(4, -10, 28, 10), Color("2a2c2e"))
	for x in [8, 16, 24]:
		draw_circle(Vector2(x, -5), 3.0, Color("4a4e54"))
	draw_circle(Vector2(-22, -5), 5.0, Color("2a2c2e"))
	draw_circle(Vector2(-22, -5), 2.0, Color("6a7078"))
	# Armored body and cab.
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -10), Vector2(-26, -22), Vector2(34, -22), Vector2(34, -10)]), hull)
	draw_rect(Rect2(-14, -30, 18, 8), hull.darkened(0.15))
	draw_rect(Rect2(-12, -28, 6, 3), Color("1a1c1e"))
	draw_rect(Rect2(6, -18, 20, 3), Color("b32424"))
	# Mounted machine gun.
	draw_line(Vector2(-14, -30), Vector2(-28, -30), Color("2b2b2b"), 2.0)
	if _shots_left > 0:
		draw_circle(Vector2(-29, -30), 3.0, Color("fff2a8"))
	if not dead:
		draw_rect(Rect2(-20, -38, 40, 2), Color("3a0d0d"))
		draw_rect(Rect2(-20, -38, 40.0 * health / max_health, 2), Color("ff4632"))
