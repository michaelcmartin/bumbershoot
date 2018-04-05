all: hello.smd bumberlogo.smd sprcont.smd cca.smd

clean:
	rm -f *.s37 *.smd *.bin *.obj *.sym *.lst *.map *.s80 *.hex

tidy:
	rm -f *.s37 *.bin *.obj *.sym *.map *.s80 *.hex

hello.s37: reset.s sinestra.s
bumberlogo.s37: reset.s logo.s 8k_dac.s 8k_dac.s80
bumberlogo.s37: logogfx.hex bumbersong.hex
cca.s37: reset.s fakecga.s logo.s 8k_dac.s 8k_dac.s80
cca.s37: logogfx.hex bumbersong.hex
sprcont.s37: reset.s sinestra.s text.s joystick.s psg.s psg80.s80

%.bin: %.asm
	z80asm -b $<

%.s80: %.bin
	od -An -t x1 -v < $< | sed 's/^/        HEX     /' > $@

%.hex: res/%.raw
	od -An -t x1 -v < $< | sed 's/^/        HEX     /' > $@

%.s37: %.s
	asm68k -w -e -s37 -o $@ $<

%.lst: %.s
	asm68k -w -e -l $@ $<

%.smd: %.s37
	tools/srec2smd.py $< $@
