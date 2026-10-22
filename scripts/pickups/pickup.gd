class_name Pickup
extends Area2D
## Something Grit can grab. Weapon drops show the gun itself; ammo boxes refill his special weapon
## (or bring back the last one he had); bomb crates add 10 grenades.
## The pickup zone reaches well above the item, arcade style, so jumping over it still collects it.

@export_enum("hmg", "rocket", "shotgun", "flame", "grenades", "ammo") var kind := "hmg"

## Pixel sprites, bottom-centered. K outline, G metal, g metal highlight, W wood, O olive,
## L olive highlight, R red, r dark red, Y brass, B dark brown.
const SPRITES := {
	"hmg": [
		"....KKKKKKKKKKKKKKK.",
		"...KGGGGGGGGGGGGGGGK",
		"KKKGgGGGGGKKKKKKKKK.",
		"KWWKGGGGGK..........",
		"KWWWKKGKKK..........",
		".KWWK.KGK...........",
		"..KK..KK............",
	],
	"rocket": [
		"..KKKKKKKKKKKKKKKKK.",
		".KOOOOOOOOOOOOOOOORK",
		"KKOLLLLLLLLLLLLLLORK",
		".KOOOOOOOOOOOOOOOORK",
		"..KKKKKKKGKKKGKKKKK.",
		"........KGK.KGK.....",
		"........KK...KK.....",
	],
	"shotgun": [
		"..........KKKKKKKKKK",
		"KKK......KGGGGGGGGGK",
		"KWWKKKKKKKGggggggggK",
		"KWWWWWWWWKKKKKKKKKK.",
		".KKWWWKKGK..........",
		"...KKK.KK...........",
	],
	"flame": [
		".KKKK...............",
		"KRRRRK..KKKKKKKKKK..",
		"KRrRRKKKGGGGGGGGGGKK",
		"KRRRRKGGGGgggggGGGYK",
		"KRRRRKKKKKKGKKKKKKK.",
		"KrRRrK....KGK.......",
		".KKKK.....KK........",
	],
	"ammo": [
		"..Y.Y.Y.Y.Y..",
		".KYKYKYKYKYK.",
		"KKKKKKKKKKKKK",
		"KOOOOOOOOOOOK",
		"KOLLLLLLLLLOK",
		"KOOOYYYYYOOOK",
		"KOOOOOOOOOOOK",
		"KKKKKKKKKKKKK",
	],
	"grenades": [
		"..KK.....KK...",
		".KOOK...KOOK..",
		".KOLK...KOLK..",
		"KKKKKKKKKKKKKK",
		"KWWWWWWWWWWWWK",
		"KWBBBBBBBBBBWK",
		"KWWWWWWWWWWWWK",
		"KKKKKKKKKKKKKK",
	],
}
const PALETTE := {
	"K": Color("1a1410"), "G": Color("4a4e54"), "g": Color("8a9098"), "W": Color("7a4a24"),
	"O": Color("5a6b3a"), "L": Color("7d8f4e"), "R": Color("b33a3a"), "r": Color("7a2222"),
	"Y": Color("d8b040"), "B": Color("3d2a18"),
}

## Supply drops float down under a small parachute from this far above where they land.
const PARACHUTE_HEIGHT := 140.0
const PARACHUTE_SPEED := 40.0

## Set before adding to the tree to make the pickup drift down onto its position.
var parachute := false

var _base_y := 0.0
var _time := 0.0
var _falling := false


func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	if parachute:
		_falling = true
		position.y = _base_y - PARACHUTE_HEIGHT


func _process(delta: float) -> void:
	_time += delta
	if _falling:
		position.y = minf(position.y + PARACHUTE_SPEED * delta, _base_y)
		_falling = position.y < _base_y
	else:
		position.y = _base_y + roundf(sin(_time * 4.0) * 1.5)
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null or player.dead:
		return
	match kind:
		"grenades":
			Game.add_grenades(10)
			Game.show_message("BOMBS +10", 1.0)
		"ammo":
			Game.show_message(player.reload_special() + " AMMO!", 1.0)
		_:
			player.give_weapon(kind)
			Game.show_message(String(Player.WEAPONS[kind]["label"]) + "!", 1.0)
	Game.add_score(200)
	queue_free()


func _draw() -> void:
	var rows: Array = SPRITES[kind]
	var width: int = rows[0].length()
	var origin := Vector2(-width / 2, -rows.size() - 2)
	if _falling:
		_draw_parachute(origin.y)
	# Small glint so pickups stand out from the scenery.
	if int(_time * 3.0) % 3 == 0:
		draw_rect(Rect2(origin + Vector2(width - 3, -2), Vector2(1, 1)), Color.WHITE)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if key != ".":
				draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), PALETTE[key])


func _draw_parachute(top: float) -> void:
	var canopy := Vector2(0, top - 22)
	draw_line(Vector2(-6, top), canopy + Vector2(-10, 2), Color("d8d0b8"))
	draw_line(Vector2(6, top), canopy + Vector2(10, 2), Color("d8d0b8"))
	var dome := PackedVector2Array()
	for i in 9:
		dome.append(canopy + Vector2.from_angle(PI + PI * i / 8.0) * Vector2(12, 9))
	draw_colored_polygon(dome, Color("c8c0a0"))
	draw_rect(Rect2(canopy + Vector2(-12, -1), Vector2(24, 2)), Color("8a826a"))
