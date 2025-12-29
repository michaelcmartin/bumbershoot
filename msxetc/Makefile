BINARIES = gallery.rom gallery.col gallery.sg vdpmodes.sg

all: $(BINARIES)

clean:
	rm -f $(BINARIES) gallery.lst vdpmodes.lst res/tms9918.bin

%.sg: sg1000/%.asm
	sjasm $< $@

%.rom: msx/%.asm
	sjasm $< $@

%.col: coleco/%.asm
	sjasm $< $@

res/tms9918.bin: ../asm/fonts/tms9918.s
	ophis -o $@ $<

gallery.sg: sg1000/sg1000bios.asm
vdpmodes.sg: sg1000/sg1000bios.asm res/g2loom.bin res/mltdemo.bin res/tms9918.bin
gallery.col: coleco/coleco_bios.asm coleco/silent_start.asm
gallery.rom: msx/msxbios.asm
