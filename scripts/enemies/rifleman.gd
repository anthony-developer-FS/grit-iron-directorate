class_name Rifleman
extends CharacterBody2D
## Basic Directorate infantry. Patrols, aims with a visible telegraph, fires slow bullets,
## and panics when Grit gets too close. The node origin sits at the soldier's feet.

enum State { PATROL, AIM, COOLDOWN, PANIC, DEAD }

const GRAVITY := 560.0
const WALK_SPEED := 22.0
const PANIC_SPEED := 60.0
const SIGHT_RANGE := 160.0
const PANIC_RANGE := 26.0
const AIM_TIME := 0.55
const BULLET_SPEED := 110.0
const DEATH_TIME := 0.8
const SCORE := 100

const BulletScene := preload("res://scenes/projectiles/bullet.tscn")

@export var max_health := 1
@export var patrol_distance := 24.0
@export_range(-1, 1, 2) var start_facing := -1

var state := State.PATROL
var health := 1
var facing := -1

var _timer := 0.0
var _panic_cooldown := 0.0
var _home_x := 0.0
var _hit_flash := 0.0
var _active := false


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	facing = start_facing
	_home_x = global_position.x
	_timer = randf_range(0.4, 1.2)


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)

	if state == State.DEAD:
		_process_death(delta)
		return

	var screen_x := get_global_transform_with_canvas().origin.x
	if screen_x < -64.0:
		# Left behind by the forward-scrolling camera.
		queue_free()
		return
	if not _active:
		_active = _is_on_screen()
		move_and_slide()
		return

	_timer -= delta
	_panic_cooldown = maxf(_panic_cooldown - delta, 0.0)
	var player := _find_player()

	match state:
		State.PATROL:
			velocity.x = facing * WALK_SPEED
			if absf(global_position.x - _home_x) > patrol_distance:
				facing = 1 if global_position.x < _home_x else -1
			if player and _can_see(player):
				_face(player)
				velocity.x = 0.0
				if _timer <= 0.0:
					state = State.AIM
					_timer = AIM_TIME
		State.AIM:
			velocity.x = 0.0
			if player:
				_face(player)
			if _timer <= 0.0:
				if player:
					_shoot(player)
				state = State.COOLDOWN
				_timer = randf_range(1.2, 2.2)
		State.COOLDOWN:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.PATROL
		State.PANIC:
			velocity.x = facing * PANIC_SPEED
			if _timer <= 0.0:
				state = State.PATROL
				_timer = 0.4

	if player and state != State.PANIC and _panic_cooldown <= 0.0 \
			and absf(player.global_position.x - global_position.x) < PANIC_RANGE:
		# Run away from Grit, genre-style.
		state = State.PANIC
		facing = 1 if global_position.x > player.global_position.x else -1
		_timer = 0.7
		_panic_cooldown = 3.0

	move_and_slide()
	queue_redraw()


func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health -= amount
	_hit_flash = 0.08
	if health <= 0:
		_die()
	queue_redraw()


func _die() -> void:
	state = State.DEAD
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	velocity = Vector2(-facing * 40.0, -120.0)
	_timer = DEATH_TIME
	Game.add_score(SCORE)


func _process_death(delta: float) -> void:
	_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 80.0 * delta)
	move_and_slide()
	modulate.a = clampf(_timer / DEATH_TIME * 2.0, 0.0, 1.0)
	if _timer <= 0.0:
		queue_free()
	queue_redraw()


func _find_player() -> Player:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.dead:
		return null
	return player


func _can_see(player: Player) -> bool:
	var offset := player.global_position - global_position
	return absf(offset.x) < SIGHT_RANGE and absf(offset.y) < 60.0


func _face(player: Player) -> void:
	facing = 1 if player.global_position.x > global_position.x else -1


func _is_on_screen() -> bool:
	var screen_pos := get_global_transform_with_canvas().origin
	return Rect2(Vector2(-8, -32), get_viewport_rect().size + Vector2(16, 64)).has_point(screen_pos)


func _shoot(player: Player) -> void:
	var muzzle := global_position + Vector2(facing * 9, -18)
	var direction := player.global_position + Vector2(0, -18) - muzzle
	# Shots at Grit's level fly flat, so crouching dodges them.
	if absf(direction.y) < 12.0:
		direction.y = 0.0
	direction.x = absf(direction.x) * facing
	var bullet := BulletScene.instantiate() as Bullet
	bullet.setup(Bullet.Team.ENEMY, muzzle, direction.normalized() * BULLET_SPEED, 1)
	get_parent().add_child(bullet)


func _draw() -> void:
	if state == State.DEAD:
		draw_rect(Rect2(-12, -6, 24, 6), Color("5d6166"))
		return
	var uniform := Color.WHITE if _hit_flash > 0.0 else Color("7d848c")
	draw_rect(Rect2(-5, -9, 4, 9), Color("2e3033"))
	draw_rect(Rect2(1, -9, 4, 9), Color("2e3033"))
	draw_rect(Rect2(-6, -20, 12, 12), uniform)
	draw_rect(Rect2(-6, -16, 12, 2), Color("b32424"))
	# Helmet and gas mask.
	draw_rect(Rect2(-5, -26, 10, 6), Color("a3aab2"))
	draw_rect(Rect2(-6, -27, 12, 2), Color("3f4347"))
	draw_rect(Rect2(facing * 2 - 1, -23, 3, 3), Color("1c1c1c"))
	# Rifle.
	draw_line(Vector2(facing * 2, -17), Vector2(facing * 12, -18), Color("3b2a1a"), 2.0)
	if state == State.AIM and int(_timer * 16.0) % 2 == 0:
		draw_circle(Vector2(facing * 12, -18), 2.0, Color("ff3b3b"))
	if state == State.PANIC:
		draw_string(ThemeDB.fallback_font, Vector2(-2, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffe066"))
