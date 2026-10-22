"""Sgt. "Grit" Calloway, Vanguard Ops commando.

Body frames are 32x32, facing right, with the feet on row 30 and the body centered on column 16.
The aiming arm is a separate overlay (see `arm_frames`) so any body pose can aim any direction.
"""
from pixel import Canvas, sheet

PALETTE = {
    "K": "#1b1612",  # outline
    "H": "#3b2619",  # hair
    "S": "#eab88c", "s": "#c08458", "k": "#2a1a10",  # skin, skin shadow, eye
    "h": "#7a5238",  # stubble and brows
    "R": "#c8352a", "r": "#84201a",  # bandana
    "O": "#6e7d3c", "o": "#4d5a2a", "L": "#94a456",  # olive shirt
    "V": "#4a4a2c", "J": "#7a7448",  # vest, pouches
    "W": "#6a4826", "Y": "#d8b040",  # belt, buckle
    "T": "#6f6a42", "t": "#4f4b2e",  # trousers
    "B": "#3e2a1a", "b": "#251810",  # boots
    "G": "#3a3d42", "g": "#6c7178", "N": "#8d949c",  # gun metal
    "D": "#5e432a", "d": "#3f2c1b",  # gun wood
    "Q": "#5a6b3a", "q": "#3c4826",  # olive drab launcher / tank
    "F": "#fff2a8", "f": "#ffb43a",  # muzzle flash
    "C": "#d6cfb4", "c": "#a69e82", "x": "#8a8270",  # parachute canopy, shade, cords
    "Z": "#e8eef2",  # knife blade
}

HEAD = """
...H.HHH.H..
..HHHHHHHHH.
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

HEAD_HURT = """
...H.HHH.H..
..HHHHHHHHH.
.HHHHHHHHHH.
RRRRRRRRRRR.
rRRRRRRRRRr.
HHHsSSSSSSS.
HHssSSSkSkS.
HHsSSSSSkSSS
.HHSSSSSSSs.
..shhSkkShh.
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


# Leg poses: (front knee, front foot, back knee, back foot, body lift), relative to the hip.
RUN = [
    ((3, 5), (6, 9), (-2, 5), (-5, 7), 0),
    ((2, 4), (3, 9), (-3, 4), (-3, 6), 1),
    ((1, 5), (0, 9), (1, 3), (2, 6), 1),
    ((-2, 5), (-5, 7), (3, 5), (6, 9), 0),
    ((-3, 4), (-3, 6), (2, 4), (3, 9), 1),
    ((1, 3), (2, 6), (1, 5), (0, 9), 1),
]
STAND = ((1, 5), (2, 9), (-2, 5), (-2, 9), 0)
JUMP = ((3, 3), (2, 7), (-1, 4), (-4, 6), 0)
FALL = ((2, 5), (3, 9), (-2, 4), (-3, 8), 0)
HANG = ((1, 5), (1, 9), (-1, 5), (-2, 9), 0)
# Crouching: the upper body drops 7 px and the legs fold.
CROUCH = [((4, 2), (5, 9), (-3, 4), (-4, 9), -7), ((5, 2), (6, 9), (-2, 4), (-3, 9), -7)]

# Where the aiming arm attaches, in body-frame pixels (before any lift).
SHOULDER = (19, 15)


def body(pose, tail=0, breathe=0, head=HEAD):
    fk, ff, bk, bf, lift = pose
    c = Canvas(32, 32)
    hip_y = 21 - max(lift, 0)
    top = -lift + breathe
    hip = (16, hip_y)
    _leg(c, (hip[0] - 1, hip[1]), (hip[0] + bk[0], hip[1] + bk[1]), (hip[0] + bf[0], hip[1] + bf[1]), True)
    c.stamp(ARM_BACK, 9, 15 + top)
    c.stamp(TORSO, 10, 13 + top)
    _leg(c, (hip[0] + 1, hip[1]), (hip[0] + fk[0], hip[1] + fk[1]), (hip[0] + ff[0], hip[1] + ff[1]), False)
    c.stamp(TAILS[tail], 8, 6 + top)
    c.stamp(head, 10, 3 + top)
    c.outline()
    return c.to_image(PALETTE)


def dead_frames():
    frames = []
    # Knocked back: leaning away from the hit.
    c = Canvas(32, 32)
    _leg(c, (15, 21), (13, 25), (11, 30), True)
    _leg(c, (17, 21), (18, 25), (17, 30), False)
    c.stamp(TORSO, 8, 13)
    c.stamp(TAILS[2], 6, 5)
    c.stamp(HEAD_HURT, 7, 2)
    c.outline()
    frames.append(c.to_image(PALETTE))
    # Falling backwards.
    c = Canvas(32, 32)
    _leg(c, (17, 25), (21, 24), (25, 27), True)
    _leg(c, (17, 26), (21, 26), (26, 30), False)
    c.stamp(_rotate_ccw(TORSO), 9, 19)
    c.stamp(_rotate_ccw(HEAD_HURT), 1, 18)
    c.outline()
    frames.append(c.to_image(PALETTE))
    # Lying flat.
    c = Canvas(32, 32)
    _leg(c, (18, 28), (22, 28), (27, 29), True)
    _leg(c, (18, 29), (22, 29), (27, 30), False)
    c.stamp(_rotate_ccw(TORSO), 10, 22)
    c.stamp(_rotate_ccw(HEAD_HURT), 0, 21)
    c.outline()
    frames.append(c.to_image(PALETTE))
    return frames


def _rows(grid):
    rows = grid.strip("\n").split("\n")
    width = max(len(r) for r in rows)
    return [r.ljust(width, ".") for r in rows]


