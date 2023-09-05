OBJS = snes_init.o logo.o pbmp.o lz4dec.o
TOOLS = makelogo make_gfx pbmpconv lz4_unframe
BINARIES = logo.smc pbmp.smc

all: $(BINARIES)

logo.smc: snes_init.o logo.o lorom128.cfg
	ld65 -C lorom128.cfg -o logo.smc snes_init.o logo.o

pbmp.smc: snes_init.o pbmp.o lorom128f.cfg
	ld65 -C lorom128f.cfg -o pbmp.smc snes_init.o pbmp.o

clean:
	rm -f $(BINARIES) $(OBJS) $(TOOLS) res/*.bin

$(OBJS): %.o: %.s
	ca65 $<

res/bumberlogo.bin: makelogo res/orig/logosnes.png
	cd res && ../makelogo orig/logosnes.png

res/bumberpal.bin: makelogo res/orig/logosnes.png
	cd res && ../makelogo orig/logosnes.png

res/ancillary.bin: make_gfx res/font_1bpp.bin
	cd res && ../make_gfx

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

logo.o: res/bumberlogo.bin res/bumberpal.bin
pbmp.o: res/bumberpal.bin res/pbmp_0.bin res/pbmp_1.bin res/ancillary.bin
