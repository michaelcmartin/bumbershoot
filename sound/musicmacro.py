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
        if dots > 0:
            dot_mul = 1.0 + (((2 ** dots) - 1) / (2 ** dots))
        else:
            dot_mul = 1.0
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
            result.append((0, 14400.0 * dot_mul / (arg * tempo)))
        elif cmd in notes:
            if arg is None:
                arg = length
            result.append((notes[cmd] + 12*octave, 14400.0 * dot_mul / (arg * tempo)))
        else:
            print("Unknown command: ", cmd)
    return result


def oldstyle_text(notes, tempo):
    """Convert a list of note tuples into the old manual score format."""
    result = []
    step = 1800.0 / tempo
    names = ["c-","c#","d-","d#","e-","f-","f#","g-","g#","a-","a#","b-"]
    for (n, v) in notes:
        steps = int(round(v / step))
        if n == 0:
            result.append(f"r-0-{steps}")
        else:
            result.append(f"{names[(n-1)%12]}{(n-1)//12}-{steps}")
    return " ".join(result)


def generate_sample_music():
    """Pre-encoded songs used by various demo programs."""
    global bach_sample
    global banner_sample
    global nyan_sample

    # A simple adaptation of Bach's Minuet in G major
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

    # A chiptune rendition of The Star-Spangled Banner, adapted
    # from the PCjr port of John Jainschigg's "Portrait of Liberty"
    # program from Family Computing July 1984 issue
    voice1 = """t230l4o4g.e8l2ceg>l1cl4e.d8l2c<ef#l1g
                l4ggl2>e.d4c<l1bl4a.b8>l2cc<gec
                l4o4g.e8l2ceg>l1cl4e.d8l2c<ef#l1g
                l4ggl2>e.d4c<l1bl4a.b8>l2cc<gec
                l4>e.e8l2efgl1gl4fel2defl1f
                l2fe.d4c<b1l4a.b8>l2c<ef#l1gl2g
                >ccl4c<bl2aaa>l4defedcl2c<bl4ggl2>c.l4defl1g
                l4cdl2efdl1c"""
    voice2 = """t230o4p1p1l1al4<g#.g#8l2a>ccl1<b
                l4ggl2>c.<b4al1gl4ggl2>cc<b>cp2
                o4p1p1l1al4<g#.g#8l2a>ccl1<bl4ggl2>c.<b4al1g
                l4ggl2>cc<b>cp2<p1p1l2cef#l1gp2l2ga
                b>c.l4<baf#l1gl4f.g8l2eadl4gagfed
                l2ccl4ecl2ffc#l4d<a>defdl2ggl4ggl2c.l4<b>cdl1e
                l4fdl2cd<b>l1c"""
    voice3 = """t230o4p1l2c<bl1al4<b.b8>l2>c<a>dl1d
                p2l2>c.<l4gef#l1gl4f.g8l2eefp1
                o4p1l2c<bl1al4<b.b8>l2>c<a>dl1dp2l2>c.<l4gef#l1g
                l4f.g8l2eefp1l4c.c8l2cdel1el4dc<l2b>cdl1d
                l2dc.l4gef#g1l4f.d8l2eddl1gl2geel4gel2ffel4agagaal2gg
                l4gfl2e.l4dcdl1el4ag#l2gagl1e"""
    banner_sample = (voice1, voice2, voice3)

    # A chiptune rendition of the Nyancat song, itself adapted from
    # Vincent Johnson's arrangement, as seen improvised upon by Tom
    # Brier here: https://www.youtube.com/watch?v=dIivJwz5jL8
    voice1 = """T130O5L16P1P1
                G8A8EE8CD#DC8C8D8D#8D#DCDEG
                AEGDECDCE8G8AEGDECD#ED#DCD
                D#8CDEGDEDCD8C8D8
                G8A8EE8CD#DC8C8D8D#8D#DCDEG
                AEGDECDCE8G8AEGDECD#ED#DCD
                D#8CDEGDEDCD8C8D8
                C8<GA>C8<GA>CDECFEFG
                C8C8<GA>C<G>FEDC<GEFG>
                C8<GA>C8<GA>CCDEC<GAG>
                C8C<B>C<GA>CFEFGC8<B8>
                C8<GA>C8<GA>CDECFEFG
                C8C8<GA>C<G>FEDC<GEFG>
                C8<GA>C8<GA>CCDEC<GAG>
                C8C<B>C<GA>CFEFGC8D8"""
    voice2 = """T130O6L16EFG8>C8<EFG>CDED<B>C8
                <G8EFG8>C8D<B>CDFEFD
                L8O3F>A<G>G<C>A<A>A<D>F<G>G<C>G<E>A#<
                F>A<G>G<C>A<A>A<D>F<G>G<CDD#E
                F>A<G>G<C>A<A>A<D>F<G>G<C>G<E>A#<
                F>A<G>G<C>A<A>A<D>F<G>G<CDD#E
                F>A<C>A<E>G<A>G<D>A<A>A<C>G<E>G<
                F>A<C>A<E>G<A>G<D>A<A>A<CDEE
                F>A<C>A<E>G<A>G<D>A<A>A<C>G<E>G<
                F>A<C>A<E>G<A>G<D>A<A>A<CDD#E"""
    voice3 = """T130O3P1P1L8
                A>FP8DP8D#P8G<F#>C<F>FP8EP8E
                <A>FP8DP8D#P8G<F#>CFF<EFF#G
                A>FP8DP8D#P8G<F#>C<F>FP8EP8E
                <A>FP8DP8D#P8G<F#>CFF<EFF#G
                A>FP8FP8FP8F<F>FP8F<E>E<G>C
                <A>FP8FP8EP8E<F>FP8F<EFGG#
                A>FP8FP8FP8F<F>FP8F<E>E<G>C
                <A>FP8FP8EP8E<F>FP8F<EFF#G"""
    nyan_sample = (voice1, voice2, voice3)

generate_sample_music()
