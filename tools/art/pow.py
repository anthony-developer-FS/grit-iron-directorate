"""Vanguard prisoners of war: bearded, in a torn shirt and field cap. 32x32, facing right."""
from pixel import Canvas, sheet
from grit import _leg, RUN, STAND

PALETTE = {
    "K": "#1b1612",
    "S": "#e0b48a", "s": "#b8875e", "k": "#2a1a10", "h": "#7a5230",  # skin, eye, beard
    "C": "#5a6b3a", "c": "#3f4c28",  # cap
    "U": "#c9c1a6", "u": "#a39a7c",  # shirt
    "T": "#5a5040", "t": "#40382c",  # trousers
    "B": "#3d3324", "b": "#251c12",  # boots
    "r": "#a07c4a",  # rope
    "G": "#3b2a1a", "g": "#5e432a", "Z": "#2b2d31",  # rifle
    "F": "#fff2a8", "f": "#ffb43a",
}

HEAD = """
..CCCCCC..
.CCCCCCCCC
.cccccccccc
.SSSSSSkS.
.sSSSSSkSS
.hSSSSSSS.
.hhhhhhhh.
..hhhhhh..
"""

SHIRT = """
.UUUUUUUU.
UUUUuUUUUU
UUUUUUUUUU
uUUUUUuUUu
.UUUUUUUU.
.uUUuUUUu.
"""

ROPES = """
r.......r
.rrrrrrr.
r.......r
.rrrrrrr.
"""

RIFLE = """
UUSggZZZZZZ
uuSGGGGZ...
...GG......
"""

SALUTE = """
....S
...Su
..Uu.
.Uu..
"""


def pow_frame(pose, extras=(), sit=False, sway=0):
    c = Canvas(32, 32)
    if sit:
        c.stamp("..TTTTTTTTT..\n.TTTTTTTTTTT.\nbbBB.....BBbb", 9 + sway, 27)
        top = 8
    else:
        fk, ff, bk, bf, lift = pose
        hip = (16, 21 - lift)
        _leg(c, (hip[0] - 1, hip[1]), (hip[0] + bk[0], hip[1] + bk[1]), (hip[0] + bf[0], hip[1] + bf[1]), True)
        _leg(c, (hip[0] + 1, hip[1]), (hip[0] + fk[0], hip[1] + fk[1]), (hip[0] + ff[0], hip[1] + ff[1]), False)
        top = -lift
    c.stamp(SHIRT, 11 + sway, 14 + top)
    c.stamp(HEAD, 11 + sway, 6 + top)
    for grid, x, y in extras:
        c.stamp(grid, x + sway, y + top)
    c.outline()
    return c.to_image(PALETTE)


FRAMES = ["tied0", "tied1", "idle", "run0", "run1", "run2", "run3", "run4", "run5", "salute",
          "fight", "fight_shoot"]


def build():
    frames = [pow_frame(None, [(ROPES, 11, 15)], sit=True, sway=0),
              pow_frame(None, [(ROPES, 11, 15)], sit=True, sway=1),
              pow_frame(STAND)]
    frames += [pow_frame(p) for p in RUN]
    frames += [pow_frame(STAND, [(SALUTE, 18, 10)])]
    frames += [pow_frame(STAND, [(RIFLE, 16, 16)]), pow_frame(STAND, [(RIFLE, 16, 16), (".fF\nfFF\n.fF", 27, 15)])]
    assert len(frames) == len(FRAMES)
    return {"pow.png": sheet(frames)}
