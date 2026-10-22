class_name Enemy
extends CharacterBody2D
## Shared behavior for Directorate ground troops: health, hit flash, waking up when on screen,
## clean-up once left behind, and the death knockback. Subclasses override _think() and _draw_body().
## The node origin sits at the enemy's feet.

signal defeated

const GRAVITY := 560.0
const DEATH_TIME := 0.8
const BulletScene := preload("res://scenes/projectiles/bullet.tscn")

@export var max_health := 1
@export var score_value := 100
@export_range(-1, 1, 2) var start_facing := -1

var health := 1
var facing := -1
var dead := false

var _hit_flash := 0.0
var _active := false
var _death_timer := 0.0


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	facing = start_facing


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)

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


## The Directorate infantry look: grey uniform, red armband, gas-mask helmet.
func _draw_soldier(uniform: Color, crouched := false) -> void:
	var lift := 6.0 if crouched else 0.0
	var body := Color.WHITE if _hit_flash > 0.0 else uniform
	draw_rect(Rect2(-5, -9 + lift * 0.5, 4, 9 - lift * 0.5), Color("2e3033"))
	draw_rect(Rect2(1, -9 + lift * 0.5, 4, 9 - lift * 0.5), Color("2e3033"))
	draw_rect(Rect2(-6, -20 + lift, 12, 12), body)
	draw_rect(Rect2(-6, -16 + lift, 12, 2), Color("b32424"))
	draw_rect(Rect2(-5, -26 + lift, 10, 6), Color("a3aab2"))
	draw_rect(Rect2(-6, -27 + lift, 12, 2), Color("3f4347"))
	draw_rect(Rect2(facing * 2 - 1, -23 + lift, 3, 2), Color("ff4632"))


func _draw_corpse(color: Color) -> void:
	draw_rect(Rect2(-12, -6, 24, 6), color)
