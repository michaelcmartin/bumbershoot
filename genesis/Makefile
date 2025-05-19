BINARIES = hello.bin bumberlogo.bin sprcont.bin cca.bin
Z80OBJS  = 8k_dac.bin fm_mus.bin psg80.bin
TOOLS    = smdfix

all: $(BINARIES)

$(BINARIES): %.bin: %.s smdfix
	asmx -C 68000 -w -e -b -o $@ $< && ./smdfix $@

$(Z80OBJS): %.bin: %.asm
	asmx -C z80 -w -e -b -o $@ $<

smdfix: tools/smdfix.c
	gcc -O2 -o $@ $<

clean:
	rm -f $(BINARIES) $(Z80OBJS) $(TOOLS)

tidy:
	rm -f $(Z80OBJS) $(TOOLS)

hello.bin: reset.s res/sinestra.bin
bumberlogo.bin: reset.s logo.s 8k_dac.s 8k_dac.bin
bumberlogo.bin: res/logogfx.bin res/bumbersong.bin
cca.bin: reset.s fakecga.s logo.s joystick.s xorshift.s 8k_dac.s 8k_dac.bin
cca.bin: ccamain.s res/logogfx.bin res/bumbersong.bin simplefm.s fm_mus.bin
sprcont.bin: reset.s text.s joystick.s psg.s psg80.bin res/sinestra.bin
fm_mus.bin: res/bachsong.bin
psg80.bin: res/nyansong.bin
