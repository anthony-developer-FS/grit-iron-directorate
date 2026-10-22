"""Regenerates every sprite sheet in assets/sprites from the scripts in this folder.
Run: python3 tools/art/build.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import grit  # noqa: E402
import trooper  # noqa: E402
import vehicles  # noqa: E402
import pow as pow_art  # noqa: E402
import world  # noqa: E402
import boss  # noqa: E402
import fx  # noqa: E402
import font  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
FONTS = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "fonts")


def main():
    os.makedirs(OUT, exist_ok=True)
    outputs = {
        "grit_body.png": grit.body_sheet(),
        "grit_arms.png": grit.arms_sheet(),
        "parachute.png": grit.parachute(),
        "muzzle_flash.png": grit.muzzle_flash(),
        "enemies.png": trooper.enemy_sheet(),
        "enemies_flash.png": trooper.flash_sheet(),
    }
    outputs.update(vehicles.build())
    outputs.update(pow_art.build())
    outputs.update(world.build())
    outputs.update(boss.build())
    outputs.update(fx.build())
    outputs["logo.png"] = font.logo("VANGUARD OPS", 3, "ffe066", "e0661c")
    os.makedirs(FONTS, exist_ok=True)
    font.build(os.path.join(FONTS, "pixel.fnt"), "pixel.png").save(os.path.join(FONTS, "pixel.png"))
    print("wrote pixel.fnt and pixel.png")
    for name, image in outputs.items():
        image.save(os.path.join(OUT, name))
        print("wrote", name, image.size)


if __name__ == "__main__":
    main()
