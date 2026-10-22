"""Sound effects, all synthesized. Run build.py to write assets/sound/*.wav."""
import numpy as np
from synth import (env, osc, noise, lowpass, highpass, sweep, mix, at, normalize, crush, t_axis)


def gunshot(length, body_hz, crack_hz, seed, punch=0.6):
    n = noise(length, seed)
    crack = highpass(n, crack_hz) * env(length, 0.001, curve=6)
    body = lowpass(n, body_hz) * env(length, 0.002, curve=3) * 2.5
    thump = osc(sweep(160, 50, length), length, "sine") * env(length, 0.001, curve=4) * punch
    return normalize(crush(mix(crack, body, thump), 7))


def explosion(length=1.1, seed=3, size=1.0):
    n = noise(length, seed)
    rumble = lowpass(n, sweep(1800 * size, 120, length, 0.5)) * env(length, 0.003, curve=2.2) * 3
    boom = osc(sweep(90, 30, length), length, "sine") * env(length, 0.002, curve=3) * 1.2
    crackle = highpass(noise(length, seed + 1), 2500) * env(length, 0.001, curve=8) * 0.6
    return normalize(crush(mix(rumble, boom, crackle), 7))


def blip(freqs, note=0.06, shape="square", duty=0.5, gap=0.0):
    parts = []
    for i, f in enumerate(freqs):
        tone = osc(f, note, shape, duty) * env(note, 0.002, curve=1.5)
        parts.append(at(tone, i * (note + gap)))
    return normalize(mix(*parts), 0.4)


def build():
    s = {}
    s["pistol"] = gunshot(0.18, 2200, 3000, 1)
    s["hmg"] = gunshot(0.12, 1600, 2400, 2, punch=0.8)
    s["shotgun"] = normalize(mix(gunshot(0.35, 1200, 1800, 4, punch=1.0), at(blip([180, 140], 0.05, "square", 0.3) * 0.3, 0.22)))
    flame_len = 0.25
    s["flame"] = normalize(lowpass(noise(flame_len, 5), sweep(900, 3000, flame_len)) * env(flame_len, 0.03, curve=1.5)) * 0.8
    rl = 0.45
    s["rocket"] = normalize(mix(lowpass(noise(rl, 6), 2500) * env(rl, 0.01, curve=1.2),
                                osc(sweep(200, 900, rl), rl, "saw") * env(rl, 0.01, curve=2) * 0.2))
    s["enemy_shot"] = normalize(gunshot(0.2, 1400, 2000, 7, punch=0.4)) * 0.8
    s["mg_shot"] = gunshot(0.1, 1300, 2000, 8, punch=0.7) * 0.8
    s["flak"] = normalize(mix(gunshot(0.25, 900, 1500, 9, punch=1.0), osc(sweep(700, 300, 0.25), 0.25, "square") * env(0.25, curve=4) * 0.2))
    s["cannon"] = explosion(1.4, 10, 0.6)
    ch = 0.9
    s["cannon_charge"] = normalize(osc(sweep(80, 420, ch, 1.5), ch, "saw") * env(ch, ch * 0.9, curve=0.3) * 0.5
                                   + lowpass(noise(ch, 11), 600) * np.linspace(0, 0.6, int(ch * 22050)))
    s["explosion"] = explosion()
    s["explosion_big"] = explosion(1.8, 12, 1.4)
    s["grenade_throw"] = normalize(lowpass(noise(0.15, 13), sweep(400, 2400, 0.15)) * env(0.15, 0.05, curve=1)) * 0.5
    s["knife"] = normalize(highpass(noise(0.12, 14), sweep(2000, 6000, 0.12)) * env(0.12, 0.01, curve=2)) * 0.7
    s["hit"] = normalize(mix(lowpass(noise(0.08, 15), 900) * env(0.08, 0.001, curve=3), osc(sweep(220, 90, 0.08), 0.08, "square") * env(0.08, curve=3) * 0.4)) * 0.6
    s["ping"] = normalize(mix(osc(2400, 0.25, "sine") * env(0.25, 0.001, curve=4), osc(3700, 0.25, "sine") * env(0.25, 0.001, curve=6) * 0.5, highpass(noise(0.03, 16), 3000) * 0.5)) * 0.6
    s["enemy_die"] = normalize(osc(sweep(420, 110, 0.35, 0.7), 0.35, "square", 0.3) * env(0.35, 0.005, curve=1.5)) * 0.45
    s["player_hurt"] = normalize(mix(osc(sweep(600, 200, 0.25), 0.25, "square", 0.25) * env(0.25, curve=1.5), lowpass(noise(0.12, 17), 1500) * 0.6)) * 0.6
    s["player_die"] = normalize(mix(*[at(osc(f, 0.16, "square", 0.4) * env(0.16, curve=1.2), i * 0.14) for i, f in enumerate([523, 392, 330, 262, 196])])) * 0.6
    s["jump"] = normalize(osc(sweep(260, 620, 0.12), 0.12, "square", 0.25) * env(0.12, 0.002, curve=1.5)) * 0.3
    s["pickup_weapon"] = blip([523, 659, 784, 1047], 0.06)
    s["pickup_item"] = blip([784, 1047], 0.07)
    s["pow_freed"] = blip([392, 523, 659, 784, 659, 784], 0.08, "square", 0.25)
    s["checkpoint"] = blip([659, 784, 988, 1319], 0.09, "tri")
    s["supply_drop"] = blip([440, 440, 660], 0.1, "square", 0.25, 0.04)
    s["weapon_empty"] = blip([330, 220], 0.08, "square", 0.25)
    wl = 1.2
    s["shell_whistle"] = normalize(osc(sweep(1800, 500, wl, 0.8), wl, "sine") * np.linspace(0.2, 1.0, int(wl * 22050)) ** 2) * 0.35
    s["flare"] = blip([1200, 0, 1200, 0, 1200], 0.05, "square", 0.5)
    s["menu_move"] = blip([880], 0.04)
    s["menu_select"] = blip([660, 1320], 0.06)
    s["pause"] = blip([523, 392], 0.07, "tri")
    s["mission_complete"] = blip([392, 392, 392, 523, 0, 659, 784, 1047], 0.12, "square", 0.3, 0.02)
    s["game_over"] = blip([392, 370, 349, 330, 0, 262], 0.22, "tri")
    s["elevator"] = normalize(mix(osc(55, 1.0, "saw") * 0.3, lowpass(noise(1.0, 18), 300) * 0.5) * env(1.0, 0.2, curve=0.5)) * 0.5
    s["alarm"] = normalize(mix(*[at(osc(sweep(500, 900, 0.3), 0.3, "square", 0.5) * env(0.3, 0.01, curve=0.6), i * 0.35) for i in range(3)])) * 0.4
    return s
