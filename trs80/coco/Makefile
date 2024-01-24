TOOLS = cococas lz4_unframe
BINARIES = hello.bin charmap.bin bumber.bin res/bumberlz4.bin
CASSETTES = hello.cas charmap.cas bumber.cas

all: $(CASSETTES)

hello.cas: cococas hello.bin
	./cococas hello.bin 1200 1210

charmap.cas: cococas charmap.bin
	./cococas charmap.bin 1200

bumber.cas: cococas bumber.bin
	./cococas bumber.bin 4000

clean:
	rm -f $(CASSETTES) $(BINARIES) $(TOOLS)

cococas: support/cococas.c
	$(CC) -o $@ -O2 $<

lz4_unframe: ../../snes/support/lz4_unframe.c
	$(CC) -o $@ -O2 $<

res/bumberlz4.bin: lz4_unframe res/bumber_gfx.bin
	cd res && lz4 bumber_gfx.bin && ../lz4_unframe bumber_gfx.bin.lz4 && mv compressed.bin bumberlz4.bin && rm bumber_gfx.bin.lz4

%.bin: %.s
	asm6809 -o $@ $<

bumber.bin: lz4dec.s res/bumberlz4.bin
