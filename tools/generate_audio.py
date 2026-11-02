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
# Eight-bar, 120 BPM toy-band loop: marimba, rounded bass, brushed hats and kick.
# Every phrase ends before the loop boundary, avoiding a click or a silent gap.
chords = [[261.6256,329.6276,391.9954], [220,261.6256,329.6276],
          [174.6141,220,261.6256], [195.9977,246.9417,293.6648]]
melody = [0, 2, 1, 2, 0, 1, 2, 1, 2, 1, 0, 1, 2, 0, 1, 2]
def ambient(t):
    chord = chords[int(t / 4) % 4]
    step = int(t / .25)
    phase = t % .25
    note = chord[melody[step % len(melody)]] * (2 if step % 8 in (3, 6) else 1)
    bell = (tone(phase, note*2) + .26*tone(phase, note*5.01))
    bell *= math.exp(-phase*18) * min(1,phase*500) * .30
    beat = t % .5
    bass_note = chord[0] / 2 if int(t/.5) % 4 != 3 else chord[2] / 2
    bass = (tone(beat,bass_note) + .18*tone(beat,bass_note*2))
    bass *= math.sin(math.pi*min(1,beat/.45))**2 * .19
    kick = math.sin(math.tau*(46*beat + 3*(1-math.exp(-beat*35))))
    kick *= math.exp(-beat*24) * min(1,beat*600) * .18
    # Deterministic metallic brush without random generator state at the seam.
    hat = (tone(phase,5300)+tone(phase,7100)) * math.exp(-phase*65)*min(1,phase*700)*.035
    return bell + bass + kick + hat
write("ambient",16,ambient)
write("pop",.42,lambda t: (tone(t,300*math.exp(-t*9))+.3*tone(t,620))*math.exp(-t*13)*min(1,t*400)*.65)
print("Generated seven original audio assets.")
