ROMS = cbanner gallery nyancat recursion xorshift99
GROMS = gbanner gbanner2
HROMS = xsrnd

BINARIES = $(patsubst %,%c.bin,$(ROMS) $(HROMS)) $(patsubst %,%g.bin,$(GROMS) $(HROMS))
ROMCTGS = $(patsubst %,%.ctg,$(ROMS))
GROMCTGS = $(patsubst %,%.ctg,$(GROMS))
HROMCTGS = $(patsubst %,%.ctg,$(HROMS))
ROMRPKS = $(patsubst %,%.rpk,$(ROMS))
GROMRPKS = $(patsubst %,%.rpk,$(GROMS))
HROMRPKS = $(patsubst %,%.rpk,$(HROMS))

all-rpk: $(ROMRPKS) $(GROMRPKS) $(HROMRPKS)

all-ctg: $(ROMCTGS) $(GROMCTGS) $(HROMCTGS)

all-bin: $(BINARIES)

clean:
	rm -f $(BINARIES) $(ROMRPKS) $(GROMRPKS) $(HROMRPKS) $(ROMCTGS) $(GROMCTGS) $(HROMCTGS)

cbanner.asm: vdplib.asm
gallery.asm: vdplib.asm
nyancat.asm: vdplib.asm
xorshift99.asm: vdplib.asm
gbanner2.gpl: minuet.bin
xsrnd.gpl: minuet.bin

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

$(HROMCTGS): %.ctg: %c.bin %g.bin
	convert-ctg $(subst c.bin,.bin,$<)

$(HROMRPKS): %.rpk: %c.bin %g.bin
	tools/makerpk.py $(subst c.bin,,$<)

minuet.bin: ../sound/musicmacro.py tools/makesoundlist.py
	tools/makesoundlist.py
