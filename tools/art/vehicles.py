"""Directorate hardware: the MG nest pillbox and the half-track mini-boss. Both face right."""
import random
from pixel import Canvas, sheet
from trooper import BASE, HEAD

PALETTE = dict(BASE)
PALETTE.update({
    "C": "#7a7f84", "c": "#5a5f64", "D": "#9a9fa4", "d": "#1a1c1e",  # concrete
    "A": "#8a7f58", "a": "#6b6142", "L": "#a59a6e",  # sandbags
    "V": "#5d6166", "v": "#44484d", "J": "#787d83", "j": "#33363a",  # vehicle armor
    "R": "#b32424",  # red stripe
    "o": "#2a2c2e", "O": "#4a4e54", "w": "#6a7078",  # tracks, wheels
    "s": "#2b2b2b",  # burnt
})


def mg_nest(firing=False, destroyed=False):
    rng = random.Random(4)
    c = Canvas(40, 32)
    if destroyed:
        c.stamp("""
........c...........c.......
.....cCCc....d...cCCCc......
...cCCCCCcd.ddd.cCCCCCCc....
.ccCCCCCCCCcdddcCCCCCCCCCc..
cCCCCCCCCCCCCCCCCCCCCCCCCCCc
""", 6, 26)
        c.outline()
        return c
    # Pillbox: rounded concrete block with a firing slit, sandbags along the base.
    c.rect(8, 6, 24, 22, "C")
    c.rect(9, 5, 22, 1, "D")
    c.rect(8, 6, 24, 2, "D")
    c.rect(30, 8, 2, 20, "c")
    for _ in range(14):
        c.put(rng.randrange(9, 30), rng.randrange(9, 27), "c")
    c.rect(12, 13, 18, 4, "d")
    c.rect(12, 17, 18, 1, "D")
    # Gun barrel through the slit, with the gunner's goggles glowing behind it.
    c.rect(22, 14, 12, 2, "Z")
    c.rect(26, 13, 2, 1, "z")
    c.put(15, 14, "E")
    c.put(16, 14, "E")
    for x in range(6, 34, 7):
        c.stamp("LAAAAAL\nAAAAAAa\naaaaaaa", x, 25)
    c.outline()
    if firing:
        c.stamp(".fF\nfFFf\n.fF", 35, 13)
    return c


def half_track(frame=0, burnt=False):
    c = Canvas(72, 44)
    # Rear tracks: a long loop with road wheels that turn by shifting the tread pattern.
    c.rect(4, 34, 34, 9, "o")
    for x in range(4, 38):
        if (x + frame * 2) % 4 == 0:
            c.put(x, 34, "O")
            c.put(x, 42, "O")
    for x in (9, 17, 25, 33):
        c.stamp(".OO.\nOwwO\nOwwO\n.OO.", x - 2, 36)
    # Front wheel.
    c.stamp("..oooo..\n.oOOOOo.\nooOwwOoo\nooOwwOoo\n.oOOOOo.\n..oooo..", 52, 36)
    # Armored hull, sloped nose, red stripe.
    c.stamp("""
.......VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV..........
......VJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJVV........
.....VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV......
.....VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV....
.....VVRRRRRRRRRRRRRRRRRRRRRRVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV..
.....VVVVVVVVVVVVVVVVVVVVVVVVVVVjjjVVVVVVVVVVVVVVVVVVVVVVVVV.
.....vvvvvvvvvvvvvvvvvvvvvvvvvvvjjjvvvvvvvvvvvvvvvvvvvvvvvvvv
.....vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
""", 2, 27)
    # Cab with a vision slit.
    c.stamp("""
...VVVVVVVVVVVV
..VJJJJJJJJJJJV
.VVVVVVVVVVVVVV
VVVVVddddddVVVV
VVVVVVVVVVVVVVV
""", 42, 22)
    # Gunner and the mounted MG on a ring.
    c.stamp(HEAD, 16, 12)
    c.rect(14, 21, 16, 6, "v")
    c.rect(14, 20, 16, 1, "J")
    c.rect(26, 16, 18, 2, "Z")
    c.rect(26, 18, 6, 2, "z")
    c.outline()
    if burnt:
        for y in range(c.height):
            for x in range(c.width):
                key = c.get(x, y)
                if key and key not in ("K",):
                    c.pixels[y][x] = {"V": "s", "J": "v", "R": "s", "E": "o"}.get(key, key if key in "oOwvjZz" else "s")
    return c


def build():
    pal = PALETTE
    white = {k: "#ffffff" for k in pal}
    nest = [mg_nest(), mg_nest(firing=True), mg_nest(destroyed=True)]
    nest_white = [mg_nest()]
    track = [half_track(0), half_track(1), half_track(0, burnt=True)]
    track_white = [half_track(0)]
    return {
        "mg_nest.png": sheet([n.to_image(pal) for n in nest] + [n.to_image(white) for n in nest_white]),
        "half_track.png": sheet([t.to_image(pal) for t in track] + [t.to_image(white) for t in track_white]),
    }
