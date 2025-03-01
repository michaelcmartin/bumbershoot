#!/usr/bin/env python

# A Chiptune rendition of the Nyancat song, itself adapted from
# Vincent Johnson's arrangement, as seen improvised upon by Tom
# Brier here: https://www.youtube.com/watch?v=dIivJwz5jL8

nyan = ["""r-0-32

g-5-2 a-5-2 e-5-1 e-5-2 c-5-1 d#5-1 d-5-1 c-5-2 c-5-2 d-5-2
d#5-2 d#5-1 d-5-1 c-5-1 d-5-1 e-5-1 g-5-1
a-5-1 e-5-1 g-5-1 d-5-1 e-5-1 c-5-1 d-5-1 c-5-1
e-5-2 g-5-2 a-5-1 e-5-1 g-5-1 d-5-1
e-5-1 c-5-1 d#5-1 e-5-1 d#5-1 d-5-1 c-5-1 d-5-1
d#5-2 c-5-1 d-5-1 e-5-1 g-5-1 d-5-1 e-5-1 d-5-1 c-5-1 d-5-2 c-5-2 d-5-2

g-5-2 a-5-2 e-5-1 e-5-2 c-5-1 d#5-1 d-5-1 c-5-2 c-5-2 d-5-2
d#5-2 d#5-1 d-5-1 c-5-1 d-5-1 e-5-1 g-5-1
a-5-1 e-5-1 g-5-1 d-5-1 e-5-1 c-5-1 d-5-1 c-5-1
e-5-2 g-5-2 a-5-1 e-5-1 g-5-1 d-5-1
e-5-1 c-5-1 d#5-1 e-5-1 d#5-1 d-5-1 c-5-1 d-5-1
d#5-2 c-5-1 d-5-1 e-5-1 g-5-1 d-5-1 e-5-1 d-5-1 c-5-1 d-5-2 c-5-2 d-5-2

c-5-2 g-4-1 a-4-1 c-5-2 g-4-1 a-4-1
c-5-1 d-5-1 e-5-1 c-5-1 f-5-1 e-5-1 f-5-1 g-5-1
c-5-2 c-5-2 g-4-1 a-4-1 c-5-1 g-4-1
f-5-1 e-5-1 d-5-1 c-5-1 g-4-1 e-4-1 f-4-1 g-4-1
c-5-2 g-4-1 a-4-1 c-5-2 g-4-1 a-4-1
c-5-1 c-5-1 d-5-1 e-5-1 c-5-1 g-4-1 a-4-1 g-4-1
c-5-2 c-5-1 b-4-1 c-5-1 g-4-1 a-4-1 c-5-1
f-5-1 e-5-1 f-5-1 g-5-1 c-5-2 b-4-2

c-5-2 g-4-1 a-4-1 c-5-2 g-4-1 a-4-1
c-5-1 d-5-1 e-5-1 c-5-1 f-5-1 e-5-1 f-5-1 g-5-1
c-5-2 c-5-2 g-4-1 a-4-1 c-5-1 g-4-1
f-5-1 e-5-1 d-5-1 c-5-1 g-4-1 e-4-1 f-4-1 g-4-1
c-5-2 g-4-1 a-4-1 c-5-2 g-4-1 a-4-1
c-5-1 c-5-1 d-5-1 e-5-1 c-5-1 g-4-1 a-4-1 g-4-1
c-5-2 c-5-1 b-4-1 c-5-1 g-4-1 a-4-1 c-5-1
f-5-1 e-5-1 f-5-1 g-5-1 c-5-2 d-5-2""",
        """e-6-1 f-6-1 g-6-2 c-7-2 e-6-1 f-6-1
g-6-1 c-7-1 d-7-1 e-7-1 d-7-1 b-6-1 c-7-2
g-6-2 e-6-1 f-6-1 g-6-2 c-7-2
d-7-1 b-6-1 c-7-1 d-7-1 f-7-1 e-7-1 f-7-1 d-7-1

f-3-2 a-4-2 g-3-2 g-4-2 c-3-2 a-4-2 a-3-2 a-4-2
d-3-2 f-4-2 g-3-2 g-4-2 c-3-2 g-4-2 e-3-2 a#4-2
f-3-2 a-4-2 g-3-2 g-4-2 c-3-2 a-4-2 a-3-2 a-4-2
d-3-2 f-4-2 g-3-2 g-4-2 c-3-2 d-3-2 d#3-2 e-3-2

f-3-2 a-4-2 g-3-2 g-4-2 c-3-2 a-4-2 a-3-2 a-4-2
d-3-2 f-4-2 g-3-2 g-4-2 c-3-2 g-4-2 e-3-2 a#4-2
f-3-2 a-4-2 g-3-2 g-4-2 c-3-2 a-4-2 a-3-2 a-4-2
d-3-2 f-4-2 g-3-2 g-4-2 c-3-2 d-3-2 d#3-2 e-3-2

f-3-2 a-4-2 c-3-2 a-4-2 e-3-2 g-4-2 a-3-2 g-4-2
d-3-2 a-4-2 a-3-2 a-4-2 c-3-2 g-4-2 e-3-2 g-4-2
f-3-2 a-4-2 c-3-2 a-4-2 e-3-2 g-4-2 a-3-2 g-4-2
d-3-2 a-4-2 a-3-2 a-4-2 c-3-2 d-3-2 e-3-2 e-3-2

f-3-2 a-4-2 c-3-2 a-4-2 e-3-2 g-4-2 a-3-2 g-4-2
d-3-2 a-4-2 a-3-2 a-4-2 c-3-2 g-4-2 e-3-2 g-4-2
f-3-2 a-4-2 c-3-2 a-4-2 e-3-2 g-4-2 a-3-2 g-4-2
d-3-2 a-4-2 a-3-2 a-4-2 c-3-2 d-3-2 d#3-2 e-3-2""",
        """r-0-32

a-3-2 f-4-2 r-0-2 d-4-2 r-0-2 d#4-2 r-0-2 g-4-2
f#3-2 c-4-2 f-3-2 f-4-2 r-0-2 e-4-2 r-0-2 e-4-2
a-3-2 f-4-2 r-0-2 d-4-2 r-0-2 d#4-2 r-0-2 g-4-2
f#3-2 c-4-2 f-4-2 f-4-2 e-3-2 f-3-2 f#3-2 g-3-2

a-3-2 f-4-2 r-0-2 d-4-2 r-0-2 d#4-2 r-0-2 g-4-2
f#3-2 c-4-2 f-3-2 f-4-2 r-0-2 e-4-2 r-0-2 e-4-2
a-3-2 f-4-2 r-0-2 d-4-2 r-0-2 d#4-2 r-0-2 g-4-2
f#3-2 c-4-2 f-4-2 f-4-2 e-3-2 f-3-2 f#3-2 g-3-2

a-3-2 f-4-2 r-0-2 f-4-2 r-0-2 f-4-2 r-0-2 f-4-2
f-3-2 f-4-2 r-0-2 f-4-2 e-3-2 e-4-2 g-3-2 c-4-2
a-3-2 f-4-2 r-0-2 f-4-2 r-0-2 e-4-2 r-0-2 e-4-2
f-3-2 f-4-2 r-0-2 f-4-2 e-3-2 f-3-2 g-3-2 g#3-2

a-3-2 f-4-2 r-0-2 f-4-2 r-0-2 f-4-2 r-0-2 f-4-2
f-3-2 f-4-2 r-0-2 f-4-2 e-3-2 e-4-2 g-3-2 c-4-2
a-3-2 f-4-2 r-0-2 f-4-2 r-0-2 e-4-2 r-0-2 e-4-2
f-3-2 f-4-2 r-0-2 f-4-2 e-3-2 f-3-2 f#3-2 g-3-2"""]


