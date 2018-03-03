all: hello.smd bumberlogo.smd

clean:
	rm -f *.s37 *.smd

hello.s37: reset.s sinestra.s
bumberlogo.s37: reset.s logogfx.s

%.s37: %.s
	asm68k -w -e -s37 -o $@ $<

%.smd: %.s37
	tools/srec2smd.py $< $@
