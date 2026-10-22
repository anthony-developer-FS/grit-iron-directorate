"""Effects: the explosion animation (48x48 frames)."""
import math
import random
from pixel import Canvas, sheet

PALETTE = {
    "W": "#fffbe0", "Y": "#ffe066", "O": "#ff9a2a", "R": "#e0451c", "r": "#9a2a14",
    "S": "#4a4542", "s": "#33302e", "g": "#5f5955",
}

# Per frame: radius and colour bands from the center out, as (fraction of radius, key).
FRAMES = [
    (8, [(0.6, "W"), (1.0, "Y")]),
    (14, [(0.35, "W"), (0.7, "Y"), (1.0, "O")]),
    (18, [(0.25, "Y"), (0.6, "O"), (0.9, "R"), (1.0, "r")]),
    (20, [(0.3, "O"), (0.65, "R"), (0.85, "S"), (1.0, "s")]),
    (21, [(0.25, "R"), (0.5, "S"), (1.0, "s")]),
    (22, [(0.6, "S"), (1.0, "s")]),
    (22, [(1.0, "g")]),
]


def frame(index):
    radius, bands = FRAMES[index]
    rng = random.Random(index * 13 + 5)
    c = Canvas(48, 48)
    bumps = [rng.uniform(0.82, 1.0) for _ in range(12)]
    if index >= 5:
        return _puffs(index, rng)
    for y in range(48):
        for x in range(48):
            dx, dy = x - 23.5, y - 23.5
            angle = (math.atan2(dy, dx) + math.pi) / math.tau * 12
            edge = bumps[int(angle) % 12] * radius
            d = math.hypot(dx, dy)
            if d > edge:
                continue
            f = d / edge
            for limit, key in bands:
                if f <= limit:
                    c.put(x, y, key)
                    break
    return c.to_image(PALETTE)


def _puffs(index, rng):
    """The smoke cloud breaking into drifting puffs."""
    c = Canvas(48, 48)
    spread = 12 if index == 5 else 16
    size = 7 if index == 5 else 5
    for i in range(7):
        angle = i / 7 * math.tau + rng.uniform(-0.3, 0.3)
        cx = 23.5 + math.cos(angle) * spread * rng.uniform(0.5, 1.0)
        cy = 23.5 + math.sin(angle) * spread * rng.uniform(0.5, 1.0) - (index - 4) * 3
        r = size * rng.uniform(0.7, 1.1)
        for y in range(48):
            for x in range(48):
                d = math.hypot(x - cx, y - cy)
                if d <= r:
                    c.put(x, y, "s" if d > r * 0.6 or index == 6 else "S")
    return c.to_image(PALETTE)


def build():
    return {"explosion.png": sheet([frame(i) for i in range(len(FRAMES))])}
