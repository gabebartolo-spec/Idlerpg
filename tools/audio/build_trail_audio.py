"""Original little score and reward tones for Idle RPG; standard Python only.

No recordings or source music are used. The four-bar sketch and tone envelopes
below are the complete source. Rebuilds generate identical 16-bit mono WAVs.
"""
from pathlib import Path
import array
import math
import random
import sys
import wave

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/audio"
RATE = 22050
TAU = math.tau


def frequency(note):
    return 440 * 2 ** ((note - 69) / 12)


def write(name, seconds, sample):
    samples = [sample(index / RATE) for index in range(round(seconds * RATE))]
    peak = max(abs(value) for value in samples)
    assert peak <= 0.8, (name, "clipping", peak)
    pcm = array.array("h", (round(value * 32767) for value in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(pcm.tobytes())
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    print(name, "seconds", seconds, "peak", round(peak, 4), "rms", round(rms, 4))


# Four six-second bars, quiet suspended voicings rather than a busy melody.
CHORDS = [[50, 57, 60, 64], [53, 60, 64, 67], [45, 52, 55, 60], [43, 50, 53, 57]]
MELODY = [62, 69, 64, 65, 72, 69, 67, 64]


def music(t):
    bar = min(3, int(t / 6))
    local = t - bar * 6
    attack = min(1, local / 0.7)
    release = min(1, (6 - local) / 1.4)
    pad = 0.0
    for note in CHORDS[bar]:
        phase = TAU * frequency(note) * t
        pad += (math.sin(phase) + 0.16 * math.sin(phase * 2)) * 0.025
    beat = min(7, int(t / 3))
    bell_t = t - beat * 3
    phase = TAU * frequency(MELODY[beat]) * bell_t
    bell = (math.sin(phase) + 0.22 * math.sin(phase * 2)) * min(1, bell_t / 0.025) * math.exp(-bell_t * 2.7) * 0.04
    edge = min(1, t / 0.025, (24 - t) / 0.15)
    return (pad * attack * release + bell) * max(0, edge)


def reward(t):
    result = 0.0
    for note, start in [(74, 0), (78, 0.09), (81, 0.18)]:
        local = t - start
        if local < 0:
            continue
        phase = TAU * frequency(note) * local
        result += (math.sin(phase) + 0.18 * math.sin(phase * 2.02)) * min(1, local / 0.007) * math.exp(-local * 13) * 0.13
    return result * min(1, max(0, (0.65 - t) / 0.05))


noise = random.Random(9321)


def pickup(t):
    phase = TAU * frequency(74) * t
    envelope = min(1, t / 0.004) * math.exp(-t * 24)
    return (math.sin(phase) * 0.17 + math.sin(phase * 2.9) * 0.04 + noise.uniform(-1, 1) * 0.015) * envelope * min(1, max(0, (0.22 - t) / 0.04))


if __name__ == "__main__":
    write("quiet_trail.wav", 24, music)
    write("reward.wav", 0.65, reward)
    write("pickup.wav", 0.22, pickup)
