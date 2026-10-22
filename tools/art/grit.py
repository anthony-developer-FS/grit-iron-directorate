"""Grit Kessler: Vanguard Ops commando. 32x32 frames, facing right, feet on row 30."""
from pixel import Canvas

PALETTE = {
    "K": "#1b1612",  # outline
    "H": "#3b2619",  # hair
    "S": "#eab88c", "s": "#c08458", "k": "#2a1a10",  # skin, skin shadow, eye
    "h": "#7a5238",  # stubble and brows
    "R": "#c8352a", "r": "#84201a",  # bandana
    "O": "#6e7d3c", "o": "#4d5a2a", "L": "#94a456",  # olive shirt
    "V": "#4a4a2c", "v": "#363620", "J": "#7a7448",  # vest, vest shadow, pouches
    "W": "#6a4826", "Y": "#d8b040",  # belt, buckle
    "T": "#6f6a42", "t": "#4f4b2e",  # trousers
    "B": "#3e2a1a", "b": "#251810",  # boots
    "G": "#3a3d42", "g": "#6c7178", "F": "#fff2a8", "f": "#ffb43a",  # gun, muzzle flash
}

HEAD = """
...H.HHH.H..
..HHHHHHhHH.
.HHHHHHHHHH.
RRRRRRRRRRR.
rRRRRRRRRRr.
HHHsSSSSHHS.
HHssSSSSkSS.
HHsSSSSSkSSS
.HHSSSSSSSs.
..shhSSSShh.
...hhhhhhh..
"""

TAILS = [
    ["RR.", ".rR"],
    [".RR", "RrR"],
    ["RRr", "..r"],
]

TORSO = """
..OOOOOOOO..
.OOLVVVVOOO.
.OOVVVVVVOO.
.OOVJVVJVOO.
.oOVJVVJVOo.
..oVVVVVVo..
..WWWWWWWW..
..WWWWYWWW..
"""

ARM_FORWARD = """
OOOSSggggggg
oooSsGGGGGGG
....sGG.....
.....GG.....
"""

ARM_BACK = """
oo.
oSs
.ss
"""


def _line(canvas, a, b, key, width=3):
    (x0, y0), (x1, y1) = a, b
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        x = round(x0 + (x1 - x0) * i / steps)
        y = round(y0 + (y1 - y0) * i / steps)
        for dx in range(width):
            canvas.put(x + dx - width // 2, y, key)
            canvas.put(x + dx - width // 2, y + 1, key)


def _leg(canvas, hip, knee, foot, back):
    cloth = "t" if back else "T"
    boot = "b" if back else "B"
    _line(canvas, hip, knee, cloth)
    _line(canvas, knee, (foot[0], foot[1] - 2), cloth)
    fx, fy = foot
    canvas.rect(fx - 1, fy - 2, 4, 2, boot)
    canvas.rect(fx - 1, fy, 5, 1, "b")


# (front knee, front foot, back knee, back foot, body lift), relative to the hip at (16, 21).
RUN = [
    ((3, 5), (6, 9), (-2, 5), (-5, 7), 0),
    ((2, 4), (3, 9), (-3, 4), (-3, 6), 1),
    ((1, 5), (0, 9), (1, 3), (2, 6), 1),
    ((-2, 5), (-5, 7), (3, 5), (6, 9), 0),
    ((-3, 4), (-3, 6), (2, 4), (3, 9), 1),
    ((1, 3), (2, 6), (1, 5), (0, 9), 1),
]
IDLE = [((1, 5), (2, 9), (-2, 5), (-2, 9), 0), ((1, 5), (2, 9), (-2, 5), (-2, 9), 0)]
JUMP = [((3, 3), (2, 7), (-1, 4), (-4, 6), 0)]


def frame(pose, tail=0, breathe=0, flash=False):
    fk, ff, bk, bf, lift = pose
    c = Canvas(32, 32)
    hip = (16, 21 - lift)
    top = -lift + breathe
    _leg(c, (hip[0] - 1, hip[1]), (hip[0] + bk[0], hip[1] + bk[1]), (hip[0] + bf[0], hip[1] + bf[1]), True)
    c.stamp(ARM_BACK, 9, 15 + top)
    c.stamp(TORSO, 10, 13 + top)
    _leg(c, (hip[0] + 1, hip[1]), (hip[0] + fk[0], hip[1] + fk[1]), (hip[0] + ff[0], hip[1] + ff[1]), False)
    c.stamp(TAILS[tail], 8, 6 + top)
    c.stamp(HEAD, 10, 3 + top)
    c.stamp(ARM_FORWARD, 18, 15 + top)
    c.outline()
    if flash:
        c.stamp(".fF\nfFF\n.fF", 29, 14 + top)
    return c.to_image(PALETTE)


def animations():
    return {
        "idle": [frame(IDLE[0], 0, 0), frame(IDLE[1], 1, 1)],
        "run": [frame(p, i % 3) for i, p in enumerate(RUN)],
        "jump": [frame(JUMP[0], 2)],
        "shoot": [frame(IDLE[0], 0, 0, flash=True)],
    }
