#!/usr/bin/python

conv_factor = 53693100.0 / 0x7e000000

def ym2612_hz(fnum, block):
    return fnum * (2 ** block) * conv_factor

def ym2612_vals(hz):
    fnum = hz / conv_factor
    block = 0
    while fnum >= 2048:
        fnum /= 2.0
        block += 1
    return (block, int(round(fnum)))

print ym2612_hz(1083, 4) # ~ 440 Hz
print ym2612_vals(440)   # Should give us 4, 1083 back
print ym2612_vals(523)   # Should give us 4, 1287
