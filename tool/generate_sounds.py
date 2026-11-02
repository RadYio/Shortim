"""Generates the synth sound assets used by Shortim.

Run from the repo root: python3 tool/generate_sounds.py
Outputs 16-bit mono WAV files into assets/sounds/.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def tone(freq, duration, volume=0.6, fade=0.01):
    n = int(RATE * duration)
    fade_n = int(RATE * fade)
    samples = []
    for i in range(n):
        env = min(1.0, i / fade_n, (n - i) / fade_n)
        samples.append(volume * env * math.sin(2 * math.pi * freq * i / RATE))
    return samples


def write(name, samples, rate=RATE):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in samples))


if __name__ == "__main__":
    # Short countdown beep (T-3, T-2, T-1).
    write("beep.wav", tone(880, 0.12))
    # Rising two-tone chime marking the start of a new interval.
    write("interval_change.wav", tone(660, 0.12) + tone(1320, 0.28))
    # Three ascending notes marking the end of the series.
    write("finish.wav", tone(523, 0.18) + tone(659, 0.18) + tone(784, 0.45))
    # Silent loop keeping the iOS audio session alive in background.
    write("silence.wav", [0.0] * (8000 * 10), rate=8000)
