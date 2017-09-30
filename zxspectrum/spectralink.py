#!/usr/bin/python

import sys

def encode(n):
    return chr(n & 0xff) + chr((n >> 8) & 0xff)

def encode_basic_number(n):
    return str(n) + "\x0e\x00\x00" + encode(n) + "\x00"

def create_basic_line(line, text):
    ls = encode(line)
    return ls[1]+ls[0]+encode(len(text)+1)+text+"\x0d"

def add_parity(s, data):
    if data:
        x = 0xff
    else:
        x = 0
    for c in s:
        x ^= ord(c)
    if data:
        return chr(0xff) + s + chr(x)
    else:
        return chr(0x00) + s + chr(x)

def create_loader_binary(load_addr, start_addr, autorun):
    prog = create_basic_line(10, "\xf9\xc0"+encode_basic_number(start_addr))
    prog += create_basic_line(96, "\xec"+encode_basic_number(99))
    prog += create_basic_line(97, "\xfd"+encode_basic_number(load_addr-1)+":\xef\"\" \xaf")
    if autorun:
        prog += create_basic_line(98, "\xf7")
    return prog

def create_tape (name, data, load_addr, start_addr, autorun):
    tzx = "ZXTape!\x1a\x01\x14"
    loader = create_loader_binary(load_addr, start_addr, autorun)
    dataname = (name[:7]+"/ML"+(" " * 10))[:10]
    name = (name + (" " * 10))[:10]
    tzx += "\x10\xe8\x03\x13\x00" + add_parity("\x00" + name + encode(len(loader)) + encode(97) + encode(len(loader)), False)
    tzx += "\x10\xe8\x03" + encode(len(loader)+2) + add_parity(loader, True)
    tzx += "\x10\xe8\x03\x13\x00" + add_parity("\x03" + dataname + encode(len(data)) + encode(load_addr) + encode(0x8000), False)
    tzx += "\x10\xe8\x03" + encode(len(data)+2) + add_parity(data, True)
    return tzx

if __name__=="__main__":
    name = sys.argv[1]+".tzx"
    load_addr = int(sys.argv[2],16)
    if len(sys.argv) > 3:
        start_addr = int(sys.argv[3],16)
    else:
        start_addr = load_addr
    tzx = create_tape(name[:name.index(".")], file(sys.argv[1]).read(), load_addr, start_addr, True)
    out = file(name, "wb")
    out.write(tzx)
    out.close()

    
    

