"""Regenerates every sprite sheet in assets/sprites from the scripts in this folder.
Run: python3 tools/art/build.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import grit  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")


def main():
    os.makedirs(OUT, exist_ok=True)
    outputs = {
        "grit_body.png": grit.body_sheet(),
        "grit_arms.png": grit.arms_sheet(),
        "parachute.png": grit.parachute(),
        "muzzle_flash.png": grit.muzzle_flash(),
    }
    for name, image in outputs.items():
        image.save(os.path.join(OUT, name))
        print("wrote", name, image.size)


if __name__ == "__main__":
    main()
