class_name Player
extends CharacterBody2D
## Sgt. "Grit" Calloway. Placeholder art is drawn in _draw() until real sprites arrive.
## The node origin sits at Grit's feet.

const RUN_SPEED := 75.0
const CROUCH_SPEED := 32.0
const AIR_ACCEL := 600.0
const JUMP_VELOCITY := -200.0
const GRAVITY := 560.0
const MAX_FALL_SPEED := 320.0
const KNIFE_RANGE := 20.0
const KNIFE_DAMAGE := 3
const RESPAWN_DELAY := 1.0
const INVULNERABLE_TIME := 2.0
const HMG_SWEEP_SPEED := 14.0
const PLATFORM_LAYER := 4

const WEAPONS := {
	"pistol": {"label": "PISTOL", "cooldown": 0.16, "damage": 1, "speed": 320.0, "spread": 0.0, "auto": false, "ammo": -1},
	"hmg": {"label": "HEAVY MG", "cooldown": 0.06, "damage": 1, "speed": 360.0, "spread": 0.05, "auto": true, "ammo": 200},
}

const BulletScene := preload("res://scenes/projectiles/bullet.tscn")
const GrenadeScene := preload("res://scenes/projectiles/grenade.tscn")

## Falling below this y counts as falling into a pit.
@export var fall_death_y := 220.0

var facing := 1
var aim_angle := 0.0
var crouching := false
var dead := false
var weapon := "pistol"
var ammo := -1
## Set by the camera every frame so Grit can't walk back off screen.
var camera_left_limit := -INF

var _fire_cooldown := 0.0
var _invulnerable := 0.0
var _knife_flash := 0.0
var _muzzle_flash := 0.0
var _last_safe_position := Vector2.ZERO

@onready var _standing_shape: CollisionShape2D = $StandingShape
@onready var _crouch_shape: CollisionShape2D = $CrouchShape


func _ready() -> void:
	add_to_group("player")
	_last_safe_position = global_position
	Game.continued.connect(_respawn)
	give_weapon("pistol")


func _physics_process(delta: float) -> void:
	if dead:
		return
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_knife_flash = maxf(_knife_flash - delta, 0.0)
	_muzzle_flash = maxf(_muzzle_flash - delta, 0.0)

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = int(signf(direction))
	_set_crouching(is_on_floor() and Input.is_action_pressed("crouch"))

	var speed := CROUCH_SPEED if crouching else RUN_SPEED
	if is_on_floor():
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, direction * speed, AIR_ACCEL * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		if crouching and _is_on_one_way_platform():
			_drop_through_platform()
		else:
			velocity.y = JUMP_VELOCITY

	move_and_slide()

	if global_position.x < camera_left_limit:
		global_position.x = camera_left_limit
		velocity.x = maxf(velocity.x, 0.0)
	if is_on_floor():
		_last_safe_position = global_position
	if global_position.y > fall_death_y:
		kill(true)
		return

	_update_aim(delta)
	_handle_shooting()
	if Input.is_action_just_pressed("grenade"):
		_throw_grenade()
	queue_redraw()


func give_weapon(weapon_name: String) -> void:
	weapon = weapon_name
	ammo = WEAPONS[weapon_name]["ammo"]
	Game.set_weapon(WEAPONS[weapon_name]["label"], ammo)


## Damage interface shared by everything that can be shot. Grit dies in one hit.
func take_damage(_amount: int) -> void:
	kill()


func kill(ignore_invulnerability := false) -> void:
	if dead or (_invulnerable > 0.0 and not ignore_invulnerability):
		return
	dead = true
	velocity = Vector2.ZERO
	_set_crouching(false)
	set_deferred("collision_layer", 0)
	Game.shake(3.0, 0.2)
	queue_redraw()
	await get_tree().create_timer(RESPAWN_DELAY, false).timeout
	if Game.lose_life():
		_respawn()


func is_invulnerable() -> bool:
	return _invulnerable > 0.0


func _respawn() -> void:
	dead = false
	set_deferred("collision_layer", 2)
	if global_position.y > fall_death_y - 40.0:
		# Fell into a pit: come back a step before the edge.
		global_position = _last_safe_position - Vector2(24.0 * facing, 0.0)
		global_position.x = maxf(global_position.x, camera_left_limit)
	velocity = Vector2(0, -120)
	_invulnerable = INVULNERABLE_TIME
	give_weapon("pistol")
	Game.reset_grenades()
	queue_redraw()


func _set_crouching(value: bool) -> void:
	if value == crouching:
		return
	crouching = value
	_standing_shape.set_deferred("disabled", value)
	_crouch_shape.set_deferred("disabled", not value)


func _is_on_one_way_platform() -> bool:
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is Block and collider.one_way:
			return true
	return false


