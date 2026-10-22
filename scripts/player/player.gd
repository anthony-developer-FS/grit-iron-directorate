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
const PARACHUTE_FALL_SPEED := 38.0
const KNIFE_RANGE := 20.0
const KNIFE_DAMAGE := 3
const RESPAWN_DELAY := 1.0
const INVULNERABLE_TIME := 2.0
const HIT_INVULNERABLE_TIME := 1.0
const HMG_SWEEP_SPEED := 14.0
const PLATFORM_LAYER := 4
## Special weapons last this long (or until their ammo runs out, whichever comes first).
const SPECIAL_WEAPON_TIME := 30.0

## kind: how the weapon fires. bullet = one shot, pellets = shotgun spread, flame = piercing bursts, rocket = homing rocket.
const WEAPONS := {
	"pistol": {"label": "PISTOL", "kind": "bullet", "cooldown": 0.16, "damage": 1, "speed": 320.0, "spread": 0.0, "auto": false, "ammo": -1},
	"hmg": {"label": "HEAVY MG", "kind": "bullet", "cooldown": 0.06, "damage": 1, "speed": 360.0, "spread": 0.05, "auto": true, "ammo": 200},
	"rocket": {"label": "ROCKET", "kind": "rocket", "cooldown": 0.35, "damage": 6, "speed": 0.0, "spread": 0.0, "auto": true, "ammo": 30},
	"shotgun": {"label": "SHOTGUN", "kind": "pellets", "cooldown": 0.45, "damage": 2, "speed": 300.0, "spread": 0.25, "auto": true, "ammo": 30},
	"flame": {"label": "FLAME SHOT", "kind": "flame", "cooldown": 0.12, "damage": 1, "speed": 170.0, "spread": 0.08, "auto": true, "ammo": 30},
}

const BulletScene := preload("res://scenes/projectiles/bullet.tscn")
const GrenadeScene := preload("res://scenes/projectiles/grenade.tscn")
const RocketScene := preload("res://scenes/projectiles/rocket.tscn")

## Falling below this y counts as falling into a pit.
@export var fall_death_y := 260.0
## Start the level drifting down under a parachute.
@export var start_with_parachute := false

var facing := 1
var aim_angle := 0.0
var crouching := false
var dead := false
var parachuting := false
var weapon := "pistol"
var ammo := -1
## The last special weapon Grit picked up. Ammo boxes bring it back if he's down to the pistol.
var last_special := ""
## Seconds left on the special weapon in hand.
var weapon_time_left := 0.0
## Hits left in this life (1 on Hard, 3 on Easy).
var health := 1
## Set by the camera every frame so Grit can't leave the screen.
var camera_left_limit := -INF
var camera_right_limit := INF
## Debug and test aid: Grit can't be hurt.
var god_mode := false

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
	health = Game.hits_per_life()
	parachuting = start_with_parachute
	Game.continued.connect(_respawn)
	give_weapon("pistol")


func _physics_process(delta: float) -> void:
	if dead:
		return
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_knife_flash = maxf(_knife_flash - delta, 0.0)
	_muzzle_flash = maxf(_muzzle_flash - delta, 0.0)
	_tick_weapon_timer(delta)

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = int(signf(direction))
	_set_crouching(is_on_floor() and Input.is_action_pressed("crouch"))

	var speed := CROUCH_SPEED if crouching else RUN_SPEED
	if is_on_floor():
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, direction * speed, AIR_ACCEL * delta)
	var max_fall := PARACHUTE_FALL_SPEED if parachuting else MAX_FALL_SPEED
	velocity.y = minf(velocity.y + GRAVITY * delta, max_fall)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		if crouching and _is_on_one_way_platform():
			_drop_through_platform()
		else:
			velocity.y = JUMP_VELOCITY

	move_and_slide()
	if parachuting and is_on_floor():
		parachuting = false

	if global_position.x < camera_left_limit:
		global_position.x = camera_left_limit
		velocity.x = maxf(velocity.x, 0.0)
	if global_position.x > camera_right_limit:
		global_position.x = camera_right_limit
		velocity.x = minf(velocity.x, 0.0)
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
	if weapon_name != "pistol":
		last_special = weapon_name
	weapon = weapon_name
	ammo = WEAPONS[weapon_name]["ammo"]
	weapon_time_left = SPECIAL_WEAPON_TIME if weapon_name != "pistol" else 0.0
	Game.set_weapon(WEAPONS[weapon_name]["label"], ammo)
	Game.weapon_timer_changed.emit(ceili(weapon_time_left))


