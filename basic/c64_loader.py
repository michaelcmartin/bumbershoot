#!/usr/bin/python

import sys

def convert(fname, startline):
    prg = file(fname, "rb").read()
    startaddr = ord(prg[0]) + 256 * ord(prg[1])
    codes = [ord(c) for c in prg[2:]]
    print "%d rem for i=%d to %d:read a:poke i,a:next i" % (startline-1, startaddr, startaddr + len(codes) - 1)
    linenum = startline
    line = ""
    for n in codes:
        if line == "":
            nextitem = "%d data %d" % (linenum, n)
        else:
            nextitem = ",%d" % n
        if len(line) + len(nextitem) >= 80:
            print line
            linenum += 10
            line = "%d data %d" % (linenum, n)
        else:
            line += nextitem
    print line

if __name__ == '__main__':
    convert(sys.argv[1], 100)
