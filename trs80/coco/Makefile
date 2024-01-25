TOOLS = cococas conv_coco lz4_unframe
BINARIES = hello.bin charmap.bin bumber.bin res/bumberlz4.bin res/bumberwav.bin
CASSETTES = hello.cas charmap.cas bumber.cas

all: $(CASSETTES)

hello.cas: cococas hello.bin
	./cococas hello.bin 1200 1210

charmap.cas: cococas charmap.bin
	./cococas charmap.bin 1200

bumber.cas: cococas bumber.bin
	./cococas bumber.bin 3f00

clean:
	rm -f $(CASSETTES) $(BINARIES) $(TOOLS)

cococas: support/cococas.c
	$(CC) -o $@ -O2 $<

conv_coco: ../../sound/conv_coco.c ../../sound/wavefile.c ../../sound/wavefile.h
	$(CC) -o $@ -O2 -I../../sound ../../sound/conv_coco.c ../../sound/wavefile.c

lz4_unframe: ../../snes/support/lz4_unframe.c
	$(CC) -o $@ -O2 $<

res/bumberlz4.bin: lz4_unframe res/bumber_gfx.bin
	cd res && lz4 bumber_gfx.bin && ../lz4_unframe bumber_gfx.bin.lz4 && mv compressed.bin bumberlz4.bin && rm bumber_gfx.bin.lz4

res/bumberwav.bin: conv_coco ../../sound/bumbershoot.wav
	./conv_coco ../../sound/bumbershoot.wav res/bumberwav.bin

%.bin: %.s
	asm6809 -o $@ $<

bumber.bin: lz4dec.s res/bumberlz4.bin res/bumberwav.bin
