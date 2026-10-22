"""Small numpy synthesizer for the game's sound effects and music.

Everything is mono float arrays at RATE; `save_wav` writes 16-bit PCM.
"""
import wave

import numpy as np

RATE = 22050


def t_axis(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def env(seconds, attack=0.005, decay=None, curve=3.0):
    """Linear attack then exponential-ish decay to silence over `seconds`."""
    n = int(seconds * RATE)
    a = max(1, int(attack * RATE))
    out = np.ones(n)
    out[:a] = np.linspace(0, 1, a)
    rest = n - a
    if rest > 0:
        out[a:] = np.linspace(1, 0, rest) ** curve
    return out


def osc(freq, seconds, shape="square", duty=0.5):
    """Oscillator; `freq` may be a number or an array (for pitch sweeps)."""
    n = int(seconds * RATE)
    freq = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    phase = np.cumsum(freq) / RATE % 1.0
    if shape == "square":
        return np.where(phase < duty, 1.0, -1.0)
    if shape == "saw":
        return 2.0 * phase - 1.0
    if shape == "tri":
        return 4.0 * np.abs(phase - 0.5) - 1.0
    return np.sin(phase * 2 * np.pi)


def noise(seconds, seed=0):
    return np.random.default_rng(seed).uniform(-1, 1, int(seconds * RATE))


def lowpass(x, cutoff):
    """One-pole low-pass; `cutoff` in Hz, number or array."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    alpha = 1 - np.exp(-2 * np.pi * cutoff / RATE)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def sweep(f0, f1, seconds, curve=1.0):
    return f0 + (f1 - f0) * np.linspace(0, 1, int(seconds * RATE)) ** curve


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def at(x, seconds, total=None):
    """Delays a sound by `seconds` (pads with silence)."""
    pad = np.zeros(int(seconds * RATE))
    out = np.concatenate([pad, x])
    if total:
        out = np.pad(out, (0, max(0, int(total * RATE) - len(out))))
    return out


def normalize(x, peak=0.9):
    m = np.max(np.abs(x))
    return x if m == 0 else x / m * peak


def crush(x, bits=6):
    """Bit reduction for a crunchier, arcade feel."""
    steps = 2 ** bits
    return np.round(x * steps) / steps


def save_wav(path, x):
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