def textdump_z88dk(result, loop_point):
    i = 0
    val = ""
    for byt in result:
        if i % 16 == 0 or i == loop_point:
            if i == 0:
                val += 'song:   '
            elif i == loop_point:
                val += '\nsegno:  '
                i = 0
                loop_point = -1
            else:
                val += '\n        '
            val += 'defb    '
        else:
            val += ','
        val += '$%02x' % byt
        i += 1
    return val


notes = { 'c-':  1,
          'c#':  2,
          'd-':  3,
          'd#':  4,
          'e-':  5,
          'f-':  6,
          'f#':  7,
          'g-':  8,
          'g#':  9,
          'a-': 10,
          'a#': 11,
          'b-': 12,
          'r-':  0 }

def psg_val(hz):
    return int(round(3580000.0 / (32 * hz)))

def psg_pokes(val, voice):
    if val == 0:
        return [0]
    return [(val & 0x0f) | 0x80 | (voice << 5), val >> 4]

def note_val(octave, freq):
    if freq == 0:
        # Rest
        return 0
    hz = 440.0
    val = 4 * 12 + notes["a-"]
    target = octave * 12 + freq
    step = 2.0 ** (1.0 / 12)
    result = psg_val(hz * (step ** (target - val)))
    if result >= 1024:
        raise ValueError("Illegal note %d-%d -> %d" % (freq, octave, result))
    return result

song = []
for voice in nyan:
    track = []
    for note in voice.split():
        freq = notes[note[:2]]
        (octave, duration) = [int(x) for x in note[2:].split('-')]
        track.append(note_val(octave, freq))
        if duration > 1:
            track.extend([0] * (duration-1))
    song.append(track)

song = list(zip(*song))
result = []
i = 0
loop_point = None
while i < len(song):
    frame = song[i]
    if loop_point is None and frame[0] != 0:
        loop_point = len(result)
    duration = 1
    i += 1
    while i < len(song) and song[i] == (0, 0, 0):
        duration += 1
        i += 1
    result.append(duration * 7)
    for j in range(len(frame)):
        result.extend(psg_pokes(frame[j], j))
result.append(0) # end of song

# print(textdump_z88dk(result, loop_point))
out = open("nyansong.bin", "wb")
out.write(bytes(result))
out.close()
print(f"segno = song + {loop_point}")
