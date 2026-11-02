"""Generates the synth sound assets used by Shortim.

Run from the repo root: python3 tool/generate_sounds.py
Outputs 16-bit mono WAV files into assets/sounds/<theme>/ (beep.wav,
change.wav, finish.wav for each theme) plus assets/sounds/silence.wav.

Each theme uses one timbre for its three cues, so they sound related:
the countdown beep is short, the interval change is a two-note rise and
the finish is a three/four-note ascending arpeggio.
"""

import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
PEAK = 0.6  # every cue is normalised to this peak, so themes match in level


def silence(duration):
    return [0.0] * int(RATE * duration)


def mix(*tracks):
    """Sums tracks of possibly different lengths."""
    out = [0.0] * max(len(t) for t in tracks)
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def at(offset, samples):
    """Delays samples by offset seconds (for overlapping notes)."""
    return silence(offset) + samples


def normalise(samples, peak=PEAK):
    top = max(abs(s) for s in samples) or 1.0
    return [s * peak / top for s in samples]


# --- Classic: plain sine with short fades (the v1 sounds, unchanged). ---

def tone(freq, duration, volume=0.6, fade=0.01):
    n = int(RATE * duration)
    fade_n = int(RATE * fade)
    samples = []
    for i in range(n):
        env = min(1.0, i / fade_n, (n - i) / fade_n)
        samples.append(volume * env * math.sin(2 * math.pi * freq * i / RATE))
    return samples


# --- Soft bell: inharmonic partials with long exponential decays. ---

def bell(freq, duration):
    partials = [(1.0, 1.0, 1.0), (2.0, 0.5, 1.6), (2.76, 0.35, 2.4), (5.4, 0.15, 4.0)]
    n = int(RATE * duration)
    attack = int(RATE * 0.004)
    out = []
    for i in range(n):
        t = i / RATE
        env_attack = min(1.0, i / attack)
        s = sum(
            amp * math.exp(-t * decay * 3.0) * math.sin(2 * math.pi * freq * ratio * t)
            for ratio, amp, decay in partials
        )
        out.append(env_attack * s * min(1.0, (n - i) / (RATE * 0.02)))
    return out


# --- Marimba: woody fundamental plus its strong 4th and 10th partials. ---

def marimba(freq, duration):
    partials = [(1.0, 1.0, 6.0), (3.93, 0.45, 18.0), (9.2, 0.12, 40.0)]
    n = int(RATE * duration)
    attack = int(RATE * 0.002)
    out = []
    for i in range(n):
        t = i / RATE
        s = sum(
            amp * math.exp(-t * decay) * math.sin(2 * math.pi * freq * ratio * t)
            for ratio, amp, decay in partials
        )
        out.append(min(1.0, i / attack) * s)
    return out


# --- Electro pulse: soft-clipped square with a quick pitch drop. ---

def pulse(freq, duration, glide=0.15):
    n = int(RATE * duration)
    fade = int(RATE * 0.006)
    phase = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        # Starts slightly sharp and settles: gives the "blip" its snap.
        f = freq * (1 + glide * math.exp(-t * 60))
        phase += 2 * math.pi * f / RATE
        square = math.tanh(4 * math.sin(phase)) * 0.7 + 0.3 * math.sin(2 * phase)
        env = min(1.0, i / fade, (n - i) / fade) * math.exp(-t * 7)
        out.append(env * square)
    return out


def sweep(f0, f1, duration):
    """Rising pulse sweep, for the electro interval change."""
    n = int(RATE * duration)
    fade = int(RATE * 0.006)
    phase = 0.0
    out = []
    for i in range(n):
        x = i / n
        f = f0 * (f1 / f0) ** x
        phase += 2 * math.pi * f / RATE
        env = min(1.0, i / fade, (n - i) / fade)
        out.append(env * math.tanh(3 * math.sin(phase)))
    return out


def themes():
    return {
        "classic": {
            "beep": tone(880, 0.12),
            "change": tone(660, 0.12) + tone(1320, 0.28),
            "finish": tone(523, 0.18) + tone(659, 0.18) + tone(784, 0.45),
        },
        "bell": {
            "beep": bell(1046.5, 0.35),
            "change": mix(bell(784.0, 0.9), at(0.14, bell(1174.7, 0.9))),
            "finish": mix(
                bell(523.3, 1.4),
                at(0.18, bell(659.3, 1.3)),
                at(0.36, bell(784.0, 1.3)),
                at(0.54, bell(1046.5, 1.4)),
            ),
        },
        "marimba": {
            "beep": marimba(880.0, 0.25),
            "change": marimba(659.3, 0.14) + marimba(987.8, 0.4),
            "finish": marimba(523.3, 0.14)
            + marimba(659.3, 0.14)
            + marimba(784.0, 0.14)
            + marimba(1046.5, 0.6),
        },
        "pulse": {
            "beep": pulse(1000, 0.09),
            "change": sweep(420, 1260, 0.18) + pulse(1260, 0.16),
            "finish": pulse(523.3, 0.12)
            + pulse(784.0, 0.12)
            + pulse(1046.5, 0.12)
            + pulse(1568.0, 0.4),
        },
    }


def write(path, samples, rate=RATE):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(
            b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples)
        )


if __name__ == "__main__":
    for theme, cues in themes().items():
        for cue, samples in cues.items():
            # Classic keeps its original levels; synth themes are normalised.
            out = samples if theme == "classic" else normalise(samples)
            write(OUT / theme / f"{cue}.wav", out)
    # Silent loop keeping the iOS audio session alive in background.
    write(OUT / "silence.wav", [0.0] * (8000 * 10), rate=8000)
