#!/usr/bin/python

def parse(song):
    """Consume a string of music macro language and return a list of note tuples."""
    def digits_from(s, i):
        n = 0
        while s[i:i+1].isdigit():
            n += 1
            i += 1
        return n
    notes = { 'c':   1,
              'c#':  2, 'c+':  2, 'd-':  2,
              'd':   3,
              'd#':  4, 'd+':  4, 'e-':  4,
              'e':   5,
              'f':   6,
              'f#':  7, 'f+':  7, 'g-':  7,
              'g':   8,
              'g#':  9, 'g+':  9, 'a-':  9,
              'a':  10,
              'a#': 11, 'a+': 11, 'b-': 11,
              'b':  12 }
    s = ''.join(c.lower() for c in song if not c.isspace())
    result = []
    octave = 4
    length = 4
    tempo = 100
    duty = 0.875
    i = 0
    while i < len(s):
        cmd = s[i]
        i += 1
        note=False
        if cmd in "abcdefg":
            note = True
            if i < len(s) and s[i:i+1] in "#+-":
                cmd += s[i]
                i += 1
        n = digits_from(s, i)
        arg = None
        dots = 0
        if n > 0:
            arg = int(s[i:i+n])
            i += n
        if note or cmd == 'p':
            while i < len(s) and s[i:i+1] == '.':
                dots += 1
                i += 1
        if cmd == 'o':
            if arg is not None:
                octave = arg
            else:
                print("Octave requires a value")
        elif cmd == 'l':
            if arg is not None:
                length = arg
            else:
                print("Default length requires a value")
        elif cmd == 't':
            if arg is not None:
                tempo = arg
            else:
                print("Tempo requires a value")
        elif cmd == '>':
            octave += 1
        elif cmd == '<':
            octave -= 1
        elif cmd == 'p':
            if arg is None:
                arg = length
            result.append((0, 14400.0 * (1.5 ** dots) / (arg * tempo)))
        elif cmd in notes:
            if arg is None:
                arg = length
            result.append((notes[cmd] + 12*octave, 14400.0 * (1.5 ** dots) / (arg * tempo)))
        else:
            print("Unknown command: ", cmd)
    return result

def generate_sample_music():
    global bach_sample
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

    bach_sample = (voice1, voice2)

generate_sample_music()
