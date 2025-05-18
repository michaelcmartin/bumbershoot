Z80OBJS=8k_dac.bin fm_mus.bin psg80.bin

all: hello.smd bumberlogo.smd sprcont.smd cca.smd


clean:
	rm -f *.s37 *.smd *.bin

tidy:
	rm -f *.s37 *.bin

hello.s37: reset.s res/sinestra.bin
bumberlogo.s37: reset.s logo.s 8k_dac.s 8k_dac.bin
bumberlogo.s37: res/logogfx.bin res/bumbersong.bin
cca.s37: reset.s fakecga.s logo.s joystick.s xorshift.s 8k_dac.s 8k_dac.bin
cca.s37: ccamain.s res/logogfx.bin res/bumbersong.bin simplefm.s fm_mus.bin
sprcont.s37: reset.s text.s joystick.s psg.s psg80.bin res/sinestra.bin
fm_mus.bin: res/bachsong.bin
psg80.bin: res/nyansong.bin

$(Z80OBJS): %.bin: %.asm
	asmx -C z80 -w -e -b -o $@ $<

%.s37: %.s
	asmx -C 68000 -w -e -s37 -o $@ $<

%.smd: %.s37
	tools/srec2smd.py $< $@
