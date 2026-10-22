"""Mission 1 surfaces, props and backdrop layers.

Surfaces are 16x16 tiles in pairs (top edge, fill) used by the Block script; props are single
sprites with the ground contact on their bottom row; the sky and far layer are full screens.
"""
import random
from PIL import Image, ImageDraw
from pixel import Canvas, hex_rgba

PALETTE = {
    "K": "#1a1612",
    # Sand.
    "A": "#7d6848", "a": "#6a5739", "Z": "#9a825a", "z": "#54432c", "p": "#55504a", "P": "#706a60",
    # Dirt and mud.
    "M": "#5b4a37", "m": "#4a3c2c", "n": "#6c5a43", "g": "#3e4a2c", "G": "#55643a",
    # Sandbags.
    "S": "#8a7f58", "s": "#6b6142", "L": "#a59a6e", "r": "#4f4630",
    # Wood.
    "W": "#7a5634", "w": "#5a3e24", "X": "#94704a",
    # Rock.
    "R": "#45494f", "q": "#363a3f", "Q": "#5a5f66", "y": "#2a2d31",
    # Steel.
    "T": "#4f555c", "t": "#3c4147", "U": "#6c737b", "u": "#8a9199",
    # Concrete.
    "C": "#5f656c", "c": "#474c52", "D": "#7d848b", "d": "#2a2e33",
    # Props.
    "H": "#4a4f55", "h": "#2f3338", "N": "#7a8189", "o": "#7a3a22",  # steel, rust
    "B": "#6a5030", "b": "#3b2a1a", "Y": "#d8b040",  # crate wood, brass
    "E": "#c9c1a6", "e": "#a39a7c", "V": "#b32424", "v": "#7a1818", "k": "#1c1c1c",  # paper, red
    "F": "#ffd27a", "f": "#3e4246",  # lamp
    "O": "#4ce0b8", "j": "#2a8a70",  # ore glow
}


def _noise(c, rng, keys, count, y0=0):
    for _ in range(count):
        c.put(rng.randrange(16), rng.randrange(y0, 16), rng.choice(keys))


def _tile(fill, specks, count, seed, top=None):
    rng = random.Random(seed)
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, fill)
    _noise(c, rng, specks, count)
    if top:
        top(c, rng)
    return c


def sand():
    def edge(c, rng):
        for x in range(16):
            h = 1 + (rng.random() < 0.3)
            c.rect(x, 0, 1, h, "Z")
        c.put(rng.randrange(2, 13), 3, "p")
    return [_tile("A", "aaz", 18, 1, edge), _tile("A", "aazpP", 22, 2)]


def dirt():
    def edge(c, rng):
        for x in range(16):
            c.rect(x, 0, 1, 1 + (rng.random() < 0.4), "G")
            if rng.random() < 0.3:
                c.put(x, 2, "g")
    return [_tile("M", "mmn", 20, 3, edge), _tile("M", "mmnz", 24, 4)]


def sandbags():
    c = Canvas(16, 16)
    for row, y in enumerate(range(0, 16, 5)):
        offset = 0 if row % 2 == 0 else -4
        for x in range(offset, 16, 8):
            c.stamp("LSSSSSSs\nSSSSSSSs\nsSSSSSSr\n.rrrrrr.", x, y)
            c.rect(x, y + 4, 8, 1, "r")
    return [c, c]


def wood():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 5, "W")
    c.rect(0, 0, 16, 1, "X")
    c.rect(0, 4, 16, 1, "w")
    c.put(7, 2, "w")
    c.put(15, 1, "w")
    c.put(15, 2, "w")
    c.put(15, 3, "w")
    return [c, c]


def rock():
    def edge(c, rng):
        c.rect(0, 0, 16, 2, "Q")
        for x in range(16):
            if rng.random() < 0.4:
                c.put(x, 2, "Q")
    def cracks(c, rng):
        for _ in range(2):
            x, y = rng.randrange(16), rng.randrange(3, 14)
            for i in range(4):
                c.put(x + i // 2, y + i, "y")
    top = _tile("R", "qqQ", 22, 5, edge)
    fill = _tile("R", "qqQ", 22, 6, cracks)
    return [top, fill]


def metal():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "T")
    c.rect(0, 0, 16, 1, "U")
    c.rect(0, 15, 16, 1, "t")
    c.rect(15, 0, 1, 16, "t")
    for x, y in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        c.put(x, y, "u")
        c.put(x + 1, y + 1, "t")
    return [c, c]


