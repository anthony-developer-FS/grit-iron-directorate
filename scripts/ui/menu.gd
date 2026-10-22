class_name Menu
extends Node2D
## A vertical menu list: Up/Down to choose, Left/Right to change a setting, Enter (gamepad A) to
## pick, Escape (gamepad B) to go back. Draws in screen coordinates,
## centered horizontally, so it works on the title screen and on the HUD layer.
##
## Each item is a Dictionary with a "label" and any of:
##   "pick": Callable()            run when the item is picked
##   "adjust": Callable(dir: int)  run on Left (-1) or Right (+1)
##   "value": Callable() -> String text shown after the label
##   "level": Callable() -> float  0..1, shown as a 10-segment bar after the label
##   "hint": String                small line under the selected item

const WIDTH := 320.0
const LINE := 13.0
const PAGE_COLUMNS := [34.0, 120.0, 216.0]

var title := ""
var items: Array[Dictionary] = []
var selected := 0
## Vertical center of the list.
var center_y := 110.0
## A page of plain text (such as the controls) shown instead of the items; any button closes it.
## Tab-separated lines are laid out in the PAGE_COLUMNS.
var page: PackedStringArray = []
## Dims everything behind the menu when its alpha is above zero.
var backdrop := Color(0, 0, 0, 0)
## Run when Escape is pressed on the list; empty means Escape does nothing.
var on_back := Callable()

var _time := 0.0
## Input is ignored on the frame the menu opens, so the key that opened it (Escape for the
## pause menu) doesn't also act on it.
var _shown_frame := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_items(new_title: String, new_items: Array[Dictionary], select := 0, back := Callable()) -> void:
	title = new_title
	on_back = back
	items = new_items
	selected = clampi(select, 0, items.size() - 1)
	page = []
	_time = 0.0
	_shown_frame = Engine.get_process_frames()
	visible = true
	queue_redraw()


func show_page(lines: PackedStringArray) -> void:
	page = lines
	queue_redraw()


func _process(delta: float) -> void:
	if not visible or items.is_empty():
		return
	_time += delta
	queue_redraw()
	if Engine.get_process_frames() == _shown_frame:
		return
	if not page.is_empty():
		if _pressed(["menu_accept", "menu_back"]):
			Sfx.play("menu_move", 0.0)
			page = []
		return
	if _pressed(["aim_up"]):
		_move(-1)
	elif _pressed(["crouch"]):
		_move(1)
	elif _pressed(["move_left"]):
		_adjust(-1)
	elif _pressed(["move_right"]):
		_adjust(1)
	elif _pressed(["menu_accept"]):
		var item := items[selected]
		if item.has("pick"):
			Sfx.play("menu_select", 0.0)
			item["pick"].call()
		elif item.has("adjust"):
			_adjust(1)
	elif _pressed(["menu_back"]) and on_back.is_valid():
		Sfx.play("menu_move", 0.0)
		on_back.call()


func _pressed(actions: Array) -> bool:
	return actions.any(func(action: String) -> bool: return Input.is_action_just_pressed(action))


func _move(step: int) -> void:
	selected = wrapi(selected + step, 0, items.size())
	Sfx.play("menu_move", 0.0)


func _adjust(direction: int) -> void:
	var item := items[selected]
	if item.has("adjust"):
		item["adjust"].call(direction)
		Sfx.play("menu_move", 0.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if backdrop.a > 0.0:
		draw_rect(Rect2(0, 0, WIDTH, 180), backdrop)
	if not page.is_empty():
		_draw_page(font)
		return
	var top := center_y - (items.size() * LINE) / 2.0
	if title != "":
		draw_string(font, Vector2(0, top - 8), title, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, 8, Color("ffe066"))
	for i in items.size():
		var item := items[i]
		var chosen := i == selected
		var color := Color.WHITE if chosen else Color("8a94a4")
		var y := top + i * LINE + 9
		var label: String = item["label"]
		if item.has("value"):
			label += "  " + str(item["value"].call())
		var text_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var bar_width := 0.0
		if item.has("level"):
			bar_width = 6.0 + Settings.MAX_LEVEL * 3.0
		var x := roundf((WIDTH - text_width - bar_width) / 2.0)
		draw_string(font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
		if item.has("level"):
			_draw_level(Vector2(x + text_width + 6.0, y - 6.0), item["level"].call(), color)
		if chosen and int(_time * 3.0) % 3 != 0:
			draw_string(font, Vector2(x - 10, y), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffe066"))
	var hint: String = items[selected].get("hint", "")
	if hint != "":
		var y := top + items.size() * LINE + 10
		draw_string(font, Vector2(0, y), hint, HORIZONTAL_ALIGNMENT_CENTER, WIDTH, 8, Color("ff9a6a"))


func _draw_level(at: Vector2, fraction: float, color: Color) -> void:
	var filled := roundi(fraction * Settings.MAX_LEVEL)
	for i in Settings.MAX_LEVEL:
		var rect := Rect2(at.x + i * 3.0, at.y, 2, 7)
		draw_rect(rect.grow(1), Color.BLACK)
		draw_rect(rect, color if i < filled else Color("3a4250"))


func _draw_page(font: Font) -> void:
	# Pages are centered on the screen, not on the list, so a long page fits.
	var height := page.size() * 10.0
	var top := roundf(90.0 - height / 2.0)
	draw_rect(Rect2(20, top - 6, WIDTH - 40, height + 12), Color(0.05, 0.07, 0.1, 0.96))
	for i in page.size():
		var color := Color("ffe066") if i == 0 else Color.WHITE
		var y := top + 8 + i * 10.0
		if "\t" in page[i]:
			var cells := page[i].split("\t")
			for c in cells.size():
				draw_string(font, Vector2(PAGE_COLUMNS[c], y), cells[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color if c > 0 else Color("ffe066"))
		else:
			draw_string(font, Vector2(0, y), page[i], HORIZONTAL_ALIGNMENT_CENTER, WIDTH, 8, color)