func _drop_through_platform() -> void:
	set_collision_mask_value(PLATFORM_LAYER, false)
	global_position.y += 2.0
	await get_tree().create_timer(0.25, false).timeout
	set_collision_mask_value(PLATFORM_LAYER, true)


func _target_aim_angle() -> float:
	if Input.is_action_pressed("aim_up"):
		return -PI / 2.0
	if not is_on_floor() and Input.is_action_pressed("crouch"):
		return PI / 2.0
	return 0.0 if facing > 0 else PI


func _update_aim(delta: float) -> void:
	var target := _target_aim_angle()
	if weapon == "hmg":
		# The heavy machine gun sweeps between angles, as in the arcade classics.
		aim_angle = rotate_toward(aim_angle, target, HMG_SWEEP_SPEED * delta)
	else:
		aim_angle = target


func _shoulder_offset() -> Vector2:
	return Vector2(0, -9 if crouching else -19)


func _muzzle_position() -> Vector2:
	return global_position + _shoulder_offset() + Vector2.from_angle(aim_angle) * 10.0


func _handle_shooting() -> void:
	var stats: Dictionary = WEAPONS[weapon]
	var wants_to_fire: bool
	if stats["auto"]:
		wants_to_fire = Input.is_action_pressed("shoot")
	else:
		wants_to_fire = Input.is_action_just_pressed("shoot")
	if not wants_to_fire or _fire_cooldown > 0.0:
		return

	var knife_target := _find_knife_target()
	if knife_target:
		knife_target.take_damage(KNIFE_DAMAGE)
		_knife_flash = 0.12
		_fire_cooldown = 0.25
		return

	var spread: float = stats["spread"]
	var bullet := BulletScene.instantiate() as Bullet
	var bullet_velocity := Vector2.from_angle(aim_angle + randf_range(-spread, spread)) * float(stats["speed"])
	bullet.setup(Bullet.Team.PLAYER, _muzzle_position(), bullet_velocity, stats["damage"])
	get_parent().add_child(bullet)
	_fire_cooldown = stats["cooldown"]
	_muzzle_flash = 0.05

	if ammo > 0:
		ammo -= 1
		if ammo == 0:
			give_weapon("pistol")
		else:
			Game.set_weapon(stats["label"], ammo)


## Enemies right in front of Grit get the knife instead of a bullet.
func _find_knife_target() -> Node2D:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.global_position - global_position
		if offset.x * facing >= -4.0 and absf(offset.x) <= KNIFE_RANGE and absf(offset.y) < 20.0:
			return enemy
	return null


func _throw_grenade() -> void:
	if not Game.use_grenade():
		return
	var grenade := GrenadeScene.instantiate() as Grenade
	grenade.position = global_position + Vector2(facing * 4, -10 if crouching else -20)
	grenade.velocity = Vector2(facing * 120.0 + velocity.x * 0.5, -150.0)
	get_parent().add_child(grenade)


func _draw() -> void:
	if dead:
		draw_rect(Rect2(-12, -6, 24, 6), Color("6b7a3a"))
		draw_rect(Rect2(8 * facing - 3, -7, 6, 6), Color("e0b48a"))
		return
	# Blink while invulnerable after a respawn.
	if _invulnerable > 0.0 and int(_invulnerable * 12.0) % 2 == 0:
		return

	var height := 16.0 if crouching else 28.0
	var olive := Color("6b7a3a")
	var skin := Color("e0b48a")
	# Legs and body.
	draw_rect(Rect2(-5, -height * 0.35, 4, height * 0.35), Color("3d3324"))
	draw_rect(Rect2(1, -height * 0.35, 4, height * 0.35), Color("3d3324"))
	draw_rect(Rect2(-6, -height * 0.75, 12, height * 0.42), olive)
	# Head with the red bandana.
	var head_top := -height
	draw_rect(Rect2(-4, head_top, 8, height * 0.25), skin)
	draw_rect(Rect2(-5, head_top, 10, 2), Color("b33a3a"))
	draw_rect(Rect2(2 * facing - 1, head_top + 3, 2, 1), Color.BLACK)

	# Gun.
	var shoulder := _shoulder_offset()
	var gun_length := 12.0 if weapon == "hmg" else 9.0
	var gun_end := shoulder + Vector2.from_angle(aim_angle) * gun_length
	draw_line(shoulder, gun_end, Color("2b2b2b"), 3.0 if weapon == "hmg" else 2.0)
	if _muzzle_flash > 0.0:
		draw_circle(gun_end + Vector2.from_angle(aim_angle) * 2.0, 3.0, Color("fff2a8"))
	if _knife_flash > 0.0:
		draw_arc(Vector2(facing * 10, -14), 10.0, -PI / 2.0 * facing, PI / 2.0 * facing, 8, Color.WHITE, 2.0)
