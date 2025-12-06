ROMS = cbanner gallery nyancat xorshift99
GROMS = gbanner xsrnd

BINARIES = $(patsubst %,%c.bin,$(ROMS)) $(patsubst %,%g.bin,$(GROMS))
ROMCTGS = $(patsubst %,%.ctg,$(ROMS))
GROMCTGS = $(patsubst %,%.ctg,$(GROMS))
ROMRPKS = $(patsubst %,%.rpk,$(ROMS))
GROMRPKS = $(patsubst %,%.rpk,$(GROMS))

all-rpk: $(ROMRPKS) $(GROMRPKS)

all-ctg: $(ROMCTGS) $(GROMCTGS)

all-bin: $(BINARIES)

clean:
	rm -f $(BINARIES) $(ROMRPKS) $(GROMRPKS) $(ROMCTGS) $(GROMCTGS)

cbanner.asm: vdplib.asm
gallery.asm: vdplib.asm
nyancat.asm: vdplib.asm
xorshift99.asm: vdplib.asm

%c.bin: %.asm
	xas99.py -Rb -o $@ $<

%g.bin: %.gpl
	xga99.py -o $@ $<

$(ROMRPKS): %.rpk: %.asm
	xas99.py -Rc $<

$(GROMRPKS): %.rpk: %.gpl
	xga99.py -c $<

$(ROMCTGS): %.ctg: %c.bin
	convert-ctg $(subst c.bin,.bin,$<)

$(GROMCTGS): %.ctg: %g.bin
	convert-ctg $(subst g.bin,.bin,$<)
