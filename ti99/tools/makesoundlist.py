#!/usr/bin/env python

# Add the sound directory to pythonpath so we can import our music macros
import os.path
import sys

musicpath = os.path.dirname(os.path.realpath(sys.argv[0]))
sys.path.insert(0, os.path.join(musicpath, '..', '..', 'sound'))

import musicmacro

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
        return []
    if val < 0:
        return [0x9F | (voice << 5)]
    return [(val & 0x0f) | 0x80 | (voice << 5), val >> 4, 0x94 | (voice << 5)]

def note_val(note):
    if note == 0:
        # Rest
        return 0
    hz = 440.0
    val = 2 * 12 + notes["a-"]
    step = 2.0 ** (1.0 / 12)
    result = psg_val(hz * (step ** (note - val)))
    if result >= 1024:
        raise ValueError("Illegal note %d -> %d" % (note, result))
    return result

def convert_song(voices):
    song = []
    for voice in voices:
        track = []
        t = 0
        for (note, duration) in musicmacro.parse(voice):
            note_on = int(t)
            note_off = int(t + (duration * 7/8))
            note_complete = int(t + duration)
            while len(track) <= note_complete:
                track.append(0)
            track[note_off] = -1
            track[note_on] = note_val(note)
            t += duration
        song.append(track)

    song = list(zip(*song))
    result = []
    i = 0
    while i < len(song):
        frame = song[i]
        duration = 1
        i += 1
        while i < len(song) and song[i] == (0, 0):
            duration += 1
            i += 1
        pokes = []
        for j in range(len(frame)):
            pokes.extend(psg_pokes(frame[j], j))
        if len(pokes) > 0:
            result.append(len(pokes))
            result.extend(pokes)
            result.append(duration)
    result.extend([4,0x9f,0xbf,0xdf,0xff,0]) # end of song
    return result

def convert(voices, outfilename):
    sound_list = convert_song(voices)
    out = open(outfilename, "wb")
    out.write(bytes(sound_list))
    out.close()

if __name__ == '__main__':
    for voices, fname in zip([musicmacro.bach_sample, *musicmacro.bach_sample_units],
                             ["minuet.bin", "minuet_a.bin", "minuet_b.bin"]):
        convert(voices, fname)