func _tick_weapon_timer(delta: float) -> void:
	if weapon == "pistol":
		return
	var shown := ceili(weapon_time_left)
	weapon_time_left -= delta
	if weapon_time_left <= 0.0:
		give_weapon("pistol")
		Game.show_message("OUT OF TIME!", 1.0)
	elif ceili(weapon_time_left) != shown:
		Game.weapon_timer_changed.emit(ceili(weapon_time_left))


## Ammo box: refills the special weapon in hand, or re-arms the last one Grit had
## (the heavy MG if he's never had one). Returns the weapon's label.
func reload_special() -> String:
	var weapon_name := weapon
	if weapon_name == "pistol":
		weapon_name = last_special if last_special != "" else "hmg"
	give_weapon(weapon_name)
	return WEAPONS[weapon_name]["label"]


## Damage interface shared by everything that can be shot. On Hard Grit dies in one hit; on Easy he has 3 hits per life.
func take_damage(_amount: int) -> void:
	if dead or god_mode or _invulnerable > 0.0:
		return
	health -= 1
	Game.player_health_changed.emit(health)
	if health <= 0:
		kill()
	else:
		_invulnerable = HIT_INVULNERABLE_TIME
		Game.shake(2.0, 0.15)


func kill(ignore_invulnerability := false) -> void:
	if dead or god_mode and not ignore_invulnerability:
		return
	if _invulnerable > 0.0 and not ignore_invulnerability:
		return
	dead = true
	parachuting = false
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


## Puts Grit at a spot with no momentum, e.g. when restarting from a checkpoint.
func place_at(spot: Vector2) -> void:
	global_position = spot
	_last_safe_position = spot
	velocity = Vector2.ZERO
	parachuting = false


func _respawn() -> void:
	dead = false
	set_deferred("collision_layer", 2)
	if global_position.y > fall_death_y - 40.0:
		# Fell into a pit: come back a step before the edge.
		global_position = _last_safe_position - Vector2(24.0 * facing, 0.0)
		global_position.x = maxf(global_position.x, camera_left_limit)
	velocity = Vector2(0, -120)
	_invulnerable = INVULNERABLE_TIME
	health = Game.hits_per_life()
	Game.player_health_changed.emit(health)
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

	match stats["kind"]:
		"rocket":
			var rocket := RocketScene.instantiate() as Rocket
			rocket.position = _muzzle_position()
			rocket.direction = Vector2.from_angle(aim_angle)
			get_parent().add_child(rocket)
		"pellets":
			for i in 5:
				var offset := lerpf(-1.0, 1.0, i / 4.0) * float(stats["spread"])
				_spawn_bullet(aim_angle + offset, stats, Bullet.Style.PELLET)
		"flame":
			_spawn_bullet(aim_angle + randf_range(-1.0, 1.0) * float(stats["spread"]), stats, Bullet.Style.FLAME)
		_:
			_spawn_bullet(aim_angle + randf_range(-1.0, 1.0) * float(stats["spread"]), stats, Bullet.Style.BULLET)
	_fire_cooldown = stats["cooldown"]
	_muzzle_flash = 0.05

	if ammo > 0:
		ammo -= 1
		if ammo == 0:
			give_weapon("pistol")
		else:
			Game.set_weapon(stats["label"], ammo)


func _spawn_bullet(angle: float, stats: Dictionary, style: Bullet.Style) -> void:
	var bullet := BulletScene.instantiate() as Bullet
	bullet.setup(Bullet.Team.PLAYER, _muzzle_position(), Vector2.from_angle(angle) * float(stats["speed"]), stats["damage"], style)
	get_parent().add_child(bullet)


## Enemies right in front of Grit get the knife instead of a bullet.
func _find_knife_target() -> Node2D:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Enemy:
			continue
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
	# Blink while invulnerable after a hit or respawn.
	if _invulnerable > 0.0 and int(_invulnerable * 12.0) % 2 == 0:
		return

	if parachuting:
		draw_arc(Vector2(0, -44), 18.0, PI, TAU, 16, Color("c9c1a6"), 6.0)
		draw_line(Vector2(-17, -44), Vector2(-4, -22), Color("8a8270"), 1.0)
		draw_line(Vector2(17, -44), Vector2(4, -22), Color("8a8270"), 1.0)

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
	var heavy := weapon != "pistol"
	var gun_end := shoulder + Vector2.from_angle(aim_angle) * (12.0 if heavy else 9.0)
	draw_line(shoulder, gun_end, Color("2b2b2b"), 3.0 if heavy else 2.0)
	if _muzzle_flash > 0.0:
		draw_circle(gun_end + Vector2.from_angle(aim_angle) * 2.0, 3.0, Color("fff2a8"))
	if _knife_flash > 0.0:
		draw_arc(Vector2(facing * 10, -14), 10.0, -PI / 2.0 * facing, PI / 2.0 * facing, 8, Color.WHITE, 2.0)
