class_name Options
## The options screen, shared by the title screen and the pause menu: music and effects volume,
## fullscreen and the controls list. Changes apply and save straight away.

const CONTROLS: PackedStringArray = [
	"CONTROLS",
	"\tKEYBOARD\tGAMEPAD",
	"MOVE\tARROWS, A D\tSTICK, D-PAD",
	"AIM UP\tUP, W\tUP",
	"CROUCH\tDOWN, S\tDOWN",
	"JUMP\tZ, SPACE\tA",
	"SHOOT\tX, J\tX",
	"GRENADE\tC, K\tB",
	"PAUSE\tESC, P\tSTART",
	"FULLSCREEN\tF11\t",
	"MENU PICK\tENTER\tA",
	"MENU BACK\tESC\tB",
	"",
	"DOWN + JUMP DROPS THROUGH PLANKS",
	"SHOOT UP CLOSE TO USE THE KNIFE",
]


## Shows the options on `menu`; picking BACK (or pressing Escape) calls `on_back`.
static func open(menu: Menu, on_back: Callable) -> void:
	var items: Array[Dictionary] = [
		{
			"label": "MUSIC",
			"level": func() -> float: return float(Settings.music_level) / Settings.MAX_LEVEL,
			"adjust": func(dir: int) -> void: Settings.set_music_level(Settings.music_level + dir),
		},
		{
			"label": "EFFECTS",
			"level": func() -> float: return float(Settings.sfx_level) / Settings.MAX_LEVEL,
			"adjust": func(dir: int) -> void: Settings.set_sfx_level(Settings.sfx_level + dir),
		},
		{
			"label": "FULLSCREEN",
			"value": func() -> String: return "ON" if Settings.fullscreen else "OFF",
			"adjust": func(_dir: int) -> void: Settings.set_fullscreen(not Settings.fullscreen),
		},
		{"label": "CONTROLS", "pick": func() -> void: menu.show_page(CONTROLS)},
		{"label": "BACK", "pick": on_back},
	]
	menu.show_items("OPTIONS", items, 0, on_back)
