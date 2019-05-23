#!/usr/bin/python
import sys

def encode(n):
    return bytearray([n & 0xff, (n >> 8) & 0xff])

def encode_basic_number(n):
    return str(n).encode("iso8859-1") + b"\x0e\x00\x00" + encode(n) + b"\x00"

def create_basic_line(line, text):
    ls = encode(line)
    return bytearray([ls[1], ls[0]])+encode(len(text)+1)+text+b"\x0d"

def add_parity(s, data):
    if data:
        x = 0xff
    else:
        x = 0
    for c in s:
        x ^= c
    if data:
        return b'\xff' + s + bytearray([x])
    else:
        return b'\x00' + s + bytearray([x])

def create_loader_binary(load_addr, start_addr, autorun):
    prog = create_basic_line(10, b"\xf9\xc0"+encode_basic_number(start_addr))
    prog += create_basic_line(96, b"\xec"+encode_basic_number(99))
    prog += create_basic_line(97, b"\xfd"+encode_basic_number(load_addr-1)+b":\xef\"\" \xaf")
    if autorun:
        prog += create_basic_line(98, b"\xf7")
    return prog

def create_tape (name, data, load_addr, start_addr, autorun):
    tzx = bytearray(b"ZXTape!\x1a\x01\x14")
    loader = create_loader_binary(load_addr, start_addr, autorun)
    dataname = (name[:7]+b"/ML"+(b" " * 10))[:10]
    name = (name + (b" " * 10))[:10]
    tzx += b"\x10\xe8\x03\x13\x00" + add_parity(bytearray([0]) + name + encode(len(loader)) + encode(97) + encode(len(loader)), False)
    tzx += b"\x10\xe8\x03" + encode(len(loader)+2) + add_parity(loader, True)
    tzx += b"\x10\xe8\x03\x13\x00" + add_parity(bytearray([3]) + dataname + encode(len(data)) + encode(load_addr) + encode(0x8000), False)
    tzx += b"\x10\xe8\x03" + encode(len(data)+2) + add_parity(data, True)
    return tzx

if __name__=="__main__":
    name = sys.argv[1]+".tzx"
    load_addr = int(sys.argv[2],16)
    if len(sys.argv) > 3:
        start_addr = int(sys.argv[3],16)
    else:
        start_addr = load_addr
    tzx = create_tape(bytearray(name[:name.index(".")].encode("iso8859-1")),
                      bytearray(open(sys.argv[1], "rb").read()),
                      load_addr, start_addr, True)
    out = open(name, "wb")
    out.write(tzx)
    out.close()

    
    

