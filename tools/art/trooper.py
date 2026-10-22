"""Iron Directorate infantry: rifleman, grenadier, shield trooper and mortar crew.

All share Grit's 32x32 frame and leg rig (facing right, feet on row 30). Each type is a row in
the enemy sheet; `flash_sheet` gives the matching all-white frames for hit flashes.
"""
from PIL import Image
from pixel import Canvas, sheet
from grit import _leg, _rotate_ccw, RUN, STAND, CROUCH

BASE = {
    "K": "#141518",
    "M": "#4a5058", "m": "#30353b", "N": "#6f7782",  # steel helmet
    "E": "#ff4632", "e": "#9a1d14",  # goggle glow
    "Q": "#2c3034", "q": "#5c636b",  # gas mask, filter
    "U": "#7d848c", "u": "#5a6168", "I": "#9aa2aa",  # greatcoat
    "X": "#b32424",  # red armband
    "W": "#2a2420", "Y": "#a0a6ae",  # belt, buckle
    "T": "#45494f", "t": "#33363b",  # trousers
    "B": "#1f1f22", "b": "#121214",  # boots
    "G": "#3b2a1a", "g": "#5e432a", "Z": "#2b2d31", "z": "#53575d",  # wood, gun steel
    "F": "#fff2a8", "f": "#ffb43a",  # muzzle flash
    "P": "#7a7f86", "p": "#4f545a", "O": "#a8adb3", "o": "#1c1c1c",  # shield plate, rivets, slit
    "H": "#7d8a4e", "h": "#4f5a30",  # grenade heads
}


def palette(**changes):
    result = dict(BASE)
    result.update(changes)
    return result


PALETTES = {
    "rifleman": palette(),
    "grenadier": palette(U="#6d7a80", u="#4e5a60", I="#8c999f"),
    "shield": palette(U="#5d6166", u="#43474c", I="#7a7f85"),
    "mortar": palette(),
}

HEAD = """
...MMMMMM...
..MNNMMMMM..
.MMMMMMMMMM.
mmmmmmmmmmmm
..QQQQEEQQ..
..QQQQeEQQ..
..QQQQQQQQq.
...QQQQQQqq.
....QQQQ....
"""

HEAD_HIT = """
...MMMMMM...
..MNNMMMMM..
.MMMMMMMMMM.
mmmmmmmmmmmm
..QQQQeeQQ..
..QQQQeeQQ..
..QQQQQQQQq.
...QQQQQQqq.
....QQQQ....
"""

COAT = """
..UUUUUUUU..
.UUIUUUUUUU.
.UUUUUUUUUU.
.XXUUUUUUUU.
.XXUUUUUUUU.
.uUWWWWWWUu.
..UWWWYWWU..
..UUUUUUUU..
..UUUu.UUU..
..uUu..uUu..
"""

BANDOLIER = """
.......HH
.....HH..
...HH....
.HH......
"""

RIFLE_HIP = """
UUUgggZZZZZZZZZ
uuuGGGGGGZZ....
...GGG.........
"""

RIFLE_AIM = """
.......zzZZZZZZZZ
UUUUUGGgggZZZZZZZ
uuu..GGGGGGZ.....
......GG.........
"""

ARMS_UP = """
.U....U.
.U....U.
uU....Uu
"""

ARM_HANG = """
UU
uU
.u
"""

ARM_WINDUP = """
....ZZ.
...zZh.
..UU...
.UU....
UUu....
"""

ARM_THROW = """
UUUUUZZ
uuuuzZh
"""

SHIELD = """
PPPPPPP
PpPPPpP
PPPPPPP
PPPPPPP
PPooPPP
PPPPPPP
PPPPPPP
PPPPPPP
PpPPPpP
PPPPPPP
PPPPPPP
PPPPPPP
PPPPPPP
PPPPPPP
PPPPPPP
PpPPPpP
PPPPPPP
PPPPPPP
PPPPPPP
PPPPPPP
PPPPPPP
PPPPPPP
PpPPPpP
PPPPPPP
PPPPPPP
PPPPPPP
"""

MORTAR = """
........zZ
.......zZZ
......zZZ.
.....zZZ..
....zZZ...
...zZZ....
..zZZ.....
.zZZ.Z....
ZZZ...Z...
ZZ.....Z..
"""

FLASH = ".fF\nfFF\n.fF"


