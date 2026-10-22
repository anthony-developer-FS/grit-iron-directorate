"""Iron Directorate rifleman. Same 32x32 frame and leg rig as Grit, facing right."""
from pixel import Canvas
from grit import _leg, RUN, IDLE

PALETTE = {
    "K": "#141518",
    "M": "#4a5058", "m": "#30353b", "N": "#6f7782",  # steel helmet
    "E": "#ff4632", "e": "#9a1d14",  # goggle glow
    "Q": "#2c3034", "q": "#5c636b",  # gas mask, filter
    "U": "#7d848c", "u": "#5a6168", "I": "#9aa2aa",  # greatcoat
    "X": "#b32424",  # red armband
    "W": "#2a2420", "Y": "#a0a6ae",  # belt, buckle
    "T": "#45494f", "t": "#33363b",  # trousers
    "B": "#1f1f22", "b": "#121214",  # boots
    "G": "#3b2a1a", "g": "#5e432a", "Z": "#2b2d31",  # rifle wood and steel
    "F": "#fff2a8", "f": "#ffb43a",
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

RIFLE = """
UUUgggZZZZZZZZZ
uuuGGGGGGZZ....
...GGG.........
"""


def frame(pose, flash=False):
    fk, ff, bk, bf, lift = pose
    c = Canvas(32, 32)
    hip = (16, 21 - lift)
    top = -lift
    _leg(c, (hip[0] - 1, hip[1]), (hip[0] + bk[0], hip[1] + bk[1]), (hip[0] + bf[0], hip[1] + bf[1]), True)
    _leg(c, (hip[0] + 1, hip[1]), (hip[0] + fk[0], hip[1] + fk[1]), (hip[0] + ff[0], hip[1] + ff[1]), False)
    c.stamp(COAT, 10, 13 + top)
    c.stamp(HEAD, 10, 4 + top)
    c.stamp(RIFLE, 15, 16 + top)
    c.outline()
    if flash:
        c.stamp(".fF\nfFF\n.fF", 30, 15 + top)
    return c.to_image(PALETTE)


def animations():
    return {
        "idle": [frame(IDLE[0])],
        "run": [frame(p) for p in RUN],
        "shoot": [frame(IDLE[0], flash=True)],
    }
