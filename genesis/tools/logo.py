#!/usr/bin/python

chars = " .XoO+@#$%&*=-"

pal = {" ": "#030405",
       ".": "#172633",
       "X": "#19344C",
       "o": "#304F6A",
       "O": "#54595D",
       "+": "#50718D",
       "@": "#3D6180",
       "#": "#6F8EA8",
       "$": "#9DA5AB",
       "%": "#99B4CB",
       "&": "#B5CCDF",
       "*": "#D6E7F5",
       "=": "#F0F6FA",
       "-": "#CAD4DD" }

for c in list(pal.keys()):
    v = pal[c]
    r = int(v[1:3], 16)
    g = int(v[3:5], 16)
    b = int(v[5:], 16)
    if r > 0xD1:
        r = 0xE
    else:
        r = ((r + 15) & 0xE0) >> 4
    if g > 0xD1:
        g = 0xE
    else:
        g = ((g + 15) & 0xE0) >> 4
    if b > 0xD1:
        b = 0xE
    else:
        b = ((b + 15) & 0xE0) >> 4
    pal[c] = r | (g << 4) | (b << 8)

revmap = {}
finalpal = [0] * 16
i = 0
for c in chars:
    if pal[c] not in revmap:
        revmap[pal[c]] = i
        finalpal[i] = pal[c]
        i += 1

print("pal:    dc.w    $%s" % ",$".join(["%04X" % x for x in finalpal[:8]]))
print("        dc.w    $%s" % ",$".join(["%04X" % x for x in finalpal[8:]]))
print("\nlogo:")

logolines = []
active = False
for l in open("logo.xpm").readlines():
    if not active:
        if "pixels */" in l:
            active = True
    else:
        if '"' in l:
            raster = l[l.index('"') + 1:l.rindex('"')]
            raster = "  " + raster + "  "
            if len(raster) % 8 != 0:
                print("wat: ",len(raster))
            logolines.append(raster)

chars = []
w = len(logolines[0]) // 8
h = len(logolines) // 8
for y in range(h):
    char_row = logolines[y*8:y*8+8]
    for x in range(w):
        char = []
        for scanline in range(8):
            char.append(char_row[scanline][x*8:x*8+8])
        chars.append(char)

for char in chars:
    vals = []
    for scanline in char:
        v = 0
        for c in scanline:
            v <<= 4
            v |= revmap[pal[c]]
        vals.append("$%08X" % v)
    print("        dc.l    %s" % ",".join(vals[:4]))
    print("        dc.l    %s" % ",".join(vals[4:]))
print("logoend:")