def trooper(pose, extras=(), head=HEAD, coat=True):
    fk, ff, bk, bf, lift = pose
    c = Canvas(32, 32)
    hip = (16, 21 - max(lift, 0))
    top = -lift
    _leg(c, (hip[0] - 1, hip[1]), (hip[0] + bk[0], hip[1] + bk[1]), (hip[0] + bf[0], hip[1] + bf[1]), True)
    _leg(c, (hip[0] + 1, hip[1]), (hip[0] + fk[0], hip[1] + fk[1]), (hip[0] + ff[0], hip[1] + ff[1]), False)
    if coat:
        c.stamp(COAT if lift >= 0 else "\n".join(COAT.strip("\n").split("\n")[:7]), 10, 13 + top)
    c.stamp(head, 10, 4 + top)
    for grid, x, y in extras:
        c.stamp(grid, x, y + top)
    return c


def corpse(extras_lying=()):
    """Two death frames: knocked back, then flat on the ground (falling away to the left)."""
    frames = []
    c = Canvas(32, 32)
    _leg(c, (15, 21), (13, 25), (11, 30), True)
    _leg(c, (17, 21), (18, 25), (17, 30), False)
    c.stamp(COAT, 8, 13)
    c.stamp(HEAD_HIT, 7, 3)
    frames.append(c)
    c = Canvas(32, 32)
    _leg(c, (19, 28), (23, 28), (28, 29), True)
    _leg(c, (19, 29), (23, 29), (28, 30), False)
    c.stamp(_rotate_ccw(COAT), 10, 21)
    c.stamp(_rotate_ccw(HEAD_HIT), 1, 20)
    frames.append(c)
    return frames


def _finish(canvases, pal):
    images = []
    for c in canvases:
        c.outline()
        images.append(c.to_image(pal))
    return images


def rifleman():
    hip = [(RIFLE_HIP, 15, 16)]
    aim = [(RIFLE_AIM, 13, 13)]
    frames = [trooper(STAND, hip)]
    frames += [trooper(p, hip) for p in RUN]
    frames += [trooper(STAND, aim), trooper(STAND, aim + [(FLASH, 30, 13)])]
    frames += [trooper(RUN[0], [(ARMS_UP, 12, 10)]), trooper(RUN[3], [(ARMS_UP, 12, 10)])]
    frames += corpse()
    return frames


RIFLEMAN_FRAMES = ["idle", "run0", "run1", "run2", "run3", "run4", "run5", "aim", "shoot",
                   "panic0", "panic1", "dead0", "dead1"]


def grenadier():
    band = (BANDOLIER, 11, 14)
    hang = (ARM_HANG, 19, 15)
    frames = [trooper(STAND, [band, hang])]
    frames += [trooper(p, [band, hang]) for p in RUN]
    frames += [trooper(STAND, [band, (ARM_WINDUP, 6, 8)]), trooper(STAND, [band, (ARM_THROW, 18, 15)])]
    frames += corpse()
    return frames


GRENADIER_FRAMES = ["idle", "run0", "run1", "run2", "run3", "run4", "run5", "windup", "throw",
                    "dead0", "dead1"]

WALK = [RUN[0], RUN[2], RUN[3], RUN[5]]


def shield(ping=False):
    plate = SHIELD.replace("P", "O").replace("p", "O") if ping else SHIELD
    extras = [(RIFLE_HIP, 14, 16), (plate, 21, 4)]
    frames = [trooper(STAND, extras)]
    frames += [trooper(p, extras) for p in WALK]
    return frames


SHIELD_FRAMES = ["idle", "walk0", "walk1", "walk2", "walk3", "ping0", "ping1", "ping2", "ping3", "ping4",
                 "dead0", "dead1"]


def shield_frames():
    return shield() + shield(ping=True) + corpse()


def mortar():
    kneel = CROUCH[0]
    frames = [trooper(kneel, [(MORTAR, 19, 14), (ARM_THROW, 16, 22)])]
    frames += [trooper(kneel, [(MORTAR, 19, 16), (ARM_THROW, 16, 22), ("..f.\n.fFf\nfFFF", 26, 10)])]
    frames += corpse()
    return frames


MORTAR_FRAMES = ["idle", "fire", "dead0", "dead1"]

# Sheet rows, in order. The game indexes frames by (row, column) using these names.
TYPES = [
    ("rifleman", rifleman, RIFLEMAN_FRAMES),
    ("grenadier", grenadier, GRENADIER_FRAMES),
    ("shield", shield_frames, SHIELD_FRAMES),
    ("mortar", mortar, MORTAR_FRAMES),
]
COLUMNS = 13


def _sheet(white):
    rows = []
    for name, build, names in TYPES:
        canvases = build()
        assert len(canvases) == len(names), name
        pal = PALETTES[name]
        if white:
            pal = {k: "#ffffff" for k in pal}
        images = _finish(canvases, pal)
        images += [Image.new("RGBA", (32, 32), (0, 0, 0, 0))] * (COLUMNS - len(images))
        rows += images
    return sheet(rows, COLUMNS)


def enemy_sheet():
    return _sheet(False)


def flash_sheet():
    return _sheet(True)
