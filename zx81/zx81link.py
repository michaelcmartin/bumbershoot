#!/usr/bin/python

import sys
import os.path

# These are reasonable defaults (lifted from the output of z88dk's
# app-maker), but we will be editing some of them in-place before
# writing them out. Values that *must* be filled in are set as None,
# but autorun and NTSC saves are edited in-place from otherwise
# reasonable defaults

sysvars = [ 0x00, 0x01, 0x00, None, None, None, None, None,
            None, 0x00, 0x00, None, None, None, None, 0x00,
            0x00, None, None, None, None, 0x00, 0x5d, 0x40,
            0x00, 0x02, 0x00, 0x00, 0xc1, 0xfd, 0xff, None,
            None, None, 0x00, 0x00, 0x00, 0x00, 0x00, 0x8d,
            0x0c, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xbc,
            0x21, 0x18, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x76, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x84, 0x20,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00 ];


# BASIC stub for the command 10 RAND USER 16528. Your binary should be org $4090.
basicstub4090 = [0x00, 0x0a, 0x0e, 0x00, 0xf9, 0xd4, 0x1d, 0x22,
                 0x21, 0x1e, 0x24, 0x7e, 0x8f, 0x01, 0x20, 0x00,
                 0x00, 0x76, 0xff]


def wrap(binary, compressed=False, autorun=False, ntsc=False):
    wrapped = "".join([chr(c) for c in basicstub4090]) + binary
    if compressed:
        display_file = '\x76' * 25
    else:
        display_file = '\x76' + ((('\x00' * 32) + '\x76') * 24)
    # Compute the various things we need.
    d_file = 16509+len(wrapped)
    df_cc = d_file + 1
    var_ptr = d_file + len(display_file)
    e_line = var_ptr + 1
    ch_add = e_line + 4
    stkbot = ch_add + 1
    stkend = stkbot
    if ntsc:
        margin = 31
    else:
        margin = 55
    if autorun:
        nxtlin = 16509
    else:
        nxtlin = d_file
    offsets = [3, 5, 7, 11, 13, 17, 19, 31, 32]
    values = [d_file, df_cc, var_ptr, e_line, ch_add, stkbot, stkend, margin, nxtlin]
    for v, o in zip(values, offsets):
        l = v & 0xff
        h = (v >> 8) & 0xff
        sysvars[o] = l
        sysvars[o+1] = h
    output = "".join([chr(c) for c in sysvars]) # Sysvars
    output += wrapped # The program itself
    output += display_file
    output += '\x80' # Variable area
    return output

if __name__ == "__main__":
    ntsc = False
    autorun = False
    compressed = False
    showHelp = False
    infile = None
    if len(sys.argv) < 2:
        showHelp = True
    for arg in sys.argv[1:]:
        if arg == '--autorun' or arg == '-a':
            autorun = True
        elif arg == '--ntsc' or arg == '-n':
            ntsc = True
        elif arg == '--compressed' or arg == '-c':
            compressed = True
        elif arg == '' or arg[0] == '-':
            showHelp = True
        else:
            infile = arg

    if infile is None:
        showHelp = True

    if showHelp:
        print "Usage:\n    %s [options] binfile\n\nOptions:" % sys.argv[0]
        print "    --autorun, -a       Program runs immediately on load"
        print "    --compressed, -c    Use compressed display file"
        print "    --ntsc, -n          Program acts as if saved on a TS1000"
        print "\nBinary linked should have $4090 as its origin."
        sys.exit(1)
    outfile = os.path.splitext(infile)[0] + ".P"
    output = wrap(file(infile, "rb").read(), ntsc=ntsc, compressed=compressed, autorun=autorun)
    of = file(outfile, "wb")
    of.write(output)
    of.close()
