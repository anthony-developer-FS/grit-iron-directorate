"""The two music loops, written as note lists and rendered with the chip-style synth.

Notation: each voice is a list of bars; a bar is a space-separated list of `note:beats`, where
note is like D5, Bb4, C#5 or R for a rest. Drums are 16-step strings per bar:
k = kick, s = snare, h = hi-hat, o = open hat, . = rest.
"""
import numpy as np
from synth import RATE, osc, noise, highpass, sweep, env, normalize

NOTE_INDEX = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def freq(name):
    letter = name[0]
    rest = name[1:]
    shift = 0
    while rest and rest[0] in "#b":
        shift += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + NOTE_INDEX[letter] + shift
    return 440.0 * 2 ** ((midi - 69) / 12)


def render_voice(bars, bpm, shape, duty=0.5, volume=0.3, release=0.85, vibrato=0.0, beats_per_bar=4):
    beat = 60.0 / bpm
    total = int(len(bars) * beats_per_bar * beat * RATE)
    out = np.zeros(total)
    for b, bar in enumerate(bars):
        t = b * beats_per_bar * beat
        for token in bar.split():
            name, beats = token.split(":")
            length = float(beats) * beat
            if name != "R":
                held = length * release
                f = freq(name)
                if vibrato:
                    tt = np.arange(int(held * RATE)) / RATE
                    f = f * (1 + vibrato * np.sin(2 * np.pi * 5.5 * tt) * np.clip(tt / 0.15, 0, 1))
                tone = osc(f, held, shape, duty) * env(held, 0.008, curve=0.6) * volume
                start = int(t * RATE)
                out[start:start + len(tone)] += tone[:max(0, total - start)]
            t += length
    return out


def _kick():
    return osc(sweep(140, 40, 0.16), 0.16, "sine") * env(0.16, 0.001, curve=2.5)


def _snare():
    return highpass(noise(0.14, 1), 1500) * env(0.14, 0.001, curve=3) * 0.7 + \
        osc(sweep(220, 160, 0.14), 0.14, "tri") * env(0.14, 0.001, curve=4) * 0.4


def _hat(length=0.04):
    return highpass(noise(length, 2), 6000) * env(length, 0.001, curve=3) * 0.35


def render_drums(bars, bpm, volume=0.5):
    step = 60.0 / bpm / 4
    total = int(len(bars) * 16 * step * RATE)
    out = np.zeros(total)
    kits = {"k": _kick(), "s": _snare(), "h": _hat(), "o": _hat(0.12)}
    for b, pattern in enumerate(bars):
        for i, key in enumerate(pattern):
            if key in kits:
                start = int((b * 16 + i) * step * RATE)
                hit = kits[key] * volume
                out[start:start + len(hit)] += hit[:max(0, total - start)]
    return out


def song(voices, drums, bpm):
    parts = [render_voice(bpm=bpm, **v) for v in voices] + [render_drums(drums, bpm)]
    n = min(len(p) for p in parts)
    return normalize(sum(p[:n] for p in parts), 0.85)


# --- Mission theme: "Breakwater", D minor march, 132 bpm, 16 bars. ---

MISSION_LEAD = [
    "D5:1 A4:0.5 D5:0.5 F5:1 E5:0.5 D5:0.5",
    "C5:1.5 D5:0.5 A4:2",
    "Bb4:1 D5:0.5 F5:0.5 Bb5:1 A5:0.5 G5:0.5",
    "F5:2 D5:2",
    "E5:1 C5:0.5 E5:0.5 G5:1 F5:0.5 E5:0.5",
    "D5:1 E5:0.5 F5:0.5 G5:2",
    "A5:1.5 G5:0.5 F5:1 E5:1",
    "C#5:2 A4:2",
    "D5:1 A4:0.5 D5:0.5 F5:1 E5:0.5 D5:0.5",
    "C5:1.5 D5:0.5 A4:2",
    "Bb4:1 D5:0.5 F5:0.5 Bb5:1 A5:0.5 G5:0.5",
    "F5:1 G5:0.5 A5:0.5 Bb5:2",
    "G5:1 F5:0.5 G5:0.5 A5:1 G5:0.5 F5:0.5",
    "E5:1 F5:0.5 G5:0.5 A5:2",
    "G5:1 F5:1 E5:1 C#5:1",
    "D5:3 R:1",
]

