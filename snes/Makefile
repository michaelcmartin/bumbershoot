OBJS = snes_init.o logo.o
TOOLS = make_gfx
BINARIES = logo.smc

all: $(BINARIES)

logo.smc: snes_init.o logo.o lorom128.cfg
	ld65 -C lorom128.cfg -o logo.smc snes_init.o logo.o

clean:
	rm -f $(BINARIES) $(OBJS) $(TOOLS)

$(OBJS): %.o: %.s
	ca65 $<

bumberlogo.bin: make_gfx res/orig/logosnes.png
	cd res && ../make_gfx orig/logosnes.png

bumberpal.bin: make_gfx res/orig/logosnes.png
	cd res && ../make_gfx orig/logosnes.png

make_gfx: support/make_gfx.c
	gcc -o make_gfx -I../win32 support/make_gfx.c -lm

logo.o: bumberlogo.bin bumberpal.bin
