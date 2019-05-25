#!/usr/bin/python
import musicmacro

conv_factor = 53693100.0 / 0x7e000000

def ym2612_hz(fnum, block):
    return fnum * (2 ** block) * conv_factor

def ym2612_vals(hz):
    fnum = hz / conv_factor
    block = 0
    while fnum >= 2048:
        fnum /= 2.0
        block += 1
    fnum = int(round(fnum))
    return (block << 11) | fnum

def freq(noteval):
    reference = 4 * 12 + 10  # A-440
    step = 2.0 ** (1.0 / 12)
    return ym2612_vals(440.0 * (step ** (noteval - reference)))

def set_instrument(score, instrument, voice, time):
    while len(score) <= time:
        score.append([])
    for (register, val) in zip(list(range(0x30+voice, 0xa0, 4)), instrument):
        score[time].append((register, val))
    score[time].append((0xb0, instrument[-2]))
    score[time].append((0xb4, instrument[-1]))

def set_note(score, voice, note, length, time):
    ontime = int(time)
    offtime = int(time + length * 7.0 / 8)
    while len(score) <= offtime:
        score.append([])
    regval = freq(note)
    score[ontime].append((0xa4 + voice, regval >> 8))
    score[ontime].append((0xa0 + voice, regval & 0xff))
    score[ontime].append((0x28, 0xf0+voice))
    score[offtime].append((0x28, voice))

voice1_a = """T120O3L8GB>DG<A>F#G4<G4G4GB>DG<A>F#G4<G4G4
L4O4EEE8G8DDD8G8CL8DC<B>C<A2.
O3L8GB>DG<A>F#G4<G4G4GB>DG<A>F#G4<G4G4
O4L8E4DC<BA>D4C<BAGL12AB>C<L4DF#G2."""
voice1_b = """O3L8GABAGF#G4E4E4>GF#EGF#EF#4<B4B4
O4L8GF#EGF#EL4F#<B>EL12F#GAL4<B>D#ED#8E8F#
O4L8G4GF#EDE4EDC<B>C4C<BAGF#4EF#D4
O3L4ADDBDD>CL8DC<B>C<A2.
O3L8GB>DG<A>F#G4<G4G4GB>DG<A>F#G4<G4G4
O4L8E4DC<BA>D4C<BAGABL4DF#G2."""

voice2_a = """T120O2L8G2D4<GB>DGD<BG2>D4<GB>DGD<B
O2L4CGC<B>G<BA>F#GL8DEF#DEF#
O2L8G2D4<GB>DGD<BG2>D4<GB>DGD<B
O2L4CEG<B>DGCDDGD<G"""
voice2_b = """O2L4ED#<B>E<BE>EGBL8<B>D#F#BF#D#
O2L4EGB<B>AGAB<B>E2.
O1L4B>DGCDE<AB>CD<AD
O2L8F#DF#DF#DGDGDGDF#4D4G4DEF#DEF#
O2L8G2D4<GB>DGD<BG2>D4<GB>DGD<B
O2L4CEG<B>DGC2DGD<G"""

voice1 = voice1_a + voice1_a + voice1_b + voice1_b
voice2 = voice2_a + voice2_a + voice2_b + voice2_b

piano = [0x71, 0x0d, 0x33, 0x01, # Detune/Multiple
         0x23, 0x2d, 0x26, 0x00, # Total level
         0x5f, 0x99, 0x5f, 0x94, # Rate Scaling/Attack rate
         0x05, 0x05, 0x05, 0x07, # First decay rate/AM disabled
         0x02, 0x02, 0x02, 0x02, # Secondary decay rate
         0x11, 0x11, 0x11, 0xa6, # Sustain level, release rate
         0x00, 0x00, 0x00, 0x00, # SSG-EG (should be zeroes)
         0x32,                   # Operator combination algorithm/feedback
         0xc0]                   # Stereo enable/AMS disabled/FMS disabled

score = [[]]
set_instrument(score, piano, 0, 0)
set_instrument(score, piano, 1, 0)
t = 0
for (n, v) in musicmacro.parse(voice1):
    set_note(score, 0, n, v, t)
    t += v
    while len(score) < t:
        score.append([])
t = 0
for (n, v) in musicmacro.parse(voice2):
    set_note(score, 1, n, v, t)
    t += v
    while len(score) < t:
        score.append([])

collated = []
t = 0
while t < len(score):
    l = 1
    while t+l < len(score) and len(score[t+l]) == 0:
        l += 1
    collated.append(l)
    collated.append(len(score[t]))
    for (r, v) in score[t]:
        collated.append(r)
        collated.append(v)
    t += l
collated.append(0)

t = 0
while t < len(collated):
    print(("        defb    $" + ",$".join(["%02X" % c for c in collated[t:t+16]])))
    t += 16
print("        ;; %d bytes in song" % len(collated))
