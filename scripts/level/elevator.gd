class_name Elevator
extends AnimatableBody2D
## Freight elevator up the cliff. Starts moving once Grit has stood on it for a moment,
## and Directorate troops drop in from above during the ride. It only climbs with Grit aboard,
## and comes back down for him if he gets off (or is knocked off) partway.

const RiflemanScene := preload("res://scenes/enemies/rifleman.tscn")

@export var width := 52.0
## How far up the elevator travels, in pixels.
@export var travel := 240.0
@export var speed := 32.0
@export var drop_enemies := 3

var _start_y := 0.0
var _state := 0 # 0 waiting, 1 riding, 2 arrived
var _wait := 0.0
var _drop_timer := 1.5
var _dropped := 0

@onready var _rider_check: Area2D = $RiderCheck


func _ready() -> void:
	_start_y = position.y


func _physics_process(delta: float) -> void:
	match _state:
		0:
			if _player_on_board():
				_wait += delta
				if _wait > 0.6:
					_state = 1
					Sfx.play("elevator", 0.0)
			else:
				_wait = 0.0
		1:
			if not _player_on_board():
				_wait += delta
				if _wait > 1.0:
					position.y = minf(position.y + speed * 2.0 * delta, _start_y)
					if position.y >= _start_y:
						_state = 0
						_wait = 0.0
				return
			_wait = 0.0
			position.y = maxf(position.y - speed * delta, _start_y - travel)
			_drop_timer -= delta
			if _drop_timer <= 0.0 and _dropped < drop_enemies:
				_drop_timer = 2.2
				_dropped += 1
				var rifleman := RiflemanScene.instantiate() as Rifleman
				rifleman.position = Vector2(global_position.x + randf_range(8.0, width - 8.0), global_position.y - 150.0)
				rifleman.patrol_distance = 8.0
				get_parent().add_child(rifleman)
			if position.y <= _start_y - travel:
				_state = 2


func _player_on_board() -> bool:
	for body in _rider_check.get_overlapping_bodies():
		if body is Player:
			return true
	return false


func _draw() -> void:
	draw_rect(Rect2(0, 0, width, 6), Color("6a6e72"))
	draw_rect(Rect2(0, 0, width, 1), Color("a0a4a8"))
	draw_line(Vector2(4, 0), Vector2(4, -400), Color("3a3c3e"), 1.0)
	draw_line(Vector2(width - 4, 0), Vector2(width - 4, -400), Color("3a3c3e"), 1.0)
	draw_rect(Rect2(width / 2 - 6, 6, 12, 4), Color("ffb040") if _state == 1 else Color("5a3a1e"))
