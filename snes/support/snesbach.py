#!/usr/bin/env python3

import os.path
import sys

musicdir = os.path.dirname(os.path.realpath(sys.argv[0]))
sys.path.insert(0, os.path.join(musicdir, '..', '..', 'sound'))

import musicmacro

def snes_note(noteval):
    reference = 4 * 12 + 10  # A-440
    step = 2 ** (1/12)
    hz = 440 * (step ** (noteval - reference))
    return int((hz * 0x1000) / 500)

score = [[]]
voice = 0
for track in musicmacro.bach_sample:
    t = 0
    spill = 0
    for (n,v) in musicmacro.parse(track):
        spill += int((v * 64) % 60)
        v = int((v * 64) / 60)
        while spill >= 60:
            spill -= 60
            v += 1
        while len(score) < t + v:
            score.append([])
        score[t].append(("KEY-ON", voice, n))
        if v > 4:
            score[t+v-4].append(("KEY-OFF", voice))
        t += v
    voice += 1

# Load global init commands at first
cmds = [0x6c, 0x20, 0x0c, 0x7f, 0x1c, 0x7f, 0x2c, 0x00,
        0x3c, 0x00, 0x4c, 0x00, 0x5c, 0xff, 0x2d, 0x00,
        0x3d, 0x00, 0x4d, 0x00, 0x5d, 0x02, 0x5c, 0x00]
# Add instrument control
cmds += [0x00, 0x7f, 0x01, 0x7f, 0x04, 0x00, 0x05, 0x9f, 0x06, 0x1a,
         0x10, 0x7f, 0x11, 0x7f, 0x14, 0x00, 0x15, 0x9f, 0x16, 0x1a]

loopback = len(cmds)

t = 0
p = 0
while t < len(score):
    if len(score[t]) == 0:
        p += 1
        t += 1
        continue
    if p > 0:
        cmds.append(128+p)
    koff = 0
    kon = 0
    notes = [None, None]
    for event in score[t]:
        if event[0] == "KEY-OFF":
            koff |= 1 << event[1]
        elif event[0] == "KEY-ON":
            kon |= 1 << event[1]
            notes[event[1]] = snes_note(event[2])
    cmds.append(0x5c)
    cmds.append(koff)
    if notes[0] is not None:
        cmds.extend([2,notes[0] & 0xFF,3,(notes[0] >> 8) & 0xFF])
    if notes[1] is not None:
        cmds.extend([18,notes[1] & 0xFF,19,(notes[1] >> 8) & 0xFF])
    if kon != 0:
        cmds.append(0x4c)
        cmds.append(kon)
    t += 1
    p = 1
if p > 0:
    cmds.append(128+p)

cmds.extend([0x80, loopback & 0xFF, (loopback >> 8) & 0xFF])

player = open(sys.argv[1], "rb")
final = open(sys.argv[2], "wb")
final.write(player.read()[512:])
player.close()
final.write(bytes(cmds))
final.close()
