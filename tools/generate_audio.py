"""Generate the project's original, deterministic synthesised audio. No samples."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 22050

def write(name, duration, synth):
    frames = bytearray()
    for i in range(int(duration * RATE)):
        value = max(-1, min(1, synth(i / RATE)))
        frames.extend(struct.pack("<h", int(value * 27000)))
    with wave.open(str(ROOT / (name + ".wav")), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(frames)

def tone(t, freq):
    return math.sin(math.tau * freq * t)

ROOT.mkdir(parents=True, exist_ok=True)
write("spark", .24, lambda t: (tone(t, 880) + .3*tone(t, 1320)) * math.exp(-t*24) * min(1,t*500) * .65)
write("echo", .6, lambda t: (tone(t, 220) + .4*tone(t, 330)) * math.sin(math.pi*t/.6)**2 * .5)
write("start", .4, lambda t: tone(t, [440, 554.365, 659.255, 880][min(3,int(t*10))]) * math.sin(math.pi*(t%.1)/.1)**2 * .4)
write("click", .07, lambda t: tone(t, 660)*math.exp(-t*65)*min(1,t*800)*.4)
rng = random.Random(33)
write("death", .6, lambda t: (tone(t, 95) + rng.uniform(-.16,.16))*math.exp(-t*9)*min(1,t*200)*.6)
notes = [220, 277.1826, 329.6276, 415.3047, 329.6276, 277.1826, 246.9417, 329.6276]
def ambient(t):
    # Integer-cycle low pad and soft eight-note ostinato; no hard loop edge.
    envelope = min(1, t/1.5, (16-t)/1.5)
    pad = .16*tone(t,110) + .08*tone(t,165) + .06*tone(t,220)
    phase = t % .5
    note = notes[int(t/.5)%len(notes)]
    arpeggio = tone(phase,note)*math.exp(-phase*9)*min(1,phase*100)*.18
    return (pad+arpeggio)*envelope
write("ambient",16,ambient)
print("Generated six original audio assets.")
