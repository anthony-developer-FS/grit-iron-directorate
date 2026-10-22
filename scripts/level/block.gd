@tool
class_name Block
extends StaticBody2D
## Level geometry: a solid rectangle (or a one-way platform) tiled with a surface texture from
## tools/art/world.py, or a flat color for "flat". The origin is the top-left corner. Set `size`
## in the inspector and the collision follows.

const SURFACES := {
	"sand": [preload("res://assets/sprites/surface_sand_top.png"), preload("res://assets/sprites/surface_sand_fill.png")],
	"dirt": [preload("res://assets/sprites/surface_dirt_top.png"), preload("res://assets/sprites/surface_dirt_fill.png")],
	"sandbags": [preload("res://assets/sprites/surface_sandbags_top.png"), preload("res://assets/sprites/surface_sandbags_fill.png")],
	"wood": [preload("res://assets/sprites/surface_wood_top.png"), preload("res://assets/sprites/surface_wood_fill.png")],
	"rock": [preload("res://assets/sprites/surface_rock_top.png"), preload("res://assets/sprites/surface_rock_fill.png")],
	"metal": [preload("res://assets/sprites/surface_metal_top.png"), preload("res://assets/sprites/surface_metal_fill.png")],
	"concrete": [preload("res://assets/sprites/surface_concrete_top.png"), preload("res://assets/sprites/surface_concrete_fill.png")],
}

@export var size := Vector2(64, 16):
	set(value):
		size = value
		_rebuild()
@export var color := Color("5a4a36"):
	set(value):
		color = value
		queue_redraw()
@export_enum("flat", "sand", "dirt", "sandbags", "wood", "rock", "metal", "concrete") var surface := "flat":
	set(value):
		surface = value
		queue_redraw()
## One-way platforms can be jumped through from below and dropped through with Down + Jump.
@export var one_way := false:
	set(value):
		one_way = value
		_rebuild()


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var shape_node := get_node_or_null("Shape") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "Shape"
		add_child(shape_node)
	var rect := RectangleShape2D.new()
	rect.size = size
	shape_node.shape = rect
	shape_node.position = size / 2.0
	shape_node.one_way_collision = one_way
	# Layer 1 = world, layer 4 = platforms.
	collision_layer = 8 if one_way else 1
	collision_mask = 0
	queue_redraw()


func _draw() -> void:
	if surface != "flat":
		var tiles: Array = SURFACES[surface]
		var top_height := minf(16.0, size.y)
		draw_texture_rect(tiles[0], Rect2(0, 0, size.x, top_height), true)
		if size.y > 16.0:
			draw_texture_rect(tiles[1], Rect2(0, 16, size.x, size.y - 16.0), true)
		return
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(0, 0, size.x, 2), color.lightened(0.25))
	if not one_way:
		draw_rect(Rect2(0, size.y - 1, size.x, 1), color.darkened(0.3))
