class_name BossPart
extends StaticBody2D
## A destructible piece of a boss. It soaks up bullets all the time, but only takes damage
## while `vulnerable` (the boss opens parts up phase by phase).

signal destroyed

const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

@export var max_health := 40
@export var size := Vector2(20, 16)
@export_enum("turret", "breech", "core") var kind := "turret"

var health := 40
var vulnerable := false:
	set(value):
		vulnerable = value
		if value and not is_destroyed():
			add_to_group("enemies")
		else:
			remove_from_group("enemies")
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
	collision_layer = 4
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
		set_deferred("collision_layer", 0)
		Game.add_score(1000)
		var explosion := ExplosionScene.instantiate() as Explosion
		explosion.position = global_position + Vector2(size.x / 2.0, -size.y / 2.0)
		explosion.radius = 22.0
		explosion.hurts_enemies = false
		get_parent().add_child.call_deferred(explosion)
		destroyed.emit()
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(0, -size.y, size.x, size.y)
	if is_destroyed():
		draw_rect(rect.grow(-2), Color("2a2522"))
		return
	var flash := _hit_flash > 0.0
	match kind:
		"turret":
			draw_rect(rect, Color.WHITE if flash else Color("6a6e72"))
			draw_rect(Rect2(-10, -size.y * 0.6, 12, 4), Color("2b2b2b"))
			draw_rect(Rect2(-12, -size.y * 0.6 - 4, 4, 4), Color("ff4632") if vulnerable else Color("2b2b2b"))
		"breech":
			draw_rect(rect, Color.WHITE if flash else Color("4a4e54"))
			draw_rect(Rect2(4, -size.y + 4, size.x - 8, size.y - 8), Color(1.0, 0.5 + 0.5 * charge, 0.2, 0.3 + 0.7 * charge) if vulnerable else Color("2b2b2b"))
		"core":
			var glow := Color(0.3, 1.0, 0.8, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 80.0))
			draw_rect(rect, Color.WHITE if flash else Color("2b3a3a"))
			if vulnerable:
				draw_circle(rect.get_center(), size.x * 0.35, glow)
				queue_redraw()
	if vulnerable:
		var bar := Rect2(0, -size.y - 4, size.x, 2)
		draw_rect(bar, Color("3a0d0d"))
		draw_rect(Rect2(bar.position, Vector2(size.x * health / max_health, 2)), Color("ff4632"))
