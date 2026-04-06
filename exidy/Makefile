TOOLS = lz4_unframe sorctape
BINARIES = lightsout.bin res/lightslz4.bin
TAPES = lightsout.tape

all: $(TAPES)

lightsout.bin: lightsout.asm res/lightslz4.bin
	sjasm lightsout.asm $@

res/lightslz4.bin: res/lightsoutgfx.bin lz4_unframe
	cd res && lz4 --best lightsoutgfx.bin && ../lz4_unframe lightsoutgfx.bin.lz4 && mv compressed.bin lightslz4.bin && rm lightsoutgfx.bin.lz4

lz4_unframe: ../snes/support/lz4_unframe.c
	$(CC) -o $@ -O2 $<

sorctape: support/sorctape.c
	$(CC) -o $@ -O2 $<

%.tape: %.bin sorctape
	./sorctape $< $0100

clean:
	rm -f $(TAPES) $(BINARIES) $(TOOLS)

lightsout.bin: ../asm/lightscore/lightsz80.asm ../asm/lz4core/lz4u_z80.asm
