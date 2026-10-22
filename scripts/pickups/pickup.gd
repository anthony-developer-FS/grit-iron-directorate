class_name Pickup
extends Area2D
## A supply crate. Weapon crates hand Grit a special weapon; grenade crates add 10 grenades.

@export_enum("hmg", "grenades") var kind := "hmg"

var _base_y := 0.0
var _time := 0.0


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + roundf(sin(_time * 4.0) * 1.5)


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or player.dead:
		return
	if kind == "grenades":
		Game.add_grenades(10)
		Game.show_message("BOMBS +10", 1.0)
	else:
		player.give_weapon(kind)
		Game.show_message(String(Player.WEAPONS[kind]["label"]) + "!", 1.0)
	Game.add_score(200)
	queue_free()


func _draw() -> void:
	var letter := "B" if kind == "grenades" else "H"
	draw_rect(Rect2(-6, -12, 12, 12), Color("8a6a3a"))
	draw_rect(Rect2(-6, -12, 12, 12), Color("3b2a1a"), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(-3, -3), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ffe066"))
