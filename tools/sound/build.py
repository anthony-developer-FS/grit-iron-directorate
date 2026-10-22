"""Regenerates assets/sound from the scripts in this folder (needs numpy; music needs ffmpeg).
Run: python3 tools/sound/build.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import subprocess  # noqa: E402
import tempfile  # noqa: E402

import music  # noqa: E402
import sfx  # noqa: E402
from synth import save_wav  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sound")


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, data in sfx.build().items():
        save_wav(os.path.join(OUT, name + ".wav"), data)
        print("wrote", name)
    # Music is encoded to Ogg Vorbis to keep the repository small.
    for name, render in (("music_mission", music.mission), ("music_boss", music.boss)):
        with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
            save_wav(tmp.name, render())
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis",
                            "-q:a", "5", os.path.join(OUT, name + ".ogg")], check=True)
        print("wrote", name)


if __name__ == "__main__":
    main()
