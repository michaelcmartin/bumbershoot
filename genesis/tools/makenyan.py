#!/usr/bin/env python

# Add the sound directory to pythonpath so we can import our music macros
import os.path
import sys

musicpath = os.path.dirname(os.path.realpath(sys.argv[0]))
sys.path.insert(0, os.path.join(musicpath, '..', '..', 'sound'))

import musicmacro

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

def note_val(note):
    if note == 0:
        # Rest
        return 0
    hz = 440.0
    val = 4 * 12 + notes["a-"]
    step = 2.0 ** (1.0 / 12)
    result = psg_val(hz * (step ** (note - val)))
    if result >= 1024:
        raise ValueError("Illegal note %d-%d -> %d" % (freq, octave, result))
    return result

song = []
duration_scale = (91 / 90) # Macro tempo is slightly off from original code
for voice in musicmacro.nyan_sample:
    track = []
    for (note, duration) in musicmacro.parse(voice):
        duration = int(duration * duration_scale)
        track.append(note_val(note))
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
    result.append(duration)
    for j in range(len(frame)):
        result.extend(psg_pokes(frame[j], j))
result.append(0) # end of song

# print(textdump_z88dk(result, loop_point))
out = open("nyansong.bin", "wb")
out.write(bytes(result))
out.close()
print(f"segno = song + {loop_point}")
