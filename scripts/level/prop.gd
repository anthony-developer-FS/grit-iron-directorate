@tool
class_name Prop
extends Node2D
## Non-colliding scenery: beach obstacles, lamps, crates and signs. Sprites come from
## tools/art/world.py; the lamp's light cone and the pipes are drawn in code.
## The origin is where the prop meets the ground.

const SPRITES := {
	"hedgehog": preload("res://assets/sprites/prop_hedgehog.png"),
	"wire": preload("res://assets/sprites/prop_wire.png"),
	"lamp": preload("res://assets/sprites/prop_lamp.png"),
	"crate": preload("res://assets/sprites/prop_crate.png"),
	"sign": preload("res://assets/sprites/prop_sign.png"),
	"crater": preload("res://assets/sprites/prop_crater.png"),
	"ore_crate": preload("res://assets/sprites/prop_ore_crate.png"),
	"poster": preload("res://assets/sprites/prop_poster.png"),
}

@export_enum("hedgehog", "wire", "lamp", "crate", "sign", "crater", "pipes", "ore_crate", "poster") var kind := "hedgehog":
	set(value):
		kind = value
		queue_redraw()


func _draw() -> void:
	match kind:
		"pipes":
			draw_rect(Rect2(-40, -60, 80, 3), Color("4a5258"))
			draw_rect(Rect2(-40, -52, 80, 2), Color("5a3a2a"))
			draw_rect(Rect2(20, -60, 3, 60), Color("4a5258"))
			return
		"lamp":
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -29), Vector2(2, -29), Vector2(14, 0), Vector2(-14, 0)]), Color(1.0, 0.85, 0.5, 0.12))
		"poster":
			# Pasted on the wall at head height.
			var poster: Texture2D = SPRITES[kind]
			draw_texture(poster, Vector2(-poster.get_width() / 2.0, -40))
			return
		"crater":
			var crater: Texture2D = SPRITES[kind]
			draw_texture(crater, Vector2(-crater.get_width() / 2.0, -3))
			return
	var texture: Texture2D = SPRITES[kind]
	draw_texture(texture, Vector2(-texture.get_width() / 2.0, -texture.get_height() + 1))
