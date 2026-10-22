"""Mission 1 beach set: sand tiles, props and the stormy night backdrop."""
import random
from PIL import Image, ImageDraw
from pixel import Canvas, hex_rgba

PALETTE = {
    "K": "#1a1612",
    "A": "#7d6848", "a": "#6a5739", "Z": "#9a825a", "z": "#54432c",  # sand, shadow, lit edge, deep
    "p": "#55504a", "P": "#706a60",  # pebbles
    "w": "#5f4e34",  # wet sand
    "C": "#5f656c", "c": "#474c52", "D": "#7d848b", "d": "#2a2e33", "y": "#4f4a3a",  # concrete
    "S": "#8a7f58", "s": "#6b6142", "L": "#a59a6e", "r": "#4f4630",  # sandbags
    "H": "#4a4f55", "h": "#2f3338", "N": "#7a8189", "R": "#7a3a22",  # steel hedgehog, rust
    "X": "#55595f",  # wire
}


def sand_tile(top, seed):
    rng = random.Random(seed)
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "A")
    for _ in range(18):
        c.put(rng.randrange(16), rng.randrange(16), rng.choice("aaz"))
    for _ in range(3):
        x, y = rng.randrange(15), rng.randrange(3, 15)
        c.put(x, y, "p")
        c.put(x + 1, y, "P")
    if top:
        for x in range(16):
            h = 1 + (rng.random() < 0.3)
            for y in range(h):
                c.put(x, y, "Z")
            c.put(x, h, "A")
        for _ in range(2):
            x = rng.randrange(1, 14)
            c.put(x, 2, "w")
            c.put(x + 1, 2, "w")
    return c.to_image(PALETTE)


def concrete_tile(top, seed):
    rng = random.Random(seed)
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "C")
    c.rect(0, 15, 16, 1, "c")
    c.rect(15, 0, 1, 16, "c")
    for _ in range(10):
        c.put(rng.randrange(16), rng.randrange(16), "c")
    for _ in range(2):
        x = rng.randrange(1, 15)
        for y in range(rng.randrange(4, 12)):
            c.put(x, 2 + y, "y")
    if top:
        c.rect(0, 0, 16, 2, "D")
        c.rect(0, 2, 16, 1, "c")
    return c.to_image(PALETTE)


def bunker_slit():
    """Concrete tile with a firing slit, for pillboxes."""
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, "C")
    c.rect(0, 15, 16, 1, "c")
    c.rect(15, 0, 1, 16, "c")
    c.rect(2, 6, 12, 3, "d")
    c.rect(2, 9, 12, 1, "D")
    return c.to_image(PALETTE)


SANDBAGS = """
.........LLSSSSSL.LLSSSSSL.........
........LSSSSSSSSsLSSSSSSSSs.......
........SSSsSSSSSsSSSsSSSSSs.......
........sSSSSSSSsrsSSSSSSSsr.......
...LLSSSSSL.LLSSSSSL.LLSSSSSL......
..LSSSSSSSSsLSSSSSSSSsLSSSSSSSSs...
..SSSSsSSSSsSSSSsSSSSsSSSSsSSSSs...
..sSSSSSSSsrsSSSSSSSsrsSSSSSSSsr...
LLSSSSSL.LLSSSSSL.LLSSSSSL.LLSSSSSL
LSSSSSSSsLSSSSSSSsLSSSSSSSsLSSSSSSS
SSSsSSSSsSSSsSSSSsSSSsSSSSsSSSsSSSS
SSSSSSSSsSSSSSSSSsSSSSSSSSsSSSSSSSs
sSSSSSSsrsSSSSSSsrsSSSSSSsrsSSSSSsr
.rsssssr..rsssssr..rsssssr..rsssss.
"""

HEDGEHOG = """
H.............H.
NH...........HN.
.HH.........HH..
..HH.......HH...
...HHR...RHH....
....HHH.HHH.....
.....HHNHH......
......HHH.......
.....HHHHH......
....HHR.RHH.....
...HH.....HH....
..HH.......HR...
.hH.........Hh..
hhh.........hhh.
"""


def prop(grid):
    rows = grid.strip("\n").split("\n")
    c = Canvas(max(len(r) for r in rows) + 2, len(rows) + 2)
    c.stamp(grid, 1, 1)
    c.outline()
    return c.to_image(PALETTE)


def backdrop(width=320, height=180, seed=7):
    """Stormy night over the Kesselstadt coast: sky, cloud bands, cliffs, sea, distant ships."""
    rng = random.Random(seed)
    img = Image.new("RGBA", (width, height))
    d = ImageDraw.Draw(img)
    top, bottom = hex_rgba("#121a26"), hex_rgba("#2a3644")
    horizon = 118
    for y in range(horizon):
        t = y / horizon
        # Banded gradient keeps the pixel-art look instead of a smooth blend.
        t = round(t * 6) / 6
        d.line([(0, y), (width, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    # Moon glow behind the clouds.
    for r, col in [(26, "#25313f"), (18, "#2f3c4b"), (11, "#4a5868"), (6, "#8a96a2")]:
        d.ellipse([228 - r, 30 - r, 228 + r, 30 + r], fill=hex_rgba(col))
    # Cloud bands.
    for band, col in [(22, "#1a2330"), (44, "#222c3a"), (64, "#1d2633")]:
        x = -20
        while x < width:
            w = rng.randrange(30, 70)
            h = rng.randrange(5, 10)
            d.ellipse([x, band - h, x + w, band + h], fill=hex_rgba(col))
            x += w - 12
    # Far cliffs with the Seewall battery's silhouette on the right.
    cliff = [(0, 100), (30, 94), (60, 98), (95, 88), (130, 92), (170, 84), (210, 90),
             (250, 80), (275, 78), (275, 70), (300, 70), (300, 78), (320, 76), (320, 118), (0, 118)]
    d.polygon(cliff, fill=hex_rgba("#151d26"))
    d.line(cliff[:14], fill=hex_rgba("#34414e"))
    d.rectangle([284, 64, 290, 70], fill=hex_rgba("#151d26"))
    d.point((287, 66), fill=hex_rgba("#ff4632"))
    # Sea.
    for y in range(horizon, height):
        t = (y - horizon) / (height - horizon)
        d.line([(0, y), (width, y)], fill=hex_rgba("#1c2a35" if t < 0.4 else "#172430"))
    for _ in range(40):
        x, y = rng.randrange(width), rng.randrange(horizon + 2, height)
        d.line([(x, y), (x + rng.randrange(3, 9), y)], fill=hex_rgba("#3a4e5c"))
    # Distant Directorate warships.
    for sx in (40, 150):
        d.polygon([(sx, 117), (sx + 44, 117), (sx + 40, 121), (sx + 4, 121)], fill=hex_rgba("#0c1117"))
        d.rectangle([sx + 14, 111, sx + 24, 117], fill=hex_rgba("#0c1117"))
        d.rectangle([sx + 18, 106, sx + 20, 111], fill=hex_rgba("#0c1117"))
    return img
