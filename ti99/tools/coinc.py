#!/bin/env python

data=[0x03,0x0F,0x1F,0x3F,0x7F,0x7F,0xFF,0xFF,
      0xFF,0xFE,0x7C,0x78,0x30,0x00,0x00,0x00,
      0xC0,0xF0,0xF8,0xF8,0xF0,0xE0,0xC0,0x80,
      0x80,0xC0,0x60,0x30,0x18,0x08,0x38,0x00]

def pixelize(b,zero='.',one='X'):
	return f"{b:08b}".replace('0',zero).replace('1',one)

obj = [[x for x in f"{pixelize(data[i])}{pixelize(data[i+16])}"] for i in range(15)]

h = len(obj)
w = len(obj[0])

space = [['.'] * (w * 2) for _ in range(h * 2)]
for y in range(h):
	for x in range(w):
		space[y + h][x + w] = obj[y][x]

def sprite_hit(y, x):
	global h, w, space
	if x < 0 or x >= len(space[0]): return False
	if y < 0 or y >= len(space): return False
	return space[y][x] == 'X'

adjacents = True
hits = []
for y in range(h * 2 + 1):
	row = []
	for x in range(w * 2 + 1):
		ok = False
		for cy in range(h):
			for cx in range(w):
				if obj[cy][cx] != 'X': continue
				if sprite_hit(cy + y, cx + x):
					ok = True
				if not adjacents: continue
				if sprite_hit(cy + y - 1, cx + x):
					ok = True
				if sprite_hit(cy + y + 1, cx + x):
					ok = True
				if sprite_hit(cy + y, cx + x - 1):
					ok = True
				if sprite_hit(cy + y, cx + x + 1):
					ok = True
		row.append(ok)
	hits.append(row)

for row in hits:
	line = ""
	for c in row:
		if c:
			line += 'X'
		else:
			line += '.'
	print(line)

encoding = bytearray([h * 2, w * 2, h, w])
n = 0
v = 0
for row in hits:
	for c in row:
		v *= 2
		n += 1
		if c: v += 1
		if n == 8:
			encoding.append(v)
			v = 0
			n = 0
if n > 0:
	while n < 8:
		v = v * 2 + 1
		n += 1
	encoding.append(v)

i = 0
while i < len(encoding):
	shard = encoding[i:i+8]
	print("\tBYTE\t" + ','.join([f">{x:02X}" for x in shard]))
	i += 8

