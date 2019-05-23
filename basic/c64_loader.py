#!/usr/bin/python
from __future__ import print_function

import sys

def convert(fname, startline):
    prg = bytearray(open(fname, "rb").read())
    startaddr = prg[0] + 256 * prg[1]
    codes = prg[2:]
    print("%d rem for i=%d to %d:read a:poke i,a:next i" % (startline-1, startaddr, startaddr + len(codes) - 1))
    linenum = startline
    line = ""
    for n in codes:
        if line == "":
            nextitem = "%d data %d" % (linenum, n)
        else:
            nextitem = ",%d" % n
        if len(line) + len(nextitem) >= 80:
            print(line)
            linenum += 10
            line = "%d data %d" % (linenum, n)
        else:
            line += nextitem
    print(line)

if __name__ == '__main__':
    convert(sys.argv[1], 100)