def _rotate_ccw(grid):
    """Rotates a text grid 90 degrees counter-clockwise (the top ends up on the left)."""
    rows = _rows(grid)
    return "\n".join("".join(rows[y][x] for y in range(len(rows))) for x in range(len(rows[0]) - 1, -1, -1))


def _rotate_cw(grid):
    rows = _rows(grid)
    return "\n".join("".join(rows[y][x] for y in range(len(rows) - 1, -1, -1)) for x in range(len(rows[0])))


# Arm + weapon held level, drawn from the shoulder (row 0, column 0 sits on the shoulder).
WEAPON_ARMS = {
    "pistol": """
OOOSSggggggg
oooSsGGGGGGG
....sGG.....
.....GG.....
""",
    "hmg": """
....GGGG...........
OOOSSgggggggNNNNNNNN
oooSsGGGGGGGGGGGGGGG
...dDDsGG.GG........
...dDD..............
""",
    "rocket": """
..QQQQQQQQQQQQQQ
QQQQQQQQQQQQQQQQQ
OOOSSqqqqqqqqqqqqq
oooSsGG..G.......
....GG...........
""",
    "shotgun": """
OOOSSgggggggggggg
oooSDDDDDDGGGGGGG
.dDDsGG..........
.dD..............
""",
    "flame": """
..qQQq.............
OOOQQQQSSggggggggNN
oooqQQqSsGGGGGGGGGG
.......sGG.........
""",
    "knife": """
OOOSSZZZZZ
oooSsGZZZ.
""",
}

# Muzzle (or blade tip) distance from the shoulder along the aim, in pixels.
MUZZLE = {"pistol": 12, "hmg": 20, "rocket": 18, "shotgun": 17, "flame": 19, "knife": 10}

ARM_ANGLES = [-90, -45, 0, 45, 90]


def arm_frames(name):
    """The arm and weapon at each of ARM_ANGLES, in 48x48 frames with the shoulder at (24, 24)."""
    grid = WEAPON_ARMS[name]
    frames = []
    for angle in ARM_ANGLES:
        c = Canvas(48, 48)
        if angle == 0:
            c.stamp(grid, 24, 23)
        elif angle == -90:
            rotated = _rotate_ccw(grid)
            height = len(rotated.split("\n"))
            c.stamp(rotated, 23, 24 - height + 1)
        elif angle == 90:
            c.stamp(_rotate_cw(grid), 21, 24)
        else:
            _diagonal(c, grid, angle)
        c.outline()
        frames.append(c.to_image(PALETTE))
    return frames


def _diagonal(canvas, grid, angle):
    """Shears a level grid onto a 45 degree diagonal, shortened so the gun keeps its length."""
    rows = _rows(grid)
    sign = 1 if angle > 0 else -1
    length = round(len(rows[0]) * 0.72)
    for y, row in enumerate(rows):
        for nx in range(length):
            key = row[min(round(nx / 0.72), len(row) - 1)]
            if key != ".":
                canvas.put(24 + nx, 23 + y + nx * sign, key)
                # Fill the stair-step gaps so the barrel reads as solid.
                canvas.put(24 + nx, 23 + y + nx * sign - sign, key) if y == 0 and sign > 0 else None


def muzzle_flash():
    c = Canvas(8, 8)
    c.stamp("..f.....\n.fFf.f..\nfFFFFFf.\n.fFFFf..\n..fFf...\n...f....", 0, 1)
    return c.to_image(PALETTE)


def parachute():
    c = Canvas(48, 32)
    c.stamp("""
..........CCCCCCCCCCCCCCCCCCCC..........
......CCCCCCCCCCCCCCCCCCCCCCCCCCCC......
...CCCCCCCcCCCCCCCcCCCCCCcCCCCCCCcCCC...
.CCCCCCCCcCCCCCCCcCCCCCCCCcCCCCCCCcCCCC.
CCCCCCCCcCCCCCCCCcCCCCCCCCcCCCCCCCCcCCCC
ccccccccccccccccccccccccccccccccccccccccc
""", 4, 1)
    c.outline()
    for start, end in [((5, 7), (21, 30)), ((15, 7), (22, 30)), ((33, 7), (26, 30)), ((43, 7), (27, 30))]:
        (x0, y0), (x1, y1) = start, end
        steps = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(steps + 1):
            canvas_x = round(x0 + (x1 - x0) * i / steps)
            canvas_y = round(y0 + (y1 - y0) * i / steps)
            c.put(canvas_x, canvas_y, "x")
    return c.to_image(PALETTE)


# Body sheet layout. The game script indexes frames by these names.
BODY_FRAMES = (["idle0", "idle1"] + ["run%d" % i for i in range(6)]
               + ["jump", "fall", "crouch0", "crouch1", "hang", "dead0", "dead1", "dead2"])


def body_sheet():
    frames = [body(STAND, 0, 0), body(STAND, 1, 1)]
    frames += [body(p, i % 3) for i, p in enumerate(RUN)]
    frames += [body(JUMP, 2), body(FALL, 1), body(CROUCH[0], 0), body(CROUCH[1], 1), body(HANG, 0)]
    frames += dead_frames()
    assert len(frames) == len(BODY_FRAMES)
    return sheet(frames)


def arms_sheet():
    """One row per weapon (in WEAPON_ARMS order), one column per angle in ARM_ANGLES."""
    frames = []
    for name in WEAPON_ARMS:
        frames += arm_frames(name)
    return sheet(frames, len(ARM_ANGLES))
