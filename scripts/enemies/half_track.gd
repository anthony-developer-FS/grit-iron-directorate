class_name HalfTrack
extends Enemy
## Mid-level mini-boss. Rolls in from the right once the arena locks, rakes the ground with its
## mounted MG and drops riflemen off the back. Starts dormant until an ArenaTrigger wakes it.

const DRIVE_SPEED := 40.0
const RiflemanScene := preload("res://scenes/enemies/rifleman.tscn")
const ExplosionScene := preload("res://scenes/fx/explosion.tscn")
## 72x44 frames from tools/art/vehicles.py: two tread frames, burnt out, hit flash. Faces right.
const VehicleSheet := preload("res://assets/sprites/half_track.png")

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
		var muzzle := global_position + Vector2(facing * 10, -27)
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
	modulate.a = clampf(_death_timer, 0.0, 1.0)
	if _death_timer <= 0.0:
		queue_free()


func _draw() -> void:
	var frame := int(_anim_time * 8.0) % 2 if absf(velocity.x) > 1.0 else 0
	if dead:
		frame = 2
	elif _hit_flash > 0.0:
		frame = 3
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	draw_texture_rect_region(VehicleSheet, Rect2(-36, -43, 72, 44), Rect2(frame * 72, 0, 72, 44))
	draw_set_transform(Vector2.ZERO)
	if _shots_left > 0:
		draw_circle(Vector2(facing * 11, -27), 3.0, Color("fff2a8"))
	if not dead:
		draw_rect(Rect2(-20, -38, 40, 2), Color("3a0d0d"))
		draw_rect(Rect2(-20, -38, 40.0 * health / max_health, 2), Color("ff4632"))
