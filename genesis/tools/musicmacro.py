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
                print "Octave requires a value"
        elif cmd == 'l':
            if arg is not None:
                length = arg
            else:
                print "Default length requires a value"
        elif cmd == 't':
            if arg is not None:
                tempo = arg
            else:
                print "Tempo requires a value"
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
            print "Unknown command: ", cmd
    return result
