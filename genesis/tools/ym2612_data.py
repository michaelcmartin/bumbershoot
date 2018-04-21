#!/usr/bin/python

def ym2612_hz(fnum, block):
    OSC1 = 53693100.0
    fM_YM2612 = OSC1 / 14
    fsam_YM2612 = fM_YM2612 / 72
    return (fnum * fsam_YM2612 * (2 ** block)) / 2097152

def ym2612_vals(hz):
    OSC1 = 53693100.0
    fM_YM2612 = OSC1 / 14
    fsam_YM2612 = fM_YM2612 / 72
    fnum = hz * 2097152.0 / fsam_YM2612
    block = 0
    while fnum >= 2048:
        fnum /= 2.0
        block += 1
    return (block, int(round(fnum)))

print ym2612_hz(1083, 4) # ~ 440 Hz
print ym2612_vals(440)   # Should give us 4, 1083 back
print ym2612_vals(523)   # Should give us 4, 1287
