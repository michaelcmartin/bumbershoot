OBJS = snes_init.o \
       logo.o \
       pbmpmain.o \
       soundtest.o \
       ccamain.o cca.o \
       audio.o lz4dec.o pbmp.o xss.o xs16.o
SPCOBJS = spc_digi.bin spc_mus.bin
TOOLS = makelogo make_gfx pbmpconv lz4_unframe snes_checksum
BINARIES = logo.smc pbmp.smc soundtest.smc cca.smc

all: $(BINARIES)

logo.smc: snes_init.o logo.o lorom128.cfg
	ld65 -C lorom128.cfg -o logo.smc snes_init.o logo.o

pbmp.smc: snes_init.o pbmpmain.o pbmp.o lorom128f.cfg
	ld65 -C lorom128f.cfg -o pbmp.smc snes_init.o pbmpmain.o pbmp.o

soundtest.smc: snes_init.o soundtest.o audio.o lorom128.cfg
	ld65 -C lorom128.cfg -o soundtest.smc snes_init.o soundtest.o audio.o

cca.smc: snes_init.o ccamain.o cca.o audio.o lz4dec.o pbmp.o xs16.o lorom64f.cfg
	ld65 -C lorom64f.cfg -o cca.smc snes_init.o ccamain.o cca.o audio.o lz4dec.o pbmp.o xs16.o

clean:
	rm -f $(BINARIES) $(OBJS) $(SPCOBJS) $(TOOLS) res/*.bin

$(OBJS): %.o: %.s
	ca65 $<

$(SPCOBJS): %.bin: %.s
	spcasm -f plain $< $@

res/bumberlogo.bin: makelogo res/orig/logosnes.png
	cd res && ../makelogo orig/logosnes.png

res/bumberpal.bin: makelogo res/orig/logosnes.png
	cd res && ../makelogo orig/logosnes.png

res/ancillary.bin: make_gfx res/font_1bpp.bin
	cd res && ../make_gfx

res/lz4gfx.bin: res/ancillary.bin res/bumberlogo.bin lz4_unframe
	cd res && cat ancillary.bin bumberlogo.bin > bulk.bin && lz4 bulk.bin && ../lz4_unframe bulk.bin.lz4 && mv compressed.bin lz4gfx.bin && rm bulk.bin bulk.bin.lz4

res/lz4mus.bin: spc_mus.bin ../sound/musicmacro.py support/snesbach.py lz4_unframe
	python3 support/snesbach.py spc_mus.bin bulk.bin && lz4 bulk.bin && ./lz4_unframe bulk.bin.lz4 && mv compressed.bin res/lz4mus.bin && rm bulk.bin bulk.bin.lz4

res/font_1bpp.bin: ../asm/fonts/sinestra.s
	ophis -o res/font_1bpp.bin ../asm/fonts/sinestra.s

res/pbmp_0.bin: pbmpconv res/orig/pbmp_0.png res/bumberpal.bin
	cd res && ../pbmpconv orig/pbmp_0.png pbmp_0.bin

res/pbmp_1.bin: pbmpconv res/orig/pbmp_1.png res/bumberpal.bin
	cd res && ../pbmpconv orig/pbmp_1.png pbmp_1.bin

make_gfx: support/make_gfx.c
	gcc -o make_gfx -I../win32 support/make_gfx.c -lm

makelogo: support/makelogo.c
	gcc -o makelogo -I../win32 support/makelogo.c -lm

pbmpconv: support/pbmpconv.c
	gcc -o pbmpconv -I../win32 support/pbmpconv.c -lm

lz4_unframe: support/lz4_unframe.c
	gcc -o lz4_unframe support/lz4_unframe.c

snes_checksum: support/snes_checksum.c
	gcc -o snes_checksum support/snes_checksum.c

logo.o: res/bumberlogo.bin res/bumberpal.bin
pbmpmain.o: res/ancillary.bin res/bumberpal.bin res/pbmp_0.bin res/pbmp_1.bin
ccamain.o: res/bumberpal.bin res/lz4gfx.bin res/lz4mus.bin spc_digi.bin
soundtest.o: res/bumbershoot.brr spc_digi.bin spc_mus.bin
