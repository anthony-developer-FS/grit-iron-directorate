extends Node2D
## Headless check that a freed POW jumps over an obstacle to keep up with Grit, instead of
## running into it. Builds a floor with a 20 px block between the POW and Grit.
## Run: godot --headless --fixed-fps 60 res://tests/pow_test.tscn

func _rect_body(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	shape.shape = r
	body.position = pos
	body.add_child(shape)
	add_child(body)

func _ready() -> void:
	_rect_body(Vector2(200, 110), Vector2(600, 20))
	_rect_body(Vector2(100, 90), Vector2(16, 20))
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	player.position = Vector2(150, 99)
	add_child(player)
	player.parachuting = false
	player.god_mode = true
	var pow := (load("res://scenes/pickups/pow.tscn") as PackedScene).instantiate() as Pow
	pow.position = Vector2(70, 99)
	add_child(pow)
	await get_tree().physics_frame
	pow._rescuer = player
	pow._set_state(Pow.State.FIGHTING)
	var max_y := 999.0
	for i in 180:
		await get_tree().physics_frame
		max_y = minf(max_y, pow.global_position.y)
	# The block spans x 92 to 108; he should end up past it, near his spot behind Grit (x 124).
	if pow.global_position.x > 110.0 and max_y < 80.0:
		print("POW TEST PASSED")
		get_tree().quit(0)
	else:
		printerr("POW TEST FAILED: POW stuck at x=%.1f (highest y %.1f)" % [pow.global_position.x, max_y])
		get_tree().quit(1)
