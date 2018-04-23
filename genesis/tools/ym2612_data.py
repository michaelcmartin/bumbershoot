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
    fnum = int(round(fnum))
    return (block << 11) | fnum

def freq(noteval, octave):
    val = 4 * 12 + 10  # A-440
    target = octave * 12 + noteval
    step = 2.0 ** (1.0 / 12)
    return ym2612_vals(440.0 * (step ** (target - val)))

notes = [freq(x, 4) for x in [1, 3, 5, 6, 8, 10, 12, 13]]
print "        defb    $1F,$21,$30,$71,$34,$0D,$38,$33,$3C,$01"
print "        defb    $40,$23,$44,$2D,$48,$26,$4C,$00,$50,$5F"
print "        defb    $54,$99,$58,$5F,$5C,$94,$60,$05,$64,$05"
print "        defb    $68,$05,$6C,$07,$70,$02,$74,$02,$78,$02"
print "        defb    $7C,$02,$80,$11,$84,$11,$88,$11,$8C,$A6"
print "        defb    $90,$00,$94,$00,$98,$00,$9C,$00,$B0,$32"
print "        defb    $B4,$C0,$A4,$%02X,$A0,$%02X,$28,$F0,$05,$01,$28,$00" % (notes[0] >> 8, notes[0] & 0xff)
for note in notes[1:]:
    print "        defb    $1F,$03,$A4,$%02X,$A0,$%02X,$28,$F0,$05,$01,$28,$00" % (note >> 8, note & 0xff)
print "        defb    $00"
