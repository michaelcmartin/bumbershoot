SMSROMS=hello.sms sprcont.sms rainbow.sms multiscroll.sms horizmap.sms raster.sms
LISTFILES=$(patsubst %.sms,%.lst,$(SMSROMS))
FONTS=sinestra.bin halogen.bin
TOOLS=smsfix

all: $(SMSROMS)

%.sms: %.asm smsfix
	sjasm $< $@ && ./smsfix $@

$(FONTS): %.bin: ../asm/fonts/%.s
	ophis -o $@ $<

smsfix: tools/smsfix.c
	gcc -O2 -o $@ $<

clean:
	rm -f $(SMSROMS) $(TOOLS) $(LISTFILES)

tidy:
	rm -rf $(TOOLS) $(LISTFILES)

hello.asm: sega8bios.asm
sprcont.asm: sega8bios.asm ../genesis/res/nyansong.bin sinestra.bin
rainbow.asm: sega8bios.asm sinestra.bin
multiscroll.asm: sega8bios.asm sinestra.bin halogen.bin
raster.asm: sega8bios.asm
