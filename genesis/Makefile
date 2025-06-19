BINARIES = hello.bin bumberlogo.bin sprcont.bin cca.bin
Z80OBJS  = 8k_dac.bin fm_mus.bin psg80.bin
TOOLS    = lz4_unframe makelogo smdfix
PROCGEN  = res/logogfx.bin res/font1bpp.bin

all: $(BINARIES)

$(BINARIES): %.bin: %.s smdfix
	asmx -C 68000 -w -e -b -o $@ $< && ./smdfix $@

$(Z80OBJS): %.bin: %.asm
	asmx -C z80 -w -e -b -o $@ $<

res/logogfx.bin: makelogo lz4_unframe res/logo_gen.png res/font_1bpp.bin
	cd res && ../makelogo logo_gen.png font_1bpp.bin && lz4 --best logoraw.bin && ../lz4_unframe logoraw.bin.lz4 && mv compressed.bin logogfx.bin && rm logoraw.bin logoraw.bin.lz4

res/font_1bpp.bin: ../asm/fonts/sinestra.s
	ophis -o $@ $<

lz4_unframe: ../snes/support/lz4_unframe.c
	gcc -o $@ $<

makelogo: tools/makelogo.c
	gcc -O2 -I../win32 -o $@ $< -lm

smdfix: tools/smdfix.c
	gcc -O2 -o $@ $<

clean:
	rm -f $(BINARIES) $(Z80OBJS) $(TOOLS)

tidy:
	rm -f $(Z80OBJS) $(TOOLS)

reallyclean:
	rm -f $(BINARIES) $(Z80OBJS) $(TOOLS) res/logogfx.bin

hello.bin: reset.s res/sinestra.bin
bumberlogo.bin: reset.s logo.s 8k_dac.s lz4dec.s 8k_dac.bin
bumberlogo.bin: res/logogfx.bin res/bumbersong.bin
cca.bin: reset.s fakecga.s logo.s joystick.s xorshift.s 8k_dac.s 8k_dac.bin
cca.bin: ccamain.s res/logogfx.bin res/bumbersong.bin simplefm.s fm_mus.bin
cca.bin: lz4dec.s ccatitle.s
sprcont.bin: reset.s text.s joystick.s psg.s psg80.bin res/sinestra.bin
fm_mus.bin: res/bachsong.bin
psg80.bin: res/nyansong.bin