def concrete():
    def stains(c, rng):
        c.rect(0, 15, 16, 1, "c")
        c.rect(15, 0, 1, 16, "c")
    top = _tile("C", "c", 10, 7, lambda c, r: (stains(c, r), c.rect(0, 0, 16, 2, "D")))
    fill = _tile("C", "c", 10, 8, stains)
    return [top, fill]


# Row order of the surfaces sheet; Block.surface indexes it.
SURFACES = [("sand", sand), ("dirt", dirt), ("sandbags", sandbags), ("wood", wood), ("rock", rock),
            ("metal", metal), ("concrete", concrete)]


def surface_images():
    images = {}
    for name, build in SURFACES:
        top, fill = build()
        images["surface_%s_top.png" % name] = top.to_image(PALETTE)
        images["surface_%s_fill.png" % name] = fill.to_image(PALETTE)
    return images


PROPS = {
    "hedgehog": """
H.............H.
NH...........HN.
.HH.........HH..
..HH.......HH...
...HHo...oHH....
....HHH.HHH.....
.....HHNHH......
......HHH.......
.....HHHHH......
....HHo.oHH.....
...HH.....HH....
..HH.......Ho...
.hH.........Hh..
hhh.........hhh.
""",
    "wire": """
.b....N.N.....N.N.....N.N....b.
.bN.N..N..N.N..N..N.N..N..N.Nb.
.b.N.N...N.N.N...N.N.N...N.N.b.
.bN...N.N.....N.N.....N.N...Nb.
.b.....N.......N.......N.....b.
.b...........................b.
.b...........................b.
""",
    "crate": """
bbbbbbbbbbbbbbbb
bBBBBBBBBBBBBBbb
bBbBBBBBBBBBbBBb
bBBbBBBBBBBbBBBb
bBBBbBBYBBbBBBBb
bBBBBbBBBbBBBBBb
bBBBBBbBbBBBBBBb
bBBBBBBbBBBBBBBb
bBBBBBbBbBBBBBBb
bBBBBbBBBbBBBBBb
bBBBbBBBBBbBBBBb
bBBbBBBBBBBbBBBb
bBbBBBBBBBBBbBBb
bbbbbbbbbbbbbbbb
""",
    "sign": """
EEEEEEEEEEEEEEEEEEEE
EeeeeeeeeeeeeeeeeeeE
EeVVV.kkkk.VVV.kkkeE
EeV...k..k.V.V.k..eE
EeVVV.kkkk.VVV.kkkeE
EeeeeeeeeeeeeeeeeeeE
EEEEEEEEEEEEEEEEEEEE
.........bb.........
.........bb.........
.........bb.........
.........bb.........
.........bb.........
.........bb.........
.........bb.........
.........bb.........
.........bb.........
.........bb.........
""",
    "crater": """
.....mmmmmmmmmmmmmmmmmmmm.....
..mmmzzzzzzzzzzzzzzzzzzzzmmm..
mmzzzzzzzzzzzzzzzzzzzzzzzzzzmm
.mmzzzzzzzzzzzzzzzzzzzzzzzzmm.
""",
    "ore_crate": """
....jOOOOOOOOj....
.....jOOOOOOj.....
HHHHHHHHHHHHHHHHHH
HNNNNNNNNNNNNNNNNH
HHEEEHEHEHHEEHEEHH
HHEHHHEHEHHEHHEHHH
HHEEEHEEEHHEEHEEHH
HHHHHHHHHHHHHHHHHH
HhhhhhhhhhhhhhhhhH
HHHHHHHHHHHHHHHHHH
hhhhhhhhhhhhhhhhhh
""",
    "poster": """
VVVVVVVVVVVVVVVV
VvvvvvvvvvvvvvvV
VvVVVVkkkVVVVVvV
VvVVVkkkkkVVVVvV
VvVVVkkkkkVVVVvV
VvVVVVkkkVVVVVvV
VvVVVkkkkkVVVVvV
VvVVkkkkkkkVVVvV
VvVkkkkkkkkkVVvV
VvVVVVVVVVVVVVvV
VvVEEEEEEEEEEVvV
VvVEkkEkEkEkEVvV
VvVEEEEEEEEEEVvV
VvVVVVVVVVVVVVvV
VvvvvvvvvvvvvvvV
VVVVVVVVVVVVVVVV
""",
    "lamp": """
.ffff.
ffFFff
..FF..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
...f..
..fff.
.fffff
""",
}


