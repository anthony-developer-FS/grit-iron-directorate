@tool
class_name Prop
extends Node2D
## Non-colliding scenery drawn in code: beach obstacles, lamps, crates and signs.
## The origin is where the prop meets the ground.

@export_enum("hedgehog", "wire", "lamp", "crate", "sign", "crater", "pipes", "ore_crate", "poster") var kind := "hedgehog":
	set(value):
		kind = value
		queue_redraw()


func _draw() -> void:
	match kind:
		"hedgehog":
			for line in [[Vector2(-8, 0), Vector2(8, -16)], [Vector2(8, 0), Vector2(-8, -16)], [Vector2(-7, -8), Vector2(7, -8)]]:
				draw_line(line[0], line[1], Color("2e3033"), 2.0)
		"wire":
			for x in range(-16, 16, 4):
				draw_line(Vector2(x, -6), Vector2(x + 4, -2), Color("6a6e72"), 1.0)
				draw_line(Vector2(x, -2), Vector2(x + 4, -6), Color("6a6e72"), 1.0)
			draw_line(Vector2(-16, 0), Vector2(-16, -8), Color("3b2a1a"), 1.0)
			draw_line(Vector2(16, 0), Vector2(16, -8), Color("3b2a1a"), 1.0)
		"lamp":
			draw_line(Vector2(0, 0), Vector2(0, -30), Color("2e3033"), 1.0)
			draw_rect(Rect2(-3, -34, 6, 4), Color("3e4246"))
			draw_circle(Vector2(0, -29), 2.0, Color("ffd27a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -29), Vector2(2, -29), Vector2(14, 0), Vector2(-14, 0)]), Color(1.0, 0.85, 0.5, 0.12))
		"crate":
			draw_rect(Rect2(-8, -14, 16, 14), Color("6a5030"))
			draw_rect(Rect2(-8, -14, 16, 14), Color("3b2a1a"), false, 1.0)
			draw_line(Vector2(-8, -14), Vector2(8, 0), Color("3b2a1a"), 1.0)
		"sign":
			draw_line(Vector2(0, 0), Vector2(0, -18), Color("3b2a1a"), 2.0)
			draw_rect(Rect2(-10, -24, 20, 9), Color("c9c1a6"))
			draw_string(ThemeDB.fallback_font, Vector2(-9, -17), "ACHTUNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("b32424"))
		"crater":
			draw_colored_polygon(PackedVector2Array([Vector2(-18, 0), Vector2(-12, 3), Vector2(12, 3), Vector2(18, 0), Vector2(10, -2), Vector2(-10, -2)]), Color("3d3324"))
		"pipes":
			draw_rect(Rect2(-40, -60, 80, 3), Color("4a5258"))
			draw_rect(Rect2(-40, -52, 80, 2), Color("5a3a2a"))
			draw_rect(Rect2(20, -60, 3, 60), Color("4a5258"))
		"ore_crate":
			draw_rect(Rect2(-9, -12, 18, 12), Color("5a5e62"))
			draw_rect(Rect2(-6, -16, 12, 4), Color(0.3, 1.0, 0.8, 0.8))
			draw_string(ThemeDB.fallback_font, Vector2(-8, -3), "SCI-DIV", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("c9c1a6"))
		"poster":
			draw_rect(Rect2(-8, -40, 16, 22), Color("b32424"))
			draw_rect(Rect2(-5, -36, 10, 10), Color("1c1c1c"))
			draw_string(ThemeDB.fallback_font, Vector2(-7, -21), "VANE", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color("e8e0c8"))
