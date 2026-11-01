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
write("echo", .6, lambda t: tone(t, 392 if t < .2 else 523.25) * math.exp(-(t % .2)*18) * min(1,(t % .2)*200) * .35)
write("start", .4, lambda t: tone(t, [440, 554.365, 659.255, 880][min(3,int(t*10))]) * math.sin(math.pi*(t%.1)/.1)**2 * .4)
write("click", .07, lambda t: tone(t, 660)*math.exp(-t*65)*min(1,t*800)*.4)
rng = random.Random(33)
write("death", .6, lambda t: math.sin(math.tau * (110*t + 30*(1-math.exp(-8*t)))) * math.exp(-t*8) * min(1,t*200) * .45)
notes = [220, 277.1826, 329.6276, 415.3047, 329.6276, 277.1826, 246.9417, 329.6276]
def ambient(t):
    # Integer-cycle low pad and soft eight-note ostinato; no hard loop edge.
    envelope = min(1, t/1.5, (16-t)/1.5)
    pad = .04*tone(t,220) + .02*tone(t,330)
    phase = t % .5
    note = notes[int(t/.5)%len(notes)]
    arpeggio = (tone(phase,note*2) + .24*tone(phase,note*4))*math.exp(-phase*15)*min(1,phase*180)*.20
    return (pad+arpeggio)*envelope
write("ambient",16,ambient)
print("Generated six original audio assets.")