def prop_images():
    images = {}
    for name, grid in PROPS.items():
        rows = grid.strip("\n").split("\n")
        c = Canvas(max(len(r) for r in rows) + 2, len(rows) + 2)
        c.stamp(grid, 1, 1)
        if name not in ("crater", "wire"):
            c.outline()
        images["prop_%s.png" % name] = c.to_image(PALETTE)
    return images


def sky(width=320, height=180, seed=7):
    """The fixed storm sky behind everything: banded gradient, moon glow, cloud bands."""
    rng = random.Random(seed)
    img = Image.new("RGBA", (width, height))
    d = ImageDraw.Draw(img)
    top, bottom = hex_rgba("#121a26"), hex_rgba("#2a3644")
    for y in range(height):
        t = round(min(y / 130, 1.0) * 6) / 6
        d.line([(0, y), (width, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    for r, col in [(26, "#25313f"), (18, "#2f3c4b"), (11, "#4a5868"), (6, "#8a96a2")]:
        d.ellipse([228 - r, 30 - r, 228 + r, 30 + r], fill=hex_rgba(col))
    for band, col in [(22, "#1a2330"), (44, "#222c3a"), (64, "#1d2633")]:
        x = -20
        while x < width:
            w = rng.randrange(30, 70)
            h = rng.randrange(5, 10)
            d.ellipse([x, band - h, x + w, band + h], fill=hex_rgba(col))
            x += w - 12
    return img


def far_layer(width=320, height=200, horizon=124, seed=9):
    """Cliffs, sea and the Allied fleet. Tiles horizontally; transparent above the cliffs."""
    rng = random.Random(seed)
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cliff = [(0, 104), (30, 98), (60, 102), (95, 90), (130, 96), (170, 86), (210, 94),
             (250, 84), (290, 98), (320, 104), (320, horizon), (0, horizon)]
    d.polygon(cliff, fill=hex_rgba("#151d26"))
    d.line(cliff[:10], fill=hex_rgba("#2a3644"))
    for y in range(horizon, height):
        d.line([(0, y), (width, y)], fill=hex_rgba("#1c2a35" if y < horizon + 16 else "#172430"))
    for _ in range(40):
        x, y = rng.randrange(width), rng.randrange(horizon + 2, height)
        d.line([(x, y), (x + rng.randrange(3, 9), y)], fill=hex_rgba("#3a4e5c"))
    for sx in (40, 200):
        d.polygon([(sx, horizon - 1), (sx + 44, horizon - 1), (sx + 40, horizon + 3), (sx + 4, horizon + 3)], fill=hex_rgba("#0c1117"))
        d.rectangle([sx + 14, horizon - 7, sx + 24, horizon - 1], fill=hex_rgba("#0c1117"))
        d.rectangle([sx + 18, horizon - 12, sx + 20, horizon - 7], fill=hex_rgba("#0c1117"))
    return img


def interior_tile():
    """Dark concrete back wall for bunkers and the elevator shaft (32x24 panels)."""
    rng = random.Random(11)
    c = Canvas(32, 24)
    c.rect(0, 0, 32, 24, "d")
    for _ in range(20):
        c.put(rng.randrange(32), rng.randrange(24), "k")
    c.rect(0, 0, 32, 1, "c")
    c.rect(0, 0, 1, 24, "k")
    for x, y in [(3, 3), (28, 3), (3, 20), (28, 20)]:
        c.put(x, y, "c")
    return c.to_image(PALETTE)


def build():
    out = {"sky.png": sky(), "far_layer.png": far_layer(),
           "interior_wall.png": interior_tile()}
    out.update(surface_images())
    out.update(prop_images())
    return out
