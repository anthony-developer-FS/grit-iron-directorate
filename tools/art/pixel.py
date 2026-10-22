"""Tiny pixel-art toolkit: sprites are drawn as text grids (one character per pixel) and
composed into frames, then outlined and saved as PNG sprite sheets. Everything in the game's
art is generated from the scripts in this folder, so changing a palette or a pose is a code edit.
"""
from PIL import Image

TRANSPARENT = (0, 0, 0, 0)


def hex_rgba(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Canvas:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.pixels = [[None] * width for _ in range(height)]

    def put(self, x, y, key):
        if 0 <= x < self.width and 0 <= y < self.height and key not in (".", " "):
            self.pixels[y][x] = key

    def get(self, x, y):
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.pixels[y][x]
        return None

    def stamp(self, grid, x, y, flip=False):
        """Draws a text grid with its top-left corner at (x, y)."""
        rows = grid.strip("\n").split("\n") if isinstance(grid, str) else grid
        width = max(len(r) for r in rows)
        for dy, row in enumerate(rows):
            for dx, key in enumerate(row):
                px = x + (width - 1 - dx if flip else dx)
                self.put(px, y + dy, key)

    def rect(self, x, y, w, h, key):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, key)

    def outline(self, key="K", diagonal=False):
        """Adds a 1px outline around every filled pixel, arcade style."""
        around = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            around += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
        edge = []
        for y in range(self.height):
            for x in range(self.width):
                if self.pixels[y][x] is None and any(
                        self.get(x + dx, y + dy) not in (None, key) for dx, dy in around):
                    edge.append((x, y))
        for x, y in edge:
            self.pixels[y][x] = key

    def to_image(self, palette):
        image = Image.new("RGBA", (self.width, self.height), TRANSPARENT)
        for y in range(self.height):
            for x in range(self.width):
                key = self.pixels[y][x]
                if key is not None:
                    image.putpixel((x, y), hex_rgba(palette[key]))
        return image


def sheet(frames, columns=None):
    """Packs equal-sized frames left to right (wrapping after `columns`)."""
    columns = columns or len(frames)
    w, h = frames[0].size
    rows = (len(frames) + columns - 1) // columns
    out = Image.new("RGBA", (w * columns, h * rows), TRANSPARENT)
    for i, frame in enumerate(frames):
        out.paste(frame, ((i % columns) * w, (i // columns) * h))
    return out
