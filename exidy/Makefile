TOOLS = lz4_unframe
BINARIES = lightsout.bin res/lightslz4.bin

lightsout.bin: lightsout.asm res/lightslz4.bin
	sjasm lightsout.asm $@

res/lightslz4.bin: res/lightsoutgfx.bin lz4_unframe
	cd res && lz4 --best lightsoutgfx.bin && ../lz4_unframe lightsoutgfx.bin.lz4 && mv compressed.bin lightslz4.bin && rm lightsoutgfx.bin.lz4

lz4_unframe: ../snes/support/lz4_unframe.c
	$(CC) -o $@ -O2 $<

clean:
	rm -f $(BINARIES) $(TOOLS)

lightsout.bin: ../asm/lightscore/lightsz80.asm ../asm/lz4core/lz4u_z80.asm
