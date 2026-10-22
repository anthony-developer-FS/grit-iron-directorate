class_name BossPart
extends StaticBody2D
## A destructible piece of a boss. It only takes damage, and only stops bullets, while
## `vulnerable` (the boss opens parts up phase by phase). Parts that aren't open yet let shots
## pass through to the wall behind, so they can't shield an open part they overlap.

signal destroyed

const ExplosionScene := preload("res://scenes/fx/explosion.tscn")
## Frames from tools/art/boss.py: closed, open, hit flash, wrecked. Each sheet's frame size and
## where the part's bottom-left corner sits inside a frame.
const SHEETS := {
	"turret": [preload("res://assets/sprites/boss_turret.png"), Vector2(34, 22), Vector2(13, 21)],
	"breech": [preload("res://assets/sprites/boss_breech.png"), Vector2(26, 28), Vector2(1, 27)],
	"core": [preload("res://assets/sprites/boss_core.png"), Vector2(26, 26), Vector2(1, 25)],
}

@export var max_health := 40
@export var size := Vector2(20, 16)
@export_enum("turret", "breech", "core") var kind := "turret"

var health := 40
var vulnerable := false:
	set(value):
		vulnerable = value
		var open := value and not is_destroyed()
		if open:
			add_to_group("enemies")
		else:
			remove_from_group("enemies")
		set_deferred("collision_layer", 4 if open else 0)
		queue_redraw()
## 0..1, used by the boss to show a charge-up glow.
var charge := 0.0:
	set(value):
		charge = value
		queue_redraw()

var _hit_flash := 0.0


func _ready() -> void:
	health = max_health
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(size.x / 2.0, -size.y / 2.0)
	add_child(shape)
	collision_layer = 4 if vulnerable else 0
	collision_mask = 0


func _physics_process(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash = maxf(_hit_flash - delta, 0.0)
		queue_redraw()


func is_destroyed() -> bool:
	return health <= 0


func take_damage(amount: int) -> void:
	if not vulnerable or is_destroyed():
		return
	health -= amount
	_hit_flash = 0.05
	if health <= 0:
		vulnerable = false
		Game.add_score(1000)
		var explosion := ExplosionScene.instantiate() as Explosion
		explosion.position = global_position + Vector2(size.x / 2.0, -size.y / 2.0)
		explosion.radius = 22.0
		explosion.hurts_enemies = false
		get_parent().add_child.call_deferred(explosion)
		destroyed.emit()
	queue_redraw()


func _draw() -> void:
	var entry: Array = SHEETS[kind]
	var frame_size: Vector2 = entry[1]
	var frame := 0
	if is_destroyed():
		frame = 3
	elif _hit_flash > 0.0:
		frame = 2
	elif vulnerable:
		frame = 1
	draw_texture_rect_region(entry[0], Rect2(-entry[2], frame_size), Rect2(Vector2(frame * frame_size.x, 0), frame_size))
	if is_destroyed():
		return
	var rect := Rect2(0, -size.y, size.x, size.y)
	if kind == "breech" and vulnerable and charge > 0.0:
		draw_rect(Rect2(4, -size.y + 4, size.x - 8, size.y - 8), Color(1.0, 0.5 + 0.5 * charge, 0.2, 0.3 + 0.7 * charge))
	if kind == "core" and vulnerable:
		var glow := Color(0.3, 1.0, 0.8, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 80.0))
		draw_circle(rect.get_center(), size.x * 0.3, glow)
		queue_redraw()
	if vulnerable:
		var bar := Rect2(0, -size.y - 4, size.x, 2)
		draw_rect(bar, Color("3a0d0d"))
		draw_rect(Rect2(bar.position, Vector2(size.x * health / max_health, 2)), Color("ff4632"))