# Chords per bar (root, fifth) for the bass and the pad.
MISSION_CHORDS = ["D", "D", "Bb", "Bb", "C", "C", "A", "A", "D", "D", "Bb", "Bb", "G", "C", "A", "D"]
FIFTH = {"D": "A", "Bb": "F", "C": "G", "A": "E", "G": "D", "E": "B", "B": "F#", "F": "C", "F#": "C#"}
THIRD = {"D": "F", "Bb": "D", "C": "E", "A": "C#", "G": "Bb", "E": "G", "B": "D#", "F": "A", "F#": "A"}


def march_bass(chords, octave=2):
    bars = []
    for root in chords:
        fifth = FIFTH[root]
        # The fifth sits above the root, so it moves up an octave if it wraps past C.
        wraps = NOTE_INDEX[fifth[0]] < NOTE_INDEX[root[0]]
        r, f = "%s%d" % (root, octave), "%s%d" % (fifth, octave + (1 if wraps else 0))
        bars.append(" ".join(["%s:0.5" % n for n in [r, r, f, r, r, r, f, r]]))
    return bars


def pad(chords, octave=4):
    return ["%s%d:2 %s%d:2" % (THIRD[c], octave, FIFTH[c], octave) for c in chords]


MISSION_DRUMS = (["k.h.s.h.k.k.s.hh"] * 7 + ["k.h.s.h.k.ssssss"]) * 2


def mission():
    return song([
        dict(bars=MISSION_LEAD, shape="square", duty=0.25, volume=0.22, vibrato=0.006),
        dict(bars=pad(MISSION_CHORDS), shape="square", duty=0.5, volume=0.06, release=0.95),
        dict(bars=march_bass(MISSION_CHORDS), shape="tri", volume=0.42, release=0.7),
    ], MISSION_DRUMS, 132)


# --- Boss theme: "Seewall", E minor, 152 bpm, 16 bars. ---

BOSS_LEAD = [
    "E5:0.5 E5:0.5 G5:0.5 E5:0.5 B5:1 A5:0.5 G5:0.5",
    "F#5:0.5 G5:0.5 A5:0.5 F#5:0.5 E5:2",
    "C6:1 B5:0.5 A5:0.5 G5:1 E5:1",
    "G5:0.5 A5:0.5 G5:0.5 E5:0.5 C5:2",
    "D5:0.5 F#5:0.5 A5:0.5 D6:0.5 C6:1 A5:1",
    "B5:0.5 A5:0.5 F#5:0.5 D5:0.5 A5:2",
    "B5:1 A5:0.5 G5:0.5 F#5:1 D#5:1",
    "B4:2 D#5:1 F#5:1",
    "E5:0.5 E5:0.5 G5:0.5 E5:0.5 B5:1 A5:0.5 G5:0.5",
    "F#5:0.5 G5:0.5 A5:0.5 B5:0.5 C6:2",
    "C6:0.5 B5:0.5 A5:0.5 G5:0.5 E5:1 G5:1",
    "A5:0.5 G5:0.5 E5:0.5 C5:0.5 E5:2",
    "D5:0.5 F#5:0.5 A5:0.5 D6:0.5 E6:1 D6:1",
    "C6:0.5 B5:0.5 A5:0.5 F#5:0.5 D6:2",
    "B5:0.5 C6:0.5 B5:0.5 A5:0.5 G5:1 F#5:1",
    "E5:2 B4:1 D#5:1",
]
BOSS_CHORDS = ["E", "E", "C", "C", "D", "D", "B", "B", "E", "E", "C", "C", "D", "D", "B", "B"]


def driving_bass(chords, octave=2):
    bars = []
    for root in chords:
        r = "%s%d" % (root, octave)
        hi = "%s%d" % (root, octave + 1)
        bars.append(" ".join(["%s:0.5" % n for n in [r, r, hi, r, r, hi, r, hi]]))
    return bars


BOSS_DRUMS = (["k.hkk.hks.hkk.hs", "k.hkk.hks.hkkss."] * 3 + ["k.hkk.hks.hkk.hs", "ksksksksssssssss"]) * 2


def boss():
    return song([
        dict(bars=BOSS_LEAD, shape="square", duty=0.5, volume=0.18, vibrato=0.004, release=0.8),
        dict(bars=pad(BOSS_CHORDS), shape="saw", volume=0.05, release=0.95),
        dict(bars=driving_bass(BOSS_CHORDS), shape="square", duty=0.25, volume=0.2, release=0.6),
    ], BOSS_DRUMS, 152)
