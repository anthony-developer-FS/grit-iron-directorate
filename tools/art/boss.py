"""The Seewall battery: Mission 1's boss, a cliff-top gun fortress. Faces left (toward Grit)."""
import random
from PIL import Image
from pixel import Canvas, sheet

PALETTE = {
    "K": "#121417",
    "W": "#4a4e52", "w": "#3a3e42", "X": "#5e6368", "x": "#2e3134",  # wall armor
    "r": "#6a6e72",  # rivets
    "T": "#3e4246", "t": "#2e3236",  # tower
    "L": "#ffd27a", "l": "#6a5a3a",  # window lit / dim
    "R": "#b32424", "v": "#7a1818",  # Directorate red
    "k": "#1a1c1e",  # emblem black, hatch
    "G": "#3a3e44", "g": "#55595f", "B": "#2b2b2b",  # gun steel
    "C": "#2b3a3a", "c": "#1f2a2a", "E": "#4ce0b8",  # core housing, glow
    "s": "#2a2522",  # wreckage
}


def wall(lit):
    rng = random.Random(21)
    c = Canvas(104, 196)
    base = 196 - 1  # row of ground contact
    # Main armored wall, 100x120, with plating seams and rivets.
    c.rect(0, base - 119, 100, 120, "W")
    for y in range(base - 119, base + 1, 24):
        c.rect(0, y, 100, 1, "w")
    for x in range(0, 100, 32):
        c.rect(x, base - 119, 1, 120, "w")
    for y in range(base - 112, base, 16):
        for x in range(6, 100, 16):
            c.put(x, y, "r")
            c.put(x + 1, y + 1, "x")
    for _ in range(60):
        c.put(rng.randrange(100), rng.randrange(base - 119, base), "X")
    # Battlement lip.
    c.rect(0, base - 123, 100, 4, "x")
    for x in range(0, 100, 12):
        c.rect(x, base - 127, 7, 4, "x")
    # Directorate emblem: a black gear on a red disc.
    cx, cy = 60, base - 70
    for y in range(-9, 10):
        for x in range(-9, 10):
            d = (x * x + y * y) ** 0.5
            if d <= 9:
                c.put(cx + x, cy + y, "R" if d > 6.5 else "k")
            if d <= 3:
                c.put(cx + x, cy + y, "R")
    for dx, dy in [(0, -8), (0, 8), (-8, 0), (8, 0), (-6, -6), (6, 6), (-6, 6), (6, -6)]:
        c.put(cx + dx, cy + dy, "k")
    # Hatch the riflemen come out of.
    c.rect(4, base - 29, 14, 30, "k")
    c.rect(4, base - 29, 14, 1, "x")
    c.rect(16, base - 15, 1, 3, "r")
    # Command tower with the observation window and the flag.
    c.rect(50, base - 169, 36, 46, "T")
    c.rect(50, base - 169, 36, 2, "x")
    c.rect(84, base - 169, 2, 46, "t")
    c.rect(56, base - 161, 24, 8, "L" if lit else "l")
    for x in (63, 70):
        c.rect(x, base - 161, 1, 8, "t")
    c.rect(46, base - 173, 44, 4, "x")
    c.rect(64, base - 189, 2, 16, "x")
    c.stamp("RRRRRRRR\nRRRRRRRRRRRRR\nRRRRRRRRvv\nRRRRv", 66, base - 189)
    c.outline()
    return c


def cannon():
    c = Canvas(56, 18)
    c.stamp("""
.....GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBBBBgggggggggggggggggggggggggggggggggggggggggggggg
BBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBBBBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
.....GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
""", 1, 4)
    c.rect(1, 2, 5, 14, "B")
    c.outline()
    return c


def turret(state):
    """20x18 armored turret box with a flak barrel poking 12 px left. 34x22 frame, origin
    (bottom-left of the box) at (13, 20)."""
    c = Canvas(34, 22)
    if state == "wreck":
        c.rect(14, 12, 18, 8, "s")
        c.rect(16, 9, 10, 3, "s")
        c.outline()
        return c
    c.rect(13, 3, 20, 18, "G")
    c.rect(13, 3, 20, 2, "g")
    c.rect(31, 3, 2, 18, "B")
    c.rect(17, 8, 12, 3, "B")
    # Barrel and its muzzle light (red when the turret can be damaged).
    c.rect(1, 9, 12, 4, "B")
    c.rect(1, 9, 12, 1, "g")
    c.rect(0, 8, 4, 6, "B")
    if state == "open":
        c.rect(0, 9, 3, 4, "R")
    c.outline()
    return c


def breech(state):
    """24x26 cannon breech block. 26x28 frame, origin (bottom-left) at (1, 27)."""
    c = Canvas(26, 28)
    if state == "wreck":
        c.rect(3, 14, 20, 12, "s")
        c.outline()
        return c
    c.rect(1, 1, 24, 26, "G")
    c.rect(1, 1, 24, 2, "g")
    c.rect(5, 5, 16, 18, "B")
    for y in range(7, 22, 4):
        c.rect(6, y, 14, 1, "g")
    c.outline()
    return c


def core(state):
    """24x24 generator housing. 26x26 frame, origin (bottom-left) at (1, 25)."""
    c = Canvas(26, 26)
    if state == "wreck":
        c.rect(3, 12, 20, 12, "s")
        c.outline()
        return c
    c.rect(1, 1, 24, 24, "C")
    c.rect(1, 1, 24, 2, "c")
    c.rect(1, 23, 24, 2, "c")
    for x in (3, 21):
        c.rect(x, 4, 2, 18, "c")
    if state == "open":
        c.rect(7, 7, 12, 12, "c")
    else:
        # Shutters closed over the core.
        for y in range(6, 20, 3):
            c.rect(6, y, 14, 2, "G")
    c.outline()
    return c


def build():
    white = {k: "#ffffff" for k in PALETTE}
    parts = {}
    for name, draw in (("turret", turret), ("breech", breech), ("core", core)):
        frames = [draw("closed").to_image(PALETTE), draw("open").to_image(PALETTE),
                  draw("open").to_image(white), draw("wreck").to_image(PALETTE)]
        parts["boss_%s.png" % name] = sheet(frames)
    parts["boss_wall.png"] = sheet([wall(False).to_image(PALETTE), wall(True).to_image(PALETTE)])
    # Drawn breech-right so the muzzle points left, at Grit.
    parts["boss_cannon.png"] = cannon().to_image(PALETTE).transpose(Image.FLIP_LEFT_RIGHT)
    return parts
