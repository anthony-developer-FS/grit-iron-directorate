class_name Enemy
extends CharacterBody2D
## Shared behavior for Directorate ground troops: health, hit flash, waking up when on screen,
## clean-up once left behind, and the death knockback. Subclasses override _think() and _draw().
## The node origin sits at the enemy's feet.

signal defeated

const GRAVITY := 560.0
const DEATH_TIME := 0.8
const BulletScene := preload("res://scenes/projectiles/bullet.tscn")
## One row per trooper type, 32x32 frames, from tools/art/trooper.py. The flash sheet is the
## same frames in solid white, shown for a moment when a trooper is hit.
const Sheet := preload("res://assets/sprites/enemies.png")
const FlashSheet := preload("res://assets/sprites/enemies_flash.png")

@export var max_health := 1
@export var score_value := 100
@export_range(-1, 1, 2) var start_facing := -1

var health := 1
var facing := -1
var dead := false

var _hit_flash := 0.0
var _active := false
var _death_timer := 0.0
var _anim_time := 0.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	facing = start_facing


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_anim_time += delta

	if dead:
		_process_death(delta)
		return
	if get_global_transform_with_canvas().origin.x < -64.0:
		# Left behind by the forward-scrolling camera.
		queue_free()
		return
	if not _active:
		_active = _is_on_screen()
		velocity.x = 0.0
		move_and_slide()
		return

	_think(delta, _find_player())
	move_and_slide()
	queue_redraw()


## Per-frame AI. Set velocity.x here; gravity and move_and_slide() are handled by the base class.
func _think(_delta: float, _player: Player) -> void:
	pass


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	_hit_flash = 0.08
	if health <= 0:
		die()
	queue_redraw()


func die() -> void:
	if dead:
		return
	dead = true
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	velocity = Vector2(-facing * 40.0, -120.0)
	_death_timer = DEATH_TIME
	Game.add_score(score_value)
	defeated.emit()


func _process_death(delta: float) -> void:
	_death_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 80.0 * delta)
	move_and_slide()
	modulate.a = clampf(_death_timer / DEATH_TIME * 2.0, 0.0, 1.0)
	if _death_timer <= 0.0:
		queue_free()
	queue_redraw()


func _find_player() -> Player:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.dead:
		return null
	return player


func _face(player: Player) -> void:
	facing = 1 if player.global_position.x > global_position.x else -1


func _is_on_screen() -> bool:
	var screen_pos := get_global_transform_with_canvas().origin
	return Rect2(Vector2(-8, -32), get_viewport_rect().size + Vector2(16, 64)).has_point(screen_pos)


func _fire_bullet(from: Vector2, direction: Vector2, speed: float) -> void:
	var bullet := BulletScene.instantiate() as Bullet
	bullet.setup(Bullet.Team.ENEMY, from, direction.normalized() * speed, 1)
	get_parent().add_child(bullet)


## Draws a frame from the trooper sheet, mirrored to match `facing`. The sprites face right
## and stand with their feet on the node origin.
func _draw_frame(row: int, column: int) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	var sheet := FlashSheet if _hit_flash > 0.0 and not dead else Sheet
	draw_texture_rect_region(sheet, Rect2(-16, -31, 32, 32), Rect2(column * 32, row * 32, 32, 32))
	draw_set_transform(Vector2.ZERO)


## Death frames: knocked back, then flat once the body has dropped.
func _death_frame(names: Array) -> int:
	return names.find("dead0" if _death_timer > DEATH_TIME - 0.3 else "dead1")


## Cycles through `prefix`0.. frames at `fps`.
func _cycle(names: Array, prefix: String, count: int, fps: float) -> int:
	return names.find("%s%d" % [prefix, int(_anim_time * fps) % count])
