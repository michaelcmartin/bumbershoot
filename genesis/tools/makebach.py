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

voice1 = """T120O3L8GB>DG<A>F#G4<G4G4GB>DG<A>F#G4<G4G4
L4O4EEE8G8DDD8G8CL8DC<B>C<A2.
O3L8GB>DG<A>F#G4<G4G4GB>DG<A>F#G4<G4G4
O4L8E4DC<BA>D4C<BAGL12AB>C<L4DF#G2.
O3L8GABAGF#G4E4E4>GF#EGF#EF#4<B4B4
O4L8GF#EGF#EL4F#<B>EL12F#GAL4<B>D#ED#8E8F#
O4L8G4GF#EDE4EDC<B>C4C<BAGF#4EF#D4
O3L4ADDBDD>CL8DC<B>C<A2.
O3L8GB>DG<A>F#G4<G4G4GB>DG<A>F#G4<G4G4
O4L8E4DC<BA>D4C<BAGABL4DF#G2."""

voice2 = """O2L8G2D4<GB>DGD<BG2>D4<GB>DGD<B
O2L4CGC<B>G<BA>F#GL8DEF#DEF#
O2L8G2D4<GB>DGD<BG2>D4<GB>DGD<B
O2L4CEG<B>DGCDDGD<G
O2L4ED#<B>E<BE>EGBL8<B>D#F#BF#D#
O2L4EGB<B>AGAB<B>E2.
O1L4B>DGCDE<AB>CD<AD
O2L8F#DF#DF#DGDGDGDF#4D4G4DEF#DEF#
O2L8G2D4<GB>DGD<BG2>D4<GB>DGD<B
O2L4CEG<B>DGC2DGD<G"""


notes = [(freq(n), v) for (n, v) in musicmacro.parse(voice1)]
print "        defb    $%02X,$21,$30,$71,$34,$0D,$38,$33,$3C,$01" % (int(notes[0][1]*7/8))
print "        defb    $40,$23,$44,$2D,$48,$26,$4C,$00,$50,$5F"
print "        defb    $54,$99,$58,$5F,$5C,$94,$60,$05,$64,$05"
print "        defb    $68,$05,$6C,$07,$70,$02,$74,$02,$78,$02"
print "        defb    $7C,$02,$80,$11,$84,$11,$88,$11,$8C,$A6"
print "        defb    $90,$00,$94,$00,$98,$00,$9C,$00,$B0,$32"
print "        defb    $B4,$C0,$A4,$%02X,$A0,$%02X,$28,$F0,$%02X,$01,$28,$00" % (notes[0][0] >> 8, notes[0][0] & 0xff, int(notes[0][1]) - int(notes[0][1]*7/8))
for note in notes[1:]:
    nl = int(note[1]*7/8)
    print "        defb    $%02X,$03,$A4,$%02X,$A0,$%02X,$28,$F0,$%02X,$01,$28,$00" % (nl, note[0] >> 8, note[0] & 0xff, note[1] - nl)
print "        defb    $00"
