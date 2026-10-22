"""The game's pixel font: 5x7 capitals with a baked-in 1px black outline, written as a BMFont
(.fnt text file plus a .png atlas) that Godot imports as a bitmap font. Text is white in the
atlas, so a font color tints the letters and leaves the outline black.
Lowercase letters reuse the capitals, except "x", which is a small multiplication-style x.
"""
from PIL import Image

from pixel import Canvas

HEIGHT = 7
GLYPHS = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
    "J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
    "x": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
    "!": ["#", "#", "#", "#", "#", ".", "#"],
    "?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
    ".": [".", ".", ".", ".", ".", ".", "#"],
    ",": ["..", "..", "..", "..", "..", ".#", "#."],
    ":": [".", ".", "#", ".", ".", "#", "."],
    ";": ["..", "..", ".#", "..", "..", ".#", "#."],
    "'": ["#", "#", ".", ".", ".", ".", "."],
    '"': ["#.#", "#.#", "...", "...", "...", "...", "..."],
    "-": ["....", "....", "....", "####", "....", "....", "...."],
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
    "/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
    "%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
    "#": [".#.#.", ".#.#.", "#####", ".#.#.", "#####", ".#.#.", ".#.#."],
    "(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
    ")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
    "<": ["...#", "..#.", ".#..", "#...", ".#..", "..#.", "...#"],
    ">": ["#...", ".#..", "..#.", "...#", "..#.", ".#..", "#..."],
    "=": ["....", "....", "####", "....", "####", "....", "...."],
    "\\": ["#....", ".#...", ".#...", "..#..", "...#.", "...#.", "....#"],
    "_": ["....", "....", "....", "....", "....", "....", "####"],
}
SPACE_ADVANCE = 4
COLUMNS = 16


def _chars():
    chars = dict(GLYPHS)
    for c in "abcdefghijklmnopqrstuvwyz":
        chars[c] = GLYPHS[c.upper()]
    return chars


def _glyph_canvas(rows):
    canvas = Canvas(len(rows[0]) + 2, HEIGHT + 2)
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key == "#":
                canvas.put(x + 1, y + 1, "W")
    canvas.outline("K", diagonal=True)
    return canvas


def build(fnt_path, png_name):
    """Returns the atlas image and writes the .fnt description next to where the atlas goes."""
    chars = _chars()
    cell_w = 7 + 2
    cell_h = HEIGHT + 2
    rows = (len(chars) + COLUMNS - 1) // COLUMNS
    atlas = Image.new("RGBA", (COLUMNS * cell_w, rows * cell_h), (0, 0, 0, 0))
    palette = {"W": "ffffff", "K": "000000"}
    lines = []
    for i, (char, glyph) in enumerate(sorted(chars.items())):
        canvas = _glyph_canvas(glyph)
        x, y = (i % COLUMNS) * cell_w, (i // COLUMNS) * cell_h
        atlas.paste(canvas.to_image(palette), (x, y))
        lines.append(
            f"char id={ord(char)} x={x} y={y} width={canvas.width} height={canvas.height} "
            f"xoffset=-1 yoffset=0 xadvance={canvas.width - 1} page=0 chnl=15")
    lines.append(f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={SPACE_ADVANCE} page=0 chnl=15")
    header = [
        'info face="Vanguard" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0',
        f"common lineHeight=10 base=8 scaleW={atlas.width} scaleH={atlas.height} pages=1 packed=0",
        f'page id=0 file="{png_name}"',
        f"chars count={len(lines)}",
    ]
    with open(fnt_path, "w") as f:
        f.write("\n".join(header + lines) + "\n")
    return atlas


def logo(text, scale, top, bottom, edge="1a1410", shadow="3a0f0a"):
    """Big title lettering: the font's capitals blown up `scale` times, shaded from `top` to
    `bottom` with a lighter rim on the upper edge, a dark outline and a hard drop shadow."""
    chars = _chars()
    width = sum(SPACE_ADVANCE if c == " " else len(chars[c][0]) + 1 for c in text) - 1
    canvas = Canvas(width * scale + 5, HEIGHT * scale + 6)
    x = 0
    for c in text:
        if c == " ":
            x += SPACE_ADVANCE
            continue
        for gy, row in enumerate(chars[c]):
            for gx, key in enumerate(row):
                if key == "#":
                    canvas.rect(2 + (x + gx) * scale, 1 + gy * scale, scale + 1, scale + 1, "F")
        x += len(chars[c][0]) + 1
    height = HEIGHT * scale
    for y in range(canvas.height):
        for xx in range(canvas.width):
            if canvas.pixels[y][xx] == "F":
                if canvas.get(xx, y - 1) is None:
                    canvas.pixels[y][xx] = "R"
                else:
                    canvas.pixels[y][xx] = str(min(3, (y - 1) * 4 // height))
    canvas.outline("K", diagonal=True)
    shadowed = Canvas(canvas.width, canvas.height)
    for y in range(canvas.height):
        for xx in range(canvas.width):
            if canvas.pixels[y][xx] is not None:
                shadowed.put(xx + 1, y + 2, "S")
    for y in range(canvas.height):
        for xx in range(canvas.width):
            if canvas.pixels[y][xx] is not None:
                shadowed.pixels[y][xx] = canvas.pixels[y][xx]

    def mix(a, b, t):
        a, b = int(a, 16), int(b, 16)
        return "%02x%02x%02x" % tuple(round(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t) for s in (16, 8, 0))

    palette = {str(i): mix(top, bottom, i / 3) for i in range(4)}
    palette.update({"R": "fff6d0", "K": edge, "S": shadow})
    return shadowed.to_image(palette)
