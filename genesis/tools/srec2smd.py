#!/usr/bin/env python

import sys

# Throws if it's handed a sufficiently non-SREC line
def s_line(s):
    if s[:2] == 'S1':
        start = 8
    elif s[:2] == 'S2':
        start = 10
    elif s[:2] == 'S3':
        start = 12
    else:
        return None
    count = int(s[2:4],16)
    addr = int(s[4:start],16)
    data = bytearray([int(s[i*2+2:i*2+4], 16) for i in range(count+1)])
    if sum(data[:-1]) & 0xff != data[-1] ^ 0xff:
        raise ValueError("Checksum mismatch: " + s + repr((sum(data[:-1]) & 0xff, data[-1]^0xff)))
    return (addr, data[start//2-1:-1])


def make_smd(rom):
    chunksize = 16384
    # This should never happen, but just in case
    while len(rom) % chunksize != 0:
        self.rom.append(0xff)
    # SMD Header
    smd = bytearray([len(rom) // chunksize])
    smd += b"\x03\x00\x00\x00\x00\x00\x00\xaa\xbb\x05\x00\x00\x00\x00\x00"
    smd += b"\x00" * 0x1F0
    i = 0
    while i < len(rom):
        for j in range(chunksize // 2):
            smd.append(rom[i+j*2+1])
        for j in range(chunksize // 2):
            smd.append(rom[i+j*2])
        i += chunksize
    return smd

class Rom(object):
    def __init__(self, chunk_size=16384, fill_byte=255):
        self.chunk_size = chunk_size
        self.fill_byte = fill_byte
        self.rom = bytearray(chunk_size)
        for i in range(chunk_size):
            self.rom[i] = fill_byte
    def consume(self, s):
        try:
            dat = s_line(s)
            if dat is not None:
                (addr, bits) = dat
                while addr + len(bits) >= len(self.rom):
                    self.rom.extend([self.fill_byte] * self.chunk_size)
                for byt in bits:
                    self.rom[addr] = byt
                    addr += 1
        except:
            # Bad SREC line
            raise
    def fix_sega_header(self):
        lastbyte = len(self.rom)-1
        self.rom[0x1a4] = (lastbyte >> 24) & 0xff
        self.rom[0x1a5] = (lastbyte >> 16) & 0xff
        self.rom[0x1a6] = (lastbyte >>  8) & 0xff
        self.rom[0x1a7] = (lastbyte      ) & 0xff
        csum = 0
        i = 0x200
        while i <= lastbyte:
            csum += self.rom[i]*256 + self.rom[i+1]
            i += 2
        csum &= 0xffff
        self.rom[0x18e] = (csum >> 8) & 0xff
        self.rom[0x18f] = (csum     ) & 0xff
        # print "ROM end is %08X" % lastbyte
        # print "ROM checksum is %04X" % csum


cart = Rom()
for line in open(sys.argv[1]).readlines():
    cart.consume(line)
cart.fix_sega_header()

outfile = open(sys.argv[2], "wb")
if sys.argv[2].endswith(".smd"):
    outfile.write(make_smd(cart.rom))
    outfile.close()
    outfile = open(sys.argv[2][:-3] + "bin", "wb")

outfile.write(cart.rom)
outfile.close()
